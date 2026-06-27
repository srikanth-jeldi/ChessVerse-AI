package com.epitomehub.chessverse.engine;

import org.springframework.http.HttpStatus;

public class EngineException extends RuntimeException {
    private final HttpStatus status;

    EngineException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus status() {
        return status;
    }
}
