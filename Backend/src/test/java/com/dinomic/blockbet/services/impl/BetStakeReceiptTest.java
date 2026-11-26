package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.BetOption;
import blockbet.openapi.model.PlaceMultipleOptionSimplePoolBetRequest;
import blockbet.openapi.model.TxHashResponse;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.BBTransactionReceipt;
import com.dinomic.blockbet.daos.Bet;
import com.dinomic.blockbet.daos.BetContract;
import com.dinomic.blockbet.daos.Wallet;
import com.dinomic.blockbet.enums.BettingAction;
import com.dinomic.blockbet.enums.TransactionType;
import com.dinomic.blockbet.repositories.IAccountRepo;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import com.dinomic.blockbet.repositories.IBetParticipantRepo;
import com.dinomic.blockbet.services.IBetContractService;
import com.dinomic.blockbet.services.IBetContractService.ChainBet;
import com.dinomic.blockbet.services.IBetContractService.ChainOption;
import com.dinomic.blockbet.services.IBetContractService.ChainStatus;
import com.dinomic.blockbet.services.IBetService;
import com.dinomic.blockbet.services.IBettingLogService;
import org.junit.jupiter.api.Test;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.utils.Numeric;

import java.math.BigInteger;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** Placing a bet records the stake that moved from the bettor's wallet to the contract. */
class BetStakeReceiptTest {
    private static final String WALLET = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static final String CONTRACT = "0x1111111111111111111111111111111111111111";
    private static final BigInteger STAKE = BigInteger.valueOf(1_000_000_000_000_000L);

    @Test
    void placeBetSavesABetStakeReceiptFromTheWalletToTheContract() {
        BettorService service = new BettorService();
        service.betContractService = mock(IBetContractService.class);
        service.participantRepo = mock(IBetParticipantRepo.class);
        service.accountRepo = mock(IAccountRepo.class);
        service.betService = mock(IBetService.class);
        service.bettingLogService = mock(IBettingLogService.class);
        service.receiptRepo = mock(IBBTransactionReceiptRepo.class);

        Account account = mock(Account.class);
        when(account.getAccountId()).thenReturn(5L);
        when(service.accountRepo.findByIdForUpdate(5L)).thenReturn(Optional.of(account));

        BetContract contract = mock(BetContract.class);
        when(contract.getAddress()).thenReturn(CONTRACT);
        Bet bet = mock(Bet.class);
        when(bet.getContract()).thenReturn(contract);
        when(bet.getBetId()).thenReturn(9L);
        when(bet.getChainBetId()).thenReturn(3L);
        when(service.betService.findBet(any(), any())).thenReturn(bet);
        when(service.participantRepo.findByBetAndAccount(bet, account)).thenReturn(Optional.empty());

        Wallet wallet = mock(Wallet.class);
        when(wallet.getAddress()).thenReturn(WALLET);
        when(service.betService.lockOwnWallet(account, WALLET)).thenReturn(wallet);

        when(service.betContractService.getBet(contract, 3L)).thenReturn(new ChainBet("0xbookie",
            List.of("Arsenal", "MU"), STAKE, BigInteger.TEN, ChainStatus.OPEN, ChainOption.NONE,
            List.of(BigInteger.ZERO, BigInteger.ZERO)));
        when(service.betService.toContractOption(BetOption.B)).thenReturn(ChainOption.B);

        TransactionReceipt mined = new TransactionReceipt();
        mined.setTransactionHash("0xhash");
        when(service.betContractService.placeBet(wallet, contract, 3L, ChainOption.B, STAKE)).thenReturn(mined);
        BBTransactionReceipt row = new BBTransactionReceipt();
        when(service.betService.newReceipt(TransactionType.BET_STAKE, mined, WALLET, CONTRACT, STAKE, true))
            .thenReturn(row);

        PlaceMultipleOptionSimplePoolBetRequest request = new PlaceMultipleOptionSimplePoolBetRequest();
        request.setFromAddress(WALLET);
        request.setOption(BetOption.B);
        TxHashResponse response = service.handleBettorBetsMultipleOptionSimplePoolBetIdPlacePostRequest(
            account, BigInteger.valueOf(9), request);

        assertEquals("0xhash", response.getTxHash());
        verify(service.receiptRepo).saveAndFlush(row);
        verify(service.bettingLogService).record(BettingAction.BET_PLACED, 9L, 5L, WALLET, BetOption.B, STAKE, "0xhash", null);
    }

    @Test
    void newReceiptCopiesTheTransactionFields() {
        BetService betService = new BetService();
        TransactionReceipt mined = new TransactionReceipt();
        mined.setTransactionHash("0xhash");
        mined.setBlockHash("0xblock");
        mined.setBlockNumber("0x10");
        mined.setGasUsed("0x5208");
        mined.setEffectiveGasPrice(Numeric.encodeQuantity(BigInteger.valueOf(7)));

        BBTransactionReceipt row = betService.newReceipt(TransactionType.BET_STAKE, mined, WALLET, CONTRACT, STAKE, true);

        assertSame(TransactionType.BET_STAKE, row.getTransactionType());
        assertEquals("0xhash", row.getHash());
        assertEquals(WALLET, row.getFromAddress());
        assertEquals(CONTRACT, row.getToAddress());
        assertEquals("0xblock", row.getBlockHash());
        assertEquals(16, row.getBlockNumber());
        assertEquals(21000, row.getGasUsed());
        assertEquals(7, row.getEffectiveGasPrice());
        assertEquals(STAKE, row.getAmount());
    }
}
