package com.dinomic.BlockBet.services;

import blockbet.openapi.model.WalletPostRequest;
import blockbet.openapi.model.WalletPostResponse;
import blockbet.openapi.model.WalletsGetResponse;
import com.dinomic.BlockBet.entities.Account;

import javax.validation.constraints.NotNull;

public interface IBlockBetService {

    WalletPostResponse handleWalletPostRequest(@NotNull Account account, @NotNull WalletPostRequest request);

    WalletsGetResponse handleWalletsGetRequest(@NotNull Account account);
}
