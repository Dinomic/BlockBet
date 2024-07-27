package com.dinomic.BlockBet.services;

import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Wallet;
import javax.validation.constraints.NotNull;

import java.util.List;

public interface IWalletService {
    List<Wallet> getWallets(@NotNull Account account);

    Wallet getWallet(@NotNull Account account, @NotNull String address);
}
