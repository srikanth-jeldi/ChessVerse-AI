package com.epitomehub.chessverse.auth;

import jakarta.mail.internet.MimeMessage;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
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

/** Registration/login reporting without passwords, tokens, raw IPs or precise location. */
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
            @Value("${chessverse.auth.activity-report.recipient:chessverseai@gmail.com}") String recipient,
            @Value("${chessverse.auth.activity-report.enabled:true}") boolean enabled) {
        this.jdbc = jdbc;
        this.events = events;
        this.mailSender = mailSender;
        this.from = from == null ? "" : from.trim();
        this.recipient = recipient == null ? "" : recipient.trim();
        this.enabled = enabled;
    }

    void record(PlayerAccount player, String eventType, String authMethod,
            String deviceName, String clientPlatform, String countryCode,
            String appVersion, String installationFingerprint, boolean newDevice) {
        try {
            events.save(new AuthActivityEvent(player, eventType, authMethod,
                    deviceName, clientPlatform, countryCode, appVersion,
                    installationFingerprint, newDevice));
        } catch (RuntimeException exception) {
            // Reporting must never prevent a player from registering or signing in.
            log.warn("Could not record privacy-safe auth activity: {}", exception.getClass().getSimpleName());
        }
    }

    @Scheduled(
            cron = "${chessverse.auth.activity-report.cron:0 59 23 * * *}",
            zone = "${chessverse.auth.activity-report.zone:Asia/Kolkata}")
    @Transactional
    public void sendPendingReport() {
        if (!enabled || !StringUtils.hasText(from) || !StringUtils.hasText(recipient)) return;
        List<AuthActivityRow> rows = jdbc.query("""
                select e.id,e.created_at,e.event_type,e.auth_method,
                       coalesce(p.email,'') email,
                       coalesce(p.username,'Deleted account') username,
                       coalesce(p.display_name,'Deleted account') display_name,
                       coalesce(p.verified,false) verified,
                       coalesce(e.device_name,'Unknown device') device_name,
                       coalesce(e.client_platform,'Unknown') client_platform,
                       coalesce(e.country_code,'Unknown') country_code,
                       coalesce(e.app_version,'Unknown') app_version,
                       coalesce(e.installation_fingerprint,'Unknown') installation_fingerprint,
                       e.new_device
                  from auth_activity_event e
                  left join player_account p on p.id=e.player_id
                 where e.excel_reported_at is null
                 order by e.created_at
                 limit 1000
                 for update of e skip locked
                """, (result, index) -> new AuthActivityRow(
                result.getObject("id", UUID.class), result.getTimestamp("created_at"),
                result.getString("event_type"), result.getString("auth_method"), result.getString("email"),
                result.getString("username"), result.getString("display_name"),
                result.getBoolean("verified"), result.getString("device_name"),
                result.getString("client_platform"), result.getString("country_code"),
                result.getString("app_version"), result.getString("installation_fingerprint"),
                result.getBoolean("new_device")));
        byte[] attachment;
        try {
            attachment = workbook(rows);
        } catch (Exception exception) {
            log.warn("Could not create auth activity workbook: {}", exception.getClass().getSimpleName());
            return;
        }
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());
            helper.setFrom(from);
            helper.setTo(recipient);
            helper.setSubject("ChessVerseAI daily login report • "
                    + LocalDate.now(REPORT_ZONE) + " • " + rows.size() + " events");
            helper.setText("Attached is the daily ChessVerseAI registration and login report. "
                    + "New-device logins are marked. Installation IDs are one-way pseudonymous fingerprints. "
                    + "Passwords, OTPs, tokens, raw IP addresses and precise locations are never included.");
            helper.addAttachment("chessverse-auth-activity.xlsx", new ByteArrayResource(attachment),
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
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
                "update auth_activity_event set reported_at=coalesce(reported_at,current_timestamp), "
                        + "excel_reported_at=current_timestamp where id=? and excel_reported_at is null",
                arguments);
    }

    byte[] workbook(List<AuthActivityRow> rows) throws Exception {
        try (XSSFWorkbook workbook = new XSSFWorkbook();
                ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Login activity");
            sheet.createFreezePane(0, 1);
            String[] headers = {"Time (IST)", "Event", "Method", "Email", "Username", "@Handle",
                    "Display name", "Verified", "New device", "Device manufacturer/model",
                    "Platform / OS / browser", "App version", "Approximate country",
                    "Installation fingerprint"};
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            CellStyle headerStyle = workbook.createCellStyle();
            headerStyle.setFont(headerFont);
            Row header = sheet.createRow(0);
            for (int column = 0; column < headers.length; column++) {
                header.createCell(column).setCellValue(headers[column]);
                header.getCell(column).setCellStyle(headerStyle);
            }
            int index = 1;
            for (AuthActivityRow value : rows) {
                Row row = sheet.createRow(index++);
                String[] cells = {REPORT_TIME.format(value.createdAt().toInstant()), value.eventType(),
                        value.authMethod(), value.email(), value.username(), "@" + value.username(),
                        value.displayName(), value.verified() ? "Yes" : "No",
                        value.newDevice() ? "Yes" : "No", value.deviceName(), value.clientPlatform(),
                        value.appVersion(), value.countryCode(), value.installationFingerprint()};
                for (int column = 0; column < cells.length; column++) {
                    row.createCell(column).setCellValue(cells[column] == null ? "" : cells[column]);
                }
            }
            for (int column = 0; column < headers.length; column++) {
                sheet.autoSizeColumn(column);
                sheet.setColumnWidth(column, Math.min(sheet.getColumnWidth(column) + 512, 12_000));
            }
            workbook.write(output);
            return output.toByteArray();
        }
    }

    String csvCell(String value) {
        String safe = value == null ? "" : value.replace("\"", "\"\"")
                .replace("\r", " ").replace("\n", " ");
        if (!safe.isEmpty() && "=+-@".indexOf(safe.charAt(0)) >= 0) safe = "'" + safe;
        return '"' + safe + '"';
    }

    private record AuthActivityRow(
            UUID id, Timestamp createdAt, String eventType, String authMethod,
            String email, String username, String displayName, boolean verified,
            String deviceName, String clientPlatform, String countryCode,
            String appVersion, String installationFingerprint, boolean newDevice) {}
}
