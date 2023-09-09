package com.dinomic.BlockBet.security;

import blockbet.openapi.api.AuthApi;
import blockbet.openapi.model.AuthLoginPostRequest;
import blockbet.openapi.model.AuthLoginPostResponse;
import blockbet.openapi.model.AuthSignUpRequest;
import com.dinomic.BlockBet.services.IAccountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.RestController;


@RestController
public class BlockBetAuthController implements AuthApi {


    @Autowired
    private SecurityMapper securityMapper;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private IAccountService accountService;

    @Override
    public ResponseEntity<AuthLoginPostResponse> authLoginPost(AuthLoginPostRequest authLoginPostRequest) {
        AuthLoginPostResponse response = new AuthLoginPostResponse();

        BlockBetAuthenticationToken authentication = (BlockBetAuthenticationToken) authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(authLoginPostRequest.getEmail(), authLoginPostRequest.getPassword())
        );
        SecurityContextHolder.getContext().setAuthentication(authentication);

        String token = securityMapper.issueJwtToken(authentication);

        response.setToken(token);

        return ResponseEntity.ok(response);
    }

    @Override
    public ResponseEntity<Void> authSignUpPost(AuthSignUpRequest authSignUpRequest) {

        accountService.addNewAccount(authSignUpRequest.getEmail(), authSignUpRequest.getPassword());

        return ResponseEntity.ok().build();
    }
}
