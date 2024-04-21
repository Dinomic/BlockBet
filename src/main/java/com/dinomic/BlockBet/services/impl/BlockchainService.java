package com.dinomic.BlockBet.services.impl;

import com.dinomic.BlockBet.IBBAppConstant;
import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.BBTransactionReceipt;
import com.dinomic.BlockBet.entities.Wallet;
import com.dinomic.BlockBet.enums.TransactionType;
import com.dinomic.BlockBet.exception.BlockBetError;
import com.dinomic.BlockBet.exception.BlockBetException;
import com.dinomic.BlockBet.repositories.ITransactionReceiptRepo;
import com.dinomic.BlockBet.repositories.IWalletRepo;
import com.dinomic.BlockBet.services.IBlockchainService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.RawTransaction;
import org.web3j.crypto.WalletUtils;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.response.EthGetBalance;
import org.web3j.protocol.core.methods.response.EthGetTransactionCount;
import org.web3j.protocol.core.methods.response.EthGetTransactionReceipt;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.tx.RawTransactionManager;
import org.web3j.tx.Transfer;
import org.web3j.utils.Convert;

import java.io.File;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class BlockchainService implements IBlockchainService {

    @Autowired
    Web3j web3j;

    @Autowired
    IWalletRepo walletRepo;

    @Autowired
    ITransactionReceiptRepo transactionReceiptRepo;

    @Override
    public Wallet createWallet(Account account, String password) throws Exception {
        Wallet result = new Wallet();

        if (StringUtils.isEmpty(password)) {
            throw new Exception("Password cannot be empty");
        }

        if (account == null) {
            throw new Exception("Account cannot be null");
        }

        String fileName = WalletUtils.generateNewWalletFile(
                password, new File(IBBAppConstant.WALLET_FOLDER_PATH));

        Credentials credentials = WalletUtils.loadCredentials(
                password,
                IBBAppConstant.WALLET_FOLDER_PATH + fileName);

        result.setAddress(credentials.getAddress());
        result.setPublicKey(IBBAppConstant.HEX_PREFIX + credentials.getEcKeyPair().getPublicKey().toString(16));
        result.setPrivateKey(IBBAppConstant.HEX_PREFIX + credentials.getEcKeyPair().getPrivateKey().toString(16));
        result.setAccount(account);

        return walletRepo.save(result);
    }

    @Override
    public Map<String, BigInteger> getWalletBalances(List<String> walletAddresses) {
        Map<String, BigInteger> result = new HashMap<>();

        for (String address : walletAddresses) {
            result.put(address, getWalletBalance(address));
        }

        return result;
    }

    @Override
    public BigInteger getWalletBalance(String walletAddress) {
        try {
            EthGetBalance ethGetBalance = web3j.ethGetBalance(walletAddress,
                    DefaultBlockParameterName.LATEST).send();

            return ethGetBalance.getBalance();
        } catch (IOException e) {
            throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "Error getting wallet balance");
        }
    }

    @Override
    public String transferEth(Wallet from, String toAddress, BigInteger weiAmount) {

        try {
            EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
                    from.getAddress(), DefaultBlockParameterName.PENDING).sendAsync().get();
            BigInteger nonce = ethGetTransactionCount.getTransactionCount();
            BigInteger gasPrice = web3j.ethGasPrice().send().getGasPrice();

            RawTransaction rawTransaction  = RawTransaction.createEtherTransaction(
                    nonce, gasPrice, Transfer.GAS_LIMIT, toAddress, weiAmount);

            Credentials credentials = Credentials.create(from.getPrivateKey());
            RawTransactionManager rawTransactionManager = new RawTransactionManager(web3j, credentials);

            String txHash = rawTransactionManager.signAndSend(rawTransaction).getTransactionHash();

            BBTransactionReceipt decoyReceipt = new BBTransactionReceipt();
            decoyReceipt.setHash(txHash);
            decoyReceipt.setFromAddress(from.getAddress());
            decoyReceipt.setToAddress(toAddress);
            decoyReceipt.setTransactionType(TransactionType.TOKEN_TRANSFER);
            transactionReceiptRepo.save(decoyReceipt);

            return txHash;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void transferEthFromFaucet(String toAddress, Integer etherAmount) {
        try {
            TransactionReceipt transactionReceipt = Transfer.sendFunds(
                    web3j, Credentials.create("0x" + "b0386e69d886de4f3d3fdef43e783c746ac995d56a4199cc3002eb5b512dc3f7"),
                    toAddress, BigDecimal.valueOf(etherAmount), Convert.Unit.ETHER).send();

            transactionReceiptRepo.save(transactionReceiptConvert(transactionReceipt, TransactionType.FUNDING, Boolean.TRUE));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void checkUnDoneTransactions() {
        List<BBTransactionReceipt> toCheckReceipts = transactionReceiptRepo.getUnDoneTxReceipts(BigInteger.ZERO, BigInteger.valueOf(100));
        toCheckReceipts.stream().forEach(receipt -> {
            try {
                EthGetTransactionReceipt result = web3j.ethGetTransactionReceipt(receipt.getHash()).send();
//                if (result != null) {
//                    if (result.hasError())
//                }
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        });
    }

    @Override
    public BBTransactionReceipt checkUnDoneTransaction(String txHash) {
        try {

            BBTransactionReceipt bbReceipt = transactionReceiptRepo.findByHash(txHash).orElseThrow(() -> new BlockBetException(BlockBetError.BB_RECEIPT_NOT_FOUND,
                    "transaction receipt not found with hash: " + txHash));

            if (bbReceipt.getSuccess() != null) {
                return bbReceipt;
            }

            EthGetTransactionReceipt result = web3j.ethGetTransactionReceipt(txHash).send();

            if (result == null) {
                return bbReceipt;
            }

            if (result.hasError()) {
                throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "Error processing request: "
                        + result.getError().getMessage());
            }

            Optional<TransactionReceipt> receiptOpt = result.getTransactionReceipt();
            if (receiptOpt.isEmpty()) {
                return bbReceipt;
            }

            TransactionReceipt receipt = receiptOpt.get();


            if (!RECEIPT_STATUS_SUCCESS.equals(receipt.getStatus())) {
                bbReceipt.setSuccess(Boolean.FALSE);
                return  transactionReceiptRepo.save(bbReceipt);
            }
            bbReceipt.setSuccess(Boolean.TRUE);
            bbReceipt.setBlockHash(receipt.getBlockHash());
            bbReceipt.setBlockNumber(receipt.getBlockNumber().intValue());
            bbReceipt.setGasUsed(receipt.getGasUsed().intValue());
            bbReceipt.setEffectiveGasPrice(Integer.parseInt(receipt.getEffectiveGasPrice().substring(3), 16));

            return transactionReceiptRepo.save(bbReceipt);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private BBTransactionReceipt transactionReceiptConvert(TransactionReceipt receipt, TransactionType type, Boolean isSuccess) {
        BBTransactionReceipt result = new BBTransactionReceipt();

        result.setTransactionType(type);
        result.setHash(receipt.getTransactionHash());
        result.setFromAddress(TransactionType.FUNDING.equals(type) ?  IBBAppConstant.INTERNAL_ACCOUNT : receipt.getFrom());
        result.setToAddress(receipt.getTo());
        result.setBlockHash(receipt.getBlockHash());
        result.setBlockNumber(receipt.getBlockNumber().intValue());
        result.setGasUsed(receipt.getGasUsed().intValue());
        result.setEffectiveGasPrice(Integer.parseInt(receipt.getEffectiveGasPrice().substring(3), 16));
        result.setSuccess(Boolean.TRUE.equals(isSuccess));

        return result;
    }
}
