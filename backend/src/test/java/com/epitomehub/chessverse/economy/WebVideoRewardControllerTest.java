package com.epitomehub.chessverse.economy;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class WebVideoRewardControllerTest {
    private final UUID player = UUID.fromString("00000000-0000-4000-8000-000000000001");
    private final EconomyService economy = mock(EconomyService.class);
    private final WebVideoRewardController controller = new WebVideoRewardController(economy, "test-key", "42");
    private static final String SIGNATURE = "561707328b1cb0f9fecc89329c547dfca675a9ebecfa7da049e616981e3c24e6";

    @Test
    void acceptsSignedPlacementReceipt() throws Exception {
        controller.reward("42", player, "video-1", SIGNATURE);
        verify(economy).grantVerifiedVideo(player, "ayet:video-1");
    }

    @Test
    void rejectsChangedPlayerOrTransactionOrSlot() {
        assertThrows(ResponseStatusException.class, () -> controller.reward("42", UUID.randomUUID(), "video-1", SIGNATURE));
        assertThrows(ResponseStatusException.class, () -> controller.reward("42", player, "video-2", SIGNATURE));
        assertThrows(ResponseStatusException.class, () -> controller.reward("41", player, "video-1", SIGNATURE));
        verifyNoInteractions(economy);
    }
}
