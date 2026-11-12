package com.dinomic.blockbet.security.jwt;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.Claim;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.dinomic.blockbet.security.BlockBetAuthenticationToken;
import com.dinomic.blockbet.security.BlockBetUserDetails;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Component
public class JwtSecurityMapper {

    @Autowired
    private JwtProperties properties;

    public BlockBetUserDetails decodedJwtToBlockBetUserDetail(DecodedJWT decodedJWT) {
        BlockBetUserDetails result = new BlockBetUserDetails();

        result.setAccountId(Long.valueOf(decodedJWT.getSubject()));
        result.setEmail(decodedJWT.getClaim("email").asString());
        result.setAuthorities(extractRoles(decodedJWT.getClaim("roles")));

        return result;
    }

    private List<String> extractRoles (Claim rolesClaim) {
        if (rolesClaim.isNull()) {
            return new ArrayList<>();
        }

        List<String> roles = rolesClaim.asList(String.class);
        return roles == null ? new ArrayList<>() : roles;
    }


    public String issueJwtToken(BlockBetAuthenticationToken token) {

        return JWT.create()
                .withExpiresAt(Date.from(Instant.now().plus(Duration.ofMinutes(properties.expirationTime()))))
                .withSubject(String.valueOf(token.getUserDetail().getAccountId()))
                .withClaim("email", token.getUserDetail().getEmail())
                .withClaim("roles", token.getUserDetail().getRoles())
                .sign(Algorithm.HMAC256(properties.secretKey()));
    }
}
