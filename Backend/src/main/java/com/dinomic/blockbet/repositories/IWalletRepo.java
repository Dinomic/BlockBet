package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface IWalletRepo extends JpaRepository<Wallet, Long> {
    List<Wallet> findAllByAccount(Account account);

    Optional<Wallet> findByAccountAndAddress(Account account, String address);
}