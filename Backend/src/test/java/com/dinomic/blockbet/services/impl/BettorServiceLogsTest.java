package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.BetOption;
import blockbet.openapi.model.BettingLogAction;
import blockbet.openapi.model.BettingLogsGetResponse;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.BettingLog;
import com.dinomic.blockbet.enums.BettingAction;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.services.IBettingLogService;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigInteger;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class BettorServiceLogsTest {
    private final IBettingLogService logs = mock(IBettingLogService.class);
    private final BettorService service = new BettorService();
    private final Account account = mock(Account.class);

    BettorServiceLogsTest() {
        service.bettingLogService = logs;
        when(account.getAccountId()).thenReturn(5L);
    }

    @Test
    void mapsRowsOfTheCallersAccount() {
        BettingLog row = new BettingLog();
        ReflectionTestUtils.setField(row, "bettingLogId", 1L); // set by the database in real life
        row.setAction(BettingAction.BET_PLACED);
        row.setBetId(9L);
        row.setOption("C");
        row.setAmount(BigInteger.TEN);
        row.setTxHash("0xhash");
        when(logs.count(5L, 9L)).thenReturn(1L);
        when(logs.findPage(5L, 9L, 0L, 20L)).thenReturn(List.of(row));

        BettingLogsGetResponse response = service.handleBettorBettingLogsGetRequest(
            account, BigInteger.ZERO, BigInteger.valueOf(20), BigInteger.valueOf(9));

        assertEquals(BigInteger.ONE, response.getTotal());
        assertEquals(1, response.getResult().size());
        assertEquals(BettingLogAction.PLACED, response.getResult().get(0).getAction());
        assertEquals(BetOption.C, response.getResult().get(0).getOption());
        assertEquals(BigInteger.valueOf(9), response.getResult().get(0).getBetId());
        assertNull(response.getResult().get(0).getWalletAddress());
    }

    @Test
    void noBetIdMeansEveryBet() {
        service.handleBettorBettingLogsGetRequest(account, BigInteger.ZERO, BigInteger.TEN, null);

        verify(logs).findPage(5L, null, 0L, 10L);
    }

    @Test
    void badPagingIsRejected() {
        assertThrows(BlockBetException.class, () ->
            service.handleBettorBettingLogsGetRequest(account, BigInteger.valueOf(-1), BigInteger.TEN, null));
        assertThrows(BlockBetException.class, () ->
            service.handleBettorBettingLogsGetRequest(account, BigInteger.ZERO, BigInteger.ZERO, null));
        assertThrows(BlockBetException.class, () ->
            service.handleBettorBettingLogsGetRequest(account, BigInteger.ZERO, BigInteger.valueOf(101), null));
    }
}
