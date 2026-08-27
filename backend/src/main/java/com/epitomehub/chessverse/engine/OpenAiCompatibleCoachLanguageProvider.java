package com.epitomehub.chessverse.engine;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/** Optional OpenAI-compatible chat-completions adapter. Disabled by default. */
@Component
class OpenAiCompatibleCoachLanguageProvider implements CoachLanguageProvider {
    private static final String SYSTEM_PROMPT = """
            You are ChessVerseAI's concise chess coach. Use only the supplied Stockfish evidence.
            Never invent a tactic, evaluation, legal move, or personal fact. If the evidence is
            insufficient, say so. Answer in plain language, under 140 words, and preserve UCI moves.
            """;

    private final ObjectMapper json;
    private final HttpClient http;
    private final boolean configured;
    private final URI endpoint;
    private final String apiKey;
    private final String model;
    private final Duration timeout;
    private final int maxTokens;
    private final AiCoachMetrics metrics;

    OpenAiCompatibleCoachLanguageProvider(
            ObjectMapper json,
            @Value("${chessverse.coach.language.enabled:false}") boolean enabled,
            @Value("${chessverse.coach.language.endpoint:}") String endpoint,
            @Value("${chessverse.coach.language.api-key:}") String apiKey,
            @Value("${chessverse.coach.language.model:}") String model,
            @Value("${chessverse.coach.language.timeout-seconds:8}") long timeoutSeconds,
            @Value("${chessverse.coach.language.max-output-tokens:220}") int maxTokens,
            AiCoachMetrics metrics) {
        this.json = json;
        this.http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build();
        this.endpoint = endpoint.isBlank() ? null : URI.create(endpoint.trim());
        this.apiKey = apiKey.trim();
        this.model = model.trim();
        this.timeout = Duration.ofSeconds(Math.max(2, Math.min(20, timeoutSeconds)));
        this.maxTokens = Math.max(80, Math.min(500, maxTokens));
        this.metrics = metrics;
        this.configured = enabled && this.endpoint != null && !this.apiKey.isBlank() && !this.model.isBlank()
                && isSafeEndpoint(this.endpoint);
    }

    @Override
    public boolean enabled() {
        return configured;
    }

    @Override
    public String explain(CoachLanguageContext context) {
        if (!configured) return null;
        long started = System.nanoTime();
        try {
            Map<String, Object> payload = Map.of(
                    "model", model,
                    "temperature", 0.2,
                    "max_tokens", maxTokens,
                    "messages", List.of(
                            Map.of("role", "developer", "content", SYSTEM_PROMPT),
                            Map.of("role", "user", "content", evidencePrompt(context))));
            HttpRequest.Builder request = HttpRequest.newBuilder(endpoint)
                    .timeout(timeout)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(payload)));
            if (!apiKey.isBlank()) request.header("Authorization", "Bearer " + apiKey);
            HttpResponse<String> response = http.send(request.build(), HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                metrics.languageFailure(System.nanoTime() - started);
                return null;
            }
            JsonNode content = json.readTree(response.body()).at("/choices/0/message/content");
            if (!content.isTextual()) {
                metrics.languageFailure(System.nanoTime() - started);
                return null;
            }
            String answer = content.asText().trim();
            if (answer.isBlank()) {
                metrics.languageFailure(System.nanoTime() - started);
                return null;
            }
            metrics.languageSuccess(System.nanoTime() - started);
            return answer.substring(0, Math.min(answer.length(), 1200));
        } catch (Exception exception) {
            if (exception instanceof InterruptedException) Thread.currentThread().interrupt();
            metrics.languageFailure(System.nanoTime() - started);
            return null;
        }
    }

    private static String evidencePrompt(CoachLanguageContext context) {
        return "FEN: " + context.fen() + "\n"
                + "Question: " + sanitize(context.question()) + "\n"
                + "Prior conversation: " + sanitize(context.previousQuestion()) + "\n"
                + "Played/candidate: " + context.playedMove() + " / " + context.candidateMove() + "\n"
                + "Classification: " + context.classification() + "\n"
                + "Best move: " + context.bestMove() + "\n"
                + "Centipawn loss: " + context.centipawnLoss() + "\n"
                + "Opponent threat: " + context.opponentThreat() + "\n"
                + "Principal variation: " + String.join(" ", context.principalVariation());
    }

    static String sanitize(String input) {
        if (input == null || input.isBlank()) return "none";
        String sanitized = input
                .replaceAll("(?i)bearer\\s+[a-z0-9._~-]+", "[redacted-token]")
                .replaceAll("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", "[redacted-email]")
                .replaceAll("\\b[A-Za-z0-9_-]{32,}\\b", "[redacted-secret]");
        return sanitized.substring(0, Math.min(sanitized.length(), 900));
    }

    private static boolean isSafeEndpoint(URI uri) {
        if ("https".equalsIgnoreCase(uri.getScheme())) return uri.getHost() != null;
        return "http".equalsIgnoreCase(uri.getScheme())
                && ("localhost".equalsIgnoreCase(uri.getHost()) || "127.0.0.1".equals(uri.getHost()));
    }
}
