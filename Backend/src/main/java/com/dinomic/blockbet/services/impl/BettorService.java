package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.BetContractType;
import blockbet.openapi.model.BetOption;
import blockbet.openapi.model.BettingLogAction;
import blockbet.openapi.model.BettingLogResponse;
import blockbet.openapi.model.BettingLogsGetResponse;
import blockbet.openapi.model.PlaceMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.TxHashResponse;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.Bet;
import com.dinomic.blockbet.daos.BetParticipant;
import com.dinomic.blockbet.daos.BettingLog;
import com.dinomic.blockbet.daos.Wallet;
import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.enums.TransactionType;
import com.dinomic.blockbet.repositories.IAccountRepo;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import com.dinomic.blockbet.repositories.IBetParticipantRepo;
import com.dinomic.blockbet.services.IBetContractService;
import com.dinomic.blockbet.enums.BettingAction;
import com.dinomic.blockbet.services.IBetService;
import com.dinomic.blockbet.services.IBettingLogService;
import com.dinomic.blockbet.services.IBettorService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.web3j.protocol.core.methods.response.TransactionReceipt;

import java.math.BigInteger;
import java.time.ZoneId;

/**
 * The bettor side of the bets: place a bet. The write goes to the chain first and is mined before the request
 * returns; the wallet row is locked for the whole request (as in {@link BlockBetService}).
 */
@Service
public class BettorService implements IBettorService {
    private static final Logger log = LoggerFactory.getLogger(BettorService.class);

    private static final int MAX_LOG_PAGE_SIZE = 100;

    @Autowired
    IBetContractService betContractService;

    @Autowired
    IBetParticipantRepo participantRepo;

    @Autowired
    IAccountRepo accountRepo;

    @Autowired
    IBBTransactionReceiptRepo receiptRepo;

    @Autowired
    IBetService betService;

    @Autowired
    IBettingLogService bettingLogService;

    @Override
    @Transactional
    public TxHashResponse handleBettorBetsMultipleOptionSimplePoolBetIdPlacePostRequest(
        Account account, BigInteger betId, PlaceMultipleOptionSimplePoolBetRequest request) {
        BetOption option = request.getOption();
        if (option == null) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "option is required");
        }
        // Serializes this account's bets, so the one-bet-per-account check below cannot be raced
        // by two requests that use two different wallets.
        Account lockedAccount = accountRepo.findByIdForUpdate(account.getAccountId()).orElseThrow(() ->
            new BlockBetException(BlockBetError.UNAUTHORIZED, "Account not found"));

        Bet bet = betService.findBet(betId, BetContractType.MULTIPLE_OPTION_SIMPLE_POOL);
        if (participantRepo.findByBetAndAccount(bet, lockedAccount).isPresent()) {
            throw new BlockBetException(BlockBetError.BET_REJECTED, "You have already bet on this bet");
        }

        Wallet wallet = betService.lockOwnWallet(lockedAccount, request.getFromAddress());

        IBetContractService.ChainBet chainBet = betContractService.getBet(bet.getContract(), bet.getChainBetId());
        if (chainBet.status() != IBetContractService.ChainStatus.OPEN) {
            throw new BlockBetException(BlockBetError.BET_REJECTED, "Betting is closed for this bet");
        }
        if (option.ordinal() >= chainBet.optionNames().size()) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST,
                "This bet only has the options A to " + BetOption.values()[chainBet.optionNames().size() - 1]);
        }

        TransactionReceipt placeReceipt = betContractService.placeBet(wallet, bet.getContract(), bet.getChainBetId(),
            betService.toContractOption(option), chainBet.stake());
        String txHash = placeReceipt.getTransactionHash();

        BetParticipant participant = new BetParticipant();
        participant.setBet(bet);
        participant.setAccount(lockedAccount);
        participant.setWalletAddress(wallet.getAddress());
        participant.setOption(option.getValue());
        participant.setTxHash(txHash);
        try {
            participantRepo.saveAndFlush(participant);
        } catch (RuntimeException e) {
            log.error("Wallet {} bet on bet {} (tx {}) on chain but its row could not be saved",
                wallet.getAddress(), bet.getBetId(), txHash, e);
            throw e;
        }

        // The stake moved from the bettor's wallet to the contract in this transaction.
        try {
            receiptRepo.saveAndFlush(betService.newReceipt(TransactionType.BET_STAKE, placeReceipt,
                wallet.getAddress(), bet.getContract().getAddress(), chainBet.stake(), true));
        } catch (RuntimeException e) {
            log.error("Wallet {} bet on bet {} (tx {}) but the stake receipt could not be saved",
                wallet.getAddress(), bet.getBetId(), txHash, e);
            throw e;
        }

        bettingLogService.record(BettingAction.BET_PLACED, bet.getBetId(), lockedAccount.getAccountId(),
            wallet.getAddress(), option, chainBet.stake(), txHash, null);

        TxHashResponse response = new TxHashResponse();
        response.setTxHash(txHash);
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public BettingLogsGetResponse handleBettorBettingLogsGetRequest(Account account, BigInteger offset,
                                                                    BigInteger limit, BigInteger betId) {
        if (offset.signum() < 0 || offset.bitLength() > 62) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "offset must be 0 or greater");
        }
        if (limit.signum() <= 0 || limit.compareTo(BigInteger.valueOf(MAX_LOG_PAGE_SIZE)) > 0) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST,
                "limit must be between 1 and " + MAX_LOG_PAGE_SIZE);
        }
        if (betId != null && (betId.signum() < 0 || betId.bitLength() > 62)) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "betId is not valid");
        }
        Long filterBetId = betId == null ? null : betId.longValue();
        long accountId = account.getAccountId();

        BettingLogsGetResponse response = new BettingLogsGetResponse();
        response.setOffset(offset);
        response.setLimit(limit);
        response.setTotal(BigInteger.valueOf(bettingLogService.count(accountId, filterBetId)));
        for (BettingLog entry : bettingLogService.findPage(accountId, filterBetId, offset.longValue(), limit.longValue())) {
            BettingLogResponse item = new BettingLogResponse();
            item.setBettingLogId(BigInteger.valueOf(entry.getBettingLogId()));
            item.setBetId(entry.getBetId() == null ? null : BigInteger.valueOf(entry.getBetId()));
            item.setAction(BettingLogAction.fromValue(entry.getAction().name()));
            item.setWalletAddress(entry.getWalletAddress());
            item.setOption(entry.getOption() == null ? null : BetOption.fromValue(entry.getOption()));
            item.setAmount(entry.getAmount());
            item.setTxHash(entry.getTxHash());
            item.setDetail(entry.getDetail());
            item.setCreatedAt(entry.getCreatedAt() == null ? null
                : entry.getCreatedAt().atZone(ZoneId.systemDefault()).toOffsetDateTime());
            response.addResultItem(item);
        }
        return response;
    }
}