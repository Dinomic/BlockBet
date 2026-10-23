package com.dinomic.blockbet.services;

import com.dinomic.blockbet.daos.Account;
import jakarta.validation.constraints.NotNull;

public interface IAccountService {

    Account getAccountByAccountId(@NotNull Long id);

    Account getAccountByEmail(@NotNull String email);

    Account addNewAccount(@NotNull String email, @NotNull String password);
}
