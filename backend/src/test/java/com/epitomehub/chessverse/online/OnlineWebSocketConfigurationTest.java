package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class OnlineWebSocketConfigurationTest {
    @Test
    void parsesExplicitOriginAllowList() {
        assertArrayEquals(new String[]{"https://chessverseai.com", "http://localhost:*"},
                OnlineWebSocketConfiguration.parseAllowedOrigins(
                        " https://chessverseai.com, http://localhost:* "));
    }

    @Test
    void rejectsGlobalWildcardAndEmptyConfiguration() {
        assertThrows(IllegalArgumentException.class,
                () -> OnlineWebSocketConfiguration.parseAllowedOrigins("*"));
        assertThrows(IllegalArgumentException.class,
                () -> OnlineWebSocketConfiguration.parseAllowedOrigins("  "));
    }
}
