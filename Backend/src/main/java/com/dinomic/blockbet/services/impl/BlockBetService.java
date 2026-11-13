package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.*;
import com.dinomic.blockbet.IBlockBetConstant;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.BBTransactionReceipt;
import com.dinomic.blockbet.repositories.IAccountRepo;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import com.dinomic.blockbet.daos.Wallet;
import com.dinomic.blockbet.mappers.GeneralMapper;
import com.dinomic.blockbet.services.IAccountService;
import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import com.dinomic.blockbet.repositories.IWalletRepo;
import com.dinomic.blockbet.services.IBlockBetService;
import com.dinomic.blockbet.services.IBlockchainService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class BlockBetService implements IBlockBetService {

    @Autowired
    IAccountService accountService;

    @Autowired
    IBlockchainService blockchainService;

    @Autowired
    IWalletRepo walletRepo;

    @Autowired
    IAccountRepo accountRepo;

    @Autowired
    IBBTransactionReceiptRepo receiptRepo;

    @Autowired
    TransferReceiptRecorder receiptRecorder;

    @Override
    @Transactional(readOnly = true)
    public InfosGetResponse handleInfosGetRequest(Account account) {
        return GeneralMapper.INSTANCE.accountToInfosGetResponse(
            accountService.getAccountByAccountId(account.getAccountId()));
    }

    @Override
    @Transactional
    public InfosGetResponse handleInfosPutRequest(Account account, InfosPutRequest request) {
        Account updated = accountService.updateAccountInfo(
            account.getAccountId(),
            request.getDisplayName(),
            request.getAvatarUrl(),
            request.getPhone(),
            request.getAddress(),
            request.getNationality(),
            request.getDateOfBirth(),
            GeneralMapper.INSTANCE.toGender(request.getGender()));

        return GeneralMapper.INSTANCE.accountToInfosGetResponse(updated);
    }

    /**
     * Wallet creation and its faucet funding form one unit of work: if funding fails the
     * wallet row is rolled back, so no unfunded wallet is left behind.
     */
    @Override
    @Transactional
    public WalletPostResponse handleWalletPostRequest(Account account, WalletPostRequest request){
        WalletPostResponse response = new WalletPostResponse();

        // Lock the account row first so concurrent requests cannot both pass the limit check.
        Account lockedAccount = accountRepo.findByIdForUpdate(account.getAccountId()).orElseThrow(() ->
            new BlockBetException(BlockBetError.UNAUTHORIZED, "Account not found"));

        if (walletRepo.countByAccount(lockedAccount) >= IBlockBetConstant.MAX_WALLETS_PER_ACCOUNT) {
            throw new BlockBetException(BlockBetError.WALLET_LIMIT_REACHED,
                "You can have at most " + IBlockBetConstant.MAX_WALLETS_PER_ACCOUNT + " wallets per account");
        }

        Wallet newWallet;

        try {
            newWallet = blockchainService.createWallet(lockedAccount, request.getPassword());
        } catch (BlockBetException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        response.setAddress(newWallet.getAddress());
        response.setPublicKey(newWallet.getPublicKey());
        response.setPrivateKey(newWallet.getPrivateKey());

        blockchainService.transferEthFromFaucet(newWallet.getAddress(), 10);

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public WalletsGetResponse handleWalletsGetRequest(Account account) {
        WalletsGetResponse response = new WalletsGetResponse();

        List<Wallet> accountWallets = walletRepo.findAllByAccount(account);

        Map<String, BigInteger> walletBalances = blockchainService.getWalletBalances(
            accountWallets.stream().map(Wallet::getAddress).collect(Collectors.toList()));

        for (Wallet wallet : accountWallets) {
            blockbet.openapi.model.Wallet responseWallet = new blockbet.openapi.model.Wallet();

            responseWallet.setAddress(wallet.getAddress());
            responseWallet.setPublicKey(wallet.getPublicKey());
            responseWallet.setPrivateKey(wallet.getPrivateKey());
            responseWallet.setBalance(new BigDecimal(walletBalances.getOrDefault(wallet.getAddress(), BigInteger.ZERO)));

            response.addWalletsItem(responseWallet);
        }

        return response;
    }

    private static final Pattern ADDRESS_PATTERN = Pattern.compile("^0x[0-9a-fA-F]{40}$");
    private static final Pattern IDEMPOTENCY_KEY_PATTERN = Pattern.compile("^[A-Za-z0-9_-]{1,64}$");

    /**
     * Ownership is proven by the authenticated account plus the wallet lookup (the server holds the key).
     * The wallet row is locked for the whole transaction, so transfers from one wallet run one at a time.
     */
    @Override
    @Transactional
    public TransferTokensPutResponse handleTransferTokensPutRequest(Account account, TransferTokensPutRequest request) {
        TransferTokensPutResponse response = new TransferTokensPutResponse();

        Wallet fromWallet = walletRepo.findByAccountAndAddressForUpdate(account, request.getFromAddress()).orElseThrow(() ->
            new BlockBetException(BlockBetError.WALLET_NOT_FOUND, "Wallet not found with associated account")
        );

        String toAddress = request.getToAddress();
        BigInteger amount = request.getAmount();
        String idempotencyKey = request.getIdempotencyKey();

        if (idempotencyKey == null || !IDEMPOTENCY_KEY_PATTERN.matcher(idempotencyKey).matches()) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST,
                "idempotencyKey must be 1-64 characters: letters, digits, '-' or '_'");
        }
        if (toAddress == null || !ADDRESS_PATTERN.matcher(toAddress).matches()) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "toAddress is not a valid wallet address");
        }
        if (amount == null || amount.signum() <= 0) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "amount must be greater than 0");
        }
        if (toAddress.equalsIgnoreCase(fromWallet.getAddress())) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "Cannot transfer to the same wallet");
        }

        // A retried request (same key) must not send the tokens twice.
        Optional<BBTransactionReceipt> previous =
            receiptRepo.findByFromAddressAndIdempotencyKey(fromWallet.getAddress(), idempotencyKey);
        if (previous.isPresent()) {
            BBTransactionReceipt original = previous.get();
            if (!original.getToAddress().equalsIgnoreCase(toAddress)) {
                throw new BlockBetException(BlockBetError.INVALID_REQUEST,
                    "idempotencyKey was already used for a different transfer");
            }
            // Pending but unknown to the node means the earlier broadcast never arrived: send it afresh.
            if (original.getSuccess() != null || blockchainService.transactionExists(original.getHash())) {
                response.setTxHash(original.getHash());
                return response;
            }
            receiptRecorder.markFailed(original.getHash());
        }

        response.setTxHash(blockchainService.transferEth(fromWallet, toAddress, amount, idempotencyKey));
        return response;
    }

    @Override
    public ReceiptsGetResponse handleReceiptsGetRequest(BigInteger offset, BigInteger limit) {
        return null;
    }
}
