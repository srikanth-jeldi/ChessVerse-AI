package com.epitomehub.chessverse.auth;

import jakarta.mail.internet.MimeMessage;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/** Privacy-safe registration/login reporting without email, IP, device or location data. */
@Service
class AuthActivityReportService {
    private static final Logger log = LoggerFactory.getLogger(AuthActivityReportService.class);
    private static final ZoneId REPORT_ZONE = ZoneId.of("Asia/Kolkata");
    private static final DateTimeFormatter REPORT_TIME =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss z", Locale.ENGLISH).withZone(REPORT_ZONE);

    private final JdbcTemplate jdbc;
    private final AuthActivityEventRepository events;
    private final JavaMailSender mailSender;
    private final String from;
    private final String recipient;
    private final boolean enabled;

    AuthActivityReportService(
            JdbcTemplate jdbc,
            AuthActivityEventRepository events,
            JavaMailSender mailSender,
            @Value("${chessverse.auth.mail-from:}") String from,
            @Value("${chessverse.auth.activity-report.recipient:cheseverseai@gmail.com}") String recipient,
            @Value("${chessverse.auth.activity-report.enabled:true}") boolean enabled) {
        this.jdbc = jdbc;
        this.events = events;
        this.mailSender = mailSender;
        this.from = from == null ? "" : from.trim();
        this.recipient = recipient == null ? "" : recipient.trim();
        this.enabled = enabled;
    }

    void record(PlayerAccount player, String eventType, String authMethod) {
        try {
            events.save(new AuthActivityEvent(player, eventType, authMethod));
        } catch (RuntimeException exception) {
            // Reporting must never prevent a player from registering or signing in.
            log.warn("Could not record privacy-safe auth activity: {}", exception.getClass().getSimpleName());
        }
    }

    @Scheduled(
            fixedDelayString = "${chessverse.auth.activity-report.interval-ms:900000}",
            initialDelayString = "${chessverse.auth.activity-report.initial-delay-ms:60000}")
    @Transactional
    public void sendPendingReport() {
        if (!enabled || !StringUtils.hasText(from) || !StringUtils.hasText(recipient)) return;
        List<AuthActivityRow> rows = jdbc.query("""
                select e.id,e.created_at,e.event_type,e.auth_method,
                       coalesce(p.username,'Deleted account') username,
                       coalesce(p.display_name,'Deleted account') display_name,
                       coalesce(p.verified,false) verified
                  from auth_activity_event e
                  left join player_account p on p.id=e.player_id
                 where e.reported_at is null
                 order by e.created_at
                 limit 1000
                 for update of e skip locked
                """, (result, index) -> new AuthActivityRow(
                result.getObject("id", UUID.class), result.getTimestamp("created_at"),
                result.getString("event_type"), result.getString("auth_method"),
                result.getString("username"), result.getString("display_name"),
                result.getBoolean("verified")));
        if (rows.isEmpty()) return;

        byte[] attachment = csv(rows).getBytes(StandardCharsets.UTF_8);
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());
            helper.setFrom(from);
            helper.setTo(recipient);
            helper.setSubject("ChessVerseAI registration and login report • " + rows.size() + " events");
            helper.setText("Attached is the latest privacy-safe ChessVerseAI activity report. "
                    + "It contains no email addresses, IP addresses, device names, locations or tokens.");
            helper.addAttachment("chessverse-auth-activity.csv", new ByteArrayResource(attachment), "text/csv");
            mailSender.send(message);
            markReported(rows);
        } catch (Exception exception) {
            log.warn("Auth activity report email failed; it will retry: {}",
                    exception.getClass().getSimpleName());
        }
    }

    private void markReported(List<AuthActivityRow> rows) {
        List<Object[]> arguments = new ArrayList<>(rows.size());
        for (AuthActivityRow row : rows) arguments.add(new Object[] {row.id()});
        jdbc.batchUpdate(
                "update auth_activity_event set reported_at=current_timestamp where id=? and reported_at is null",
                arguments);
    }

    private String csv(List<AuthActivityRow> rows) {
        StringBuilder output = new StringBuilder("Time (IST),Event,Method,Username,Display name,Verified\r\n");
        for (AuthActivityRow row : rows) {
            output.append(csvCell(REPORT_TIME.format(row.createdAt().toInstant()))).append(',')
                    .append(csvCell(row.eventType())).append(',')
                    .append(csvCell(row.authMethod())).append(',')
                    .append(csvCell(row.username())).append(',')
                    .append(csvCell(row.displayName())).append(',')
                    .append(row.verified() ? "Yes" : "No").append("\r\n");
        }
        return "\uFEFF" + output;
    }

    String csvCell(String value) {
        String safe = value == null ? "" : value.replace("\"", "\"\"")
                .replace("\r", " ").replace("\n", " ");
        if (!safe.isEmpty() && "=+-@".indexOf(safe.charAt(0)) >= 0) safe = "'" + safe;
        return '"' + safe + '"';
    }

    private record AuthActivityRow(
            UUID id, Timestamp createdAt, String eventType, String authMethod,
            String username, String displayName, boolean verified) {}
}
