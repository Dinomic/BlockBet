package com.dinomic.blockbet.exceptions;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/**
 * Translates exceptions thrown from controllers into {@link BlockBetErrorRestResponse}.
 * Spring MVC's own exceptions (bad request body, wrong method, ...) are still handled by
 * {@link ResponseEntityExceptionHandler}, which is more specific than the handlers below.
 */
@ControllerAdvice
public class BlockBetRestExceptionHandler extends ResponseEntityExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(BlockBetRestExceptionHandler.class);

    @ExceptionHandler(BlockBetException.class)
    public ResponseEntity<BlockBetErrorRestResponse> handleBlockBetException(BlockBetException exception, HttpServletRequest request) {
        BlockBetErrorRestResponse body = BlockBetErrorRestResponse.of(
            request, exception.getError(), exception.getMessage());

        logByStatus(body.getErrorCode(), request, exception);
        return build(body);
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<BlockBetErrorRestResponse> handleAuthenticationException(AuthenticationException exception, HttpServletRequest request) {
        log.warn("Authentication failed on {}: {}", request.getRequestURI(), exception.getMessage());
        return build(BlockBetErrorRestResponse.of(request, HttpStatus.UNAUTHORIZED, "Authentication failed"));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<BlockBetErrorRestResponse> handleAccessDeniedException(AccessDeniedException exception, HttpServletRequest request) {
        log.warn("Access denied on {}: {}", request.getRequestURI(), exception.getMessage());
        return build(BlockBetErrorRestResponse.of(request, HttpStatus.FORBIDDEN, "Access denied"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<BlockBetErrorRestResponse> handleUnexpectedException(Exception exception, HttpServletRequest request) {
        log.error("Unhandled exception on {} {}", request.getMethod(), request.getRequestURI(), exception);
        return build(BlockBetErrorRestResponse.of(
            request, HttpStatus.INTERNAL_SERVER_ERROR, HttpStatus.INTERNAL_SERVER_ERROR.getReasonPhrase()));
    }

    private void logByStatus(int status, HttpServletRequest request, BlockBetException exception) {
        if (status >= 500) {
            log.error("Error {} on {} {}: {}", exception.getError(), request.getMethod(), request.getRequestURI(),
                exception.getMessage(), exception);
        } else {
            log.warn("Error {} on {} {}: {}", exception.getError(), request.getMethod(), request.getRequestURI(),
                exception.getMessage());
        }
    }

    private ResponseEntity<BlockBetErrorRestResponse> build(BlockBetErrorRestResponse body) {
        return ResponseEntity.status(body.getErrorCode()).body(body);
    }
}
