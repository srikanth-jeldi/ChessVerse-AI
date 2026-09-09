package com.epitomehub.chessverse.progress;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import tools.jackson.databind.ObjectMapper;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

class ComputerGameControllerTest {
    final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    final PlayerAuthenticationService auth = mock(PlayerAuthenticationService.class);
    final ObjectMapper mapper = new ObjectMapper();
    final UUID player = UUID.randomUUID();
    final ComputerGameController controller = new ComputerGameController(auth, jdbc, mapper);

    @BeforeEach void authenticate() {
        when(auth.requireBearer("Bearer one")).thenReturn(new AuthenticatedPlayer(player, "one", "One", null));
    }
    @Test void staleDeviceCannotOverwriteSlot() throws Exception {
        var draft = mapper.readTree("{\"id\":\"game\",\"state\":{}}");
        var error = assertThrows(ResponseStatusException.class, () -> controller.update("Bearer one", new ComputerGameController.Update(7, draft)));
        assertEquals(HttpStatus.CONFLICT, error.getStatusCode());
        verify(jdbc).update(startsWith("UPDATE computer_game_slot"), eq(draft.toString()), eq(player), eq(7L));
    }
    @Test void replacementDoesNotDeleteCompletedHistory() {
        when(jdbc.update(startsWith("UPDATE computer_game_slot"), isNull(), eq(player), eq(3L))).thenReturn(1);
        controller.update("Bearer one", new ComputerGameController.Update(3, null));
        verify(jdbc, never()).update(contains("DELETE"), any(Object[].class));
    }
    @Test void invalidPayloadRejectedBeforeWriting() throws Exception {
        assertThrows(ResponseStatusException.class, () -> controller.update("Bearer one", new ComputerGameController.Update(0, mapper.readTree("[]"))));
        verifyNoInteractions(jdbc);
    }
    @Test void unauthenticatedCallerCannotReadAnotherAccount() {
        when(auth.requireBearer("bad")).thenThrow(new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        assertThrows(ResponseStatusException.class, () -> controller.get("bad"));
        verifyNoInteractions(jdbc);
    }
    @Test void staleCompletionCannotArchiveOrClearNewGame() throws Exception {
        when(jdbc.queryForObject(anyString(), eq(Long.class), eq(player), eq("game"))).thenReturn(0L);
        var draft = mapper.readTree("{\"id\":\"game\",\"state\":{\"result\":\"YOU WIN\"}}");
        assertThrows(ResponseStatusException.class, () -> controller.finish("Bearer one", new ComputerGameController.Update(7, draft)));
        verify(jdbc, never()).update(startsWith("INSERT INTO computer_game_history"), any(), any(), any());
    }
    @Test void repeatedCompletionIsIdempotentWithoutGrantingNewRevision() throws Exception {
        when(jdbc.queryForObject(anyString(), eq(Long.class), eq(player), eq("game"))).thenReturn(1L);
        var draft = mapper.readTree("{\"id\":\"game\",\"state\":{\"result\":\"YOU WIN\"}}");
        assertEquals(8, controller.finish("Bearer one", new ComputerGameController.Update(7, draft)).revision());
        verify(jdbc, never()).update(anyString(), any(Object[].class));
    }
}
