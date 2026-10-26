package com.dinomic.blockbet;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.security.BlockBetAuthenticationToken;
import com.dinomic.blockbet.services.IAccountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class BlockBetUtil {

    @Autowired
    IAccountService accountService;

    public Account getAccountFromRequest() {
        BlockBetAuthenticationToken userDetail = (BlockBetAuthenticationToken) SecurityContextHolder.getContext().getAuthentication();
        return accountService.getAccountByAccountId(userDetail.getPrincipal().getAccountId());
    }
}
