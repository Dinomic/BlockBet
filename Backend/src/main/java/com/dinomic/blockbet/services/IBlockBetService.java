package com.dinomic.blockbet.services;

import blockbet.openapi.model.WalletPostRequest;
import blockbet.openapi.model.WalletPostResponse;
import com.dinomic.blockbet.daos.Account;
import jakarta.validation.constraints.NotNull;

public interface IBlockBetService {
    WalletPostResponse handleWalletPostRequest(@NotNull Account account, @NotNull WalletPostRequest request);

}
