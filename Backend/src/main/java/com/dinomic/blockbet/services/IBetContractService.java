package com.dinomic.blockbet.services;

import blockbet.openapi.model.BetContractType;
import com.dinomic.blockbet.daos.BetContract;
import com.dinomic.blockbet.daos.Wallet;

import org.web3j.protocol.core.methods.response.TransactionReceipt;

import java.math.BigInteger;
import java.util.List;

/** Talks to the bet smart contracts (src/main/resources/contracts/**, today simple/BlockBetSimplePool.sol). */
public interface IBetContractService {
    /**
     * The option number the contract uses: 1 = A, 2 = B, ... 5 = E, and 0 = none (no winner yet). It is the
     * position in this enum, so the order MUST stay NONE, A, B, C, D, E.
     */
    enum ChainOption {
        NONE, A, B, C, D, E;

        public static ChainOption fromChain(BigInteger value) {
            return values()[value.intValueExact()];
        }

        public int toChain() {
            return ordinal();
        }
    }

    /** Mirrors {@code enum Status} in BlockBetSimplePool.sol; keep the order identical to the contract. */
    enum ChainStatus {
        OPEN, CLOSED, RESOLVED, REFUNDED;

        public static ChainStatus fromChain(BigInteger value) {
            return values()[value.intValueExact()];
        }
    }

    /** Same as RESOLVE_DEADLINE in the contract: how long after the close time the bookie can still resolve. */
    long RESOLVE_DEADLINE_SECONDS = 7L * 24 * 3600;

    /**
     * The contract new bets of this type are created on. It is deployed first if the compiled code of that type
     * has no deployment yet.
     */
    BetContract currentContract(BetContractType type);

    /** Sends createBet (2 to 5 option names) and waits until it is mined. */
    CreatedBet createBet(Wallet bookie, BetContract contract, List<String> optionNames,
                         BigInteger stakeWei, BigInteger durationSeconds);

    /** Sends placeBet with the stake as value and waits until it is mined. Returns the receipt of the transaction. */
    TransactionReceipt placeBet(Wallet bettor, BetContract contract, long chainBetId, ChainOption option, BigInteger stakeWei);

    /** Sends resolve and waits until it is mined (the payouts happen in this transaction). */
    ResolvedBet resolve(Wallet bookie, BetContract contract, long chainBetId, ChainOption winner);

    /** Sends refundExpired, signed by the internal account (blockchain.mainAccount), and waits until it is mined. */
    String refundExpired(BetContract contract, long chainBetId);

    /** Address of the internal account, which receives the remainder of a pool / the pool of an unwon bet. */
    String internalAccountAddress();

    ChainBet getBet(BetContract contract, long chainBetId);

    /**
     * @param internalPayout wei the contract sent to the internal account in this transaction (0 if none)
     * @param payouts        what each winner was paid, in the order the contract paid them
     */
    record ResolvedBet(TransactionReceipt receipt, BigInteger internalPayout, List<WinnerPayout> payouts) {
    }

    /**
     * @param to     the winner's address, lowercase
     * @param amount wei the contract tried to send
     * @param paid   false if the transfer failed and the amount is kept in the contract for the winner to withdraw
     */
    record WinnerPayout(String to, BigInteger amount, boolean paid) {
    }

    record CreatedBet(long chainBetId, String txHash) {
    }

    /**
     * @param optionNames names of the options, the first one is option A
     * @param counts      counts.get(i) = number of wallets that bet on option i (same order as optionNames)
     */
    record ChainBet(String bookie, List<String> optionNames, BigInteger stake, BigInteger closeTime,
                    ChainStatus status, ChainOption winner, List<BigInteger> counts) {
    }
}
