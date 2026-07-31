package com.epitomehub.chessverse.online;

import org.springframework.http.HttpStatus;

public class OnlineMatchException extends RuntimeException {
    private final HttpStatus status;

    OnlineMatchException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus status() {
        return status;
    }
}
