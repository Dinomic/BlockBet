package com.dinomic.BlockBet.exception;

import lombok.AllArgsConstructor;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.sql.Timestamp;

@AllArgsConstructor
public class BlockBetErrorRestResponse {

    private static Logger LOG = LogManager.getLogger(BlockBetErrorRestResponse.class);

    private Timestamp timestamp = new Timestamp(System.currentTimeMillis());

    private String path;

    private int errorCode;

    private String error;

    private String message;

    private String sessionId;

    public BlockBetErrorRestResponse(Throwable exception) {
        LOG.warn("Unhandled exception occurred", exception);

        this.errorCode = HttpStatus.INTERNAL_SERVER_ERROR.value();
        this.error = HttpStatus.INTERNAL_SERVER_ERROR.name();
        this.message = HttpStatus.INTERNAL_SERVER_ERROR.getReasonPhrase();

        ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (requestAttributes != null) {
            this.path  = requestAttributes.getRequest().getRequestURI();
        } else {
            this.path = RequestContextHolder.currentRequestAttributes().getSessionId();
        }

        this.sessionId = RequestContextHolder.currentRequestAttributes().getSessionId();
    }

    public BlockBetErrorRestResponse(String message,  BlockBetError error) {

        this.errorCode = error.getCode();
        this.error = error.name();
        this.message = message;

        ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (requestAttributes != null) {
            this.path  = requestAttributes.getRequest().getRequestURI();
        } else {
            this.path = RequestContextHolder.currentRequestAttributes().getSessionId();
        }

        this.sessionId = RequestContextHolder.currentRequestAttributes().getSessionId();
    }

    public BlockBetErrorRestResponse(String message,  HttpStatus httpStatus) {

        this.errorCode = httpStatus.value();
        this.error = httpStatus.name();
        this.message = message;

        ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (requestAttributes != null) {
            this.path  = requestAttributes.getRequest().getRequestURI();
        } else {
            this.path = RequestContextHolder.currentRequestAttributes().getSessionId();
        }

        this.sessionId = RequestContextHolder.currentRequestAttributes().getSessionId();
    }

    public Timestamp getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Timestamp timestamp) {
        this.timestamp = timestamp;
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public int getErrorCode() {
        return errorCode;
    }

    public void setErrorCode(int errorCode) {
        this.errorCode = errorCode;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }
}
