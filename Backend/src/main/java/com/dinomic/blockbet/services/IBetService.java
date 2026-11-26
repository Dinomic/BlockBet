package com.dinomic.blockbet.services;

import blockbet.openapi.model.BetContractType;
import blockbet.openapi.model.BetOption;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.BBTransactionReceipt;
import com.dinomic.blockbet.daos.Bet;
import com.dinomic.blockbet.daos.Wallet;
import com.dinomic.blockbet.enums.TransactionType;
import jakarta.validation.constraints.NotNull;
import org.web3j.protocol.core.methods.response.TransactionReceipt;

import java.math.BigInteger;

/**
 * Lookups shared by the bet services (bookie, bettor, internal, general). It is not behind an endpoint:
 * controllers never call it, only the services do.
 */
public interface IBetService {
    /** The bet with this id; BET_NOT_FOUND if there is none. */
    Bet findBet(@NotNull BigInteger betId);

    /** Same, but BET_NOT_FOUND also when the bet runs on another contract type than the endpoint's. */
    Bet findBet(@NotNull BigInteger betId, @NotNull BetContractType type);

    /** The account's own wallet, row-locked so one wallet never sends two transactions with the same nonce. */
    Wallet lockOwnWallet(@NotNull Account account, String address);

    IBetContractService.ChainOption toContractOption(@NotNull BetOption option);

    /**
     * A TRANSACTION_RECEIPTS row (not saved) for money that moved in a mined bet transaction. The hash, block and
     * gas columns come from the transaction receipt, so they are the same for every row of one transaction.
     *
     * @param success false for a payment that was attempted but did not reach its receiver
     */
    BBTransactionReceipt newReceipt(@NotNull TransactionType type, @NotNull TransactionReceipt receipt,
                                    @NotNull String from, @NotNull String to, BigInteger amount, boolean success);
}
