package com.dinomic.blockbet.services;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.Wallet;
import jakarta.validation.constraints.NotNull;

import java.math.BigInteger;
import java.util.List;
import java.util.Map;

public interface IBlockchainService {

    Wallet createWallet(Account account, String password) throws Exception;

    void transferEthFromFaucet(String address, Integer etherAmount);

    Map<String, BigInteger> getWalletBalances(@NotNull List<String> walletAddresses);

    BigInteger getWalletBalance(@NotNull String walletAddress);

    String transferEth(Wallet fromWallet, @NotNull String toAddress, BigInteger amount);
}
