package com.epitomehub.chessverse.auth;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
class OtpMailService implements OtpDelivery {
    private final JavaMailSender mailSender;
    private final String from;

    OtpMailService(JavaMailSender mailSender, @Value("${chessverse.auth.mail-from:}") String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    @Override
    public void sendVerificationCode(String email, String displayName, String code) {
        if (!StringUtils.hasText(from)) {
            throw new AuthException(
                    org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE,
                    "Email delivery is not configured. Set MAIL_USERNAME, MAIL_PASSWORD and MAIL_FROM.");
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email);
        message.setSubject("Your ChessVerse verification code");
        message.setText("""
                Hello %s,

                Your ChessVerse verification code is: %s

                It expires in 10 minutes. If you did not request this code, ignore this email.

                ChessVerse AI
                """.formatted(displayName, code));
        mailSender.send(message);
    }
}
