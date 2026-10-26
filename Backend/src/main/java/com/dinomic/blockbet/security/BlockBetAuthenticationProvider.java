package com.dinomic.blockbet.security;

import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Objects;

@Component
public class BlockBetAuthenticationProvider implements AuthenticationProvider {
    @Autowired
    private UserDetailsService userDetailsService;

    @Autowired
    PasswordEncoder encoder;

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String email = Objects.requireNonNull(authentication.getPrincipal()).toString();
        String password = Objects.requireNonNull(authentication.getCredentials()).toString();

        BlockBetUserDetails userDetails = (BlockBetUserDetails) userDetailsService.loadUserByUsername(email);

        if(!encoder.matches(password, userDetails.getPassword())){
            throw new BlockBetException(BlockBetError.UNAUTHORIZED, "Bad Credential");
        }

        return new BlockBetAuthenticationToken(userDetails);
    }

    @Override
    public boolean supports(Class<?> aClass) {
        return aClass.equals(UsernamePasswordAuthenticationToken.class);
    }

}