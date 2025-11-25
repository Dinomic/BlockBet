package com.dinomic.blockbet.security;

import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;

import java.util.Collection;

public class BlockBetAuthenticationToken extends AbstractAuthenticationToken {

    private final BlockBetUserDetail userDetail;

    public BlockBetUserDetail getUserDetail() {
        return userDetail;
    }

    public BlockBetAuthenticationToken(BlockBetUserDetail userDetail) {
        super(userDetail.getAuthorities());
        this.userDetail = userDetail;
        setAuthenticated(true);
    }

    @Override
    public Object getCredentials() {
        return null;
    }

    @Override
    public BlockBetUserDetail getPrincipal() {
        return userDetail;
    }
}
