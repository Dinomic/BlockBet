package com.dinomic.BlockBet.repositories;

import com.dinomic.BlockBet.entities.Account;
import com.dinomic.BlockBet.entities.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface IWalletRepo extends JpaRepository<Wallet, Long> {
    List<Wallet> findAllByAccount(Account account);
}
