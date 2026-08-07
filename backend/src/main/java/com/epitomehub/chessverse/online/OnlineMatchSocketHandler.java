package com.epitomehub.chessverse.online;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class OnlineMatchSocketHandler extends TextWebSocketHandler {
    static final Duration PRESENCE_LEASE = Duration.ofSeconds(5);
    private final ConcurrentHashMap<UUID, Set<WebSocketSession>> subscribers = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<WebSocketSession, Instant> lastSeen = new ConcurrentHashMap<>();
    private final OnlineMatchService matches;

    public OnlineMatchSocketHandler(OnlineMatchService matches) {
        this.matches = matches;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        UUID matchId = (UUID) session.getAttributes().get("matchId");
        UUID playerId = (UUID) session.getAttributes().get("playerId");
        subscribers.computeIfAbsent(matchId, ignored -> ConcurrentHashMap.newKeySet()).add(session);
        lastSeen.put(session, Instant.now());
        matches.markConnected(matchId, playerId);
        publishPresence(matchId);
        publish(matchId);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        // Application heartbeats make presence deterministic even when a
        // browser tab or mobile process is killed without a TCP close frame.
        lastSeen.put(session, Instant.now());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        UUID matchId = (UUID) session.getAttributes().get("matchId");
        UUID playerId = (UUID) session.getAttributes().get("playerId");
        lastSeen.remove(session);
        Set<WebSocketSession> sessions = subscribers.get(matchId);
        if (sessions != null) {
            sessions.remove(session);
            boolean playerStillConnected = sessions.stream().anyMatch(candidate ->
                    playerId.equals(candidate.getAttributes().get("playerId")) && candidate.isOpen());
            if (!playerStillConnected) {
                // Start the full abandonment grace period when the server
                // detects the disconnect. The last heartbeat can be several
                // seconds old and must not silently shorten the reconnect
                // window for a killed/backgrounded mobile process.
                matches.markDisconnected(matchId, playerId, Instant.now());
            }
            if (sessions.isEmpty()) {
                subscribers.remove(matchId);
            } else {
                publishPresence(matchId);
                publish(matchId);
            }
        }
    }

    void pruneStaleSessions(Instant now) {
        Instant cutoff = now.minus(PRESENCE_LEASE);
        for (var entry : subscribers.entrySet()) {
            UUID matchId = entry.getKey();
            Set<WebSocketSession> sessions = entry.getValue();
            boolean changed = false;
            for (WebSocketSession session : Set.copyOf(sessions)) {
                Instant heartbeat = lastSeen.get(session);
                if (session.isOpen() && heartbeat != null && heartbeat.isAfter(cutoff)) continue;
                UUID playerId = (UUID) session.getAttributes().get("playerId");
                sessions.remove(session);
                lastSeen.remove(session);
                changed = true;
                boolean playerStillConnected = sessions.stream().anyMatch(candidate ->
                        playerId.equals(candidate.getAttributes().get("playerId"))
                                && isFresh(candidate, now));
                if (!playerStillConnected) {
                    // The lease expiry is the detection point. Starting the
                    // grace period at the old heartbeat made users lose while
                    // a cold app launch was still reconnecting.
                    matches.markDisconnected(matchId, playerId, now);
                }
                try {
                    if (session.isOpen()) session.close(CloseStatus.SESSION_NOT_RELIABLE);
                } catch (IOException ignored) {
                    // The stale session is already removed from presence.
                }
            }
            if (sessions.isEmpty()) subscribers.remove(matchId, sessions);
            if (changed) {
                publishPresence(matchId);
                publish(matchId);
            }
        }
    }

    private boolean isFresh(WebSocketSession session, Instant now) {
        Instant heartbeat = lastSeen.get(session);
        return session.isOpen() && heartbeat != null
                && heartbeat.isAfter(now.minus(PRESENCE_LEASE));
    }

    public long connectedPlayerCount() {
        Instant now = Instant.now();
        return subscribers.values().stream()
                .flatMap(Set::stream)
                .filter(session -> isFresh(session, now))
                .map(session -> session.getAttributes().get("playerId"))
                .filter(UUID.class::isInstance)
                .map(UUID.class::cast)
                .distinct()
                .count();
    }

    public void publish(UUID matchId) {
        broadcast(matchId, "{\"type\":\"match.updated\",\"matchId\":\"" + matchId + "\"}");
    }

    private void publishPresence(UUID matchId) {
        Set<WebSocketSession> sessions = subscribers.get(matchId);
        if (sessions == null) return;
        Instant now = Instant.now();
        long connectedPlayers = sessions.stream()
                .filter(session -> isFresh(session, now))
                .map(session -> session.getAttributes().get("playerId"))
                .filter(UUID.class::isInstance)
                .distinct()
                .count();
        broadcast(matchId,
                "{\"type\":\"presence.updated\",\"matchId\":\"" + matchId
                        + "\",\"connectedPlayers\":" + connectedPlayers + "}");
    }

    private void broadcast(UUID matchId, String payload) {
        Set<WebSocketSession> sessions = subscribers.get(matchId);
        if (sessions == null) return;
        TextMessage event = new TextMessage(payload);
        for (WebSocketSession session : Set.copyOf(sessions)) {
            if (!session.isOpen()) continue;
            try {
                // Match updates, presence changes and controller responses may
                // publish from different request threads. A standard Spring
                // WebSocketSession permits only one send at a time.
                synchronized (session) {
                    if (session.isOpen()) session.sendMessage(event);
                }
            } catch (IOException | IllegalStateException ignored) {
                try {
                    session.close(CloseStatus.SERVER_ERROR);
                } catch (IOException ignoredAgain) {
                    // Connection cleanup happens through afterConnectionClosed.
                }
            }
        }
    }
}
