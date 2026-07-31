package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class OnlineRatingServiceTest {
    @Test
    void settlesEqualRatedWinOnceAndStoresMatchSnapshot() {
        OnlinePlayerRatingRepository repository =
                mock(OnlinePlayerRatingRepository.class);
        OnlineRatingService service = new OnlineRatingService(repository);
        UUID whiteId = UUID.randomUUID();
        UUID blackId = UUID.randomUUID();
        OnlinePlayerRating white = new OnlinePlayerRating(whiteId, "White");
        OnlinePlayerRating black = new OnlinePlayerRating(blackId, "Black");
        when(repository.lockByPlayerId(whiteId)).thenReturn(Optional.of(white));
        when(repository.lockByPlayerId(blackId)).thenReturn(Optional.of(black));
        when(repository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        OnlineMatch match =
                new OnlineMatch(UUID.randomUUID(), "CVRATE", whiteId, "White", null, false);
        match.blackPlayerId = blackId;
        match.blackPlayerName = "Black";
        match.status = OnlineMatchStatus.FINISHED;
        match.result = "1-0";

        service.settle(match);
        service.settle(match);

        assertEquals(1216, white.rating);
        assertEquals(1184, black.rating);
        assertEquals(1, white.wins);
        assertEquals(1, black.losses);
        assertEquals(1200, match.whiteRatingBefore);
        assertEquals(1216, match.whiteRatingAfter);
        assertNotNull(match.ratedAt);
        verify(repository, times(1)).saveAll(any());
    }

    @Test
    void drawUpdatesStatisticsWithoutChangingEqualRatings() {
        OnlinePlayerRatingRepository repository =
                mock(OnlinePlayerRatingRepository.class);
        OnlineRatingService service = new OnlineRatingService(repository);
        UUID whiteId = UUID.randomUUID();
        UUID blackId = UUID.randomUUID();
        OnlinePlayerRating white = new OnlinePlayerRating(whiteId, "White");
        OnlinePlayerRating black = new OnlinePlayerRating(blackId, "Black");
        when(repository.lockByPlayerId(whiteId)).thenReturn(Optional.of(white));
        when(repository.lockByPlayerId(blackId)).thenReturn(Optional.of(black));

        OnlineMatch match =
                new OnlineMatch(UUID.randomUUID(), "CVDRAW", whiteId, "White", null, false);
        match.blackPlayerId = blackId;
        match.blackPlayerName = "Black";
        match.status = OnlineMatchStatus.FINISHED;
        match.result = "1/2-1/2";

        service.settle(match);

        assertEquals(1200, white.rating);
        assertEquals(1200, black.rating);
        assertEquals(1, white.draws);
        assertEquals(1, black.draws);
    }
}
