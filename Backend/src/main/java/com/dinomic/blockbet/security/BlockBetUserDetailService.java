package com.dinomic.blockbet.security;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.services.IAccountService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;

@Component
public class BlockBetUserDetailService implements UserDetailsService {

    private static final Logger log = LoggerFactory.getLogger(BlockBetUserDetailService.class);

    @Autowired
    private IAccountService accountService;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {

        Account account = accountService.getAccountByEmail(email);
        if (account == null) {
            log.info("No user with email {}", email);
            throw new BlockBetException(BlockBetError.UNAUTHORIZED, "Bad Credential");
        }

        BlockBetUserDetails userDetail = new BlockBetUserDetails();
        userDetail.setAccountId(account.getAccountId());
        userDetail.setEmail(account.getEmail());
        userDetail.setPassword(account.getPassword());
        userDetail.setAuthorities(account.getAuthorities().stream().map(authority -> authority.getName().toString()).collect(Collectors.toList()));

        return userDetail;
    }
}
