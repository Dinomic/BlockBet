package com.dinomic.BlockBet.services;

import blockbet.openapi.model.*;
import com.dinomic.BlockBet.entities.Account;

import javax.validation.constraints.NotNull;
import java.math.BigInteger;

public interface IBlockBetService {

    WalletPostResponse handleWalletPostRequest(@NotNull Account account, @NotNull WalletPostRequest request);

    WalletsGetResponse handleWalletsGetRequest(@NotNull Account account);

    TransferTokensPutResponse handleTransferTokensPutRequest(@NotNull Account account, @NotNull TransferTokensPutRequest request);

    ReceiptsGetResponse handleReceiptsGetRequest(@NotNull BigInteger offset, @NotNull BigInteger limit);
}
