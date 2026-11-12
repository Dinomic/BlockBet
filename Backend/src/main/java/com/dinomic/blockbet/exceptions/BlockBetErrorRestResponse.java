package com.dinomic.blockbet.exceptions;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;

import java.time.OffsetDateTime;

/**
 * JSON body returned for every error. It is built from the {@link HttpServletRequest} passed in
 * explicitly (never from thread-local request state), so it is safe to use from filters,
 * entry points and advices alike.
 */
public class BlockBetErrorRestResponse {

    private final OffsetDateTime dateTime = OffsetDateTime.now();

    private final String path;

    private final int errorCode;

    private final String error;

    private final String message;

    private final String sessionId;

    public BlockBetErrorRestResponse(String path, String sessionId, int errorCode, String error, String message) {
        this.path = path;
        this.sessionId = sessionId;
        this.errorCode = errorCode;
        this.error = error;
        this.message = message;
    }

    public static BlockBetErrorRestResponse of(HttpServletRequest request, HttpStatus status, String message) {
        return new BlockBetErrorRestResponse(
            request.getRequestURI(), sessionIdOf(request), status.value(), status.name(), message);
    }

    public static BlockBetErrorRestResponse of(HttpServletRequest request, BlockBetError error, String message) {
        return new BlockBetErrorRestResponse(
            request.getRequestURI(), sessionIdOf(request), error.getCode(), error.name(), message);
    }

    private static String sessionIdOf(HttpServletRequest request) {
        return request.getSession().getId();
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
