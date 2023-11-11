package com.dinomic.BlockBet.controllers;

import blockbet.openapi.api.BlockbetApi;
import blockbet.openapi.model.WalletPostRequest;
import blockbet.openapi.model.WalletPostResponse;
import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.security.BlockBetAuthenticationToken;
import com.dinomic.BlockBet.services.IAccountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GeneralController implements BlockbetApi {

    @Autowired
    IAccountService accountService;

    @Override
    public ResponseEntity<WalletPostResponse> blockbetWalletPost(WalletPostRequest walletPostRequest){
        BlockBetAuthenticationToken userDetail = (BlockBetAuthenticationToken) SecurityContextHolder.getContext().getAuthentication();

        Account account = accountService.getAccountByAccountId(userDetail.getPrincipal().getAccountId());

        return ResponseEntity.ok(accountService.createWalletForAccount(account, walletPostRequest));
    }
}