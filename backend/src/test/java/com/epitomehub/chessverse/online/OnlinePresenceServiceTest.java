package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.UUID;
import org.junit.jupiter.api.Test;

class OnlinePresenceServiceTest {
    @Test
    void countsOtherAuthenticatedPlayersWithoutCountingSelfTwice() {
        OnlinePresenceService presence = new OnlinePresenceService();
        UUID android = UUID.randomUUID();
        UUID web = UUID.randomUUID();

        assertEquals(0, presence.heartbeat(android));
        assertEquals(1, presence.heartbeat(web));
        assertEquals(1, presence.heartbeat(android));
    }
}
