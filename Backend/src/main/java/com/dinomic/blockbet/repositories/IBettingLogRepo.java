package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.BettingLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IBettingLogRepo extends JpaRepository<BettingLog, Long> {
    /** The account's rows, newest first; betId null means every bet. */
    @Query(value = "select * from betting_log where account_id = :accountId "
        + "and (cast(:betId as integer) is null or bet_id = cast(:betId as integer)) "
        + "order by betting_log_id desc offset :offset limit :limit", nativeQuery = true)
    List<BettingLog> findPage(@Param("accountId") long accountId, @Param("betId") Long betId,
                              @Param("offset") long offset, @Param("limit") long limit);

    @Query(value = "select count(*) from betting_log where account_id = :accountId "
        + "and (cast(:betId as integer) is null or bet_id = cast(:betId as integer))", nativeQuery = true)
    long countFor(@Param("accountId") long accountId, @Param("betId") Long betId);
}