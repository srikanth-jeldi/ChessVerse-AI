package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.UUID;
import org.junit.jupiter.api.Test;

class OnlinePresenceServiceTest {
    @Test
    void countsAllAuthenticatedPlayersWithoutCountingSelfTwice() {
        OnlinePresenceService presence = new OnlinePresenceService();
        UUID android = UUID.randomUUID();
        UUID web = UUID.randomUUID();

        assertEquals(1, presence.heartbeat(android));
        assertEquals(2, presence.heartbeat(web));
        assertEquals(2, presence.heartbeat(android));
    }
}
