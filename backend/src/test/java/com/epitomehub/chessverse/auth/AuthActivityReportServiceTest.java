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
    void recordsOnlyPrivacySafeActivityMetadata() {
        AuthActivityEventRepository repository = mock(AuthActivityEventRepository.class);
        AuthActivityReportService service = new AuthActivityReportService(
                mock(JdbcTemplate.class), repository, mock(JavaMailSender.class),
                "from@example.com", "cheseverseai@gmail.com", true);
        PlayerAccount player = new PlayerAccount("public_user", "Public Player",
                "private@example.com", "hash");

        service.record(player, "REGISTERED", "GOOGLE");

        ArgumentCaptor<AuthActivityEvent> event = ArgumentCaptor.forClass(AuthActivityEvent.class);
        verify(repository).save(event.capture());
        assertThat(event.getValue().player).isSameAs(player);
        assertThat(event.getValue().eventType).isEqualTo("REGISTERED");
        assertThat(event.getValue().authMethod).isEqualTo("GOOGLE");
        assertThat(Arrays.stream(AuthActivityEvent.class.getDeclaredFields()).map(Field::getName))
                .doesNotContain("email", "ip", "deviceName", "location", "token");
    }

    @Test
    void neutralizesSpreadsheetFormulaInjection() {
        AuthActivityReportService service = new AuthActivityReportService(
                mock(JdbcTemplate.class), mock(AuthActivityEventRepository.class),
                mock(JavaMailSender.class), "from@example.com", "cheseverseai@gmail.com", true);

        assertThat(service.csvCell("=HYPERLINK(\"https://bad.example\")"))
                .isEqualTo("\"'=HYPERLINK(\"\"https://bad.example\"\")\"");
        assertThat(service.csvCell("normal_user")).isEqualTo("\"normal_user\"");
    }
}
