package com.epitomehub.chessverse.economy;

import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.androidpublisher.AndroidPublisher;
import com.google.api.services.androidpublisher.AndroidPublisherScopes;
import com.google.api.services.androidpublisher.model.ProductPurchase;
import com.google.auth.http.HttpCredentialsAdapter;
import com.google.auth.oauth2.GoogleCredentials;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
class GooglePlayPurchaseVerifier {
    private final boolean enabled;
    private final String packageName;
    private final String serviceAccountJson;
    private final String serviceAccountFile;

    GooglePlayPurchaseVerifier(
            @Value("${chessverse.payments.google-play.enabled:false}") boolean enabled,
            @Value("${chessverse.payments.google-play.package-name:com.epitomehub.chessverse}") String packageName,
            @Value("${chessverse.payments.google-play.service-account-json:}") String serviceAccountJson,
            @Value("${chessverse.payments.google-play.service-account-file:}") String serviceAccountFile) {
        this.enabled = enabled;
        this.packageName = packageName;
        this.serviceAccountJson = serviceAccountJson;
        this.serviceAccountFile = serviceAccountFile;
    }

    VerifiedGooglePurchase verify(String sku, String purchaseToken) {
        String credentialsJson = credentialsJson();
        if (!enabled || credentialsJson.isBlank()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Google Play purchase verification is not configured. No coins were credited.");
        }
        if (purchaseToken == null || purchaseToken.isBlank() || purchaseToken.length() > 4096) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid Google Play purchase token.");
        }
        try {
            GoogleCredentials credentials = GoogleCredentials
                    .fromStream(new ByteArrayInputStream(credentialsJson.getBytes(StandardCharsets.UTF_8)))
                    .createScoped(List.of(AndroidPublisherScopes.ANDROIDPUBLISHER));
            AndroidPublisher publisher = new AndroidPublisher.Builder(
                    GoogleNetHttpTransport.newTrustedTransport(), GsonFactory.getDefaultInstance(),
                    new HttpCredentialsAdapter(credentials))
                    .setApplicationName("ChessVerseAI purchase verifier").build();
            ProductPurchase purchase = publisher.purchases().products()
                    .get(packageName, sku, purchaseToken).execute();
            // Google: 0 = purchased, 1 = cancelled, 2 = pending.
            if (purchase.getPurchaseState() == null || purchase.getPurchaseState() != 0) {
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "Google Play purchase is not completed. No coins were credited.");
            }
            if (purchase.getPurchaseType() != null && purchase.getPurchaseType() == 1) {
                // Test purchases are valid in sandbox/license-tester flows and
                // remain visible in audit data through the order provider.
            }
            return new VerifiedGooglePurchase(sku, purchaseToken, purchase.getOrderId());
        } catch (ResponseStatusException expected) {
            throw expected;
        } catch (Exception verificationFailure) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                    "Google Play could not verify this purchase. No coins were credited.");
        }
    }

    record VerifiedGooglePurchase(String sku, String transactionKey, String orderId) {}

    boolean available() {
        return enabled && !credentialsJson().isBlank();
    }

    private String credentialsJson() {
        if (!serviceAccountJson.isBlank()) return serviceAccountJson;
        if (serviceAccountFile.isBlank()) return "";
        try {
            Path file = Path.of(serviceAccountFile).toAbsolutePath().normalize();
            if (!Files.isRegularFile(file)) return "";
            return Files.readString(file, StandardCharsets.UTF_8);
        } catch (Exception unreadable) {
            return "";
        }
    }
}
