package com.dinomic.blockbet.exceptions;

public enum BlockBetError {
    UNAUTHORIZED(401),
    BLOCKCHAIN_ERROR(500),
    INPUT_PRIVATE_KEY_NOT_MATCH(400),
    WALLET_NOT_FOUND(404),
    BB_RECEIPT_NOT_FOUND(404);

    final int code;

    BlockBetError(int code) {
        this.code = code;
    }

    public int getCode() {
        return code;
    }
}
