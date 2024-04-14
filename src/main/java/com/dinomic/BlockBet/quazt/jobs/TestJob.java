package com.dinomic.BlockBet.quazt.jobs;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.scheduling.quartz.QuartzJobBean;

import java.time.OffsetDateTime;

public class TestJob extends QuartzJobBean {

    private static Logger LOG = LogManager.getLogger(TestJob.class);

    @Override
    protected void executeInternal(JobExecutionContext context) {
        LOG.info("hehe " + OffsetDateTime.now());
    }
}
