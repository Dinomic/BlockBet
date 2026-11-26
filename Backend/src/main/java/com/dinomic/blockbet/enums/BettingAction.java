package com.dinomic.blockbet.enums;

/** What a row of BETTING_LOG records. */
public enum BettingAction {
    /** A bookie created a bet. */
    BET_CREATED,
    /** A bettor placed a bet on an option. */
    BET_PLACED,
    /** A bookie picked the winning option. */
    BET_RESOLVED,
    /** The internal team refunded a bet nobody resolved. */
    BET_REFUNDED,
    /** The caution check found a bet unresolved past the deadline. */
    BET_CAUTION_FLAGGED
}