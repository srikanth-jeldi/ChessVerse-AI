package com.epitomehub.chessverse.auth;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;

@Service
@ConditionalOnProperty(name = "chessverse.auth.delivery", havingValue = "mail", matchIfMissing = true)
class OtpMailService implements OtpDelivery {
    private final JavaMailSender mailSender;
    private final String from;
    private final String logoUrl;

    OtpMailService(
            JavaMailSender mailSender,
            @Value("${chessverse.auth.mail-from:}") String from,
            @Value("${chessverse.auth.mail-logo-url:https://chessverseai.com/assets/assets/branding/app_icon.png}") String logoUrl) {
        this.mailSender = mailSender;
        this.from = from;
        this.logoUrl = logoUrl;
    }

    @Override
    public void sendVerificationCode(String email, String displayName, String code) {
        sendCode(email, "Your ChessVerseAI verification code", displayName, code,
                "Verify your ChessVerseAI account",
                "Use the one-time code below to complete your verification.",
                "Enter this code in ChessVerseAI to continue. For your security, never share this code with anyone.",
                "Didn’t request this? You can safely ignore this email. Your account remains secure.");
    }

    @Override
    public void sendPasswordResetCode(String email, String displayName, String code) {
        sendCode(email, "Reset your ChessVerseAI password", displayName, code,
                "Reset your ChessVerseAI password",
                "Use the one-time code below to continue your password reset.",
                "Enter this code in ChessVerseAI to continue. For your security, never share this code with anyone.",
                "Didn’t request a password reset? You can safely ignore this email. Your password remains unchanged.");
    }

    private void sendCode(
            String email, String subject, String displayName, String code,
            String heading, String heroCopy, String bodyCopy, String warning) {
        if (!StringUtils.hasText(from)) {
            throw new AuthException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Email delivery is not configured. Set MAIL_USERNAME, MAIL_PASSWORD and MAIL_FROM.");
        }

        String safeName = escapeHtml(StringUtils.hasText(displayName) ? displayName.trim() : "Player");
        String safeCode = escapeHtml(code);
        String plainText = """
                Hello %s,

                %s: %s

                This code expires in 10 minutes. Never share this code with anyone.
                If you did not request this, you can safely ignore this email.

                ChessVerseAI • Powered by EpitomeHub Technologies
                """.formatted(displayName, heading, code);

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message, MimeMessageHelper.MULTIPART_MODE_MIXED_RELATED, StandardCharsets.UTF_8.name());
            helper.setFrom(from);
            helper.setTo(email);
            helper.setSubject(subject);
            helper.setText(plainText, buildHtml(safeName, safeCode, heading, heroCopy, bodyCopy, warning));
            mailSender.send(message);
        } catch (MessagingException exception) {
            throw new AuthException(HttpStatus.SERVICE_UNAVAILABLE, "Verification email could not be prepared.");
        }
    }

    private String buildHtml(
            String safeName, String safeCode, String heading,
            String heroCopy, String bodyCopy, String warning) {
        StringBuilder digitBoxes = new StringBuilder();
        for (int index = 0; index < safeCode.length(); index++) {
            digitBoxes.append("<td style=\"padding:0 3px\"><div style=\"width:42px;height:52px;line-height:52px;text-align:center;border:2px solid #f0b84b;border-radius:7px;background:#ffffff!important;color:#071725!important;font-family:Georgia,serif;font-size:27px;font-weight:700\">")
                    .append(safeCode.charAt(index)).append("</div></td>");
        }

        return """
                <!doctype html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light"><meta name="supported-color-schemes" content="light"></head>
                <body style="margin:0;padding:0;background:#eef3f5;font-family:Arial,Helvetica,sans-serif;color:#152333">
                <div style="display:none;max-height:0;overflow:hidden">Your ChessVerseAI one-time verification code is %s.</div>
                <table role="presentation" width="100%%" cellspacing="0" cellpadding="0" border="0" style="background:#eef3f5"><tr><td align="center" style="padding:20px 10px">
                <table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="width:100%%;max-width:600px;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 8px 28px rgba(4,25,39,.12)">
                <tr><td bgcolor="#ffffff" style="padding:24px 30px 20px;background:#ffffff!important;color:#132233!important;font-size:20px;font-weight:700">Hello %s,</td></tr>
                <tr><td align="center" bgcolor="#087eae" style="padding:28px 24px 32px;background-color:#087eae!important;background-image:linear-gradient(135deg,#075b91,#079ac4 55%%,#056a9c)">
                <img src="%s" width="64" height="64" alt="ChessVerseAI" style="display:block;width:64px;height:64px;border-radius:14px;border:1px solid #e7b64f;object-fit:cover">
                <div style="margin-top:15px;color:#ffffff!important;font-family:Georgia,serif;font-size:27px;font-weight:700;line-height:1.25;text-shadow:0 1px 2px #03496f">%s</div>
                <div style="margin-top:8px;color:#e8f9ff!important;font-size:14px;font-weight:600;line-height:1.5">%s</div>
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" bgcolor="#ffffff" style="width:100%%;max-width:480px;margin-top:22px;background:#ffffff!important;border-radius:10px">
                <tr><td align="center" style="padding:22px 12px 10px;color:#25465d!important;font-size:11px;font-weight:800;letter-spacing:1px">YOUR VERIFICATION CODE</td></tr>
                <tr><td align="center" style="padding:0 8px"><table role="presentation" cellspacing="0" cellpadding="0" border="0"><tr>%s</tr></table></td></tr>
                <tr><td align="center" style="padding:14px 12px 20px;color:#334f62!important;font-size:12px;font-weight:600"><span style="color:#00a7bf;font-size:17px">◷</span>&nbsp; Expires in 10 minutes</td></tr></table>
                </td></tr>
                <tr><td bgcolor="#ffffff" style="padding:26px 30px 10px;background:#ffffff!important;color:#314b5d!important;font-size:15px;line-height:1.65">%s</td></tr>
                <tr><td style="padding:12px 30px 24px"><table role="presentation" width="100%%" cellspacing="0" cellpadding="0" border="0" style="background:#f2fbfc;border:1px solid #57cbd4;border-radius:8px"><tr><td width="52" align="center" style="padding:16px 0 16px 14px;color:#16a9bb;font-size:26px">🔒</td><td style="padding:16px;color:#294454;font-size:12px;line-height:1.55">%s</td></tr></table></td></tr>
                <tr><td align="center" style="padding:4px 24px 24px;border-top:1px solid #e4eaee;color:#70808d;font-size:11px;line-height:1.7">
                <div style="margin-top:18px;color:#243c4d;font-size:13px">Play smarter. Rise higher.</div><div>ChessVerseAI&nbsp; • &nbsp;Powered by EpitomeHub Technologies</div>
                <div><a href="https://chessverseai.com" style="color:#1598aa;text-decoration:none">Help Center</a>&nbsp; • &nbsp;<a href="https://chessverseai.com/privacy" style="color:#1598aa;text-decoration:none">Privacy</a>&nbsp; • &nbsp;<a href="https://chessverseai.com/terms" style="color:#1598aa;text-decoration:none">Terms</a></div>
                <div style="margin-top:4px;color:#9aa6af;font-style:italic">This is an automated message. Please do not reply.</div></td></tr>
                </table></td></tr></table></body></html>
                """.formatted(safeCode, safeName, escapeHtml(logoUrl), escapeHtml(heading),
                escapeHtml(heroCopy), digitBoxes, escapeHtml(bodyCopy), escapeHtml(warning));
    }

    private static String escapeHtml(String value) {
        return value == null ? "" : value.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
}
