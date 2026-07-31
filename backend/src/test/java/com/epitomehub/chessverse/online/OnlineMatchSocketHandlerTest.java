package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.when;

import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

class OnlineMatchSocketHandlerTest {
    @Test
    void updateEventIsBroadcastToBothConnectedPlayers() throws Exception {
        UUID matchId = UUID.randomUUID();
        WebSocketSession white = session(matchId);
        WebSocketSession black = session(matchId);
        OnlineMatchSocketHandler handler = new OnlineMatchSocketHandler();
        handler.afterConnectionEstablished(white);
        handler.afterConnectionEstablished(black);

        handler.publish(matchId);

        ArgumentCaptor<TextMessage> whiteMessage = ArgumentCaptor.forClass(TextMessage.class);
        ArgumentCaptor<TextMessage> blackMessage = ArgumentCaptor.forClass(TextMessage.class);
        verify(white, atLeastOnce()).sendMessage(whiteMessage.capture());
        verify(black, atLeastOnce()).sendMessage(blackMessage.capture());
        assertTrue(whiteMessage.getAllValues().stream()
                .anyMatch(message -> message.getPayload().contains(matchId.toString())));
        assertTrue(blackMessage.getAllValues().stream()
                .anyMatch(message -> message.getPayload().contains("match.updated")));
    }

    private WebSocketSession session(UUID matchId) {
        WebSocketSession session = mock(WebSocketSession.class);
        when(session.getAttributes()).thenReturn(
                Map.of("matchId", matchId, "playerId", UUID.randomUUID()));
        when(session.isOpen()).thenReturn(true);
        return session;
    }
}
