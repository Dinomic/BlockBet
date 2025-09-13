package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.entities.Account;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface IAccountRepo extends JpaRepository<Account, Long> {
    Optional<Account> findByEmail(String email);
}
