package com.dinomic.blockbet.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "blockchain")
public record BlockchainProperties(
    NetworkProperties network,
    MainAccountProperties mainAccount
) {
    public record NetworkProperties(
        String url,
        Long chainId
    ) {
    }

    public record MainAccountProperties(
        String address,
        String privateKey
    ) {
    }
}
