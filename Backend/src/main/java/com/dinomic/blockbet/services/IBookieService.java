package com.dinomic.blockbet.services;

import blockbet.openapi.model.CreateBetResponse;
import blockbet.openapi.model.CreateMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.ResolveMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.TxHashResponse;
import com.dinomic.blockbet.daos.Account;
import jakarta.validation.constraints.NotNull;

import java.math.BigInteger;

/** Handles the /bookie/** endpoints. */
public interface IBookieService {
    CreateBetResponse handleBookieBetsMultipleOptionSimplePoolPostRequest(
        @NotNull Account account, @NotNull CreateMultipleOptionSimplePoolBetRequest request);

    TxHashResponse handleBookieBetsMultipleOptionSimplePoolBetIdResultPutRequest(
        @NotNull Account account, @NotNull BigInteger betId, @NotNull ResolveMultipleOptionSimplePoolBetRequest request);
}
