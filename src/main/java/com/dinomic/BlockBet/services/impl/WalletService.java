package com.dinomic.blockbet.services.impl;

import com.dinomic.blockbet.entities.Account;
import com.dinomic.blockbet.entities.Wallet;
import com.dinomic.blockbet.exception.BlockBetError;
import com.dinomic.blockbet.exception.BlockBetException;
import com.dinomic.blockbet.repositories.IWalletRepo;
import com.dinomic.blockbet.services.IBlockchainService;
import com.dinomic.blockbet.services.IWalletService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class WalletService implements IWalletService {

    @Autowired
    IWalletRepo walletRepo;

    @Autowired
    IBlockchainService blockchainService;

    @Override
    public List<Wallet> getWallets(Account account) {
        return walletRepo.findAllByAccount(account);
    }

    @Override
    public Wallet getWallet(Account account, String address) {
        return walletRepo.findByAccountAndAddress(account, address).orElseThrow(() ->
                new BlockBetException(BlockBetError.WALLET_NOT_FOUND, "Wallet not found with associated account"));
    }
}
