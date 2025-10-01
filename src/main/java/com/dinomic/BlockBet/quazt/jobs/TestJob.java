package com.dinomic.blockbet.quazt.jobs;

import lombok.extern.slf4j.Slf4j;
import org.quartz.JobExecutionContext;
import org.springframework.scheduling.quartz.QuartzJobBean;

import java.time.OffsetDateTime;

@Slf4j
public class TestJob extends QuartzJobBean {

    @Override
    protected void executeInternal(JobExecutionContext context) {
        log.info("hehe " + OffsetDateTime.now());
    }
}
