package com.dinomic.BlockBet.services.impl;

import blockbet.openapi.model.WalletPostRequest;
import blockbet.openapi.model.WalletPostResponse;
import blockbet.openapi.model.WalletsGetResponse;
import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Authority;
import com.dinomic.BlockBet.entities.Wallet;
import com.dinomic.BlockBet.enums.Role;
import com.dinomic.BlockBet.repositories.IAccountRepo;
import com.dinomic.BlockBet.repositories.IWalletRepo;
import com.dinomic.BlockBet.services.IAccountService;
import com.dinomic.BlockBet.services.IBlockchainService;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class AccountService implements IAccountService {

    @Autowired
    IAccountRepo accountRepo;

    @Autowired
    IWalletRepo walletRepo;

    @Autowired
    IBlockchainService blockchainService;

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

        blockchainService.transferEthFromFaucet(newWallet.getAddress(), BigDecimal.TEN);

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
    public Account getAccountByAccountId(Long id) {
        return accountRepo.findById(id).orElseThrow();
    }

    @Override
    public Account getAccountByEmail(String email) {
        if (StringUtils.isEmpty(email)) return null;

        return accountRepo.findByEmail(email).orElse(null);
    }

    @Override
    public Account addNewAccount(String email, String password) {
        Account account = new Account();
        account.setEmail(email);
        account.setUsername(email);
        account.setPassword(password);
        Authority defaultAuthority = new Authority(account, Role.ROLE_BETTOR);
        account.setAuthorities(Set.of(defaultAuthority));
        return accountRepo.save(account);
    }
}
