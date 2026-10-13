package com.epitomehub.chessverse.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import java.lang.reflect.Field;
import java.util.Arrays;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.javamail.JavaMailSender;

class AuthActivityReportServiceTest {
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
    void neutralizesSpreadsheetFormulaInjection() {
        AuthActivityReportService service = new AuthActivityReportService(
                mock(JdbcTemplate.class), mock(AuthActivityEventRepository.class),
                mock(JavaMailSender.class), "from@example.com", "chessverseai@gmail.com", true);

        assertThat(service.csvCell("=HYPERLINK(\"https://bad.example\")"))
                .isEqualTo("\"'=HYPERLINK(\"\"https://bad.example\"\")\"");
        assertThat(service.csvCell("normal_user")).isEqualTo("\"normal_user\"");
    }
}
