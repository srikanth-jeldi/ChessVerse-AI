package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class OnlinePresenceServiceTest {
    @Test
    void countsAllAuthenticatedPlayersWithoutCountingSelfTwice() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        OnlinePresenceService presence = new OnlinePresenceService(
                jdbc, mock(PlayerNotificationService.class));
        UUID android = UUID.randomUUID();
        UUID web = UUID.randomUUID();

        assertEquals(1, presence.heartbeat(android));
        assertEquals(2, presence.heartbeat(web));
        assertEquals(2, presence.heartbeat(android));
        verify(jdbc, times(2)).queryForObject(
                eq("select display_name from player_account where id=?"), eq(String.class),
                any(UUID.class));
    }
}
