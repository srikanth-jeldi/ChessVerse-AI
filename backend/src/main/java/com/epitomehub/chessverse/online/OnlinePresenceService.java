package com.epitomehub.chessverse.online;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
class OnlinePresenceService {
    static final Duration PRESENCE_LEASE = Duration.ofSeconds(45);

    private final ConcurrentHashMap<UUID, Instant> lastSeen = new ConcurrentHashMap<>();
    private final JdbcTemplate jdbc;
    private final PlayerNotificationService notifications;

    OnlinePresenceService(JdbcTemplate jdbc, PlayerNotificationService notifications) {
        this.jdbc = jdbc;
        this.notifications = notifications;
    }

    long heartbeat(UUID playerId) {
        Instant now = Instant.now();
        Instant previous = lastSeen.get(playerId);
        boolean cameOnline = previous == null || previous.isBefore(now.minus(PRESENCE_LEASE));
        lastSeen.put(playerId, now);
        Instant cutoff = now.minus(PRESENCE_LEASE);
        lastSeen.entrySet().removeIf(entry -> entry.getValue().isBefore(cutoff));
        if (cameOnline) notifyFriends(playerId, now);
        return lastSeen.entrySet().stream()
                .filter(entry -> !entry.getValue().isBefore(cutoff))
                .count();
    }

    private void notifyFriends(UUID playerId, Instant now) {
        String displayName = jdbc.queryForObject(
                "select display_name from player_account where id=?", String.class, playerId);
        if (displayName == null || displayName.isBlank()) return;
        jdbc.queryForList("""
                select case when requester_id=? then addressee_id else requester_id end
                from friend_connection
                where status='ACCEPTED' and (requester_id=? or addressee_id=?)
                """, UUID.class, playerId, playerId, playerId).stream()
                .filter(friendId -> !isOnline(friendId))
                .forEach(friendId -> notifications.createOnce(
                        friendId, "FRIEND_ONLINE",
                        LocalDate.ofInstant(now, ZoneId.of("Asia/Kolkata")) + ":" + playerId,
                        "Friend online", displayName + " is online now.",
                        "FRIEND_ONLINE", playerId));
    }

    boolean isOnline(UUID playerId) {
        Instant seen = lastSeen.get(playerId);
        return seen != null && !seen.isBefore(Instant.now().minus(PRESENCE_LEASE));
    }
}
