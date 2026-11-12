package com.dinomic.blockbet.controllers;

import blockbet.openapi.api.BlockbetApi;
import blockbet.openapi.model.*;
import com.dinomic.blockbet.BlockBetUtil;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.mappers.GeneralMapper;
import com.dinomic.blockbet.security.BlockBetAuthenticationToken;
import com.dinomic.blockbet.services.IAccountService;
import com.dinomic.blockbet.services.IBlockBetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;

import java.math.BigInteger;

@Controller
public class GeneralController implements BlockbetApi {

    @Autowired
    BlockBetUtil blockBetUtil;

    @Autowired
    IBlockBetService blockBetService;

    @Override
    public ResponseEntity<InfosGetResponse> blockbetInfosGet() {
        Account account = blockBetUtil.getAccountFromRequest();
        return ResponseEntity.ok(blockBetService.handleInfosGetRequest(account));
    }

    @Override
    public ResponseEntity<InfosGetResponse> blockbetInfosPut(InfosPutRequest infosPutRequest) {
        Account account = blockBetUtil.getAccountFromRequest();
        return ResponseEntity.ok(blockBetService.handleInfosPutRequest(account, infosPutRequest));
    }

    @Override
    public ResponseEntity<ReceiptsGetResponse> blockbetReceiptsGet(BigInteger offset, BigInteger limit) {

        return ResponseEntity.ok(blockBetService.handleReceiptsGetRequest(offset, limit));
    }

    @Override
    public ResponseEntity<TransferTokensPutResponse> blockbetTransferTokensPut(TransferTokensPutRequest transferTokensPutRequest) {
        Account account = blockBetUtil.getAccountFromRequest();

        return ResponseEntity.ok(blockBetService.handleTransferTokensPutRequest(account, transferTokensPutRequest));
    }

    @Override
    public ResponseEntity<WalletPostResponse> blockbetWalletPost(WalletPostRequest walletPostRequest) {

        Account account = blockBetUtil.getAccountFromRequest();

        return ResponseEntity.ok(blockBetService.handleWalletPostRequest(account, walletPostRequest));
    }

    @Override
    public ResponseEntity<WalletsGetResponse> blockbetWalletsGet() {

        Account account = blockBetUtil.getAccountFromRequest();

        return ResponseEntity.ok(blockBetService.handleWalletsGetRequest(account));
    }
}
