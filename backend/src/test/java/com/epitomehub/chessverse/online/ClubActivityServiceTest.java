package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.time.LocalDate;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ClubActivityServiceTest {
    final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    final ClubActivityService service = new ClubActivityService(jdbc, mock(OnlinePresenceService.class));

    @Test void allTwoHundredPuzzlesHaveLegalCompleteLines() {
        Set<String> ids = new HashSet<>();
        for (int n=0;n<200;n++) {
            var puzzle = service.puzzle(LocalDate.ofEpochDay(n));
            ids.add(puzzle.id());
            List<String> moves = new ArrayList<>();
            for (int i=0;i<puzzle.moves().size();i+=2) {
                moves.add(puzzle.moves().get(i));
                var result = ClubActivityService.evaluate(puzzle,moves);
                assertTrue(result.correct(),puzzle.id());
                assertEquals(i+2>=puzzle.moves().size(),result.completed(),puzzle.id());
            }
            assertFalse(ClubActivityService.evaluate(puzzle,List.of("a1a1")).correct());
        }
        assertEquals(200,ids.size());
    }
    @Test void rotationIsStableAndWeeksStartMonday() {
        var day = LocalDate.of(2026,10,18);
        assertEquals(LocalDate.of(2026,10,12),ClubActivityService.weekStart(day));
        assertEquals(service.puzzle(day),service.puzzle(day.plusDays(200)));
        assertThrows(OnlineMatchException.class,()->ClubActivityService.evaluate(service.puzzle(day),List.of()));
    }
    @Test void nonMembersCannotSubmitOrReadActivities() {
        var player = new AuthenticatedPlayer(UUID.randomUUID(),"test","Test",null);
        var club = UUID.randomUUID();
        assertThrows(OnlineMatchException.class,()->service.attempt(player,club,LocalDate.now(ClubActivityService.ZONE),List.of("e2e4")));
        assertThrows(OnlineMatchException.class,()->service.detail(player,club));
        verify(jdbc,never()).update(anyString(),any(Object[].class));
    }
    @Test void completedAttemptsUseIdempotentInsertAndStaleDaysAreRejected() {
        var player = new AuthenticatedPlayer(UUID.randomUUID(),"test","Test",null);
        var club = UUID.randomUUID();
        when(jdbc.queryForObject(anyString(),eq(Boolean.class),eq(club),eq(player.id()))).thenReturn(true);
        var day = LocalDate.now(ClubActivityService.ZONE);
        var puzzle = service.puzzle(day);
        List<String> moves = new ArrayList<>();
        for(int i=0;i<puzzle.moves().size();i+=2) moves.add(puzzle.moves().get(i));
        assertThrows(OnlineMatchException.class,()->service.attempt(player,club,day.minusDays(1),moves));
        assertTrue(service.attempt(player,club,day,moves).completed());
        assertTrue(service.attempt(player,club,day,moves).completed());
        verify(jdbc,times(2)).update(eq("insert into club_daily_completion(club_id,player_id,puzzle_day) values (?,?,?) on conflict do nothing"),eq(club),eq(player.id()),eq(java.sql.Date.valueOf(day)));
    }
}
