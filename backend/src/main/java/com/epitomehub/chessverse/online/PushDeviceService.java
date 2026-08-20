package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.time.Instant;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class PushDeviceService {
    private final JdbcTemplate jdbc;
    PushDeviceService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @Transactional
    void register(AuthenticatedPlayer player, String installationId, String token, String platform) {
        if (installationId == null || installationId.isBlank() || token == null || token.isBlank()) {
            throw new IllegalArgumentException("Installation id and push token are required.");
        }
        Instant now = Instant.now();
        jdbc.update("delete from push_notification_device where token=? and player_id<>?", token, player.id());
        jdbc.update("insert into push_notification_device(id,player_id,installation_id,platform,token,enabled,created_at,updated_at) " +
                        "values(?,?,?,?,?,true,?,?) on conflict(player_id,installation_id) do update set " +
                        "platform=excluded.platform,token=excluded.token,enabled=true,updated_at=excluded.updated_at",
                UUID.randomUUID(), player.id(), installationId.trim(), normalized(platform), token.trim(), now, now);
    }

    void unregister(AuthenticatedPlayer player, String installationId) {
        jdbc.update("update push_notification_device set enabled=false,updated_at=? where player_id=? and installation_id=?",
                Instant.now(), player.id(), installationId);
    }

    private String normalized(String platform) {
        String value = platform == null ? "unknown" : platform.trim().toLowerCase();
        return value.length() > 20 ? value.substring(0, 20) : value;
    }
}
