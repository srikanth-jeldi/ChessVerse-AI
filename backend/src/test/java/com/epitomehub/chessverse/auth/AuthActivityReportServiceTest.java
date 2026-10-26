package com.epitomehub.chessverse.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.mockito.ArgumentMatchers.anyString;

import java.lang.reflect.Field;
import java.util.Arrays;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.javamail.JavaMailSender;

class AuthActivityReportServiceTest {
    @Test
    void facebookWithoutEmailIsReportedAsSuccessfulLoginNotInvalidContact() throws Exception {
        var service = new AuthActivityReportService(mock(JdbcTemplate.class),
                mock(AuthActivityEventRepository.class), mock(JavaMailSender.class),
                "from@example.com", "owner@example.com", true);
        var row = new AuthActivityReportService.AuthActivityRow(java.util.UUID.randomUUID(),
                java.sql.Timestamp.from(java.time.Instant.now()), "LOGIN", "FACEBOOK",
                "facebook_123@identity.chessverse.invalid", "facebook_123", "Player", true,
                "Test device", "Android", "Unknown", "UNKNOWN", "IN", "1.3.48", "test", false);
        try (var workbook = new org.apache.poi.xssf.usermodel.XSSFWorkbook(
                new java.io.ByteArrayInputStream(service.workbook(java.util.List.of(row))))) {
            var sheet = workbook.getSheet("Login activity");
            assertThat(sheet.getRow(1).getCell(1).getStringCellValue()).isEqualTo("LOGIN");
            assertThat(sheet.getRow(1).getCell(3).getStringCellValue()).isEmpty();
            assertThat(sheet.getRow(1).getCell(17).getStringCellValue()).isEqualTo("Not shared by Facebook");
        }
        assertThat(AuthActivityReportService.reportEmail("real@example.com")).isEqualTo("real@example.com");
        assertThat(AuthActivityReportService.emailAvailability("real@example.com", "FACEBOOK")).isEqualTo("Provided");
        assertThat(AuthActivityReportService.emailAvailability(null, "GUEST")).isEqualTo("Not provided");
    }

    @Test
    void emptyPendingRowsNeverCreateOrSendMail() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        JavaMailSender sender = mock(JavaMailSender.class);
        when(jdbc.query(anyString(), org.mockito.ArgumentMatchers
                .<org.springframework.jdbc.core.RowMapper<AuthActivityReportService.AuthActivityRow>>any()))
                .thenReturn(java.util.List.of());
        var service = new AuthActivityReportService(jdbc, mock(AuthActivityEventRepository.class),
                sender, "from@example.com", "owner@example.com", true);
        service.sendPendingReport();
        verifyNoInteractions(sender);
    }

    @Test
    void disabledSchedulerDoesNotQueryOrSendMail() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        JavaMailSender sender = mock(JavaMailSender.class);
        var service = new AuthActivityReportService(jdbc, mock(AuthActivityEventRepository.class),
                sender, "from@example.com", "owner@example.com", false);
        service.sendPendingReport();
        verifyNoInteractions(jdbc, sender);
    }

    @Test
    void nonemptyPendingReportStillSendsAndMarksEvents() throws Exception {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        JavaMailSender sender = mock(JavaMailSender.class);
        var id = java.util.UUID.randomUUID();
        var row = new AuthActivityReportService.AuthActivityRow(id,
                java.sql.Timestamp.from(java.time.Instant.now()), "LOGIN", "GOOGLE",
                "player@example.com", "player", "Player", true, "Test device", "Android",
                "Unknown", "UNKNOWN", "IN", "1.3.30+297", "test-fingerprint", false);
        when(jdbc.query(anyString(), org.mockito.ArgumentMatchers
                .<org.springframework.jdbc.core.RowMapper<AuthActivityReportService.AuthActivityRow>>any()))
                .thenReturn(java.util.List.of(row));
        var message = new jakarta.mail.internet.MimeMessage(
                jakarta.mail.Session.getInstance(new java.util.Properties()));
        when(sender.createMimeMessage()).thenReturn(message);
        var service = new AuthActivityReportService(jdbc, mock(AuthActivityEventRepository.class),
                sender, "from@example.com", "owner@example.com", true);
        service.sendPendingReport();
        verify(sender).send(message);
        assertThat(message.getSubject()).endsWith("1 events");
        verify(jdbc).batchUpdate(anyString(), org.mockito.ArgumentMatchers.<java.util.List<Object[]>>any());
    }

    @Test
    void recordsUsefulActivityMetadataWithoutRawSecrets() {
        AuthActivityEventRepository repository = mock(AuthActivityEventRepository.class);
        AuthActivityReportService service = new AuthActivityReportService(
                mock(JdbcTemplate.class), repository, mock(JavaMailSender.class),
                "from@example.com", "chessverseai@gmail.com", true);
        PlayerAccount player = new PlayerAccount("public_user", "Public Player",
                "private@example.com", "hash");

        service.record(player, "REGISTERED", "GOOGLE",
                "Samsung SM-S921B", "Android 15", "IN", "DEVICE_REGION", "IN", "1.3.1+246",
                "a1b2c3d4e5f60708", true);

        ArgumentCaptor<AuthActivityEvent> event = ArgumentCaptor.forClass(AuthActivityEvent.class);
        verify(repository).save(event.capture());
        assertThat(event.getValue().player).isSameAs(player);
        assertThat(event.getValue().eventType).isEqualTo("REGISTERED");
        assertThat(event.getValue().authMethod).isEqualTo("GOOGLE");
        assertThat(event.getValue().deviceName).isEqualTo("Samsung SM-S921B");
        assertThat(event.getValue().clientPlatform).isEqualTo("Android 15");
        assertThat(event.getValue().countryCode).isEqualTo("IN");
        assertThat(event.getValue().countrySource).isEqualTo("DEVICE_REGION");
        assertThat(event.getValue().deviceRegion).isEqualTo("IN");
        assertThat(event.getValue().appVersion).isEqualTo("1.3.1+246");
        assertThat(event.getValue().installationFingerprint).isEqualTo("a1b2c3d4e5f60708");
        assertThat(event.getValue().newDevice).isTrue();
        assertThat(Arrays.stream(AuthActivityEvent.class.getDeclaredFields()).map(Field::getName))
                .doesNotContain("password", "ip", "location", "token", "deviceId");
    }

    @Test
    void workbookKeepsCountryProvenanceAndDoesNotClaimVerifiedLocation() throws Exception {
        AuthActivityReportService service = new AuthActivityReportService(
                mock(JdbcTemplate.class), mock(AuthActivityEventRepository.class),
                mock(JavaMailSender.class), "from@example.com", "owner@example.com", true);
        var rows = java.util.List.of(
                new AuthActivityReportService.AuthActivityRow(java.util.UUID.randomUUID(),
                        java.sql.Timestamp.from(java.time.Instant.parse("2026-10-13T00:00:00Z")),
                        "LOGIN", "GUEST", "", "guest", "Guest", true,
                        "Test device", "Android", "US", "DEVICE_REGION", "US",
                        "1.3.25+292", "test-fingerprint", false),
                new AuthActivityReportService.AuthActivityRow(java.util.UUID.randomUUID(),
                        java.sql.Timestamp.from(java.time.Instant.parse("2026-10-13T00:01:00Z")),
                        "LOGIN", "GUEST", "", "guest", "Guest", true,
                        "Test device", "Android", "GB", "LEGACY_UNVERIFIED", "Unknown",
                        "1.3.25+292", "test-fingerprint", false));
        try (var workbook = new org.apache.poi.xssf.usermodel.XSSFWorkbook(
                new java.io.ByteArrayInputStream(service.workbook(rows)))) {
            var sheet = workbook.getSheet("Login activity");
            assertThat(sheet.getRow(0).getCell(16).getStringCellValue()).isEqualTo("Client type");
            assertThat(sheet.getRow(1).getCell(16).getStringCellValue()).isEqualTo("Android app");
            assertThat(sheet.getRow(0).getCell(12).getStringCellValue())
                    .isEqualTo("Reported country/region (unverified)");
            assertThat(sheet.getRow(0).getCell(14).getStringCellValue())
                    .isEqualTo("Device region (locale)");
            assertThat(sheet.getRow(1).getCell(12).getStringCellValue()).isEqualTo("US");
            assertThat(sheet.getRow(1).getCell(14).getStringCellValue()).isEqualTo("US");
            assertThat(sheet.getRow(1).getCell(15).getStringCellValue()).isEqualTo("DEVICE_REGION");
            assertThat(sheet.getRow(2).getCell(14).getStringCellValue()).isEqualTo("Unknown");
            assertThat(sheet.getRow(2).getCell(15).getStringCellValue()).isEqualTo("LEGACY_UNVERIFIED");
        }
    }

    @Test
    void distinguishesWebFromNativeAndKeepsMissingMetadataUnknown() {
        assertThat(AuthActivityReportService.clientType("Web / Academy", "Academy web browser")).isEqualTo("Web");
        assertThat(AuthActivityReportService.clientType("Linux armv8l", "chrome browser")).isEqualTo("Web");
        assertThat(AuthActivityReportService.clientType("Web", "Unknown device")).isEqualTo("Web");
        assertThat(AuthActivityReportService.clientType("Android 15", "Pixel")).isEqualTo("Android app");
        assertThat(AuthActivityReportService.clientType("iOS 18", "iPhone")).isEqualTo("iOS app");
        assertThat(AuthActivityReportService.clientType("Unknown", "Unknown device")).isEqualTo("Unknown");
        assertThat(AuthActivityReportService.clientType(null, null)).isEqualTo("Unknown");
        assertThat(AuthActivityReportService.clientType("Linux", "Unknown device")).isEqualTo("Unknown");
    }

    @Test
    void neutralizesSpreadsheetFormulaInjection() {
        AuthActivityReportService service = new AuthActivityReportService(
                mock(JdbcTemplate.class), mock(AuthActivityEventRepository.class),
                mock(JavaMailSender.class), "from@example.com", "chessverseai@gmail.com", true);

        assertThat(service.csvCell("=HYPERLINK(\"https://bad.example\")"))
                .isEqualTo("\"'=HYPERLINK(\"\"https://bad.example\"\")\"");
        assertThat(service.csvCell("normal_user")).isEqualTo("\"normal_user\"");
    }
}
