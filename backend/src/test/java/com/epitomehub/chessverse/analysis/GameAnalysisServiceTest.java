package com.epitomehub.chessverse.analysis;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.mockito.ArgumentCaptor;

import com.epitomehub.chessverse.analysis.GameAnalysisDtos.CreateRequest;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.core.task.TaskRejectedException;

class GameAnalysisServiceTest {
    private static final String START =
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    @Test
    void duplicateClientRequestReturnsTheOriginalJobWithoutDispatchingTwice() {
        UUID player = UUID.randomUUID();
        GameAnalysisJobRepository jobs = mock(GameAnalysisJobRepository.class);
        GameAnalysisWorker worker = mock(GameAnalysisWorker.class);
        GameAnalysisPlyRepository plies = mock(GameAnalysisPlyRepository.class);
        PlayerWeaknessEventRepository events = mock(PlayerWeaknessEventRepository.class);
        GameAnalysisJob existing = new GameAnalysisJob(
                player, "device-game-1", START, "e2e4", 16, 1, "WHITE", "10+0");
        when(jobs.findByPlayerIdAndClientRequestId(player, "device-game-1"))
                .thenReturn(Optional.of(existing));

        GameAnalysisDtos.JobResponse response = new GameAnalysisService(jobs, worker, plies, events)
                .create(player, new CreateRequest(
                        "device-game-1", START, List.of("e2e4"), 16, "WHITE", "10+0"));

        assertEquals(existing.id, response.id());
        verify(worker, never()).process(existing.id);
    }

    @Test
    void onePlayerCannotReadAnotherPlayersAnalysis() {
        GameAnalysisJobRepository jobs = mock(GameAnalysisJobRepository.class);
        GameAnalysisService service = new GameAnalysisService(jobs,
                mock(GameAnalysisWorker.class), mock(GameAnalysisPlyRepository.class),
                mock(PlayerWeaknessEventRepository.class));
        UUID player = UUID.randomUUID();
        UUID foreignJob = UUID.randomUUID();
        when(jobs.findByIdAndPlayerId(foreignJob, player)).thenReturn(Optional.empty());

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.get(player, foreignJob));
        assertEquals(404, exception.getStatusCode().value());
    }

    @Test
    void fullQueuePersistsARecoverableFailureInsteadOfLosingTheJob() {
        UUID player = UUID.randomUUID();
        GameAnalysisJobRepository jobs = mock(GameAnalysisJobRepository.class);
        GameAnalysisWorker worker = mock(GameAnalysisWorker.class);
        GameAnalysisPlyRepository plies = mock(GameAnalysisPlyRepository.class);
        PlayerWeaknessEventRepository events = mock(PlayerWeaknessEventRepository.class);
        when(jobs.findByPlayerIdAndClientRequestId(player, "queue-test"))
                .thenReturn(Optional.empty());
        when(jobs.saveAndFlush(org.mockito.ArgumentMatchers.any()))
                .thenAnswer(invocation -> invocation.getArgument(0));
        doThrow(new TaskRejectedException("full")).when(worker)
                .process(org.mockito.ArgumentMatchers.any());

        GameAnalysisDtos.JobResponse response = new GameAnalysisService(jobs, worker, plies, events)
                .create(player, new CreateRequest(
                        "queue-test", START, List.of("e2e4"), 16, "WHITE", "10+0"));

        assertEquals(AnalysisJobStatus.FAILED, response.status());
        assertEquals("QUEUE_CAPACITY", response.errorCode());
        verify(jobs).save(org.mockito.ArgumentMatchers.any());
    }

    @Test
    void importedSanMovesAreValidatedAndStoredAsIndividualUciMoves() {
        UUID player = UUID.randomUUID();
        GameAnalysisJobRepository jobs = mock(GameAnalysisJobRepository.class);
        GameAnalysisWorker worker = mock(GameAnalysisWorker.class);
        when(jobs.findByPlayerIdAndClientRequestId(player, "pgn-1"))
                .thenReturn(Optional.empty());
        when(jobs.saveAndFlush(any(GameAnalysisJob.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        GameAnalysisService service = new GameAnalysisService(jobs, worker,
                mock(GameAnalysisPlyRepository.class), mock(PlayerWeaknessEventRepository.class));

        service.create(player, new CreateRequest(
                "pgn-1", START, List.of(), 16, "WHITE", null,
                "PGN", "Chess.com", "[Event \"Live Chess\"]", "{}",
                "White", "Black", "1-0", List.of("e4", "e5", "Nf3")));

        ArgumentCaptor<GameAnalysisJob> saved = ArgumentCaptor.forClass(GameAnalysisJob.class);
        verify(jobs).saveAndFlush(saved.capture());
        assertEquals("e2e4,e7e5,g1f3", saved.getValue().movesJson);
        assertEquals("PGN", saved.getValue().sourceFormat);
        assertEquals("[Event \"Live Chess\"]", saved.getValue().originalPgn);
    }
}
