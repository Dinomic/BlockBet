package com.dinomic.blockbet.services.impl;

import com.dinomic.blockbet.IBlockBetConstant;
import com.dinomic.blockbet.config.BlockchainProperties;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.BBTransactionReceipt;
import com.dinomic.blockbet.daos.Wallet;
import com.dinomic.blockbet.enums.TransactionType;
import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import com.dinomic.blockbet.repositories.IWalletRepo;
import com.dinomic.blockbet.services.IBlockchainService;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.RawTransaction;
import org.web3j.crypto.WalletUtils;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.response.EthGetBalance;
import org.web3j.protocol.core.methods.response.EthGetTransactionCount;
import org.web3j.protocol.core.methods.response.EthSendTransaction;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.tx.RawTransactionManager;
import org.web3j.tx.TransactionManager;
import org.web3j.tx.Transfer;
import org.web3j.utils.Convert;

import java.io.File;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class BlockchainService implements IBlockchainService {
    private static final Logger log = LoggerFactory.getLogger(BlockchainService.class);

    @Autowired
    BlockchainProperties blockchainProperties;

    @Autowired
    Web3j web3j;

    @Autowired
    IWalletRepo walletRepo;

    @Autowired
    IBBTransactionReceiptRepo transactionReceiptRepo;

    @Override
    public Wallet createWallet(Account account, String password) throws Exception {

        Wallet result = new Wallet();

        if (StringUtils.isEmpty(password)) {
            throw new Exception("Password cannot be empty");
        }

        if (account == null) {
            throw new Exception("Account cannot be null");
        }

        File walletDirectory = new File(IBlockBetConstant.WALLET_FOLDER_PATH);

        String fileName = WalletUtils.generateNewWalletFile(
            password, walletDirectory);

        Credentials credentials = WalletUtils.loadCredentials(
            password,
            IBlockBetConstant.WALLET_FOLDER_PATH + fileName);

        result.setAddress(credentials.getAddress());
        result.setPublicKey(IBlockBetConstant.HEX_PREFIX + credentials.getEcKeyPair().getPublicKey().toString(16));
        result.setPrivateKey(IBlockBetConstant.HEX_PREFIX + credentials.getEcKeyPair().getPrivateKey().toString(16));
        result.setAccount(account);

        return walletRepo.save(result);
    }

    @Override
    public void transferEthFromFaucet(String toAddress, Integer etherAmount) {
        try {
            Credentials faucetCredentials = Credentials.create(blockchainProperties.mainAccount().privateKey());
            TransactionManager txManager = new RawTransactionManager(web3j, faucetCredentials, blockchainProperties.network().chainId());
            Transfer transfer = new Transfer(web3j, txManager);
            TransactionReceipt transactionReceipt = transfer.sendFunds(
                toAddress, BigDecimal.valueOf(etherAmount), Convert.Unit.ETHER).send();

            transactionReceiptRepo.save(transactionReceiptConvert(transactionReceipt, TransactionType.FUNDING, Boolean.TRUE));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private BBTransactionReceipt transactionReceiptConvert(TransactionReceipt receipt, TransactionType type, Boolean isSuccess) {
        BBTransactionReceipt result = new BBTransactionReceipt();

        result.setTransactionType(type);
        result.setHash(receipt.getTransactionHash());
        result.setFromAddress(TransactionType.FUNDING.equals(type) ?  IBlockBetConstant.INTERNAL_ACCOUNT : receipt.getFrom());
        result.setToAddress(receipt.getTo());
        result.setBlockHash(receipt.getBlockHash());
        result.setBlockNumber(receipt.getBlockNumber().intValue());
        result.setGasUsed(receipt.getGasUsed().intValue());
        result.setEffectiveGasPrice(Integer.parseInt(receipt.getEffectiveGasPrice().substring(3), 16));
        result.setSuccess(Boolean.TRUE.equals(isSuccess));

        return result;
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
            RawTransactionManager rawTransactionManager = new RawTransactionManager(web3j, credentials, blockchainProperties.network().chainId());

            EthSendTransaction ethSendTransaction = rawTransactionManager.signAndSend(rawTransaction);
            String txHash = ethSendTransaction.getTransactionHash();

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
}
