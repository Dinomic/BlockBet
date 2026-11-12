package com.dinomic.blockbet.services;

import blockbet.openapi.model.*;
import com.dinomic.blockbet.daos.Account;
import jakarta.validation.constraints.NotNull;

import java.math.BigInteger;

public interface IBlockBetService {
    InfosGetResponse handleInfosGetRequest(@NotNull Account account);

    InfosGetResponse handleInfosPutRequest(@NotNull Account account, @NotNull InfosPutRequest request);

    WalletPostResponse handleWalletPostRequest(@NotNull Account account, @NotNull WalletPostRequest request);

    WalletsGetResponse handleWalletsGetRequest(@NotNull Account account);

    TransferTokensPutResponse handleTransferTokensPutRequest(@NotNull Account account, @NotNull TransferTokensPutRequest request);

    ReceiptsGetResponse handleReceiptsGetRequest(@NotNull BigInteger offset, @NotNull BigInteger limit);
}
