package com.epitomehub.chessverse.academy;

import jakarta.mail.internet.MimeMessage;
import java.nio.charset.StandardCharsets;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
class AcademyInvitationMailService {
    private static final Logger log = LoggerFactory.getLogger(AcademyInvitationMailService.class);
    private final JavaMailSender sender;
    private final String from;
    private final String academyUrl;

    AcademyInvitationMailService(JavaMailSender sender,
            @Value("${chessverse.auth.mail-from:}") String from,
            @Value("${chessverse.academy.public-url:https://academy.chessverseai.com/academy/}") String academyUrl) {
        this.sender = sender;
        this.from = from == null ? "" : from.trim();
        this.academyUrl = academyUrl.endsWith("/") ? academyUrl : academyUrl + "/";
    }

    boolean sendInvitation(String email, String academy, String role, String token, boolean reminder) {
        if (!StringUtils.hasText(from)) return false;
        String url = academyUrl + "?invite=" + token;
        String subject = reminder ? "Reminder: your ChessVerseAI Academy invitation" : "Join " + academy + " on ChessVerseAI";
        String heading = reminder ? "Your invitation is waiting" : "You’re invited";
        String text = heading + "\n\n" + academy + " invited you as " + role.toLowerCase() + ".\n"
                + "Accept within seven days: " + url + "\n\nIf you were not expecting this, ignore this email.";
        try {
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, StandardCharsets.UTF_8.name());
            helper.setFrom(from); helper.setTo(email); helper.setSubject(subject);
            helper.setText(text, "<!doctype html><html><body style=\"font-family:Arial;background:#eef3f5;padding:24px\"><div style=\"max-width:560px;margin:auto;background:#fff;padding:32px;border-radius:14px\"><h1 style=\"color:#092238\">"+escape(heading)+"</h1><p><strong>"+escape(academy)+"</strong> invited you to join as <strong>"+escape(role.toLowerCase())+"</strong>.</p><p><a href=\""+escape(url)+"\" style=\"display:inline-block;background:#0b8f86;color:#fff;padding:13px 20px;border-radius:8px;text-decoration:none\">Accept invitation</a></p><p style=\"color:#68788a\">This private link expires in seven days. If you were not expecting it, safely ignore this email.</p><hr><small>ChessVerseAI · Powered by EpitomeHub Technologies</small></div></body></html>");
            sender.send(message);
            return true;
        } catch (Exception failure) {
            log.warn("Academy invitation email delivery failed: {}", failure.getClass().getSimpleName());
            return false;
        }
    }

    private static String escape(String value) {
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
}
