package com.dinomic.blockbet.security.filters;

import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.dinomic.blockbet.security.BlockBetAuthenticationToken;
import com.dinomic.blockbet.security.BlockBetUserDetails;
import com.dinomic.blockbet.security.jwt.JwtDecoder;
import com.dinomic.blockbet.security.jwt.JwtSecurityMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Optional;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    private static final String BEARER_PREFIX = "Bearer ";

    @Autowired
    JwtSecurityMapper mapper;

    @Autowired
    JwtDecoder decoder;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        Optional<String> token = extractTokenFromRequest(request);

        if (token.isPresent()) {
            try {
                DecodedJWT decodedJWT = decoder.decodedJWT(token.get());
                BlockBetUserDetails userDetails = mapper.decodedJwtToBlockBetUserDetail(decodedJWT);
                SecurityContextHolder.getContext().setAuthentication(new BlockBetAuthenticationToken(userDetails));
            } catch (JWTVerificationException | IllegalArgumentException e) {
                // Invalid / expired / malformed token: leave the request unauthenticated.
                // Protected endpoints will answer 401 through the AuthenticationEntryPoint,
                SecurityContextHolder.clearContext();
                log.debug("Rejected JWT token: {}", e.getMessage());
            }
        }

        filterChain.doFilter(request, response);
    }

    private Optional<String> extractTokenFromRequest(HttpServletRequest request) {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (StringUtils.startsWith(authorization, BEARER_PREFIX)) {
            String token = authorization.substring(BEARER_PREFIX.length()).trim();
            if (!token.isEmpty()) {
                return Optional.of(token);
            }
        }

        return Optional.empty();
    }
}
