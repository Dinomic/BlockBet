package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.Bet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface IBetRepo extends JpaRepository<Bet, Long> {
    /** Bets whose resolve deadline has passed and that the caution check has not looked at yet. */
    List<Bet> findByCloseTimeBeforeAndCautionCheckedAtIsNull(LocalDateTime deadline, Pageable pageable);

    /** Newest first. */
    @Query(value = "select * from bets order by bet_id desc offset :offset limit :limit", nativeQuery = true)
    List<Bet> findPage(@Param("offset") long offset, @Param("limit") long limit);
}
