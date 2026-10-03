package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;

class FirebasePushServiceTest {
    @Test
    void blocksAllPushesDuringIndiaQuietHours() {
        assertTrue(FirebasePushService.isQuietHours(at("2026-10-03T16:30:00Z"))); // 22:00 IST
        assertTrue(FirebasePushService.isQuietHours(at("2026-10-04T01:29:59Z"))); // 06:59 IST
        assertFalse(FirebasePushService.isQuietHours(at("2026-10-04T01:30:00Z"))); // 07:00 IST
        assertFalse(FirebasePushService.isQuietHours(at("2026-10-03T16:29:59Z"))); // 21:59 IST
    }

    private Clock at(String instant) {
        return Clock.fixed(Instant.parse(instant), ZoneOffset.UTC);
    }
}
