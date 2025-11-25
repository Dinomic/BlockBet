package com.dinomic.blockbet.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Getter
@Setter
@Configuration
@ConfigurationProperties("blockchain")
public class BlockchainProperties {

    NetworkProperties network;
    mainAccountProperties mainAccount;

    @Getter
    @Setter
    public static class NetworkProperties {
        private String url;
    }

    @Getter
    @Setter
    public static class mainAccountProperties {
        private String address;
        private String privateKey;
    }

}
