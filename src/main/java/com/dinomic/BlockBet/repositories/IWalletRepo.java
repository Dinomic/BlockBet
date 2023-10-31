package com.dinomic.BlockBet.repositories;

import com.dinomic.BlockBet.entities.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IWalletRepo extends JpaRepository<Wallet, Long> {

}
