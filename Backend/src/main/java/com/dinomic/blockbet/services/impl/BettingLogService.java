package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.BetOption;
import com.dinomic.blockbet.daos.BettingLog;
import com.dinomic.blockbet.enums.BettingAction;
import com.dinomic.blockbet.repositories.IBettingLogRepo;
import com.dinomic.blockbet.services.IBettingLogService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigInteger;
import java.util.List;

@Service
public class BettingLogService implements IBettingLogService {
    /** Size of the DETAIL column. */
    private static final int MAX_DETAIL_LENGTH = 512;

    @Autowired
    IBettingLogRepo bettingLogRepo;

    /**
     * Joins the caller's transaction on purpose: the row is saved with the change it records, and the insert
     * cannot fail on a foreign key (there are none) or on the size of a value (DETAIL is cut here).
     */
    @Override
    public void record(BettingAction action, Long betId, Long accountId, String walletAddress, BetOption option,
                       BigInteger amount, String txHash, String detail) {
        BettingLog entry = new BettingLog();
        entry.setAction(action);
        entry.setBetId(betId);
        entry.setAccountId(accountId);
        entry.setWalletAddress(walletAddress);
        entry.setOption(option == null ? null : option.getValue());
        entry.setAmount(amount);
        entry.setTxHash(txHash);
        entry.setDetail(StringUtils.abbreviate(detail, MAX_DETAIL_LENGTH));
        bettingLogRepo.save(entry);
    }

    @Override
    public List<BettingLog> findPage(long accountId, Long betId, long offset, long limit) {
        return bettingLogRepo.findPage(accountId, betId, offset, limit);
    }

    @Override
    public long count(long accountId, Long betId) {
        return bettingLogRepo.countFor(accountId, betId);
    }
}