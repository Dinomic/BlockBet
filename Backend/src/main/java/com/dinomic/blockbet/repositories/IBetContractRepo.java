package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.BetContract;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface IBetContractRepo extends JpaRepository<BetContract, Long> {
    Optional<BetContract> findByCodeHash(String codeHash);
}
