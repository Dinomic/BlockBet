package com.dinomic.blockbet.jobs;

import com.dinomic.blockbet.daos.Bet;
import com.dinomic.blockbet.enums.BettingAction;
import com.dinomic.blockbet.repositories.IBetRepo;
import com.dinomic.blockbet.services.IBetContractService;
import com.dinomic.blockbet.services.IBettingLogService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;

/**
 * Flags bets the bookie left unresolved past the resolve deadline (CAUTION) so the internal team can handle them.
 * The flag lives only in the database; the contract does not know about it. Run by {@code BetCautionJob} (Quartz).
 */
@Component
public class BetCautionTracker {
    private static final Logger log = LoggerFactory.getLogger(BetCautionTracker.class);
    private static final int BATCH_SIZE = 50;

    @Autowired
    IBetRepo betRepo;

    @Autowired
    IBetContractService betContractService;

    @Autowired
    IBettingLogService bettingLogService;

    @Transactional
    public void flagOverdueBets() {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        LocalDateTime deadline = now.minusSeconds(IBetContractService.RESOLVE_DEADLINE_SECONDS);

        List<Bet> overdue = betRepo.findByCloseTimeBeforeAndCautionCheckedAtIsNull(deadline, PageRequest.of(0, BATCH_SIZE));
        for (Bet bet : overdue) {
            try {
                IBetContractService.ChainStatus status =
                    betContractService.getBet(bet.getContract(), bet.getChainBetId()).status();
                // Still waiting for the result: needs the internal team. Resolved or refunded: nothing to flag.
                bet.setCaution(status == IBetContractService.ChainStatus.CLOSED);
                bet.setCautionCheckedAt(now);
                if (bet.isCaution()) {
                    log.warn("Bet {} was not resolved by its bookie in time, flagged CAUTION", bet.getBetId());
                    bettingLogService.record(BettingAction.BET_CAUTION_FLAGGED, bet.getBetId(), null, null, null, null, null,
                        "not resolved " + IBetContractService.RESOLVE_DEADLINE_SECONDS + " seconds after the close time");
                }
            } catch (RuntimeException e) {
                // Chain unreachable: leave it unchecked, the next run tries again.
                log.warn("Could not check bet {} for caution: {}", bet.getBetId(), e.getMessage());
            }
        }
    }
}
