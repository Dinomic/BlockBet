package com.dinomic.blockbet.config;

import com.dinomic.blockbet.jobs.BetCautionJob;
import com.dinomic.blockbet.jobs.PendingReceiptJob;
import org.quartz.JobBuilder;
import org.quartz.JobDetail;
import org.quartz.SimpleScheduleBuilder;
import org.quartz.Trigger;
import org.quartz.TriggerBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * The Quartz jobs and their triggers. They are stored in the database (QRTZ_ tables), and
 * spring.quartz.overwrite-existing-jobs makes the intervals below win over what was saved earlier.
 */
@Configuration
public class QuartzConfig {
    private static final String GROUP = "blockbet";

    @Bean
    public JobDetail pendingReceiptJobDetail() {
        return JobBuilder.newJob(PendingReceiptJob.class)
            .withIdentity("pendingReceiptJob", GROUP)
            .withDescription("Confirms broadcast transfers once the chain has mined them")
            .storeDurably()
            .build();
    }

    @Bean
    public Trigger pendingReceiptTrigger(JobDetail pendingReceiptJobDetail,
                                         @Value("${blockbet.receipt-tracker.interval-ms:5000}") long intervalMs) {
        return everyMs(pendingReceiptJobDetail, "pendingReceiptTrigger", intervalMs);
    }

    @Bean
    public JobDetail betCautionJobDetail() {
        return JobBuilder.newJob(BetCautionJob.class)
            .withIdentity("betCautionJob", GROUP)
            .withDescription("Flags bets the bookie has not resolved in time as CAUTION")
            .storeDurably()
            .build();
    }

    @Bean
    public Trigger betCautionTrigger(JobDetail betCautionJobDetail,
                                     @Value("${blockbet.bet-caution.interval-ms:60000}") long intervalMs) {
        return everyMs(betCautionJobDetail, "betCautionTrigger", intervalMs);
    }

    private static Trigger everyMs(JobDetail job, String name, long intervalMs) {
        return TriggerBuilder.newTrigger()
            .forJob(job)
            .withIdentity(name, GROUP)
            .withSchedule(SimpleScheduleBuilder.simpleSchedule()
                .withIntervalInMilliseconds(intervalMs)
                .repeatForever()
                // after downtime, run once and go back to the normal rhythm instead of catching up
                .withMisfireHandlingInstructionNextWithRemainingCount())
            .build();
    }
}
