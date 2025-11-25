package com.dinomic.blockbet.services.impl;

import com.dinomic.blockbet.entities.Account;
import com.dinomic.blockbet.entities.Authority;
import com.dinomic.blockbet.enums.Role;
import com.dinomic.blockbet.repositories.IAccountRepo;
import com.dinomic.blockbet.repositories.IWalletRepo;
import com.dinomic.blockbet.services.IAccountService;
import com.dinomic.blockbet.services.IBlockchainService;
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
