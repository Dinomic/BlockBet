package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface IAccountRepo extends JpaRepository<Account, Long> {
    Optional<Account> findByEmail(String email);
}
