package com.epitomehub.chessverse.online;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.Message;
import java.io.FileInputStream;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
class FirebasePushService {
    private static final Logger log = LoggerFactory.getLogger(FirebasePushService.class);
    private final JdbcTemplate jdbc;
    private FirebaseMessaging messaging;

    FirebasePushService(JdbcTemplate jdbc,
            @Value("${GOOGLE_APPLICATION_CREDENTIALS:}") String credentialsPath) {
        this.jdbc = jdbc;
        if (!credentialsPath.isBlank()) {
            try (FileInputStream input = new FileInputStream(credentialsPath)) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(input)).build();
                FirebaseApp app = FirebaseApp.getApps().isEmpty()
                        ? FirebaseApp.initializeApp(options)
                        : FirebaseApp.getInstance();
                messaging = FirebaseMessaging.getInstance(app);
            } catch (Exception exception) {
                log.warn("Firebase push disabled: {}", exception.getMessage());
            }
        }
    }

    void send(UUID playerId, UUID notificationId, String title, String body,
              String actionType, UUID actionId) {
        if (messaging == null) return;
        for (String token : jdbc.queryForList(
                "select token from push_notification_device where player_id=? and enabled=true",
                String.class, playerId)) {
            try {
                Message.Builder builder = Message.builder().setToken(token)
                        .setNotification(com.google.firebase.messaging.Notification.builder()
                                .setTitle(title).setBody(body).build())
                        .setAndroidConfig(AndroidConfig.builder()
                                .setCollapseKey(notificationId.toString())
                                .setNotification(AndroidNotification.builder()
                                        .setTag(notificationId.toString())
                                        .build())
                                .build())
                        .putAllData(Map.of(
                                "notificationId", notificationId.toString(),
                                "actionType", actionType == null ? "notifications" : actionType,
                                "actionId", actionId == null ? "" : actionId.toString()));
                messaging.send(builder.build());
            } catch (Exception exception) {
                log.warn("FCM delivery failed for player {}: {}", playerId, exception.getMessage());
            }
        }
    }
}
