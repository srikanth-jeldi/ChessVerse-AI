package com.epitomehub.chessverse.speech;

import org.springframework.http.HttpStatus;

public class SpeechException extends RuntimeException {
    private final HttpStatus status;

    SpeechException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus status() {
        return status;
    }
}
