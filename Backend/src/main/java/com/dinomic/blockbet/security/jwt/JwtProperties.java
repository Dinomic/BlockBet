package com.dinomic.blockbet.security.jwt;

import org.springframework.boot.context.properties.ConfigurationProperties;


@ConfigurationProperties(prefix = "security.jwt")
public record JwtProperties (
    String secretKey,
    /** Access token lifetime, in minutes. */
    Integer expirationTime,
    /** Refresh token lifetime, in days. */
    Integer refreshExpirationDays,
    /** Value of the {@code iss} claim; tokens from another issuer are rejected. */
    String issuer
){}
