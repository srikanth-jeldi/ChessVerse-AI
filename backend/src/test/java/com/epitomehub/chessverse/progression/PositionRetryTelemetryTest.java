package com.epitomehub.chessverse.progression;

import static org.mockito.Mockito.*;
import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class PositionRetryTelemetryTest {
    @Test void noOptInMeansNoStoredTelemetry() {
        var db=mock(JdbcTemplate.class);var auth=mock(PlayerAuthenticationService.class);
        UUID player=UUID.randomUUID();
        when(auth.requireBearer("token")).thenReturn(new AuthenticatedPlayer(player,"student","student",null));
        when(db.queryForObject(anyString(),eq(Integer.class),eq(player))).thenReturn(0);
        new PuzzleSprintController(auth,db).positionRetry("token",new PuzzleSprintController.PositionRetryRequest(UUID.randomUUID(),false));
        verify(db,never()).update(anyString(),any(),any(),any());
    }
    @Test void authenticatedIdentityAndClientEventIdAreUsedForDeduplication() {
        var db=mock(JdbcTemplate.class);var auth=mock(PlayerAuthenticationService.class);
        UUID player=UUID.randomUUID(),event=UUID.randomUUID();
        when(auth.requireBearer("token")).thenReturn(new AuthenticatedPlayer(player,"student","student",null));
        when(db.queryForObject(anyString(),eq(Integer.class),eq(player))).thenReturn(1);
        new PuzzleSprintController(auth,db).positionRetry("token",new PuzzleSprintController.PositionRetryRequest(event,true));
        verify(db).update("INSERT INTO player_position_retry(id,player_id,correct) VALUES(?,?,?) ON CONFLICT (id) DO NOTHING",event,player,true);
    }
}
