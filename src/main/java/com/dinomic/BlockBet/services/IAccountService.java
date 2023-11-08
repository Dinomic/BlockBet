package com.dinomic.BlockBet.services;

import blockbet.openapi.model.WalletPostRequest;
import blockbet.openapi.model.WalletPostResponse;
import com.dinomic.BlockBet.entities.Account;

import javax.validation.constraints.NotNull;

public interface IAccountService {

    WalletPostResponse createWalletForAccount(@NotNull Account account, @NotNull WalletPostRequest request);

    Account getAccountByAccountId(@NotNull Long id);

    Account getAccountByEmail(@NotNull String email);

    Account addNewAccount(@NotNull String email, @NotNull String password);
}
