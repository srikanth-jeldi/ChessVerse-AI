package com.epitomehub.chessverse.online;

import java.io.IOException;
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
    private final ConcurrentHashMap<UUID, Set<WebSocketSession>> subscribers = new ConcurrentHashMap<>();
    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        UUID matchId = (UUID) session.getAttributes().get("matchId");
        subscribers.computeIfAbsent(matchId, ignored -> ConcurrentHashMap.newKeySet()).add(session);
        publishPresence(matchId);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        UUID matchId = (UUID) session.getAttributes().get("matchId");
        Set<WebSocketSession> sessions = subscribers.get(matchId);
        if (sessions != null) {
            sessions.remove(session);
            if (sessions.isEmpty()) {
                subscribers.remove(matchId);
            } else {
                publishPresence(matchId);
            }
        }
    }

    public void publish(UUID matchId) {
        broadcast(matchId, "{\"type\":\"match.updated\",\"matchId\":\"" + matchId + "\"}");
    }

    private void publishPresence(UUID matchId) {
        Set<WebSocketSession> sessions = subscribers.get(matchId);
        if (sessions == null) return;
        long connectedPlayers = sessions.stream()
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
