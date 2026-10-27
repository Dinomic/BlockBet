package com.dinomic.blockbet.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.methods.response.EthBlockNumber;
import org.web3j.protocol.http.HttpService;

@Configuration
public class BlockBetConfig {
    private static final Logger log = LoggerFactory.getLogger(BlockBetConfig.class);

    @Autowired
    BlockchainProperties blockchainProperties;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public Web3j getWeb3j() throws Exception {
        try {
            Web3j web3j = Web3j.build(new HttpService(blockchainProperties.network().url()));

            log.info("Connected to Ethereum client version: "
                + web3j.web3ClientVersion().send().getWeb3ClientVersion());

            EthBlockNumber result = web3j.ethBlockNumber().sendAsync().get();
            log.info("The Block Number is: " + result.getBlockNumber().toString());

            return web3j;
        } catch (Exception e) {
            log.error("Cannot connect to BC network !!! Please check");
            throw new Exception("Cannot connect to BC network !!! Please check");
        }
    }

}
