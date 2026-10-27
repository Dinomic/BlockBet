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
    IAccountService accountService;

    @Autowired
    BlockBetUtil blockBetUtil;

    @Autowired
    IBlockBetService blockBetService;

    @Override
    public ResponseEntity<InfosGetResponse> blockbetInfosGet() {
        //TODO refine account info response
        Account account = blockBetUtil.getAccountFromRequest();
        return ResponseEntity.ok(GeneralMapper.INSTANCE.accountToInfosGetResponse(account));
    }

    @Override
    public ResponseEntity<ReceiptsGetResponse> blockbetReceiptsGet(BigInteger offset, BigInteger limit) {
        return null;
    }

    @Override
    public ResponseEntity<TransferTokensPutResponse> blockbetTransferTokensPut(TransferTokensPutRequest transferTokensPutRequest) {
        return null;
    }

    @Override
    public ResponseEntity<WalletPostResponse> blockbetWalletPost(WalletPostRequest walletPostRequest) {
        Account account = blockBetUtil.getAccountFromRequest();
        return ResponseEntity.ok(blockBetService.handleWalletPostRequest(account, walletPostRequest));
    }

    @Override
    public ResponseEntity<WalletsGetResponse> blockbetWalletsGet() {
        return null;
    }
}
