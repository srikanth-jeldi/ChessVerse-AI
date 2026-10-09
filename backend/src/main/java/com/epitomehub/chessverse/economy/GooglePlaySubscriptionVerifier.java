package com.epitomehub.chessverse.economy;

import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.androidpublisher.AndroidPublisher;
import com.google.api.services.androidpublisher.AndroidPublisherScopes;
import com.google.api.services.androidpublisher.model.SubscriptionPurchaseLineItem;
import com.google.api.services.androidpublisher.model.SubscriptionPurchaseV2;
import com.google.api.services.androidpublisher.model.SubscriptionPurchasesAcknowledgeRequest;
import com.google.auth.http.HttpCredentialsAdapter;
import com.google.auth.oauth2.GoogleCredentials;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
class GooglePlaySubscriptionVerifier {
    private static final String PRODUCT_ID = "chessverse_premium";
    private final boolean enabled;
    private final String packageName;
    private final String serviceAccountJson;
    private final String serviceAccountFile;

    GooglePlaySubscriptionVerifier(
            @Value("${chessverse.payments.google-play.enabled:false}") boolean enabled,
            @Value("${chessverse.payments.google-play.package-name:com.epitomehub.chessverse}") String packageName,
            @Value("${chessverse.payments.google-play.service-account-json:}") String serviceAccountJson,
            @Value("${chessverse.payments.google-play.service-account-file:}") String serviceAccountFile) {
        this.enabled = enabled;
        this.packageName = packageName;
        this.serviceAccountJson = serviceAccountJson;
        this.serviceAccountFile = serviceAccountFile;
    }

    VerifiedSubscription verify(String purchaseToken) {
        if (purchaseToken == null || purchaseToken.isBlank() || purchaseToken.length() > 4096) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid subscription purchase token.");
        }
        try {
            AndroidPublisher publisher = publisher();
            SubscriptionPurchaseV2 purchase = publisher.purchases().subscriptionsv2()
                    .get(packageName, purchaseToken).execute();
            String state = purchase.getSubscriptionState();
            if (!List.of("SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
                    "SUBSCRIPTION_STATE_CANCELED").contains(state)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "Google Play reports that this subscription is not active.");
            }
            SubscriptionPurchaseLineItem line = purchase.getLineItems() == null ? null
                    : purchase.getLineItems().stream()
                    .filter(item -> PRODUCT_ID.equals(item.getProductId())).findFirst().orElse(null);
            if (line == null || line.getExpiryTime() == null) {
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "The verified purchase does not contain ChessVerseAI Premium.");
            }
            Instant expiry = Instant.parse(line.getExpiryTime());
            if (!expiry.isAfter(Instant.now())) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "The subscription has expired.");
            }
            String basePlan = line.getOfferDetails() == null ? "unknown"
                    : line.getOfferDetails().getBasePlanId();
            boolean autoRenewing = line.getAutoRenewingPlan() != null
                    && Boolean.TRUE.equals(line.getAutoRenewingPlan().getAutoRenewEnabled());
            if ("ACKNOWLEDGEMENT_STATE_PENDING".equals(purchase.getAcknowledgementState())) {
                publisher.purchases().subscriptions().acknowledge(packageName, PRODUCT_ID,
                        purchaseToken, new SubscriptionPurchasesAcknowledgeRequest()).execute();
            }
            return new VerifiedSubscription(PRODUCT_ID, basePlan, expiry, autoRenewing);
        } catch (ResponseStatusException expected) {
            throw expected;
        } catch (Exception failure) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                    "Google Play could not verify this subscription.");
        }
    }

    boolean available() {
        return enabled && !credentialsJson().isBlank();
    }

    private AndroidPublisher publisher() throws Exception {
        String json = credentialsJson();
        if (!enabled || json.isBlank()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Google Play subscription verification is not configured.");
        }
        GoogleCredentials credentials = GoogleCredentials
                .fromStream(new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)))
                .createScoped(List.of(AndroidPublisherScopes.ANDROIDPUBLISHER));
        return new AndroidPublisher.Builder(GoogleNetHttpTransport.newTrustedTransport(),
                GsonFactory.getDefaultInstance(), new HttpCredentialsAdapter(credentials))
                .setApplicationName("ChessVerseAI subscription verifier").build();
    }

    private String credentialsJson() {
        if (!serviceAccountJson.isBlank()) return serviceAccountJson;
        if (serviceAccountFile.isBlank()) return "";
        try {
            Path path = Path.of(serviceAccountFile).toAbsolutePath().normalize();
            return Files.isRegularFile(path) ? Files.readString(path, StandardCharsets.UTF_8) : "";
        } catch (Exception ignored) {
            return "";
        }
    }

    record VerifiedSubscription(String productId, String basePlanId,
            Instant expiresAt, boolean autoRenewing) {}
}
