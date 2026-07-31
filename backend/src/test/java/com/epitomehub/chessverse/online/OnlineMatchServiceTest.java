package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class OnlineMatchServiceTest {
    private OnlineMatchRepository repository;
    private OnlineRatingService ratings;
    private OnlineMatchService service;
    private AuthenticatedPlayer white;
    private AuthenticatedPlayer black;

    @BeforeEach
    void setUp() {
        repository = mock(OnlineMatchRepository.class);
        ratings = mock(OnlineRatingService.class);
        service = new OnlineMatchService(repository, ratings);
        white = new AuthenticatedPlayer(UUID.randomUUID(), "white", "White Player", "https://example.com/white.png");
        black = new AuthenticatedPlayer(UUID.randomUUID(), "black", "Black Player", "https://example.com/black.png");
        when(repository.save(any(OnlineMatch.class))).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void secondRandomPlayerActivatesOldestWaitingMatch() {
        OnlineMatch waiting = waitingMatch();
        when(repository.findCurrentForPlayer(black.id())).thenReturn(Optional.empty());
        when(repository.lockOldestRandomOpponent(eq(black.id()), any()))
                .thenReturn(Optional.of(waiting));

        OnlineDtos.MatchDto result = service.randomMatch(black);

        assertEquals(OnlineMatchStatus.ACTIVE, result.status());
        assertEquals("black", result.yourColor());
        assertEquals("Black Player", result.blackPlayerName());
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
        assertEquals("RESIGNATION", result.resultReason());
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
    void secondRematchRequestCreatesColorSwappedMatch() {
        OnlineMatch match = activeMatch();
        match.status = OnlineMatchStatus.FINISHED;
        match.result = "1-0";
        when(repository.lockById(match.id)).thenReturn(Optional.of(match));
        when(repository.findByRoomCodeIgnoreCase(any())).thenReturn(Optional.empty());

        service.requestRematch(white, match.id);
        OnlineDtos.MatchDto rematch = service.requestRematch(black, match.id);

        assertEquals(OnlineMatchStatus.ACTIVE, rematch.status());
        assertEquals("Black Player", rematch.whitePlayerName());
        assertEquals("white", rematch.yourColor());
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

    private OnlineMatch waitingMatch() {
        return new OnlineMatch(
                UUID.randomUUID(),
                "CVTEST",
                white.id(),
                white.displayName(),
                white.photoUrl(),
                true);
    }

    private OnlineMatch activeMatch() {
        OnlineMatch match = waitingMatch();
        match.blackPlayerId = black.id();
        match.blackPlayerName = black.displayName();
        match.status = OnlineMatchStatus.ACTIVE;
        match.turnStartedAt = java.time.Instant.now();
        return match;
    }
}
