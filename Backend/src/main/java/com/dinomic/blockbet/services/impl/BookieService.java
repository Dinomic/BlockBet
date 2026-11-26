package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.BetContractType;
import blockbet.openapi.model.CreateBetResponse;
import blockbet.openapi.model.CreateMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.ResolveMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.TxHashResponse;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.BBTransactionReceipt;
import com.dinomic.blockbet.daos.Bet;
import com.dinomic.blockbet.daos.BetContract;
import com.dinomic.blockbet.daos.Wallet;
import com.dinomic.blockbet.enums.BettingAction;
import com.dinomic.blockbet.enums.TransactionType;
import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import com.dinomic.blockbet.repositories.IBetRepo;
import com.dinomic.blockbet.repositories.IWalletRepo;
import com.dinomic.blockbet.services.IBetContractService;
import com.dinomic.blockbet.services.IBetService;
import com.dinomic.blockbet.services.IBettingLogService;
import com.dinomic.blockbet.services.IBookieService;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.web3j.protocol.core.methods.response.TransactionReceipt;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * The bookie side of the bets: create a bet and pick its winner. Writes go to the chain first and are mined
 * before the request returns; the wallet row is locked for the whole request (as in {@link BlockBetService}).
 */
@Service
public class BookieService implements IBookieService {
    private static final Logger log = LoggerFactory.getLogger(BookieService.class);

    private static final int MIN_OPTIONS = 2;
    private static final int MAX_OPTIONS = 5;
    private static final int MAX_OPTION_NAME_BYTES = 64;
    private static final BigInteger MAX_DURATION_SECONDS = BigInteger.valueOf(365L * 24 * 3600);

    @Autowired
    IBetContractService betContractService;

    @Autowired
    IBetRepo betRepo;

    @Autowired
    IBBTransactionReceiptRepo receiptRepo;

    @Autowired
    IWalletRepo walletRepo;

    @Autowired
    IBetService betService;

    @Autowired
    IBettingLogService bettingLogService;

    @Override
    @Transactional
    public CreateBetResponse handleBookieBetsMultipleOptionSimplePoolPostRequest(
        Account account, CreateMultipleOptionSimplePoolBetRequest request) {
        String title = StringUtils.trimToNull(request.getTitle());
        if (title == null) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "title is required");
        }

        List<String> optionNames = request.getOptions() == null ? List.of()
            : request.getOptions().stream().map(StringUtils::trimToNull).toList();
        if (optionNames.size() < MIN_OPTIONS || optionNames.size() > MAX_OPTIONS) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST,
                "options must have between " + MIN_OPTIONS + " and " + MAX_OPTIONS + " names");
        }
        Set<String> seen = new HashSet<>();
        for (String name : optionNames) {
            if (name == null) {
                throw new BlockBetException(BlockBetError.INVALID_REQUEST, "Option names cannot be empty");
            }
            if (name.getBytes(StandardCharsets.UTF_8).length > MAX_OPTION_NAME_BYTES) {
                throw new BlockBetException(BlockBetError.INVALID_REQUEST,
                    "An option name can be at most " + MAX_OPTION_NAME_BYTES + " bytes");
            }
            if (!seen.add(name.toLowerCase())) {
                throw new BlockBetException(BlockBetError.INVALID_REQUEST, "The option names must be different");
            }
        }

        if (request.getStake() == null || request.getStake().signum() <= 0) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "stake must be greater than 0");
        }
        BigInteger duration = request.getDurationSeconds();
        if (duration == null || duration.signum() <= 0 || duration.compareTo(MAX_DURATION_SECONDS) > 0) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST,
                "durationSeconds must be between 1 and " + MAX_DURATION_SECONDS);
        }

        Wallet bookieWallet = betService.lockOwnWallet(account, request.getFromAddress());
        BetContract contract = betContractService.currentContract(BetContractType.MULTIPLE_OPTION_SIMPLE_POOL);

        IBetContractService.CreatedBet created = betContractService.createBet(
            bookieWallet, contract, optionNames, request.getStake(), duration);

        Bet bet = new Bet();
        bet.setContract(contract);
        bet.setChainBetId(created.chainBetId());
        bet.setTitle(title);
        bet.setDescription(StringUtils.trimToNull(request.getDescription()));
        bet.setImageUrl(StringUtils.trimToNull(request.getImageUrl()));
        bet.setBookieWallet(bookieWallet);
        bet.setCreateTxHash(created.txHash());
        bet.setCloseTime(LocalDateTime.ofEpochSecond(
            betContractService.getBet(contract, created.chainBetId()).closeTime().longValueExact(), 0, ZoneOffset.UTC));
        try {
            bet = betRepo.saveAndFlush(bet);
        } catch (RuntimeException e) {
            // The bet is already on chain; keep what is needed to rebuild its row by hand.
            log.error("Bet {} on contract {} (tx {}) exists on chain but its row could not be saved",
                created.chainBetId(), contract.getAddress(), created.txHash(), e);
            throw e;
        }

        bettingLogService.record(BettingAction.BET_CREATED, bet.getBetId(), account.getAccountId(),
            bookieWallet.getAddress(), null, request.getStake(), created.txHash(),
            "title=" + title + "; options=" + String.join(" | ", optionNames) + "; durationSeconds=" + duration);

        CreateBetResponse response = new CreateBetResponse();
        response.setBetId(BigInteger.valueOf(bet.getBetId()));
        response.setTxHash(created.txHash());
        return response;
    }

    @Override
    @Transactional
    public TxHashResponse handleBookieBetsMultipleOptionSimplePoolBetIdResultPutRequest(
        Account account, BigInteger betId, ResolveMultipleOptionSimplePoolBetRequest request) {
        if (request.getWinner() == null) {
            throw new BlockBetException(BlockBetError.INVALID_REQUEST, "winner is required");
        }

        Bet bet = betService.findBet(betId, BetContractType.MULTIPLE_OPTION_SIMPLE_POOL);
        // Only the wallet that created the bet can resolve it on chain, and only its owner can use that wallet.
        Wallet bookieWallet = walletRepo.findByAccountAndAddressForUpdate(account, bet.getBookieWallet().getAddress())
            .orElseThrow(() -> new BlockBetException(BlockBetError.FORBIDDEN, "Only the bookie of this bet can resolve it"));

        // A winner letter beyond the bet's options is refused by the contract ("Invalid winner").
        IBetContractService.ResolvedBet resolved = betContractService.resolve(bookieWallet, bet.getContract(),
            bet.getChainBetId(), betService.toContractOption(request.getWinner()));
        TransactionReceipt receipt = resolved.receipt();
        bet.setCaution(false);

        // The contract paid every winner and the internal account inside this transaction: keep a receipt for
        // each payment (same tx hash, told apart by the receiving address).
        List<BBTransactionReceipt> payoutReceipts = new ArrayList<>();
        for (IBetContractService.WinnerPayout payout : resolved.payouts()) {
            payoutReceipts.add(payoutReceipt(TransactionType.BET_PAYOUT, bet, receipt, payout.to(), payout.amount(),
                payout.paid()));
        }
        // The division remainder / the pool of a bet nobody won.
        if (resolved.internalPayout().signum() > 0) {
            payoutReceipts.add(payoutReceipt(TransactionType.BET_INTERNAL_PAYOUT, bet, receipt,
                betContractService.internalAccountAddress(), resolved.internalPayout(), true));
        }
        try {
            receiptRepo.saveAllAndFlush(payoutReceipts);
        } catch (RuntimeException e) {
            log.error("Bet {} resolved in tx {} paid {} winners and {} wei to the internal account but the receipts could not be saved",
                bet.getBetId(), receipt.getTransactionHash(), resolved.payouts().size(), resolved.internalPayout(), e);
            throw e;
        }

        bettingLogService.record(BettingAction.BET_RESOLVED, bet.getBetId(), account.getAccountId(),
            bookieWallet.getAddress(), request.getWinner(), null, receipt.getTransactionHash(),
            "winners=" + resolved.payouts().size() + "; internalPayoutWei=" + resolved.internalPayout());

        TxHashResponse response = new TxHashResponse();
        response.setTxHash(receipt.getTransactionHash());
        return response;
    }

    /**
     * A payment the contract made inside the resolve transaction. The gas columns are those of the whole
     * transaction (the bookie paid it), the same for every receipt of it.
     *
     * @param success false for a winner whose transfer failed and whose amount stayed in the contract
     */
    private BBTransactionReceipt payoutReceipt(TransactionType type, Bet bet, TransactionReceipt receipt, String to,
                                               BigInteger amount, boolean success) {
        return betService.newReceipt(type, receipt, bet.getContract().getAddress(), to, amount, success);
    }
}
