package com.dinomic.BlockBet.repositories;

import com.dinomic.BlockBet.entities.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface IAccountRepo extends JpaRepository<Account, Long> {
    Optional<Account> findByEmail(String email);
}
