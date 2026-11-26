package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.TxHashResponse;
import com.dinomic.blockbet.daos.Bet;
import com.dinomic.blockbet.services.IBetContractService;
import com.dinomic.blockbet.enums.BettingAction;
import com.dinomic.blockbet.services.IBetService;
import com.dinomic.blockbet.services.IBettingLogService;
import com.dinomic.blockbet.services.IInternalService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigInteger;

/** What the internal team does with bets. The contract only accepts refundExpired from the internal account. */
@Service
public class InternalService implements IInternalService {

    @Autowired
    IBetContractService betContractService;

    @Autowired
    IBetService betService;

    @Autowired
    IBettingLogService bettingLogService;

    @Override
    @Transactional
    public TxHashResponse handleInternalBetsBetIdRefundPostRequest(BigInteger betId) {
        Bet bet = betService.findBet(betId);

        String txHash = betContractService.refundExpired(bet.getContract(), bet.getChainBetId());
        bet.setCaution(false);
        // no account: the internal team has no authentication of its own yet
        bettingLogService.record(BettingAction.BET_REFUNDED, bet.getBetId(), null, null, null, null, txHash, null);

        TxHashResponse response = new TxHashResponse();
        response.setTxHash(txHash);
        return response;
    }
}
