package com.epitomehub.chessverse.economy;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Map;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

@Component
class RazorpayPurchaseGateway {
    private final boolean enabled;
    private final String keyId;
    private final String keySecret;
    private final String webhookSecret;
    private final ObjectMapper json;
    private volatile HttpClient http;

    RazorpayPurchaseGateway(ObjectMapper json,
            @Value("${chessverse.payments.razorpay.enabled:false}") boolean enabled,
            @Value("${chessverse.payments.razorpay.key-id:}") String keyId,
            @Value("${chessverse.payments.razorpay.key-secret:}") String keySecret,
            @Value("${chessverse.payments.razorpay.webhook-secret:}") String webhookSecret) {
        this.enabled = enabled;
        this.keyId = keyId.trim();
        this.keySecret = keySecret.trim();
        this.webhookSecret = webhookSecret.trim();
        this.json = json;
    }

    boolean available() {
        return enabled && keyId.startsWith("rzp_test_") && !keySecret.isBlank();
    }

    ProviderOrder createOrder(String receipt, long amountMinor, String currency) {
        if (!available()) throw unavailable();
        try {
            String body = json.writeValueAsString(Map.of(
                    "amount", amountMinor,
                    "currency", currency,
                    "receipt", receipt,
                    "notes", Map.of("purpose", "ChessVerseAI direct coin pack")));
            HttpRequest request = HttpRequest.newBuilder(URI.create("https://api.razorpay.com/v1/orders"))
                    .timeout(Duration.ofSeconds(12))
                    .header("Authorization", authorization())
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body)).build();
            HttpResponse<String> response = client().send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) throw unavailable();
            JsonNode result = json.readTree(response.body());
            String id = result.path("id").asText();
            long verifiedAmount = result.path("amount").asLong(-1);
            String verifiedCurrency = result.path("currency").asText();
            if (id.isBlank() || verifiedAmount != amountMinor || !currency.equals(verifiedCurrency)) {
                throw unavailable();
            }
            return new ProviderOrder(id, keyId);
        } catch (ResponseStatusException expected) {
            throw expected;
        } catch (Exception failure) {
            if (failure instanceof InterruptedException) Thread.currentThread().interrupt();
            throw unavailable();
        }
    }

    VerifiedPayment verifyCapturedPayment(String paymentId, String expectedOrderId,
                                           long expectedAmount, String expectedCurrency) {
        if (!available() || paymentId == null || paymentId.isBlank()) throw unavailable();
        try {
            HttpRequest request = HttpRequest.newBuilder(
                            URI.create("https://api.razorpay.com/v1/payments/" + paymentId))
                    .timeout(Duration.ofSeconds(12))
                    .header("Authorization", authorization()).GET().build();
            HttpResponse<String> response = client().send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) throw unavailable();
            JsonNode payment = json.readTree(response.body());
            if (!paymentId.equals(payment.path("id").asText())
                    || !expectedOrderId.equals(payment.path("order_id").asText())
                    || !"captured".equals(payment.path("status").asText())
                    || expectedAmount != payment.path("amount").asLong(-1)
                    || !expectedCurrency.equals(payment.path("currency").asText())) {
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "Payment is not captured for this exact order. No coins were credited.");
            }
            return new VerifiedPayment(paymentId);
        } catch (ResponseStatusException expected) {
            throw expected;
        } catch (Exception failure) {
            if (failure instanceof InterruptedException) Thread.currentThread().interrupt();
            throw unavailable();
        }
    }

    String findCapturedPayment(String providerOrderId, long expectedAmount, String expectedCurrency) {
        if (!available()) return null;
        try {
            HttpRequest request = HttpRequest.newBuilder(URI.create(
                            "https://api.razorpay.com/v1/orders/" + providerOrderId + "/payments"))
                    .timeout(Duration.ofSeconds(12))
                    .header("Authorization", authorization()).GET().build();
            HttpResponse<String> response = client().send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) return null;
            for (JsonNode payment : json.readTree(response.body()).path("items")) {
                if ("captured".equals(payment.path("status").asText())
                        && providerOrderId.equals(payment.path("order_id").asText())
                        && expectedAmount == payment.path("amount").asLong(-1)
                        && expectedCurrency.equals(payment.path("currency").asText())) {
                    return payment.path("id").asText(null);
                }
            }
            return null;
        } catch (Exception ignored) {
            if (ignored instanceof InterruptedException) Thread.currentThread().interrupt();
            return null;
        }
    }

    boolean validPaymentSignature(String providerOrderId, String paymentId, String signature) {
        if (!available() || providerOrderId == null || paymentId == null || signature == null
                || signature.length() != 64) return false;
        byte[] expected = hmacSha256(keySecret, providerOrderId + '|' + paymentId);
        byte[] received;
        try {
            received = HexFormat.of().parseHex(signature);
        } catch (IllegalArgumentException invalidHex) {
            return false;
        }
        return MessageDigest.isEqual(expected, received);
    }

    boolean validWebhookSignature(String rawBody, String signature) {
        if (!enabled || webhookSecret.isBlank() || rawBody == null || signature == null
                || signature.length() != 64) return false;
        byte[] expected = hmacSha256(webhookSecret, rawBody);
        try {
            return MessageDigest.isEqual(expected, HexFormat.of().parseHex(signature));
        } catch (IllegalArgumentException invalidHex) {
            return false;
        }
    }

    static byte[] hmacSha256(String secret, String value) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return mac.doFinal(value.getBytes(StandardCharsets.UTF_8));
        } catch (Exception impossible) {
            throw new IllegalStateException(impossible);
        }
    }

    private ResponseStatusException unavailable() {
        return new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                "Secure web checkout is temporarily unavailable. No payment was completed.");
    }

    private String authorization() {
        return "Basic " + Base64.getEncoder().encodeToString(
                (keyId + ':' + keySecret).getBytes(StandardCharsets.UTF_8));
    }

    private HttpClient client() {
        HttpClient current = http;
        if (current != null) return current;
        synchronized (this) {
            if (http == null) http = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(5)).build();
            return http;
        }
    }

    record ProviderOrder(String id, String publicKeyId) {}
    record VerifiedPayment(String id) {}
}
