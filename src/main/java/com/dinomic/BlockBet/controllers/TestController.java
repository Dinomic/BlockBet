package com.dinomic.BlockBet.controllers;

import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Wallet;
import com.dinomic.BlockBet.exception.BlockBetError;
import com.dinomic.BlockBet.exception.BlockBetException;
import com.dinomic.BlockBet.services.IBlockchainService;
import org.checkerframework.checker.units.qual.A;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigInteger;

@RestController
@RequestMapping("/test")
public class TestController {

    @Autowired
    IBlockchainService blockchainService;

    @GetMapping("/num1")
    public String testNum1() {
//        System.out.println(testService);
        return "test num 1 OK";
    }

    @GetMapping("/num2")
    public String testNum2() {
//        System.out.println(testService);
        return "test num 2 OK";
    }

    @GetMapping("/num3")
    public String testNum3() throws Exception {
//        System.out.println(testService);
        Account dummyAccount = new Account();
        dummyAccount.setEmail("dummyEmail");
//        blockchainService.createWallet(dummyAccount, "tesst");
        return "test num 3 OK";
    }


    @GetMapping("/num4")
    public String testNum4() throws Exception {
        Wallet testWallet = new Wallet();
        testWallet.setPrivateKey("0x3c6932e46cc5c38f7c96c234d18e08ac0c83faee214652b494254c0f9e4e7404");
        return blockchainService.transferEth(testWallet, "0x05d77d6951dadc8952d5ba9f1b91124a6570de70", BigInteger.valueOf(100000L));
    }


    @GetMapping("/num5")
    public String testNum5() throws Exception {
        throw new BlockBetException(BlockBetError.BLOCKCHAIN_ERROR, "test");
//        return "test num 5 OK";
    }
}
