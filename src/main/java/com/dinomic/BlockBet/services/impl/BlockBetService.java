package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.*;
import com.dinomic.blockbet.entities.Account;
import com.dinomic.blockbet.entities.Wallet;
import com.dinomic.blockbet.exception.BlockBetError;
import com.dinomic.blockbet.exception.BlockBetException;
import com.dinomic.blockbet.mappers.GeneralMapper;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import com.dinomic.blockbet.repositories.IWalletRepo;
import com.dinomic.blockbet.services.IBlockBetService;
import com.dinomic.blockbet.services.IBlockchainService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class BlockBetService implements IBlockBetService {

    @Autowired
    IBlockchainService blockchainService;

    @Autowired
    IWalletRepo walletRepo;

    @Autowired
    IBBTransactionReceiptRepo bbTransactionReceiptRepo;

    @Override
    public WalletPostResponse handleWalletPostRequest(Account account, WalletPostRequest request){
        WalletPostResponse response = new WalletPostResponse();

        Wallet newWallet;

        try {
            newWallet = blockchainService.createWallet(account, request.getPassword());
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        response.setAddress(newWallet.getAddress());
        response.setPublicKey(newWallet.getPublicKey());
        response.setPrivateKey(newWallet.getPrivateKey());

        blockchainService.transferEthFromFaucet(newWallet.getAddress(), 10);

        return response;
    }

    @Override
    public WalletsGetResponse handleWalletsGetRequest(Account account) {
        WalletsGetResponse response = new WalletsGetResponse();

        List<Wallet> accountWallets = walletRepo.findAllByAccount(account);

        Map<String, BigInteger> walletBalances = blockchainService.getWalletBalances(
                accountWallets.stream().map(Wallet::getAddress).collect(Collectors.toList()));

        for (Wallet wallet : accountWallets) {
            blockbet.openapi.model.Wallet responseWallet = new blockbet.openapi.model.Wallet();

            responseWallet.setAddress(wallet.getAddress());
            responseWallet.setPublicKey(wallet.getPublicKey());
            responseWallet.setPrivateKey(wallet.getPrivateKey());
            responseWallet.setBalance(new BigDecimal(walletBalances.getOrDefault(wallet.getAddress(), BigInteger.ZERO)));

            response.addWalletsItem(responseWallet);
        }

        return response;
    }

    @Override
    public TransferTokensPutResponse handleTransferTokensPutRequest(Account account, TransferTokensPutRequest request) {
        TransferTokensPutResponse response = new TransferTokensPutResponse();

        Wallet fromWallet = walletRepo.findByAccountAndAddress(account, request.getFromAddress()).orElseThrow(() ->
                new BlockBetException(BlockBetError.WALLET_NOT_FOUND, "Wallet not found with associated account")
        );

        if (!fromWallet.getPrivateKey().equals(request.getFromPrivateKey())) {
            throw new BlockBetException(BlockBetError.INPUT_PRIVATE_KEY_NOT_MATCH, "input private key not match");
        }

        response.setTxHash(blockchainService.transferEth(fromWallet, request.getToAddress(),
                request.getAmount()));


        return response;
    }

    @Override
    public ReceiptsGetResponse handleReceiptsGetRequest(BigInteger offset, BigInteger limit) {
        ReceiptsGetResponse response = new ReceiptsGetResponse();
        response.setResult(GeneralMapper.INSTANCE.bbTransactionReceiptsToReceiptsGetResponseEntries(bbTransactionReceiptRepo.getBBTransactionReceipts(offset, limit)));
        return response;
    }
}
