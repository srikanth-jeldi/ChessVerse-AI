package com.epitomehub.chessverse.online;

import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
class ClubInvitationMailService {
    private final JavaMailSender mail;
    private final String from;
    private final String appUrl;

    ClubInvitationMailService(JavaMailSender mail,
            @Value("${chessverse.auth.mail-from:}") String from,
            @Value("${chessverse.clubs.public-url:https://chessverseai.com/play/}") String appUrl) {
        this.mail = mail;
        this.from = from;
        this.appUrl = appUrl;
    }

    void send(String email, String club, String inviter, UUID invitation) throws Exception {
        if (from == null || from.isBlank()) throw new IllegalStateException("Club invitation mail is not configured");
        String url = appUrl + (appUrl.contains("?") ? "&" : "?") + "clubInvite=" + invitation;
        String instructions = "Sign in or create your free account using the email that received this invitation. "
                + "Then open Community > Clubs and choose Accept invitation. You will only join after accepting. "
                + "This invitation expires in 7 days.";
        String text = inviter + " invited you to join " + club + " on ChessVerseAI.\n\n"
                + url + "\n\n" + instructions + "\n\nAndroid: https://play.google.com/store/apps/details?id=com.epitomehub.chessverse"
                + "\n\nIf you were not expecting this invitation, you can ignore it.";
        var message = mail.createMimeMessage();
        var helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());
        helper.setFrom(from);
        helper.setTo(email);
        helper.setSubject("You're invited to a ChessVerseAI club");
        helper.setText(text, "<!doctype html><html><body style='font-family:Arial;background:#071827;color:#fff;padding:24px'>"
                + "<div style='max-width:540px;margin:auto'><h1>You're invited</h1><p>" + escape(inviter)
                + " invited you to <strong>" + escape(club) + "</strong>.</p><p><a style='display:inline-block;padding:14px 22px;background:#f5cc67;color:#10202a;border-radius:10px' href='"
                + escape(url) + "'>Join club</a></p><p style='line-height:1.6'>" + instructions
                + "</p><p><a style='color:#7be8d4' href='https://play.google.com/store/apps/details?id=com.epitomehub.chessverse'>Get ChessVerseAI for Android</a></p>"
                + "<p>If you were not expecting this invitation, you can ignore it.</p></div></body></html>");
        mail.send(message);
    }

    static String escape(String text) {
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
}
