package com.dinomic.blockbet.controllers;

import blockbet.openapi.api.BookieApi;
import blockbet.openapi.model.CreateBetResponse;
import blockbet.openapi.model.CreateMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.ResolveMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.TxHashResponse;
import com.dinomic.blockbet.BlockBetUtil;
import com.dinomic.blockbet.services.IBookieService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;

import java.math.BigInteger;

/** Bookie endpoints (/bookie/**, role BOOKIE): create a bet and pick its winner. */
@Controller
public class BookieController implements BookieApi {

    @Autowired
    BlockBetUtil blockBetUtil;

    @Autowired
    IBookieService bookieService;

    @Override
    public ResponseEntity<CreateBetResponse> bookieBetsMultipleOptionSimplePoolPost(CreateMultipleOptionSimplePoolBetRequest request) {
        return ResponseEntity.ok(bookieService.handleBookieBetsMultipleOptionSimplePoolPostRequest(
            blockBetUtil.getAccountFromRequest(), request));
    }

    @Override
    public ResponseEntity<TxHashResponse> bookieBetsMultipleOptionSimplePoolBetIdResultPut(
        BigInteger betId, ResolveMultipleOptionSimplePoolBetRequest request) {
        return ResponseEntity.ok(bookieService.handleBookieBetsMultipleOptionSimplePoolBetIdResultPutRequest(
            blockBetUtil.getAccountFromRequest(), betId, request));
    }
}
