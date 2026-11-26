package com.dinomic.blockbet.services;

import blockbet.openapi.model.BettingLogsGetResponse;
import blockbet.openapi.model.PlaceMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.TxHashResponse;
import com.dinomic.blockbet.daos.Account;
import jakarta.validation.constraints.NotNull;

import java.math.BigInteger;

/** Handles the /bettor/** endpoints. */
public interface IBettorService {
    TxHashResponse handleBettorBetsMultipleOptionSimplePoolBetIdPlacePostRequest(
        @NotNull Account account, @NotNull BigInteger betId, @NotNull PlaceMultipleOptionSimplePoolBetRequest request);

    /** The caller's own betting log, newest first; betId null means every bet. */
    BettingLogsGetResponse handleBettorBettingLogsGetRequest(@NotNull Account account, @NotNull BigInteger offset,
                                                             @NotNull BigInteger limit, BigInteger betId);
}
