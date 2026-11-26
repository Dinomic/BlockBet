package com.dinomic.blockbet.services;

import blockbet.openapi.model.TxHashResponse;
import jakarta.validation.constraints.NotNull;

import java.math.BigInteger;

/** Handles the /internal/** endpoints. */
public interface IInternalService {
    TxHashResponse handleInternalBetsBetIdRefundPostRequest(@NotNull BigInteger betId);
}
