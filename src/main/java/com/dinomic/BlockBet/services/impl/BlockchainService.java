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
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.tx.RawTransactionManager;
import org.web3j.tx.Transfer;
import org.web3j.tx.gas.DefaultGasProvider;
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
                password, new File(IBBAppConstant.walletFolderPath));

        Credentials credentials = WalletUtils.loadCredentials(
                password,
                IBBAppConstant.walletFolderPath + fileName);

        result.setAddress(credentials.getAddress());
        result.setPublicKey(IBBAppConstant.hexPrefix + credentials.getEcKeyPair().getPublicKey().toString(16));
        result.setPrivateKey(IBBAppConstant.hexPrefix + credentials.getEcKeyPair().getPrivateKey().toString(16));
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

            return rawTransactionManager.signAndSend(rawTransaction).getTransactionHash();
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

            transactionReceiptRepo.save(transactionReceiptConvert(transactionReceipt, TransactionType.FUNDING));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private BBTransactionReceipt transactionReceiptConvert(TransactionReceipt receipt, TransactionType type) {
        BBTransactionReceipt result = new BBTransactionReceipt();

        result.setTransactionType(type);
        result.setHash(receipt.getTransactionHash());
        result.setFromAddress(TransactionType.FUNDING.equals(type) ?  IBBAppConstant.internalAccount : receipt.getFrom());
        result.setToAddress(receipt.getTo());
        result.setBlockHash(receipt.getBlockHash());
        result.setBlockNumber(receipt.getBlockNumber().intValue());
        result.setGasUsed(receipt.getGasUsed().intValue());
        result.setEffectiveGasPrice(Integer.parseInt(receipt.getEffectiveGasPrice().substring(3), 16));

        return result;
    }
}
