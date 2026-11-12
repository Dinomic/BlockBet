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
import org.springframework.transaction.annotation.Transactional;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.Hash;
import org.web3j.crypto.RawTransaction;
import org.web3j.crypto.TransactionEncoder;
import org.web3j.crypto.WalletUtils;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.response.EthGetBalance;
import org.web3j.protocol.core.methods.response.EthSendTransaction;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.tx.RawTransactionManager;
import org.web3j.tx.TransactionManager;
import org.web3j.tx.Transfer;
import org.web3j.utils.Convert;
import org.web3j.utils.Numeric;

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
    @Transactional
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
    @Transactional
    public void transferEthFromFaucet(String toAddress, Integer etherAmount) {
        TransactionReceipt transactionReceipt;
        try {
            Credentials faucetCredentials = Credentials.create(blockchainProperties.mainAccount().privateKey());
            TransactionManager txManager = new RawTransactionManager(web3j, faucetCredentials, blockchainProperties.network().chainId());
            Transfer transfer = new Transfer(web3j, txManager);
            transactionReceipt = transfer.sendFunds(
                toAddress, BigDecimal.valueOf(etherAmount), Convert.Unit.ETHER).send();
        } catch (Exception e) {
            log.error("Faucet transfer to {} failed", toAddress, e);
            throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "Error funding wallet from faucet");
        }

        try {
            transactionReceiptRepo.save(transactionReceiptConvert(transactionReceipt, TransactionType.FUNDING, Boolean.TRUE));
        } catch (RuntimeException e) {
            // Funds are already on chain; keep the hash in the log so the record can be rebuilt manually.
            log.error("Faucet tx {} to {} succeeded on chain but its receipt could not be saved",
                transactionReceipt.getTransactionHash(), toAddress, e);
            throw e;
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

    /**
     * The transaction is signed locally first so its hash is known up front. The receipt row is
     * written (and flushed) <b>before</b> the transaction is broadcast: if the DB write fails nothing
     * has been sent, and if the broadcast fails the surrounding DB transaction rolls the row back.
     * That way a transfer can never exist on chain without a matching record.
     */
    @Override
    @Transactional
    public String transferEth(Wallet from, String toAddress, BigInteger weiAmount) {
        try {
            BigInteger nonce = web3j.ethGetTransactionCount(
                from.getAddress(), DefaultBlockParameterName.PENDING).send().getTransactionCount();
            BigInteger gasPrice = web3j.ethGasPrice().send().getGasPrice();

            RawTransaction rawTransaction = RawTransaction.createEtherTransaction(
                nonce, gasPrice, Transfer.GAS_LIMIT, toAddress, weiAmount);

            Credentials credentials = Credentials.create(from.getPrivateKey());
            byte[] signedMessage = TransactionEncoder.signMessage(
                rawTransaction, blockchainProperties.network().chainId(), credentials);
            String signedHex = Numeric.toHexString(signedMessage);
            String txHash = Hash.sha3(signedHex);

            BBTransactionReceipt pendingReceipt = new BBTransactionReceipt();
            pendingReceipt.setHash(txHash);
            pendingReceipt.setFromAddress(from.getAddress());
            pendingReceipt.setToAddress(toAddress);
            pendingReceipt.setTransactionType(TransactionType.TOKEN_TRANSFER);
            transactionReceiptRepo.saveAndFlush(pendingReceipt);

            EthSendTransaction ethSendTransaction = web3j.ethSendRawTransaction(signedHex).send();
            if (ethSendTransaction.hasError()) {
                throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR,
                    "Transfer rejected by network: " + ethSendTransaction.getError().getMessage());
            }

            return txHash;
        } catch (BlockBetException e) {
            throw e;
        } catch (Exception e) {
            log.error("Error transferring ETH from {} to {}", from.getAddress(), toAddress, e);
            throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "Error transferring tokens");
        }
    }
}
