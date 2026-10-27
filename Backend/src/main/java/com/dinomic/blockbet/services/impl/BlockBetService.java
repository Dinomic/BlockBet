package com.dinomic.blockbet.services.impl;

import blockbet.openapi.model.WalletPostRequest;
import blockbet.openapi.model.WalletPostResponse;
import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.Wallet;
import com.dinomic.blockbet.repositories.IBBTransactionReceiptRepo;
import com.dinomic.blockbet.repositories.IWalletRepo;
import com.dinomic.blockbet.services.IBlockBetService;
import com.dinomic.blockbet.services.IBlockchainService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

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
}
