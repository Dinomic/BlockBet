package com.dinomic.blockbet.quazt.jobs;

import com.dinomic.blockbet.services.IBlockchainService;
import lombok.extern.slf4j.Slf4j;
import org.quartz.JobExecutionContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.quartz.QuartzJobBean;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;

@Component
@Slf4j
public class CheckPendingTransactionJob extends QuartzJobBean {

    @Autowired
    IBlockchainService blockchainService;

    @Override
    protected void executeInternal(JobExecutionContext context) {

        blockchainService.checkUnDoneTransactions();

        log.info("hehehehehehehe " + OffsetDateTime.now());

    }
}
