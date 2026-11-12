package com.dinomic.blockbet.services;

public interface IRefreshTokenService {

    /** Result of a successful rotation: the owner of the old token and the freshly issued raw token. */
    record Rotation(Long accountId, String newRefreshToken) {}

    /** Starts a new token family (a new login) and returns the raw refresh token to hand to the client. */
    String issue(Long accountId);

    /**
     * Exchanges a refresh token for a new one (rotation). The presented token is revoked.
     * Presenting a token that was already used or revokes the whole family.
     *
     * @throws com.dinomic.blockbet.exceptions.BlockBetException INVALID_REFRESH_TOKEN if unknown, expired, or reused
     */
    Rotation rotate(String rawRefreshToken);

    /** Revokes the family of the given refresh token (logout). Idempotent: unknown tokens are ignored. */
    void revoke(String rawRefreshToken);
}
