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

    /**
     * Signs and broadcasts a transfer and returns its transaction hash. A durable record is written
     * before the broadcast; {@code idempotencyKey} is stored with it.
     */
    String transferEth(Wallet fromWallet, @NotNull String toAddress, BigInteger amount, @NotNull String idempotencyKey);

    /** Whether the node knows this transaction (pending or mined). */
    boolean transactionExists(@NotNull String txHash);
}
