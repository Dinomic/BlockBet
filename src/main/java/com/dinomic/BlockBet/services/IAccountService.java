package com.dinomic.BlockBet.services;

import blockbet.openapi.model.BettorWalletPostRequest;
import blockbet.openapi.model.BettorWalletPostResponse;
import com.dinomic.BlockBet.entities.Account;

import javax.validation.constraints.NotNull;

public interface IAccountService {

    BettorWalletPostResponse createWalletForAccount(@NotNull Account account, @NotNull BettorWalletPostRequest request);

    Account getAccountByAccountId(@NotNull Long id);

    Account getAccountByEmail(@NotNull String email);

    Account addNewAccount(@NotNull String email, @NotNull String password);
}
