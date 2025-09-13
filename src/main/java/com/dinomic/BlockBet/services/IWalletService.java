package com.dinomic.blockbet.services;

import com.dinomic.blockbet.entities.Account;
import com.dinomic.blockbet.entities.Wallet;
import javax.validation.constraints.NotNull;

import java.util.List;

public interface IWalletService {
    List<Wallet> getWallets(@NotNull Account account);

    Wallet getWallet(@NotNull Account account, @NotNull String address);
}
