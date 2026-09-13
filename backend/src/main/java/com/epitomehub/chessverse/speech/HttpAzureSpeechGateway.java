package com.epitomehub.chessverse.speech;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
class HttpAzureSpeechGateway implements AzureSpeechGateway {
    private static final int MAX_AUDIO_BYTES = 8 * 1024 * 1024;
    private volatile HttpClient client;
    private final String key;
    private final URI endpoint;
    private final Duration timeout;

    HttpAzureSpeechGateway(
            @Value("${chessverse.speech.azure.key:}") String key,
            @Value("${chessverse.speech.azure.region:}") String region,
            @Value("${chessverse.speech.azure.timeout-seconds:15}") int timeoutSeconds) {
        this.key = key == null ? "" : key.trim();
        String safeRegion = region == null ? "" : region.trim().toLowerCase();
        this.endpoint = safeRegion.matches("^[a-z0-9]+$")
                ? URI.create("https://" + safeRegion + ".tts.speech.microsoft.com/cognitiveservices/v1")
                : null;
        this.timeout = Duration.ofSeconds(Math.max(3, Math.min(timeoutSeconds, 30)));
    }

    @Override
    public byte[] synthesize(String ssml) {
        if (key.isEmpty() || endpoint == null) {
            throw new SpeechException(HttpStatus.SERVICE_UNAVAILABLE, "Cloud narration is temporarily unavailable.");
        }
        HttpRequest request = HttpRequest.newBuilder(endpoint)
                .timeout(timeout)
                .header("Ocp-Apim-Subscription-Key", key)
                .header("Content-Type", "application/ssml+xml")
                .header("X-Microsoft-OutputFormat", "audio-24khz-48kbitrate-mono-mp3")
                .header("User-Agent", "ChessVerseAI")
                .POST(HttpRequest.BodyPublishers.ofString(ssml))
                .build();
        try {
            HttpResponse<byte[]> response = client().send(request, HttpResponse.BodyHandlers.ofByteArray());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new SpeechException(HttpStatus.SERVICE_UNAVAILABLE, "Cloud narration is temporarily unavailable.");
            }
            byte[] audio = response.body();
            if (audio.length == 0 || audio.length > MAX_AUDIO_BYTES) {
                throw new SpeechException(HttpStatus.BAD_GATEWAY, "Cloud narration returned an invalid audio response.");
            }
            return audio;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new SpeechException(HttpStatus.SERVICE_UNAVAILABLE, "Cloud narration was interrupted.");
        } catch (IOException exception) {
            throw new SpeechException(HttpStatus.SERVICE_UNAVAILABLE, "Cloud narration is temporarily unavailable.");
        }
    }

    private HttpClient client() {
        HttpClient current = client;
        if (current != null) {
            return current;
        }
        synchronized (this) {
            if (client == null) {
                client = HttpClient.newBuilder().connectTimeout(timeout).build();
            }
            return client;
        }
    }
}
