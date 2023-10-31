package com.dinomic.BlockBet.controllers;

import blockbet.openapi.api.BettorApi;
import blockbet.openapi.model.BettorWalletPostRequest;
import blockbet.openapi.model.BettorWalletPostResponse;
import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.security.BlockBetAuthenticationToken;
import com.dinomic.BlockBet.services.IAccountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BettorController implements BettorApi {

    @Autowired
    IAccountService accountService;

    @Override
    public ResponseEntity<BettorWalletPostResponse> bettorWalletPost(BettorWalletPostRequest bettorWalletPostRequest){
        BlockBetAuthenticationToken userDetail = (BlockBetAuthenticationToken) SecurityContextHolder.getContext().getAuthentication();

        Account account = accountService.getAccountByAccountId(userDetail.getPrincipal().getAccountId());

        return ResponseEntity.ok(accountService.createWalletForAccount(account, bettorWalletPostRequest));
    }
}
