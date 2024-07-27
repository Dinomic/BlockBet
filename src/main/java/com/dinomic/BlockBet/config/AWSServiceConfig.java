package com.dinomic.BlockBet.config;

import com.amazonaws.auth.AWSCredentialsProvider;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.document.DynamoDB;
// import org.apache.logging.log4j.LogManager;
// import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;


@Configuration
public class AWSServiceConfig {

    // private static Logger LOG = LogManager.getLogger(AWSServiceConfig.class);

    @Autowired
    AWSProperties awsProperties;

    @Bean
    public DynamoDB amazonDynamoDBClient() {
        return new DynamoDB(AmazonDynamoDBClientBuilder.standard()
                .withRegion(awsProperties.getGeneral().getRegion())
                .withCredentials(getCredentialsProvider())
                .build());
    }

    private AWSCredentialsProvider getCredentialsProvider() {
        return new AWSStaticCredentialsProvider(
            new BasicAWSCredentials(
                    awsProperties.credentials.getAccessKey(),
                    awsProperties.credentials.getSecretKey())
        );
    }
}
