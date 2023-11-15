package com.dinomic.BlockBet.repositories;

import com.dinomic.BlockBet.entities.Account;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface IAccountRepo extends JpaRepository<Account, Long> {
    Optional<Account> findByEmail(String email);
}
