package com.dinomic.blockbet.controllers;

import blockbet.openapi.api.AuthApi;
import blockbet.openapi.model.AuthLoginPostRequest;
import blockbet.openapi.model.AuthLogoutPostRequest;
import blockbet.openapi.model.AuthRefreshPostRequest;
import blockbet.openapi.model.AuthSignUpRequest;
import blockbet.openapi.model.AuthTokenResponse;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.security.BlockBetAuthenticationToken;
import com.dinomic.blockbet.security.BlockBetUserDetails;
import com.dinomic.blockbet.security.jwt.JwtSecurityMapper;
import com.dinomic.blockbet.services.IAccountService;
import com.dinomic.blockbet.services.IRefreshTokenService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Controller;

@Controller
public class AuthController implements AuthApi {

    private static final String TOKEN_TYPE = "Bearer";

    @Autowired
    private JwtSecurityMapper securityMapper;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private IAccountService accountService;

    @Autowired
    private IRefreshTokenService refreshTokenService;

    @Autowired
    private UserDetailsService userDetailsService;

    @Override
    public ResponseEntity<AuthTokenResponse> authLoginPost(AuthLoginPostRequest authLoginPostRequest) {
        BlockBetAuthenticationToken authentication = (BlockBetAuthenticationToken) authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(authLoginPostRequest.getEmail(), authLoginPostRequest.getPassword())
        );
        SecurityContextHolder.getContext().setAuthentication(authentication);

        String refreshToken = refreshTokenService.issue(authentication.getUserDetail().getAccountId());

        return ResponseEntity.ok(buildTokenResponse(authentication, refreshToken));
    }

    @Override
    public ResponseEntity<AuthTokenResponse> authRefreshPost(AuthRefreshPostRequest authRefreshPostRequest) {
        IRefreshTokenService.Rotation rotation = refreshTokenService.rotate(authRefreshPostRequest.getRefreshToken());

        // Reload the account so role changes / disabled accounts take effect at refresh time.
        Account account = accountService.getAccountByAccountId(rotation.accountId());
        if (!Boolean.TRUE.equals(account.getEnabled())) {
            refreshTokenService.revoke(rotation.newRefreshToken());
            throw new BlockBetException(BlockBetError.UNAUTHORIZED, "Account disabled");
        }

        BlockBetUserDetails userDetails = (BlockBetUserDetails) userDetailsService.loadUserByUsername(account.getEmail());
        BlockBetAuthenticationToken authentication = new BlockBetAuthenticationToken(userDetails);

        return ResponseEntity.ok(buildTokenResponse(authentication, rotation.newRefreshToken()));
    }

    /**
     * Public on purpose: the access token may already be expired when the user logs out, and the
     * refresh token in the body is itself the proof of possession.
     */
    @Override
    public ResponseEntity<Void> authLogoutPost(AuthLogoutPostRequest authLogoutPostRequest) {
        refreshTokenService.revoke(authLogoutPostRequest.getRefreshToken());

        return ResponseEntity.noContent().build();
    }

    @Override
    public ResponseEntity<Void> authSignUpPost(AuthSignUpRequest authSignUpRequest) {
        accountService.addNewAccount(authSignUpRequest.getEmail(), authSignUpRequest.getPassword());

        return ResponseEntity.ok().build();
    }

    private AuthTokenResponse buildTokenResponse(BlockBetAuthenticationToken authentication, String refreshToken) {
        AuthTokenResponse response = new AuthTokenResponse();
        response.setAccessToken(securityMapper.issueJwtToken(authentication));
        response.setRefreshToken(refreshToken);
        response.setTokenType(TOKEN_TYPE);
        response.setExpiresIn(securityMapper.accessTokenTtlSeconds());
        return response;
    }
}
