package com.dinomic.BlockBet.services.impl;

import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Wallet;
import com.dinomic.BlockBet.exception.BlockBetError;
import com.dinomic.BlockBet.exception.BlockBetException;
import com.dinomic.BlockBet.repositories.IWalletRepo;
import com.dinomic.BlockBet.services.IBlockchainService;
import com.dinomic.BlockBet.services.IWalletService;
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
