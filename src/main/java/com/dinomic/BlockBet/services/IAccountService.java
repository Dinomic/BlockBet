package com.dinomic.BlockBet.services;

import com.dinomic.BlockBet.entities.Account;

public interface IAccountService {

    Account getAccountByEmail(String email);

    Account addNewAccount(String email, String password);
}
