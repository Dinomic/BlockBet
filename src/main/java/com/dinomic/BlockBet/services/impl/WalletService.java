package com.dinomic.BlockBet.services.impl;

import blockbet.openapi.model.WalletPostRequest;
import blockbet.openapi.model.WalletPostResponse;
import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Authority;
import com.dinomic.BlockBet.entities.Wallet;
import com.dinomic.BlockBet.enums.Role;
import com.dinomic.BlockBet.repositories.IAccountRepo;
import com.dinomic.BlockBet.repositories.IWalletRepo;
import com.dinomic.BlockBet.services.IAccountService;
import com.dinomic.BlockBet.services.IBlockchainService;
import com.dinomic.BlockBet.services.IWalletService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

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
}
