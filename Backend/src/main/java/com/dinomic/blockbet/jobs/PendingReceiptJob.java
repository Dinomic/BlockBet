package com.dinomic.blockbet.jobs;

import org.quartz.DisallowConcurrentExecution;
import org.quartz.JobExecutionContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.quartz.QuartzJobBean;

/** Quartz entry point for {@link TransferReceiptTracker}: updates transfers that had no result yet. */
@DisallowConcurrentExecution
public class PendingReceiptJob extends QuartzJobBean {

    @Autowired
    TransferReceiptTracker tracker;

    @Override
    protected void executeInternal(JobExecutionContext context) {
        tracker.confirmPendingTransfers();
    }
}
