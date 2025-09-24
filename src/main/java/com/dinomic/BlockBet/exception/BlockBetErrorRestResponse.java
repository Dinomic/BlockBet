package com.dinomic.blockbet.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.sql.Timestamp;

@Getter
@Setter
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
        this.sessionId = RequestContextHolder.currentRequestAttributes().getSessionId();
        LOG.error("Session {} Unhandled exception occurred", this.sessionId, exception);

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
        LOG.error("Session {} exception occurred - error {} message: {}", this.sessionId, error, message);

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
        LOG.error("Session {} exception occurred - error {} message: {}", this.sessionId, error, message);

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

}
