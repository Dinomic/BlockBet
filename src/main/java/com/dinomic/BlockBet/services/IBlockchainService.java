package com.dinomic.BlockBet.services;

import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.BBTransactionReceipt;
import com.dinomic.BlockBet.entities.Wallet;

import javax.validation.constraints.NotNull;
import java.math.BigInteger;
import java.util.List;
import java.util.Map;

public interface IBlockchainService {

    static String RECEIPT_STATUS_SUCCESS = "0x1";

    Wallet createWallet(Account account, String password) throws Exception;

    String transferEth(@NotNull Wallet from, @NotNull String toAddress, @NotNull BigInteger weiAmount);

    void transferEthFromFaucet(@NotNull String toAddress, @NotNull Integer etherAmount);

    Map<String, BigInteger> getWalletBalances(@NotNull List<String> walletAddresses);

    BigInteger getWalletBalance(@NotNull String walletAddress);

    void checkUnDoneTransactions();


    BBTransactionReceipt checkUnDoneTransaction(@NotNull String txHash);
}
