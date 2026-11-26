package com.dinomic.blockbet.controllers;

import blockbet.openapi.api.InternalApi;
import blockbet.openapi.model.TxHashResponse;
import com.dinomic.blockbet.services.IInternalService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;

import java.math.BigInteger;

/** Internal-team endpoints (/internal/**, role INTERNAL). */
@Controller
public class InternalController implements InternalApi {

    @Autowired
    IInternalService internalService;

    @Override
    public ResponseEntity<TxHashResponse> internalBetsBetIdRefundPost(BigInteger betId) {
        return ResponseEntity.ok(internalService.handleInternalBetsBetIdRefundPostRequest(betId));
    }
}
