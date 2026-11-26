package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.Account;
import com.dinomic.blockbet.daos.Bet;
import com.dinomic.blockbet.daos.BetParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface IBetParticipantRepo extends JpaRepository<BetParticipant, Long> {
    Optional<BetParticipant> findByBetAndAccount(Bet bet, Account account);
}
