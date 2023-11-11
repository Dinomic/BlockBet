package com.dinomic.BlockBet.exception;

import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;

import java.util.List;

@AllArgsConstructor
public class BlockBetException extends RuntimeException{

    private BlockBetError error;

    private String message;



    public BlockBetError getError() {
        return error;
    }

    public void setError(BlockBetError error) {
        this.error = error;
    }

    @Override
    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
