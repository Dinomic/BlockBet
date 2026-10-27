package com.dinomic.blockbet.services;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.Wallet;

public interface IBlockchainService {

    Wallet createWallet(Account account, String password) throws Exception;

    void transferEthFromFaucet(String address, Integer etherAmount);
}
