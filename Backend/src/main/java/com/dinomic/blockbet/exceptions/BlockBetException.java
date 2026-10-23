package com.dinomic.blockbet.exceptions;

public class BlockBetException extends RuntimeException{

    private BlockBetError error;

    private String message;

    public BlockBetException (BlockBetError error, String message) {
        this.error = error;
        this.message = message;
    }

    public BlockBetError getError() {
        return error;
    }

    @Override
    public String getMessage() {
        return message;
    }
}
