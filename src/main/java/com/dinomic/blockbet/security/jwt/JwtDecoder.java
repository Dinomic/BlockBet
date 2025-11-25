package com.dinomic.blockbet.security.jwt;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class JwtDecoder {

    @Autowired
    private JwtProperties properties;

    public DecodedJWT decodedJWT (String jwtToken) {
        return JWT.require(Algorithm.HMAC256(properties.getSecretKey()))
                .build().verify(jwtToken);
    }

}
