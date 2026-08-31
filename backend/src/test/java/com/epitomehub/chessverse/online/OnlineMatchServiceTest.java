package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.economy.EconomyService;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class OnlineMatchServiceTest {
    private OnlineMatchRepository repository;
    private OnlineRatingService ratings;
    private OnlineMatchService service;
    private EconomyService economy;
    private AuthenticatedPlayer white;
    private AuthenticatedPlayer black;

    @BeforeEach
    void setUp() {
        repository = mock(OnlineMatchRepository.class);
        ratings = mock(OnlineRatingService.class);
        economy = mock(EconomyService.class);
        service = new OnlineMatchService(repository, ratings, null, null, economy);
        white = new AuthenticatedPlayer(UUID.randomUUID(), "white", "White Player", "https://example.com/white.png");
        black = new AuthenticatedPlayer(UUID.randomUUID(), "black", "Black Player", "https://example.com/black.png");
        when(repository.save(any(OnlineMatch.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(ratings.profile(any(AuthenticatedPlayer.class))).thenAnswer(invocation -> {
            AuthenticatedPlayer player = invocation.getArgument(0);
            return new LeaderboardDtos.PlayerRatingDto(
                    player.id(), player.displayName(), "India", 1200, 1200,
                    0, 0, 0, 0, 0, 1, 1);
        });
    }

    @Test
    void secondRandomPlayerActivatesOldestWaitingMatch() {
        OnlineMatch waiting = waitingMatch();
        when(repository.findCurrentForPlayer(black.id())).thenReturn(Optional.empty());
        when(repository.lockOldestRandomOpponent(
                eq(black.id()), any(), eq(10), eq(100), eq("WORLDWIDE"),
                eq("India"), eq(1200), eq(0)))
                .thenReturn(Optional.of(waiting));

        OnlineDtos.MatchDto result = service.randomMatch(black);

        assertEquals(OnlineMatchStatus.ACTIVE, result.status());
        assertEquals("black", result.yourColor());
        assertEquals("Black Player", result.blackPlayerName());
        assertNotNull(result.startedAt());
        assertEquals(100, result.entryCoins());
        assertEquals(200, result.rewardPoolCoins());
        verify(economy).spend(eq(black.id()), eq("COINS"), eq(100L),
                eq("MATCH_ENTRY_RESERVED"), any(), eq("Online match entry reserved"));
    }

    @Test
    void rejectsMoveFromPlayerWhoseTurnHasNotStarted() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        OnlineMatchException error =
                assertThrows(OnlineMatchException.class, () -> service.move(black, match.id, "e7e5", 0));

        assertEquals(HttpStatus.CONFLICT, error.status());
        assertEquals(0, match.moves.size());
    }

    @Test
    void validatesLegalMoveAndAdvancesAuthoritativeTurn() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        OnlineDtos.MatchDto result = service.move(white, match.id, "e2e4", 0);

        assertEquals(1, result.moves().size());
        assertEquals("black", result.activeColor());
        assertEquals("e2e4", result.moves().getFirst().uci());
    }

    @Test
    void blackCanMoveImmediatelyAfterWhiteAndTurnReturnsToWhite() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        service.move(white, match.id, "e2e4", 0);
        OnlineDtos.MatchDto result = service.move(black, match.id, "e7e5", 1);

        assertEquals(2, result.moves().size());
        assertEquals("white", result.activeColor());
        assertEquals("e7e5", result.moves().get(1).uci());
    }

    @Test
    void rejectsStaleSimultaneousMoveUsingExpectedPly() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        service.move(white, match.id, "e2e4", 0);
        OnlineMatchException error =
                assertThrows(OnlineMatchException.class, () -> service.move(black, match.id, "e7e5", 0));

        assertEquals(HttpStatus.CONFLICT, error.status());
        assertEquals(1, match.moves.size());
    }

    @Test
    void authoritativeReconnectReturnsCurrentBoardMovesAndClock() {
        OnlineMatch match = activeMatch();
        match.moves.add("e2e4");
        match.activeColor = "black";
        match.fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1";
        when(repository.findCurrentForPlayer(white.id())).thenReturn(Optional.of(match));

        OnlineDtos.MatchDto result = service.reconnect(white);

        assertEquals(OnlineMatchStatus.ACTIVE, result.status());
        assertEquals("black", result.activeColor());
        assertEquals("e2e4", result.moves().getFirst().uci());
        assertEquals(match.fen, result.fen());
    }

    @Test
    void foolsMateFinishesAsCheckmate() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        service.move(white, match.id, "f2f3", 0);
        service.move(black, match.id, "e7e5", 1);
        service.move(white, match.id, "g2g4", 2);
        OnlineDtos.MatchDto result = service.move(black, match.id, "d8h4", 3);

        assertEquals(OnlineMatchStatus.FINISHED, result.status());
        assertEquals("0-1", result.result());
        assertEquals("CHECKMATE", result.resultReason());
    }

    @Test
    void rejectsIllegalChessMove() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        OnlineMatchException error =
                assertThrows(OnlineMatchException.class, () -> service.move(white, match.id, "e2e5", 0));

        assertEquals(HttpStatus.UNPROCESSABLE_ENTITY, error.status());
        assertEquals(0, match.moves.size());
    }

    @Test
    void cancellingWaitingMatchRemovesItFromReconnectFlow() {
        OnlineMatch match = waitingMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        OnlineDtos.MatchDto result = service.cancelWaiting(white, match.id);

        assertEquals(OnlineMatchStatus.CANCELLED, result.status());
    }

    @Test
    void resignationFinishesMatchWithOpponentWin() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        OnlineDtos.MatchDto result = service.resign(white, match.id);

        assertEquals(OnlineMatchStatus.FINISHED, result.status());
        assertEquals("0-1", result.result());
        verify(economy).grantCoins(eq(white.id()), eq(20L), eq("MATCH_COMPLETED"), any(), eq("Match completion reward"));
        verify(economy).grantCoins(eq(black.id()), eq(20L), eq("MATCH_COMPLETED"), any(), eq("Match completion reward"));
        verify(economy).grantCoins(eq(black.id()), eq(30L), eq("MATCH_WON"), any(), eq("Match victory bonus"));
        assertEquals("RESIGNATION", result.resultReason());
        assertNotNull(result.finishedAt());
        assertNotNull(result.durationSeconds());
    }

    @Test
    void opponentCanAcceptDrawOffer() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        OnlineDtos.MatchDto offered = service.offerDraw(white, match.id);
        OnlineDtos.MatchDto accepted = service.respondDraw(black, match.id, true);

        assertEquals("white", offered.drawOfferedByColor());
        assertEquals("1/2-1/2", accepted.result());
        assertEquals("DRAW_AGREEMENT", accepted.resultReason());
    }

    @Test
    void opponentCanDeclineDrawOffer() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        service.offerDraw(white, match.id);
        OnlineDtos.MatchDto declined = service.respondDraw(black, match.id, false);

        assertEquals(OnlineMatchStatus.ACTIVE, declined.status());
        assertNull(declined.drawOfferedByColor());
    }

    @Test
    void pendingOpponentDrawOfferCannotBeOverwritten() {
        OnlineMatch match = activeMatch();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        service.offerDraw(white, match.id);
        OnlineMatchException error =
                assertThrows(OnlineMatchException.class, () -> service.offerDraw(black, match.id));

        assertEquals(HttpStatus.CONFLICT, error.status());
        assertEquals(white.id(), match.drawOfferedBy);
    }

    @Test
    void secondRematchRequestCreatesColorSwappedMatch() {
        OnlineMatch match = activeMatch();
        match.timeControlMinutes = 5;
        match.whiteTimeMs = 5 * 60 * 1000L;
        match.blackTimeMs = 5 * 60 * 1000L;
        match.status = OnlineMatchStatus.FINISHED;
        match.result = "1-0";
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));
        when(repository.findByRoomCodeIgnoreCase(any())).thenReturn(Optional.empty());

        service.requestRematch(white, match.id);
        OnlineDtos.MatchDto rematch = service.requestRematch(black, match.id);

        assertEquals(OnlineMatchStatus.ACTIVE, rematch.status());
        assertEquals("Black Player", rematch.whitePlayerName());
        assertEquals("white", rematch.yourColor());
        assertEquals(5 * 60 * 1000L, rematch.whiteTimeMs());
        assertEquals(5 * 60 * 1000L, rematch.blackTimeMs());
    }

    @Test
    void expiredActiveClockFinishesMatch() {
        OnlineMatch match = activeMatch();
        match.whiteTimeMs = 1;
        match.turnStartedAt = java.time.Instant.now().minusSeconds(2);
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        OnlineDtos.MatchDto result = service.get(white, match.id);

        assertEquals(OnlineMatchStatus.FINISHED, result.status());
        assertEquals("0-1", result.result());
        assertEquals("TIMEOUT", result.resultReason());
    }

    @Test
    void reconnectWithinGraceClearsDisconnectDeadline() {
        OnlineMatch match = activeMatch();
        match.blackDisconnectedAt = java.time.Instant.now();
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        service.markConnected(match.id, black.id());

        assertNull(match.blackDisconnectedAt);
    }

    @Test
    void expiredDisconnectedPlayerLosesMatch() {
        OnlineMatch match = activeMatch();
        match.blackDisconnectedAt = java.time.Instant.now().minusSeconds(61);
        when(repository.lockExpiredDisconnects(any())).thenReturn(java.util.List.of(match));

        java.util.List<UUID> finished = service.finishExpiredDisconnects();

        assertEquals(java.util.List.of(match.id), finished);
        assertEquals(OnlineMatchStatus.FINISHED, match.status);
        assertEquals("1-0", match.result);
        assertEquals("OPPONENT_LEFT", match.resultReason);
        verify(ratings).settle(match);
    }

    @Test
    void queueReservesSelectedEntryBeforeSearching() {
        when(repository.findCurrentForPlayer(white.id())).thenReturn(Optional.empty());
        when(repository.lockOldestRandomOpponent(
                eq(white.id()), any(), eq(10), eq(500), eq("WORLDWIDE"),
                eq("India"), eq(1200), eq(0))).thenReturn(Optional.empty());

        OnlineDtos.MatchDto queued = service.randomMatch(white,
                new OnlineDtos.QueueRequest(10, "WORLDWIDE", 0, 500));

        assertEquals(OnlineMatchStatus.WAITING, queued.status());
        assertEquals(500, queued.entryCoins());
        assertEquals(1000, queued.rewardPoolCoins());
        verify(economy).spend(eq(white.id()), eq("COINS"), eq(500L),
                eq("MATCH_ENTRY_RESERVED"), any(), eq("Online match entry reserved"));
    }

    @Test
    void cancellingQueueReturnsReservedEntry() {
        OnlineMatch waiting = waitingMatch();
        waiting.entryCoins = 200;
        when(repository.lockById(waiting.id)).thenReturn(Optional.of(waiting));

        OnlineDtos.MatchDto cancelled = service.cancelWaiting(white, waiting.id);

        assertEquals(OnlineMatchStatus.CANCELLED, cancelled.status());
        verify(economy).grantCoins(eq(white.id()), eq(200L),
                eq("MATCH_ENTRY_RELEASED"), any(),
                eq("Cancelled matchmaking entry returned"));
    }

    @Test
    void completedRankedMatchAwardsTheTwoHundredCoinPoolOnce() {
        OnlineMatch match = activeMatch();
        match.entryCoins = 100;
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));

        service.move(white, match.id, "f2f3", 0);
        service.move(black, match.id, "e7e5", 1);
        service.move(white, match.id, "g2g4", 2);
        OnlineDtos.MatchDto result = service.move(black, match.id, "d8h4", 3);

        assertEquals(200, result.coinsEarned());
        verify(economy).grantCoins(eq(black.id()), eq(200L),
                eq("RANKED_MATCH_POOL"), any(), eq("Ranked match coin pool"));
    }

    @Test
    void challengeCannotReplaceAnActiveMatch() {
        OnlineMatch match = activeMatch();
        when(repository.findCurrentForPlayer(white.id())).thenReturn(Optional.of(match));

        OnlineMatchException error = assertThrows(
                OnlineMatchException.class,
                () -> service.createChallengeRoom(white, 10));

        assertEquals(HttpStatus.CONFLICT, error.status());
        assertEquals(OnlineMatchStatus.ACTIVE, match.status);
    }

    @Test
    void challengeReplacesAStaleWaitingQueueWithPrivateTimedRoom() {
        OnlineMatch queued = waitingMatch();
        when(repository.findCurrentForPlayer(white.id())).thenReturn(Optional.of(queued));
        when(repository.findByRoomCodeIgnoreCase(any())).thenReturn(Optional.empty());

        OnlineDtos.MatchDto result = service.createChallengeRoom(white, 5);

        assertEquals(OnlineMatchStatus.CANCELLED, queued.status);
        assertEquals(OnlineMatchStatus.WAITING, result.status());
        assertEquals(5 * 60 * 1000L, result.whiteTimeMs());
    }

    private OnlineMatch waitingMatch() {
        OnlineMatch match = new OnlineMatch(
                UUID.randomUUID(),
                "CVTEST",
                white.id(),
                white.displayName(),
                white.photoUrl(),
                true);
        match.entryCoins = 100;
        return match;
    }

    private OnlineMatch activeMatch() {
        OnlineMatch match = waitingMatch();
        match.entryCoins = 0;
        match.blackPlayerId = black.id();
        match.blackPlayerName = black.displayName();
        match.status = OnlineMatchStatus.ACTIVE;
        match.startedAt = java.time.Instant.now();
        match.turnStartedAt = match.startedAt;
        return match;
    }
}
