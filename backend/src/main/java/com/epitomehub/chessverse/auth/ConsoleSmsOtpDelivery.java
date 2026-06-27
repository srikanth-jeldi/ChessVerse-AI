package com.epitomehub.chessverse.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(
        prefix = "chessverse.auth.sms",
        name = "mode",
        havingValue = "console")
class ConsoleSmsOtpDelivery implements SmsOtpDelivery {
    private static final Logger log = LoggerFactory.getLogger(ConsoleSmsOtpDelivery.class);

    @Override
    public void sendVerificationCode(String phone, String displayName, String code) {
        String lastFour = phone.substring(Math.max(0, phone.length() - 4));
        log.info("Local SMS verification code for phone ending {}: {}", lastFour, code);
    }
}
