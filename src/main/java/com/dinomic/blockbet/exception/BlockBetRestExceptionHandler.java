package com.dinomic.blockbet.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

@ControllerAdvice
public class BlockBetRestExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler({ Throwable.class })
    public ResponseEntity<Object> handleException(final Throwable exception) {

        final BlockBetErrorRestResponse errorRestResponse;

        if (exception instanceof BlockBetException blockBetException) {
            errorRestResponse = new BlockBetErrorRestResponse(blockBetException.getMessage(), blockBetException.getError());
        }
        else {
            errorRestResponse = new BlockBetErrorRestResponse(exception);
        }
        return new ResponseEntity<>(errorRestResponse, HttpStatus.valueOf(errorRestResponse.getErrorCode()));
    }
}
