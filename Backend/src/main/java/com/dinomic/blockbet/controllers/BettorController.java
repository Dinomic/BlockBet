package com.dinomic.blockbet.controllers;

import blockbet.openapi.api.BettorApi;
import blockbet.openapi.model.BettingLogsGetResponse;
import blockbet.openapi.model.PlaceMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.TxHashResponse;
import com.dinomic.blockbet.BlockBetUtil;
import com.dinomic.blockbet.services.IBettorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;

import java.math.BigInteger;

/** Bettor endpoints (/bettor/**, role BETTOR): place a bet; read the caller's betting log (/bettor/betting-logs). */
@Controller
public class BettorController implements BettorApi {

    @Autowired
    BlockBetUtil blockBetUtil;

    @Autowired
    IBettorService bettorService;

    @Override
    public ResponseEntity<TxHashResponse> bettorBetsMultipleOptionSimplePoolBetIdPlacePost(
        BigInteger betId, PlaceMultipleOptionSimplePoolBetRequest request) {
        return ResponseEntity.ok(bettorService.handleBettorBetsMultipleOptionSimplePoolBetIdPlacePostRequest(
            blockBetUtil.getAccountFromRequest(), betId, request));
    }

    @Override
    public ResponseEntity<BettingLogsGetResponse> bettorBettingLogsGet(BigInteger offset, BigInteger limit, BigInteger betId) {
        return ResponseEntity.ok(bettorService.handleBettorBettingLogsGetRequest(
            blockBetUtil.getAccountFromRequest(), offset, limit, betId));
    }
}
