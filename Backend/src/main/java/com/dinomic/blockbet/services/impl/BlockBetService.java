package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.*;
import com.dinomic.blockbet.IBlockBetConstant;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.repositories.IAccountRepo;
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

    @Override
    @Transactional
    public TransferTokensPutResponse handleTransferTokensPutRequest(Account account, TransferTokensPutRequest request) {
        TransferTokensPutResponse response = new TransferTokensPutResponse();

        Wallet fromWallet = walletRepo.findByAccountAndAddress(account, request.getFromAddress()).orElseThrow(() ->
            new BlockBetException(BlockBetError.WALLET_NOT_FOUND, "Wallet not found with associated account")
        );

        if (!fromWallet.getPrivateKey().equals(request.getFromPrivateKey())) {
            throw new BlockBetException(BlockBetError.INPUT_PRIVATE_KEY_NOT_MATCH, "input private key not match");
        }

        response.setTxHash(blockchainService.transferEth(fromWallet, request.getToAddress(),
            request.getAmount()));


        return response;
    }

    @Override
    public ReceiptsGetResponse handleReceiptsGetRequest(BigInteger offset, BigInteger limit) {
        return null;
    }
}
