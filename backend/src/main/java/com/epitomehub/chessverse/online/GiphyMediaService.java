package com.epitomehub.chessverse.online;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

@Service
class GiphyMediaService {
    record MediaResult(String id, String title, String previewUrl, String mediaUrl, String kind) {}

    private final String androidApiKey;
    private final String webApiKey;
    private final String fallbackApiKey;
    private final RestClient client = RestClient.create();
    private final ObjectMapper mapper = new ObjectMapper();

    GiphyMediaService(
            @Value("${chessverse.chat.giphy.android-api-key:}") String androidApiKey,
            @Value("${chessverse.chat.giphy.web-api-key:}") String webApiKey,
            @Value("${chessverse.chat.giphy.api-key:}") String fallbackApiKey) {
        this.androidApiKey = clean(androidApiKey);
        this.webApiKey = clean(webApiKey);
        this.fallbackApiKey = clean(fallbackApiKey);
    }

    List<MediaResult> search(String query, String kind, String locale, String platform) {
        String apiKey = apiKeyFor(platform);
        if (apiKey.isBlank()) return List.of();
        String safeKind = "sticker".equalsIgnoreCase(kind) ? "sticker" : "gif";
        String trimmed = query == null || query.isBlank() ? "chess" : query.trim();
        String safeQuery = trimmed.substring(0, Math.min(50, trimmed.length()));
        String safeLocale = locale == null || !locale.matches("^[A-Za-z]{2}([_-][A-Za-z]{2})?$")
                ? "en" : locale.substring(0, 2).toLowerCase();
        URI uri = UriComponentsBuilder
                .fromUriString("https://api.giphy.com/v1/" + ("sticker".equals(safeKind) ? "stickers" : "gifs") + "/search")
                .queryParam("api_key", apiKey)
                .queryParam("q", safeQuery)
                .queryParam("limit", 18)
                .queryParam("rating", "pg")
                .queryParam("lang", safeLocale)
                .build().encode().toUri();
        String body = client.get().uri(uri).retrieve().body(String.class);
        if (body == null || body.isBlank()) return List.of();
        try {
            List<MediaResult> media = new ArrayList<>();
            for (JsonNode result : mapper.readTree(body).path("data")) {
                JsonNode images = result.path("images");
                String preview = images.path("fixed_width_small").path("url").asText("");
                String full = images.path("downsized").path("url").asText(
                        images.path("original").path("url").asText(preview));
                if (isGiphyUrl(preview) && isGiphyUrl(full)) {
                    media.add(new MediaResult(result.path("id").asText(),
                            result.path("alt_text").asText(result.path("title").asText(safeKind)),
                            preview, full, safeKind));
                }
            }
            return List.copyOf(media);
        } catch (Exception error) {
            throw new IllegalStateException("GIPHY response could not be read", error);
        }
    }

    private String apiKeyFor(String platform) {
        String platformKey = "web".equalsIgnoreCase(platform) ? webApiKey : androidApiKey;
        return platformKey.isBlank() ? fallbackApiKey : platformKey;
    }

    private static String clean(String value) {
        return value == null ? "" : value.trim();
    }

    private boolean isGiphyUrl(String value) {
        try {
            URI uri = URI.create(value);
            String host = uri.getHost();
            return "https".equalsIgnoreCase(uri.getScheme()) && host != null
                    && (host.equals("giphy.com") || host.endsWith(".giphy.com"));
        } catch (RuntimeException ignored) {
            return false;
        }
    }
}
