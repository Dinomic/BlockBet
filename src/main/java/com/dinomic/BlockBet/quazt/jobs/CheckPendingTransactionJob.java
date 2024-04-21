package com.dinomic.BlockBet.quazt.jobs;

import com.dinomic.BlockBet.services.IBlockchainService;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.quartz.JobExecutionContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.quartz.QuartzJobBean;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;

@Component
public class CheckPendingTransactionJob extends QuartzJobBean {

    private static Logger LOG = LogManager.getLogger(CheckPendingTransactionJob.class);


    @Autowired
    IBlockchainService blockchainService;

    @Override
    protected void executeInternal(JobExecutionContext context) {

        blockchainService.checkUnDoneTransactions();

        LOG.info("hehehehehehehe " + OffsetDateTime.now());


    }
}
