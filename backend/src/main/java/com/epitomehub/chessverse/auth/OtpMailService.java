package com.epitomehub.chessverse.auth;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
@ConditionalOnProperty(
        name = "chessverse.auth.delivery",
        havingValue = "mail",
        matchIfMissing = true)
class OtpMailService implements OtpDelivery {
    private final JavaMailSender mailSender;
    private final String from;

    OtpMailService(JavaMailSender mailSender, @Value("${chessverse.auth.mail-from:}") String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    @Override
    public void sendVerificationCode(String email, String displayName, String code) {
        sendCode(
                email,
                "Your ChessVerse verification code",
                """
                Hello %s,

                Your ChessVerse verification code is: %s

                It expires in 10 minutes. If you did not request this code, ignore this email.

                ChessVerse AI
                """.formatted(displayName, code));
    }

    @Override
    public void sendPasswordResetCode(String email, String displayName, String code) {
        sendCode(
                email,
                "Reset your ChessVerse password",
                """
                Hello %s,

                Your ChessVerse password reset code is: %s

                It expires in 10 minutes. If you did not request a reset, ignore this email.

                ChessVerse AI
                """.formatted(displayName, code));
    }

    private void sendCode(String email, String subject, String body) {
        if (!StringUtils.hasText(from)) {
            throw new AuthException(
                    org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE,
                    "Email delivery is not configured. Set MAIL_USERNAME, MAIL_PASSWORD and MAIL_FROM.");
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email);
        message.setSubject(subject);
        message.setText(body);
        mailSender.send(message);
    }
}
