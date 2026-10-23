package com.dinomic.blockbet.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.time.OffsetDateTime;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BlockBetErrorRestResponse {
    private static final Logger logger = LoggerFactory.getLogger(BlockBetErrorRestResponse.class);

    private OffsetDateTime dateTime = OffsetDateTime.now();

    private String path;

    private int errorCode;

    private String error;

    private String message;

    private String sessionId;

    public BlockBetErrorRestResponse(Throwable exception) {
        this.sessionId = RequestContextHolder.currentRequestAttributes().getSessionId();
        logger.error("Session {} Unhandled exception occurred", this.sessionId, exception);

        this.errorCode = HttpStatus.INTERNAL_SERVER_ERROR.value();
        this.error = HttpStatus.INTERNAL_SERVER_ERROR.name();
        this.message = HttpStatus.INTERNAL_SERVER_ERROR.getReasonPhrase();

        ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (requestAttributes != null) {
            this.path  = requestAttributes.getRequest().getRequestURI();
        } else {
            this.path = RequestContextHolder.currentRequestAttributes().getSessionId();
        }

    }

    public BlockBetErrorRestResponse(String message,  BlockBetError error) {
        this.sessionId = RequestContextHolder.currentRequestAttributes().getSessionId();
        logger.error("Session {} exception occurred - error {} message: {}", this.sessionId, error, message);

        this.errorCode = error.getCode();
        this.error = error.name();
        this.message = message;

        ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (requestAttributes != null) {
            this.path  = requestAttributes.getRequest().getRequestURI();
        } else {
            this.path = RequestContextHolder.currentRequestAttributes().getSessionId();
        }
    }

    public BlockBetErrorRestResponse(String message,  HttpStatus httpStatus) {
        this.sessionId = RequestContextHolder.currentRequestAttributes().getSessionId();
        logger.error("Session {} exception occurred - error {} message: {}", this.sessionId, error, message);

        this.errorCode = httpStatus.value();
        this.error = httpStatus.name();
        this.message = message;

        ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (requestAttributes != null) {
            this.path  = requestAttributes.getRequest().getRequestURI();
        } else {
            this.path = RequestContextHolder.currentRequestAttributes().getSessionId();
        }
    }

    public OffsetDateTime getDateTime() {
        return dateTime;
    }

    public String getPath() {
        return path;
    }

    public int getErrorCode() {
        return errorCode;
    }

    public String getError() {
        return error;
    }

    public String getMessage() {
        return message;
    }

    public String getSessionId() {
        return sessionId;
    }
}
