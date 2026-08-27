package com.epitomehub.chessverse.analysis;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

class AnalysisJobException extends ResponseStatusException {
    AnalysisJobException(HttpStatus status, String reason) {
        super(status, reason);
    }
}
