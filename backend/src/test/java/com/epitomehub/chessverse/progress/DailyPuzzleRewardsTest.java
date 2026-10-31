package com.epitomehub.chessverse.progress;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.time.*;
import java.util.*;

class DailyPuzzleRewardsTest {
    @Test void cycleRestartsAfterSevenDays() {
        assertEquals(List.of(10,15,20,25,30,35,40,10,15), java.util.stream.IntStream.rangeClosed(1,9).mapToObj(DailyPuzzleRewards::coins).toList());
    }
    @Test void missedDayResetsAndDuplicateDifficultiesDoNotExtendStreak() {
        LocalDate day = LocalDate.of(2026,10,29);
        var ids = List.of("2026-10-27-v8-medium-001", "2026-10-29-v8-medium-002", "2026-10-29-v8-hard-001");
        assertEquals(1, DailyPuzzleRewards.streak(ids,day));
        assertEquals(1, DailyPuzzleRewards.streak(ids,day.plusDays(1)));
        assertEquals(0, DailyPuzzleRewards.streak(ids,day.plusDays(2)));
    }
    @Test void onlyCorrectDatedSolutionCanClaim() {
        LocalDate today = LocalDate.of(2026,10,29);
        var puzzle = DailyPuzzleRewards.puzzle(today,false);
        String id = today + "-v8-" + puzzle.id();
        assertTrue(DailyPuzzleRewards.eligible(id,puzzle.moves(),today));
        assertTrue(DailyPuzzleRewards.eligible(id,puzzle.moves(),today.plusDays(6)));
        assertFalse(DailyPuzzleRewards.eligible(id,puzzle.moves(),today.plusDays(7)));
        assertFalse(DailyPuzzleRewards.eligible(id,List.of("a2a3"),today));
        assertFalse(DailyPuzzleRewards.eligible(id,null,today));
        assertFalse(DailyPuzzleRewards.eligible(id,puzzle.moves(),today.minusDays(1)));
    }
    @Test void catalogueRequiresAtLeastThreePlayerMoves() {
        for (boolean hard : List.of(false,true)) for (int i=0;i<200;i++) {
            var puzzle = DailyPuzzleRewards.puzzle(LocalDate.of(2026,1,1).plusDays(i),hard);
            assertTrue(puzzle.moves().size()>=5);
        }
    }
}
