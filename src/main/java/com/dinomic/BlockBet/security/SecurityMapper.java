package com.dinomic.blockbet.security;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.Claim;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.dinomic.blockbet.security.jwt.JwtProperties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.sql.Date;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Component
public class SecurityMapper {

    @Autowired
    private JwtProperties properties;

    public BlockBetUserDetail decodedJwtToBlockBetUserDetail(DecodedJWT decodedJWT) {
        BlockBetUserDetail result = new BlockBetUserDetail();

        result.setAccountId(Long.valueOf(decodedJWT.getSubject()));
        result.setEmail(decodedJWT.getClaim("email").asString());
        result.setAuthorities(extractRoles(decodedJWT.getClaim("roles")));

        return result;
    }

    private List<String> extractRoles (Claim rolesClaim) {
        if (rolesClaim.isNull()) {
            new ArrayList<>();
        }

        return  rolesClaim.asList(String.class);
    }


    public String issueJwtToken(BlockBetAuthenticationToken token) {

        return JWT.create()
                .withExpiresAt(Date.from(Instant.now().plus(Duration.ofMinutes(15))))
                .withSubject(String.valueOf(token.getUserDetail().getAccountId()))
                .withClaim("email", token.getUserDetail().getEmail())
                .withClaim("roles", token.getUserDetail().getRoles())
                .sign(Algorithm.HMAC256(properties.getSecretKey()));
    }
}
