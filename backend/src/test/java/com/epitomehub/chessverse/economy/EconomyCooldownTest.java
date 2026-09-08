package com.epitomehub.chessverse.economy;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class EconomyCooldownTest {
    @Test
    void freeCoinDropRefreshesEveryEightHours() {
        assertEquals(8, EconomyService.FREE_COIN_COOLDOWN_HOURS);
    }
}
