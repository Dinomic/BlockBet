package com.dinomic.blockbet.quazt.jobs;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.scheduling.quartz.QuartzJobBean;

import java.time.OffsetDateTime;

public class TestJob2 extends QuartzJobBean {

    private static Logger LOG = LogManager.getLogger(TestJob2.class);

    @Override
    protected void executeInternal(JobExecutionContext context) {
        LOG.info("hehehehehehehe " + OffsetDateTime.now());
    }
}
