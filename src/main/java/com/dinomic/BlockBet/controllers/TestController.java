package com.dinomic.BlockBet.controllers;

import com.dinomic.BlockBet.aws.dynamodb.IDynamoDBService;
import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Wallet;
import com.dinomic.BlockBet.exception.BlockBetError;
import com.dinomic.BlockBet.exception.BlockBetException;
import com.dinomic.BlockBet.security.BlockBetAuthenticationToken;
import com.dinomic.BlockBet.services.IAccountService;
import com.dinomic.BlockBet.services.IBlockchainService;
import com.dinomic.BlockBet.services.impl.WalletService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigInteger;

@RestController
@RequestMapping("/test")
public class TestController {

    @Autowired
    IBlockchainService blockchainService;

    @Autowired
    IAccountService accountService;

    @Autowired
    IDynamoDBService dynamoDBService;

    @Autowired
    private WalletService walletService;

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

    @GetMapping("/num6")
    public String testNum6(@RequestParam(value = "hash", required = true) String hash) throws Exception {
        blockchainService.checkUnDoneTransaction(hash);
        return "test num 6 OK";
    }

    @GetMapping("/num7")
    public String testNum7() throws Exception {
        dynamoDBService.putItemToTable(null, null);
        return "test num 7 OK";
    }

    @GetMapping("/num8")
    public String testNum8() throws Exception {
        BlockBetAuthenticationToken userDetail = (BlockBetAuthenticationToken) SecurityContextHolder.getContext().getAuthentication();
        Account account = accountService.getAccountByAccountId(userDetail.getPrincipal().getAccountId());
        Wallet wallet = walletService.getWallet(account, "0x3e275791625b86f85d536f5e646c9a523b1c0851");

        blockchainService.deployContract(wallet, "password");
        return "test num 8 OK";
    }
}
