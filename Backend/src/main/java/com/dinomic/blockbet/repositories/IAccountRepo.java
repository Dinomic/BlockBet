package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.Account;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface IAccountRepo extends JpaRepository<Account, Long> {
    Optional<Account> findByEmail(String email);

    /**
     * Row-locks the account until the surrounding transaction ends, so concurrent
     * "create wallet" calls for the same account are serialized and cannot both pass the limit check.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Account a where a.accountId = :id")
    Optional<Account> findByIdForUpdate(@Param("id") Long id);
}
