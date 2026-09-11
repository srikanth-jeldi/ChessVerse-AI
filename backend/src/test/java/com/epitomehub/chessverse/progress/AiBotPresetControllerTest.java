package com.epitomehub.chessverse.progress;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;

class AiBotPresetControllerTest {
    final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    final PlayerAuthenticationService auth = mock(PlayerAuthenticationService.class);
    final UUID player = UUID.randomUUID();
    final AiBotPresetController controller = new AiBotPresetController(auth, jdbc);

    @BeforeEach void authenticate() {
        when(auth.requireBearer("Bearer one")).thenReturn(new AuthenticatedPlayer(player, "one", "One", null));
    }

    @Test void rejectsInvalidStyleBeforeWriting() {
        assertThrows(ResponseStatusException.class,
                () -> controller.save("Bearer one", new AiBotPresetController.Save("Trap", 1200, "reckless")));
        verifyNoInteractions(jdbc);
    }

    @Test void presetIsAlwaysBoundToAuthenticatedPlayer() {
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(player))).thenReturn(0);
        controller.save("Bearer one", new AiBotPresetController.Save("Attacker", 1450, "aggressive"));
        verify(jdbc).update(startsWith("INSERT INTO ai_bot_presets"), any(UUID.class), eq(player), eq("Attacker"), eq(1450), eq("aggressive"));
    }

    @Test void cannotDeleteAnotherPlayersPreset() {
        UUID preset = UUID.randomUUID();
        assertThrows(ResponseStatusException.class, () -> controller.delete("Bearer one", preset));
        verify(jdbc).update(startsWith("DELETE FROM ai_bot_presets"), eq(preset), eq(player));
    }
}
