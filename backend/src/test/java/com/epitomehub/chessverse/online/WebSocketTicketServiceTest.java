package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class WebSocketTicketServiceTest {
    @Test
    void issuesOpaqueShortLivedTicketForParticipant() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        OnlineMatchService matches = mock(OnlineMatchService.class);
        UUID playerId = UUID.randomUUID(), matchId = UUID.randomUUID();
        when(matches.isParticipant(playerId, matchId)).thenReturn(true);
        var service = new WebSocketTicketService(jdbc, matches);

        var ticket = service.issue(new AuthenticatedPlayer(playerId, "p", "Player", null), matchId);

        assertTrue(ticket.ticket().length() >= 40);
        assertTrue(ticket.expiresAt().isAfter(java.time.Instant.now()));
        verify(jdbc).update(startsWith("insert into websocket_access_ticket"),
                argThat(value -> value instanceof String text && text.length() == 64),
                eq(playerId), eq(matchId), any(), any());
    }

    @Test
    void refusesTicketForNonParticipant() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        OnlineMatchService matches = mock(OnlineMatchService.class);
        var service = new WebSocketTicketService(jdbc, matches);
        assertThrows(OnlineMatchException.class, () -> service.issue(
                new AuthenticatedPlayer(UUID.randomUUID(), "p", "Player", null), UUID.randomUUID()));
        verifyNoInteractions(jdbc);
    }

    @Test
    void consumesWithSingleAtomicUpdateAndRejectsMalformedTokens() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        OnlineMatchService matches = mock(OnlineMatchService.class);
        UUID playerId = UUID.randomUUID(), matchId = UUID.randomUUID();
        when(jdbc.query(anyString(), any(org.springframework.jdbc.core.ResultSetExtractor.class),
                any(), any(), any(), any())).thenReturn(playerId);
        var service = new WebSocketTicketService(jdbc, matches);

        assertEquals(playerId, service.consume("a".repeat(43), matchId));
        assertNull(service.consume("short", matchId));
        verify(jdbc, times(1)).query(argThat(sql -> sql.contains("used_at is null")
                        && sql.contains("expires_at>?") && sql.contains("returning player_id")),
                any(org.springframework.jdbc.core.ResultSetExtractor.class),
                any(), any(), any(), any());
    }
}
