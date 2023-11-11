package com.dinomic.BlockBet.exception;

public enum BlockBetError {
    BLOCKCHAIN_ERROR(500),
    TEST_ERROR(400);

    final int code;

    BlockBetError(int code) {
        this.code = code;
    }

    public int getCode() {
        return code;
    }
}
