package com.dinomic.blockbet.quazt.jobdetails;

import com.dinomic.blockbet.quazt.jobs.TestJob;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.quartz.JobDetailFactoryBean;
import org.springframework.scheduling.quartz.SimpleTriggerFactoryBean;

import java.util.Objects;

@Configuration
public class TestJobConfig {

    @Bean
    public JobDetailFactoryBean testJobDetail() {
        JobDetailFactoryBean factoryBean = new JobDetailFactoryBean();
        factoryBean.setJobClass(TestJob.class);
        factoryBean.setDurability(true);
        return factoryBean;
    }

    @Bean
    public SimpleTriggerFactoryBean testJobTrigger() {
        SimpleTriggerFactoryBean factoryBean = new SimpleTriggerFactoryBean();
        factoryBean.setJobDetail(Objects.requireNonNull(testJobDetail().getObject()));
        factoryBean.setStartDelay(0);
        factoryBean.setRepeatInterval(10000);
        return factoryBean;
    }
}
