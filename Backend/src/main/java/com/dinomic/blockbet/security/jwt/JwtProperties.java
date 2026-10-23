package com.dinomic.blockbet.security.jwt;

import org.springframework.boot.context.properties.ConfigurationProperties;


@ConfigurationProperties(prefix = "security.jwt")
public record JwtProperties (
    String secretKey
){}