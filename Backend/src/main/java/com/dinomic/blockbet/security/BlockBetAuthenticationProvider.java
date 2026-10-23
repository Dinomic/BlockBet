package com.dinomic.blockbet.security;

import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class BlockBetAuthenticationProvider implements AuthenticationProvider {
    @Autowired
    private UserDetailsService userDetailsService;

    PasswordEncoder encoder = new BCryptPasswordEncoder();

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String email = authentication.getPrincipal().toString();
        String password = authentication.getCredentials().toString();

        BlockBetUserDetails userDetails = (BlockBetUserDetails) userDetailsService.loadUserByUsername(email);

        if(!encoder.matches(userDetails.getPassword(), password)){
            throw new BlockBetException(BlockBetError.UNAUTHORIZED, "Bad Credential");
        }

        return new BlockBetAuthenticationToken(userDetails);
    }

    @Override
    public boolean supports(Class<?> aClass) {
        return aClass.equals(UsernamePasswordAuthenticationToken.class);
    }

}