package com.dinomic.blockbet.security.jwt;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import org.springframework.stereotype.Component;

@Component
public class JwtDecoder {

    private final JWTVerifier verifier;

    public JwtDecoder(JwtProperties properties) {
        // The verifier is thread-safe and reusable, so build it only once.
        this.verifier = JWT.require(Algorithm.HMAC256(properties.secretKey()))
                .withIssuer(properties.issuer())
                .build();
    }

    /**
     * Verifies signature and expiry of the token.
     *
     * @throws JWTVerificationException if the token is malformed, tampered with or expired
     */
    public DecodedJWT decodedJWT(String jwtToken) throws JWTVerificationException {
        return verifier.verify(jwtToken);
    }
}
