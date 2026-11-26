package com.dinomic.blockbet.jobs;

import org.quartz.DisallowConcurrentExecution;
import org.quartz.JobExecutionContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.quartz.QuartzJobBean;

/** Quartz entry point for {@link BetCautionTracker}: flags bets left unresolved by their bookie. */
@DisallowConcurrentExecution
public class BetCautionJob extends QuartzJobBean {

    @Autowired
    BetCautionTracker tracker;

    @Override
    protected void executeInternal(JobExecutionContext context) {
        tracker.flagOverdueBets();
    }
}
