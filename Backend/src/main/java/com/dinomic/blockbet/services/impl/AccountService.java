package com.dinomic.blockbet.services.impl;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.Authority;
import com.dinomic.blockbet.enums.AccountRole;
import com.dinomic.blockbet.repositories.IAccountRepo;
import com.dinomic.blockbet.services.IAccountService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Set;

@Service
public class AccountService implements IAccountService {

    @Autowired
    IAccountRepo accountRepo;

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
        Authority defaultAuthority = new Authority(account, AccountRole.ROLE_BETTOR);
        account.setAuthorities(Set.of(defaultAuthority));
        return accountRepo.save(account);
    }
}
