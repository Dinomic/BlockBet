package com.dinomic.BlockBet.quazt.jobdetails;

import com.dinomic.BlockBet.quazt.jobs.TestJob;
import com.dinomic.BlockBet.quazt.jobs.TestJob2;
import org.quartz.JobDetail;
import org.quartz.Trigger;
import org.quartz.spi.JobFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.quartz.JobDetailFactoryBean;
import org.springframework.scheduling.quartz.SchedulerFactoryBean;
import org.springframework.scheduling.quartz.SimpleTriggerFactoryBean;
import org.springframework.scheduling.quartz.SpringBeanJobFactory;

import java.io.IOException;
import java.util.Objects;

@Configuration
public class TestJobConfig2 {

    @Bean
    public JobDetailFactoryBean testJobDetail2() {
        JobDetailFactoryBean factoryBean2 = new JobDetailFactoryBean();
        factoryBean2.setJobClass(TestJob2.class);
        factoryBean2.setDurability(true);
        return factoryBean2;
    }

    @Bean
    public SimpleTriggerFactoryBean testJobTrigger2() {
        System.out.println("simpleJobTrigger");
        SimpleTriggerFactoryBean factoryBean2 = new SimpleTriggerFactoryBean();
        factoryBean2.setJobDetail(Objects.requireNonNull(testJobDetail2().getObject()));
        factoryBean2.setStartDelay(0);
        factoryBean2.setRepeatInterval(10000);
        return factoryBean2;
    }


}
