package com.dinomic.BlockBet.services;

import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Wallet;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.List;
import java.util.Map;

public interface IBlockchainService {

    Wallet createWallet(Account account, String password) throws Exception;

    void transferEth(@NotNull Wallet from, @NotNull String toAddress, @NotNull BigInteger weiAmount);

    void transferEthFromFaucet(@NotNull String toAddress, @NotNull BigDecimal etherAmount);

    Map<String, BigInteger> getWalletBalances(List<String> walletAddresses);

    BigInteger getWalletBalance(String walletAddress);
}
