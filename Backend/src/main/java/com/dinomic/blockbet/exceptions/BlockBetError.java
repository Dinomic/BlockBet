package com.dinomic.blockbet.exceptions;

public enum BlockBetError {
    UNAUTHORIZED(401),
    INVALID_REFRESH_TOKEN(401),
    BLOCKCHAIN_ERROR(500),
    INVALID_REQUEST(400),
    INSUFFICIENT_BALANCE(400),
    WALLET_NOT_FOUND(404),
    WALLET_LIMIT_REACHED(409),
    BB_RECEIPT_NOT_FOUND(404);

    final int code;

    BlockBetError(int code) {
        this.code = code;
    }

    public int getCode() {
        return code;
    }
}
