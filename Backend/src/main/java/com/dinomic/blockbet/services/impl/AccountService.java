package com.dinomic.blockbet.services.impl;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.AccountDetail;
import com.dinomic.blockbet.daos.Authority;
import com.dinomic.blockbet.enums.AccountRole;
import com.dinomic.blockbet.enums.Gender;
import com.dinomic.blockbet.repositories.IAccountRepo;
import com.dinomic.blockbet.services.IAccountService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Set;

@Service
public class AccountService implements IAccountService {

    @Autowired
    private PasswordEncoder passwordEncoder;

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
        account.setPassword(passwordEncoder.encode(password));
        Authority defaultAuthority = new Authority(account, AccountRole.ROLE_BETTOR);
        account.setAuthorities(Set.of(defaultAuthority));
        return accountRepo.save(account);
    }

    @Override
    @Transactional
    public Account updateAccountInfo(Long accountId, String displayName, String avatarUrl, String phone,
                                     String address, String nationality, LocalDate dateOfBirth, Gender gender) {
        Account account = getAccountByAccountId(accountId);

        if (displayName != null) account.setDisplayName(displayName);
        if (avatarUrl != null) account.setAvatarUrl(avatarUrl);

        if (phone != null || address != null || nationality != null || dateOfBirth != null || gender != null) {
            AccountDetail detail = account.getAccountDetail();
            if (detail == null) {
                detail = new AccountDetail();
                detail.setAccount(account);
                account.setAccountDetail(detail);
            }
            if (phone != null) detail.setPhone(phone);
            if (address != null) detail.setAddress(address);
            if (nationality != null) detail.setNationality(nationality.toUpperCase());
            if (dateOfBirth != null) detail.setDateOfBirth(dateOfBirth);
            if (gender != null) detail.setGender(gender);
        }

        return accountRepo.save(account);
    }
}
