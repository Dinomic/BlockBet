package com.dinomic.blockbet.security;

import com.dinomic.blockbet.entities.Account;
import com.dinomic.blockbet.entities.Authority;
import com.dinomic.blockbet.services.IAccountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;


@Component
public class BlockBetUserDetailService implements UserDetailsService {

    @Autowired
    private IAccountService accountService;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {

        Account account = accountService.getAccountByEmail(email);
        if (account == null) {
            throw new UsernameNotFoundException("No user with email " + email);
        }

        BlockBetUserDetail userDetail = new BlockBetUserDetail();
        userDetail.setAccountId(account.getAccountId());
        userDetail.setEmail(account.getEmail());
        userDetail.setPassword(account.getPassword());
        userDetail.setAuthorities(account.getAuthorities().stream().map(authority -> authority.getName().toString()).collect(Collectors.toList()));

        return userDetail;
    }
}
