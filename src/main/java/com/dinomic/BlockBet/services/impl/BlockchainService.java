package com.dinomic.BlockBet.services.impl;

import com.dinomic.BlockBet.IBBAppConstant;
import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Wallet;
import com.dinomic.BlockBet.repositories.IWalletRepo;
import com.dinomic.BlockBet.services.IBlockchainService;
import jakarta.validation.constraints.NotNull;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.Keys;
import org.web3j.crypto.WalletUtils;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.tx.Transfer;
import org.web3j.utils.Convert;

import java.io.File;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;

@Service
public class BlockchainService implements IBlockchainService {

    @Autowired
    Web3j web3j;

    @Autowired
    IWalletRepo walletRepo;

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
    public void transferEth(@NotNull Wallet from, @NotNull String toAddress, @NotNull BigInteger weiAmount) {

//        Credentials credentials = Credentials.create(from.getPrivateKey());
//        Credentials credentials = Credentials.create("0xbe4b83a3bff4fd9ec8b060e68fab18a2c0f78ac3943865931dcb73e6303dc48c");
        String randomAddress = null;
        try {
            randomAddress = Keys.getAddress(Keys.createEcKeyPair());
        } catch (InvalidAlgorithmParameterException e) {
            throw new RuntimeException(e);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        } catch (NoSuchProviderException e) {
            throw new RuntimeException(e);
        }


        try {
            TransactionReceipt transactionReceipt = Transfer.sendFunds(
                    web3j, Credentials.create("0x" + "b0386e69d886de4f3d3fdef43e783c746ac995d56a4199cc3002eb5b512dc3f7"),
                    "0x05d77d6951dadc8952d5ba9f1b91124a6570de70",
                    BigDecimal.valueOf(10000000), Convert.Unit.ETHER).send();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

    }

    @Override
    public void transferEthFromFaucet(@NotNull String toAddress, @NotNull BigDecimal etherAmount) {
        try {
            TransactionReceipt transactionReceipt = Transfer.sendFunds(
                    web3j, Credentials.create("0x" + "b0386e69d886de4f3d3fdef43e783c746ac995d56a4199cc3002eb5b512dc3f7"),
                    toAddress, etherAmount, Convert.Unit.ETHER).send();

            // to log funding transaction
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
