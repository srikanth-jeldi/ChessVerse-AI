package com.epitomehub.chessverse.auth;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
class FacebookIdentityVerifier {
    private final String appId;
    private final String appSecret;
    private final String graphVersion;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    FacebookIdentityVerifier(
            @Value("${chessverse.oauth.facebook-app-id:}") String appId,
            @Value("${chessverse.oauth.facebook-app-secret:}") String appSecret,
            @Value("${chessverse.oauth.facebook-graph-version:v26.0}") String graphVersion,
            ObjectMapper objectMapper) {
        this.appId = appId.trim();
        this.appSecret = appSecret.trim();
        this.graphVersion = graphVersion.trim();
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    }

    VerifiedFacebookIdentity verify(String accessToken) {
        if (appId.isEmpty() || appSecret.isEmpty() || appId.startsWith("replace-")) {
            throw new AuthException(HttpStatus.SERVICE_UNAVAILABLE, "Facebook login is not configured.");
        }
        try {
            JsonNode debug = get("debug_token?input_token=" + encode(accessToken)
                    + "&access_token=" + encode(appId + "|" + appSecret)).path("data");
            if (!debug.path("is_valid").asBoolean(false)
                    || !appId.equals(debug.path("app_id").asText())
                    || debug.path("user_id").asText().isBlank()) {
                throw invalidToken();
            }

            JsonNode profile = get("me?fields=id,name,email,picture.type(large)&access_token="
                    + encode(accessToken));
            String subject = profile.path("id").asText();
            String email = profile.path("email").asText();
            if (!subject.equals(debug.path("user_id").asText()) || email.isBlank()) {
                throw invalidToken();
            }
            String name = profile.path("name").asText(null);
            String photo = profile.path("picture").path("data").path("url").asText(null);
            return new VerifiedFacebookIdentity(subject, email, name, photo);
        } catch (AuthException exception) {
            throw exception;
        } catch (IOException | InterruptedException | RuntimeException exception) {
            if (exception instanceof InterruptedException) Thread.currentThread().interrupt();
            throw invalidToken();
        }
    }

    private JsonNode get(String pathAndQuery) throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://graph.facebook.com/" + graphVersion + "/" + pathAndQuery))
                .timeout(Duration.ofSeconds(8))
                .GET()
                .build();
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) throw invalidToken();
        return objectMapper.readTree(response.body());
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private AuthException invalidToken() {
        return new AuthException(HttpStatus.UNAUTHORIZED, "Facebook sign-in could not be verified.");
    }

    record VerifiedFacebookIdentity(String subject, String email, String displayName, String photoUrl) {
    }
}
