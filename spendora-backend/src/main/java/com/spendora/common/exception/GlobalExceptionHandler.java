package com.spendora.common.exception;

import com.spendora.common.api.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusinessException(
            BusinessException ex,
            HttpServletRequest request) {
        return build(
                ex.getStatus(),
                ex.getErrorCode().name(),
                ex.getMessage(),
                List.of(),
                request.getRequestURI());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        List<String> details = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(this::fieldErrorMessage)
                .collect(Collectors.toList());

        return build(
                HttpStatus.BAD_REQUEST,
                ErrorCode.VALIDATION_ERROR.name(),
                "Validation failed",
                details,
                request.getRequestURI());
    }

    @ExceptionHandler({
            HttpMessageNotReadableException.class,
            MethodArgumentTypeMismatchException.class,
            MissingServletRequestParameterException.class
    })
    public ResponseEntity<ErrorResponse> handleRequestShapeExceptions(
            Exception ex,
            HttpServletRequest request) {
        return build(
                HttpStatus.BAD_REQUEST,
                ErrorCode.BAD_REQUEST.name(),
                "Request is invalid or malformed",
                List.of(ex.getMessage()),
                request.getRequestURI());
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied(
            AccessDeniedException ex,
            HttpServletRequest request) {
        return build(
                HttpStatus.FORBIDDEN,
                ErrorCode.FORBIDDEN.name(),
                "Access denied",
                List.of(),
                request.getRequestURI());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(
            Exception ex,
            HttpServletRequest request) {
        return build(
                HttpStatus.INTERNAL_SERVER_ERROR,
                ErrorCode.INTERNAL_ERROR.name(),
                "Unexpected server error",
                List.of(ex.getClass().getSimpleName()),
                request.getRequestURI());
    }

    private String fieldErrorMessage(FieldError error) {
        return error.getField() + ": " + (error.getDefaultMessage() == null
                ? "invalid value"
                : error.getDefaultMessage());
    }

    private ResponseEntity<ErrorResponse> build(
            HttpStatus status,
            String code,
            String message,
            List<String> details,
            String path) {
        return ResponseEntity.status(status)
                .body(new ErrorResponse(code, message, details, path, Instant.now()));
    }
}
