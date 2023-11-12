package com.dinomic.BlockBet.services.impl;

import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Authority;
import com.dinomic.BlockBet.enums.Role;
import com.dinomic.BlockBet.repositories.IAccountRepo;
import com.dinomic.BlockBet.repositories.IWalletRepo;
import com.dinomic.BlockBet.services.IAccountService;
import com.dinomic.BlockBet.services.IBlockchainService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Set;

@Service
public class AccountService implements IAccountService {

    @Autowired
    IAccountRepo accountRepo;

    @Autowired
    IWalletRepo walletRepo;

    @Autowired
    IBlockchainService blockchainService;

    @Override
    public Account getAccountByAccountId(Long id) {
        return accountRepo.findById(id).orElseThrow();
    }

    @Override
    public Account getAccountByEmail(String email) {
        if (StringUtils.isEmpty(email)) return null;

        return accountRepo.findByEmail(email).orElse(null);
    }

    @Override
    public Account addNewAccount(String email, String password) {
        Account account = new Account();
        account.setEmail(email);
        account.setUsername(email);
        account.setPassword(password);
        Authority defaultAuthority = new Authority(account, Role.ROLE_BETTOR);
        account.setAuthorities(Set.of(defaultAuthority));
        return accountRepo.save(account);
    }
}
