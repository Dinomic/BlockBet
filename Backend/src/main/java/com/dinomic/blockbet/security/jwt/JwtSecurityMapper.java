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
import java.util.UUID;

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


    /** Lifetime of an access token in seconds, as reported to clients ({@code expires_in}). */
    public long accessTokenTtlSeconds() {
        return Duration.ofMinutes(properties.expirationTime()).toSeconds();
    }

    /** Issues a short-lived access token. Long-lived sessions are carried by the refresh token. */
    public String issueJwtToken(BlockBetAuthenticationToken token) {
        Instant now = Instant.now();

        return JWT.create()
                .withIssuer(properties.issuer())
                .withIssuedAt(Date.from(now))
                .withExpiresAt(Date.from(now.plus(Duration.ofMinutes(properties.expirationTime()))))
                .withJWTId(UUID.randomUUID().toString())
                .withSubject(String.valueOf(token.getUserDetail().getAccountId()))
                .withClaim("email", token.getUserDetail().getEmail())
                .withClaim("roles", token.getUserDetail().getRoles())
                .sign(Algorithm.HMAC256(properties.secretKey()));
    }
}
