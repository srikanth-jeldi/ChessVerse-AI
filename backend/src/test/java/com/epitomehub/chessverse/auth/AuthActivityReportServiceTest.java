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
                "Samsung SM-S921B", "Android 15", "IN", "1.3.1+246",
                "a1b2c3d4e5f60708", true);

        ArgumentCaptor<AuthActivityEvent> event = ArgumentCaptor.forClass(AuthActivityEvent.class);
        verify(repository).save(event.capture());
        assertThat(event.getValue().player).isSameAs(player);
        assertThat(event.getValue().eventType).isEqualTo("REGISTERED");
        assertThat(event.getValue().authMethod).isEqualTo("GOOGLE");
        assertThat(event.getValue().deviceName).isEqualTo("Samsung SM-S921B");
        assertThat(event.getValue().clientPlatform).isEqualTo("Android 15");
        assertThat(event.getValue().countryCode).isEqualTo("IN");
        assertThat(event.getValue().appVersion).isEqualTo("1.3.1+246");
        assertThat(event.getValue().installationFingerprint).isEqualTo("a1b2c3d4e5f60708");
        assertThat(event.getValue().newDevice).isTrue();
        assertThat(Arrays.stream(AuthActivityEvent.class.getDeclaredFields()).map(Field::getName))
                .doesNotContain("password", "ip", "location", "token", "deviceId");
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
