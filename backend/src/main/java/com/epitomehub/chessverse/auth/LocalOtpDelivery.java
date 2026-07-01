package com.epitomehub.chessverse.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(
        name = "chessverse.auth.delivery",
        havingValue = "local")
class LocalOtpDelivery implements OtpDelivery {
    private static final Logger log = LoggerFactory.getLogger(LocalOtpDelivery.class);

    @Override
    public void sendVerificationCode(String email, String displayName, String code) {
        log.info("Local ChessVerse verification requested for {}", email);
    }

    @Override
    public void sendPasswordResetCode(String email, String displayName, String code) {
        log.info("Local ChessVerse password reset requested for {}", email);
    }
}
