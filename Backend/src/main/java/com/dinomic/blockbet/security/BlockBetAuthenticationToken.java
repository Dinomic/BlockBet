package com.dinomic.blockbet.security;

import org.springframework.security.authentication.AbstractAuthenticationToken;

public class BlockBetAuthenticationToken extends AbstractAuthenticationToken {

    private final BlockBetUserDetails userDetail;

    public BlockBetUserDetails getUserDetail() {
        return userDetail;
    }

    public BlockBetAuthenticationToken(BlockBetUserDetails userDetail) {
        super(userDetail.getAuthorities());
        this.userDetail = userDetail;
        setAuthenticated(true);
    }

    @Override
    public Object getCredentials() {
        return null;
    }

    @Override
    public BlockBetUserDetails getPrincipal() {
        return userDetail;
    }
}