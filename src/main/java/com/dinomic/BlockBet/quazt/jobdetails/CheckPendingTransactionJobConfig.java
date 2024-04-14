package com.dinomic.BlockBet.quazt.jobdetails;

import com.dinomic.BlockBet.quazt.jobs.CheckPendingTransactionJob;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.quartz.JobDetailFactoryBean;
import org.springframework.scheduling.quartz.SimpleTriggerFactoryBean;

import java.util.Objects;

@Configuration
public class CheckPendingTransactionJobConfig {

    @Bean
    public JobDetailFactoryBean checkPendingTransactionJobDetail() {
        JobDetailFactoryBean factoryBean = new JobDetailFactoryBean();
        factoryBean.setJobClass(CheckPendingTransactionJob.class);
        factoryBean.setDurability(true);
        return factoryBean;
    }

    @Bean
    public SimpleTriggerFactoryBean checkPendingTransactionJobTrigger() {
        SimpleTriggerFactoryBean factoryBean = new SimpleTriggerFactoryBean();
        factoryBean.setJobDetail(Objects.requireNonNull(checkPendingTransactionJobDetail().getObject()));
        factoryBean.setStartDelay(0);
        factoryBean.setRepeatInterval(10000);
        return factoryBean;
    }


}
