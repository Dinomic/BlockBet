package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.BetOption;
import com.dinomic.blockbet.daos.BettingLog;
import com.dinomic.blockbet.enums.BettingAction;
import com.dinomic.blockbet.repositories.IBettingLogRepo;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class BettingLogServiceTest {
    private final IBettingLogRepo repo = mock(IBettingLogRepo.class);
    private final BettingLogService service = new BettingLogService();

    BettingLogServiceTest() {
        service.bettingLogRepo = repo;
    }

    private BettingLog saved() {
        ArgumentCaptor<BettingLog> captor = ArgumentCaptor.forClass(BettingLog.class);
        verify(repo).save(captor.capture());
        return captor.getValue();
    }

    @Test
    void savesEveryField() {
        service.record(BettingAction.BET_PLACED, 7L, 3L, "0xabc", BetOption.C, BigInteger.TEN, "0xhash", "detail");

        BettingLog entry = saved();
        assertEquals(BettingAction.BET_PLACED, entry.getAction());
        assertEquals(7L, entry.getBetId());
        assertEquals(3L, entry.getAccountId());
        assertEquals("0xabc", entry.getWalletAddress());
        assertEquals("C", entry.getOption());
        assertEquals(BigInteger.TEN, entry.getAmount());
        assertEquals("0xhash", entry.getTxHash());
        assertEquals("detail", entry.getDetail());
    }

    @Test
    void systemActionHasNoAccountOptionOrAmount() {
        service.record(BettingAction.BET_CAUTION_FLAGGED, 7L, null, null, null, null, null, null);

        BettingLog entry = saved();
        assertNull(entry.getAccountId());
        assertNull(entry.getOption());
        assertNull(entry.getAmount());
        assertNull(entry.getDetail());
    }

    @Test
    void longDetailIsCutToTheColumnSize() {
        service.record(BettingAction.BET_CREATED, 7L, 3L, null, null, null, null, "x".repeat(2000));

        assertTrue(saved().getDetail().length() <= 512);
    }
}
