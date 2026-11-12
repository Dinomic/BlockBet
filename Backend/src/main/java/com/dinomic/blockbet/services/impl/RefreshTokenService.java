package com.dinomic.blockbet.services.impl;

import com.dinomic.blockbet.daos.RefreshToken;
import com.dinomic.blockbet.exceptions.BlockBetError;
import com.dinomic.blockbet.exceptions.BlockBetException;
import com.dinomic.blockbet.repositories.IRefreshTokenRepo;
import com.dinomic.blockbet.security.jwt.JwtProperties;
import com.dinomic.blockbet.services.IRefreshTokenService;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;

@Service
public class RefreshTokenService implements IRefreshTokenService {

    private static final Logger log = LoggerFactory.getLogger(RefreshTokenService.class);

    private static final int TOKEN_BYTES = 32;

    private final SecureRandom secureRandom = new SecureRandom();

    @Autowired
    private IRefreshTokenRepo refreshTokenRepo;

    @Autowired
    private JwtProperties properties;

    @Override
    @Transactional
    public String issue(Long accountId) {
        return createToken(accountId, UUID.randomUUID().toString());
    }

    /**
     * {@code noRollbackFor}: when a reused token is detected we revoke the family and then throw;
     * the revocation must still be committed.
     */
    @Override
    @Transactional(noRollbackFor = BlockBetException.class)
    public Rotation rotate(String rawRefreshToken) {
        RefreshToken current = find(rawRefreshToken)
                .orElseThrow(() -> invalid("Invalid refresh token"));

        Instant now = Instant.now();

        if (current.isRevoked()) {
            // Someone presents a token that was already rotated or logged out: it may have been
            // stolen, so kill every token that descends from the same login.
            log.warn("Refresh token reuse detected for account {}, revoking family {}",
                    current.getAccountId(), current.getFamilyId());
            refreshTokenRepo.revokeFamily(current.getFamilyId(), now);
            throw invalid("Invalid refresh token");
        }

        if (current.isExpired(now)) {
            throw invalid("Refresh token expired");
        }

        current.setRevokedAt(now);
        String newToken = createToken(current.getAccountId(), current.getFamilyId());
        return new Rotation(current.getAccountId(), newToken);
    }

    @Override
    @Transactional
    public void revoke(String rawRefreshToken) {
        find(rawRefreshToken).ifPresent(token -> refreshTokenRepo.revokeFamily(token.getFamilyId(), Instant.now()));
    }

    private String createToken(Long accountId, String familyId) {
        byte[] bytes = new byte[TOKEN_BYTES];
        secureRandom.nextBytes(bytes);
        String raw = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        Instant now = Instant.now();
        refreshTokenRepo.save(new RefreshToken(accountId, hash(raw), familyId, now,
                now.plus(Duration.ofDays(properties.refreshExpirationDays()))));
        return raw;
    }

    private Optional<RefreshToken> find(String rawRefreshToken) {
        if (StringUtils.isBlank(rawRefreshToken)) {
            return Optional.empty();
        }
        return refreshTokenRepo.findByTokenHash(hash(rawRefreshToken));
    }

    private BlockBetException invalid(String message) {
        return new BlockBetException(BlockBetError.INVALID_REFRESH_TOKEN, message);
    }

    /** SHA-256 is enough here: the token is 256 bits of randomness, so it cannot be brute forced like a password. */
    private static String hash(String rawToken) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
