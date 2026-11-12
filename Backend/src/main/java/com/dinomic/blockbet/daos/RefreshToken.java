package com.dinomic.blockbet.daos;

import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "REFRESH_TOKENS")
public class RefreshToken {

    @SequenceGenerator(name = "SEQ_REFRESH_TOKENS", sequenceName = "SEQ_REFRESH_TOKENS", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "SEQ_REFRESH_TOKENS")
    @Column(name = "REFRESH_TOKEN_ID", nullable = false)
    @Id
    private Long id;

    @Column(name = "ACCOUNT_ID", nullable = false)
    private Long accountId;

    @Column(name = "TOKEN_HASH", nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(name = "FAMILY_ID", nullable = false, length = 36)
    private String familyId;

    @Column(name = "CREATED_AT", nullable = false)
    private Instant createdAt;

    @Column(name = "EXPIRES_AT", nullable = false)
    private Instant expiresAt;

    @Column(name = "REVOKED_AT")
    private Instant revokedAt;

    public RefreshToken() {
    }

    public RefreshToken(Long accountId, String tokenHash, String familyId, Instant createdAt, Instant expiresAt) {
        this.accountId = accountId;
        this.tokenHash = tokenHash;
        this.familyId = familyId;
        this.createdAt = createdAt;
        this.expiresAt = expiresAt;
    }

    public Long getId() {
        return id;
    }

    public Long getAccountId() {
        return accountId;
    }

    public String getTokenHash() {
        return tokenHash;
    }

    public String getFamilyId() {
        return familyId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public Instant getRevokedAt() {
        return revokedAt;
    }

    public void setRevokedAt(Instant revokedAt) {
        this.revokedAt = revokedAt;
    }

    public boolean isRevoked() {
        return revokedAt != null;
    }

    public boolean isExpired(Instant now) {
        return !expiresAt.isAfter(now);
    }
}
