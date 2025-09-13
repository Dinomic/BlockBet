package com.dinomic.blockbet.controllers;

import blockbet.openapi.api.BlockbetApi;
import blockbet.openapi.model.*;
import com.dinomic.blockbet.entities.Account;
import com.dinomic.blockbet.security.BlockBetAuthenticationToken;
import com.dinomic.blockbet.services.IAccountService;
import com.dinomic.blockbet.services.IBlockBetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigInteger;

@RestController
public class GeneralController implements BlockbetApi {

    @Autowired
    IAccountService accountService;

    @Autowired
    IBlockBetService blockBetService;

    @Override
    public ResponseEntity<WalletPostResponse> blockbetWalletPost(WalletPostRequest walletPostRequest){
        BlockBetAuthenticationToken userDetail = (BlockBetAuthenticationToken) SecurityContextHolder.getContext().getAuthentication();
        Account account = accountService.getAccountByAccountId(userDetail.getPrincipal().getAccountId());

        return ResponseEntity.ok(blockBetService.handleWalletPostRequest(account, walletPostRequest));
    }

    @Override
    public ResponseEntity<WalletsGetResponse> blockbetWalletsGet() {
        BlockBetAuthenticationToken userDetail = (BlockBetAuthenticationToken) SecurityContextHolder.getContext().getAuthentication();
        Account account = accountService.getAccountByAccountId(userDetail.getPrincipal().getAccountId());

        return ResponseEntity.ok(blockBetService.handleWalletsGetRequest(account));
    }

    @Override
    public ResponseEntity<TransferTokensPutResponse> blockbetTransferTokensPut(TransferTokensPutRequest transferTokensPutRequest) {
        BlockBetAuthenticationToken userDetail = (BlockBetAuthenticationToken) SecurityContextHolder.getContext().getAuthentication();
        Account account = accountService.getAccountByAccountId(userDetail.getPrincipal().getAccountId());

        return ResponseEntity.ok(blockBetService.handleTransferTokensPutRequest(account, transferTokensPutRequest));
    }

    @Override
    public ResponseEntity<ReceiptsGetResponse> blockbetReceiptsGet(BigInteger offset, BigInteger limit) {

        return ResponseEntity.ok(blockBetService.handleReceiptsGetRequest(offset, limit));
    }
}
