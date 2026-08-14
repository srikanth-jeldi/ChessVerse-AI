package com.epitomehub.chessverse.online;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Service;

@Service
class OnlinePresenceService {
    static final Duration PRESENCE_LEASE = Duration.ofSeconds(45);

    private final ConcurrentHashMap<UUID, Instant> lastSeen = new ConcurrentHashMap<>();

    long heartbeat(UUID playerId) {
        Instant now = Instant.now();
        lastSeen.put(playerId, now);
        Instant cutoff = now.minus(PRESENCE_LEASE);
        lastSeen.entrySet().removeIf(entry -> entry.getValue().isBefore(cutoff));
        return lastSeen.entrySet().stream()
                .filter(entry -> !entry.getKey().equals(playerId))
                .filter(entry -> !entry.getValue().isBefore(cutoff))
                .count();
    }
}
