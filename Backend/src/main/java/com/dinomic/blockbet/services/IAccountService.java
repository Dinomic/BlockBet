package com.dinomic.blockbet.services;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.enums.Gender;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public interface IAccountService {

    Account getAccountByAccountId(@NotNull Long id);

    Account getAccountByEmail(@NotNull String email);

    Account addNewAccount(@NotNull String email, @NotNull String password);

    /**
     * Updates the given profile fields; null arguments leave the stored value unchanged.
     */
    Account updateAccountInfo(@NotNull Long accountId, String displayName, String avatarUrl, String phone,
                              String address, String nationality, LocalDate dateOfBirth, Gender gender);
}
