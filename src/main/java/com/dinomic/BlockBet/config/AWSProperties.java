package com.dinomic.BlockBet.config;

import lombok.Getter;
import lombok.Setter;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

@Getter
@Setter
@Configuration
@ConfigurationProperties("aws")
public class AWSProperties {

    private static Logger LOG = LogManager.getLogger(AWSProperties.class);

    GeneralProperties general;
    CredentialsProperties credentials;

    @Getter
    @Setter
    public static class CredentialsProperties {
        private String accessKey;
        private String secretKey;
    }

    @Getter
    @Setter
    public static class GeneralProperties {
        private String region;
    }
}
