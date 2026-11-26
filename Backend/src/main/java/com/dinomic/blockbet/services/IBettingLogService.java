package com.dinomic.blockbet.services;

import blockbet.openapi.model.BetOption;
import com.dinomic.blockbet.daos.BettingLog;
import com.dinomic.blockbet.enums.BettingAction;

import java.math.BigInteger;
import java.util.List;

/**
 * Writes the BETTING_LOG audit rows. Called by the bet services (never by a controller) from inside their own
 * transaction, so a row is committed together with the change it describes.
 */
public interface IBettingLogService {
    /**
     * @param betId         the bet's database id, null if none
     * @param accountId     who did it; null for the system and the internal team
     * @param walletAddress the wallet involved, null if none
     * @param option        the option chosen (a bettor's option, a bookie's winner), null if none
     * @param amount        wei the action moved when known, null otherwise
     * @param txHash        the blockchain transaction of the action, null if it had none
     * @param detail        free text, cut to the column size
     */
    void record(BettingAction action, Long betId, Long accountId, String walletAddress, BetOption option,
                BigInteger amount, String txHash, String detail);

    /** The account's own rows, newest first; betId null means every bet. */
    List<BettingLog> findPage(long accountId, Long betId, long offset, long limit);

    /** How many rows the same filter matches in total. */
    long count(long accountId, Long betId);
}