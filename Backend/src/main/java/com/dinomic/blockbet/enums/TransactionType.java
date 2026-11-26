package com.dinomic.blockbet.enums;

public enum TransactionType {
    FUNDING,
    TOKEN_TRANSFER,
    /** The part of a bet's pool paid to the internal account when the bet was resolved. */
    BET_INTERNAL_PAYOUT,
    /** What a winner received from the contract when its bet was resolved (one row per winner, same tx hash). */
    BET_PAYOUT,
    /** The stake a bettor sent to the contract when placing a bet. */
    BET_STAKE;
}
