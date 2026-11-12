package com.dinomic.blockbet.repositories;

import com.dinomic.blockbet.daos.RefreshToken;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;

public interface IRefreshTokenRepo extends JpaRepository<RefreshToken, Long> {

    /** Row-locked so two concurrent refreshes with the same token cannot both succeed. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<RefreshToken> findByTokenHash(String tokenHash);

    /** Revokes every still-active token of a rotation chain. */
    @Modifying
    @Query("update RefreshToken t set t.revokedAt = :now where t.familyId = :familyId and t.revokedAt is null")
    int revokeFamily(@Param("familyId") String familyId, @Param("now") Instant now);

    /** Revokes every still-active token of an account (logout on all devices). */
    @Modifying
    @Query("update RefreshToken t set t.revokedAt = :now where t.accountId = :accountId and t.revokedAt is null")
    int revokeAllByAccount(@Param("accountId") Long accountId, @Param("now") Instant now);
}
