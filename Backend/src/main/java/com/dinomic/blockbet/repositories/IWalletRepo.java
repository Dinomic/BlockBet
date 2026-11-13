package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.Wallet;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface IWalletRepo extends JpaRepository<Wallet, Long> {
    List<Wallet> findAllByAccount(Account account);

    long countByAccount(Account account);

    Optional<Wallet> findByAccountAndAddress(Account account, String address);

    /**
     * Same lookup, but row-locks the wallet until the transaction ends. Transfers from one wallet
     * are therefore serialized, so two of them can never read the same nonce.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select w from Wallet w where w.account = :account and lower(w.address) = lower(:address)")
    Optional<Wallet> findByAccountAndAddressForUpdate(@Param("account") Account account, @Param("address") String address);
}