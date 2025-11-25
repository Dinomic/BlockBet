package com.dinomic.blockbet.exception;

import lombok.AllArgsConstructor;
@AllArgsConstructor
public class BlockBetException extends RuntimeException{

    private BlockBetError error;

    private String message;



    public BlockBetError getError() {
        return error;
    }

    @Override
    public String getMessage() {
        return message;
    }
}
