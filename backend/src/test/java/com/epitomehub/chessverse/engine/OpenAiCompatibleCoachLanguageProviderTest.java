package com.epitomehub.chessverse.engine;

import static org.assertj.core.api.Assertions.assertThat;

import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

class OpenAiCompatibleCoachLanguageProviderTest {
    @Test
    void staysDisabledWithoutExplicitConfiguration() {
        var provider = new OpenAiCompatibleCoachLanguageProvider(
                new ObjectMapper(), false, "", "", "", 8, 220,
                org.mockito.Mockito.mock(AiCoachMetrics.class));
        assertThat(provider.enabled()).isFalse();
    }

    @Test
    void refusesInsecureRemoteEndpoints() {
        var provider = new OpenAiCompatibleCoachLanguageProvider(
                new ObjectMapper(), true, "http://example.com/v1/chat/completions", "key", "model", 8, 220,
                org.mockito.Mockito.mock(AiCoachMetrics.class));
        assertThat(provider.enabled()).isFalse();
    }

    @Test
    void masksTokensEmailsAndLongSecretsBeforeExternalUse() {
        String value = OpenAiCompatibleCoachLanguageProvider.sanitize(
                "mail me at player@example.com Bearer abc.def.ghi "
                        + "abcdefghijklmnopqrstuvwxyzABCDEF0123456789");
        assertThat(value).doesNotContain("player@example.com", "abc.def.ghi",
                "abcdefghijklmnopqrstuvwxyzABCDEF0123456789");
        assertThat(value).contains("[redacted-email]", "[redacted-token]", "[redacted-secret]");
    }

    @Test
    void callsConfiguredCompatibleEndpointWithChessEvidenceOnly() throws Exception {
        AtomicReference<String> received = new AtomicReference<>();
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/chat", exchange -> {
            received.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            byte[] response = "{\"choices\":[{\"message\":{\"content\":\"Develop first, then castle.\"}}]}"
                    .getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            exchange.getResponseBody().write(response);
            exchange.close();
        });
        server.start();
        try {
            var provider = new OpenAiCompatibleCoachLanguageProvider(
                    new ObjectMapper(), true,
                    "http://127.0.0.1:" + server.getAddress().getPort() + "/chat",
                    "test-key", "test-model", 3, 120, org.mockito.Mockito.mock(AiCoachMetrics.class));
            String answer = provider.explain(new CoachLanguageProvider.CoachLanguageContext(
                    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                    "Why? player@example.com", "none", "e2e4", null,
                    "Best", "e2e4", 0, "e7e5", List.of("e2e4", "e7e5")));

            assertThat(answer).isEqualTo("Develop first, then castle.");
            assertThat(received.get()).contains("test-model", "e2e4", "[redacted-email]")
                    .doesNotContain("player@example.com", "test-key");
        } finally {
            server.stop(0);
        }
    }
}
