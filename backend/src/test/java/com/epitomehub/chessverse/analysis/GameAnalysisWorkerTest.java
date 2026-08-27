package com.epitomehub.chessverse.analysis;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import org.mockito.ArgumentCaptor;

import java.util.Optional;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;

class GameAnalysisWorkerTest {
    private static final String START =
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    @Test
    void validatesAndPersistsACompleteGameLifecycle() {
        GameAnalysisJobRepository repository = mock(GameAnalysisJobRepository.class);
        GameAnalysisPlyRepository plies = mock(GameAnalysisPlyRepository.class);
        GamePositionAnalyzer analyzer = mock(GamePositionAnalyzer.class);
        EcoOpeningBook openings = mock(EcoOpeningBook.class);
        PlayerWeaknessEventRepository weaknessEvents = mock(PlayerWeaknessEventRepository.class);
        GameAnalysisJob job = new GameAnalysisJob(
                UUID.randomUUID(), "game-1", START, "e2e4,e7e5,g1f3", 16, 3, "WHITE", "10+0");
        AtomicReference<GameAnalysisJob> persisted = new AtomicReference<>(job);
        when(repository.findById(job.id)).thenAnswer(ignored -> Optional.ofNullable(persisted.get()));
        when(repository.save(any(GameAnalysisJob.class))).thenAnswer(invocation -> {
            GameAnalysisJob saved = invocation.getArgument(0);
            persisted.set(saved);
            return saved;
        });
        when(repository.saveAndFlush(any(GameAnalysisJob.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(plies.findByJobIdAndPly(any(UUID.class), any(Integer.class))).thenReturn(Optional.empty());
        when(plies.save(any(GameAnalysisPly.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(analyzer.analyze(any(String.class), any(String.class), any(Integer.class)))
                .thenReturn(result());
        when(openings.find(any(String.class))).thenReturn(Optional.empty());

        RecommendationOutcomeResolver outcomes = mock(RecommendationOutcomeResolver.class);
        new GameAnalysisWorker(repository, plies, analyzer, openings, weaknessEvents, outcomes).process(job.id);

        assertEquals(AnalysisJobStatus.COMPLETED, job.status);
        assertEquals(3, job.analyzedPlies);
        assertEquals(1, job.attemptCount);
        assertNotNull(job.startedAt);
        assertNotNull(job.completedAt);
        ArgumentCaptor<GameAnalysisPly> evidence = ArgumentCaptor.forClass(GameAnalysisPly.class);
        verify(plies, times(3)).save(evidence.capture());
        assertEquals(START, evidence.getAllValues().get(0).fenBefore);
        assertEquals("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
                evidence.getAllValues().get(1).fenBefore);
        assertEquals("e2e4", evidence.getAllValues().get(0).playedMove);
        assertEquals(1, evidence.getAllValues().get(0).ply);
        assertEquals(3, evidence.getAllValues().get(2).ply);
        verify(outcomes).resolveFromCompletedGame(job);
    }

    @Test
    void retryReusesPersistedPlyEvidenceAndContinuesFromTheNextPosition() {
        GameAnalysisJobRepository repository = mock(GameAnalysisJobRepository.class);
        GameAnalysisPlyRepository plies = mock(GameAnalysisPlyRepository.class);
        GamePositionAnalyzer analyzer = mock(GamePositionAnalyzer.class);
        EcoOpeningBook openings = mock(EcoOpeningBook.class);
        PlayerWeaknessEventRepository weaknessEvents = mock(PlayerWeaknessEventRepository.class);
        GameAnalysisJob job = new GameAnalysisJob(
                UUID.randomUUID(), "game-2", START, "e2e4,e7e5", 16, 2, "WHITE", "10+0");
        when(repository.findById(job.id)).thenReturn(Optional.of(job));
        when(repository.save(any(GameAnalysisJob.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(repository.saveAndFlush(any(GameAnalysisJob.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(plies.findByJobIdAndPly(job.id, 1)).thenReturn(Optional.of(
                new GameAnalysisPly(job.id, 1, START, "e2e4", result())));
        when(plies.findByJobIdAndPly(job.id, 2)).thenReturn(Optional.empty());
        when(plies.save(any(GameAnalysisPly.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(analyzer.analyze(any(String.class), any(String.class), any(Integer.class))).thenReturn(result());
        when(openings.find(any(String.class))).thenReturn(Optional.empty());

        new GameAnalysisWorker(repository, plies, analyzer, openings, weaknessEvents,
                mock(RecommendationOutcomeResolver.class)).process(job.id);

        assertEquals(AnalysisJobStatus.COMPLETED, job.status);
        verify(analyzer, times(1)).analyze(
                "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
                "e7e5", 16);
        verify(plies, times(1)).save(any(GameAnalysisPly.class));
    }

    @Test
    void illegalGameFailsWithTheExactPlyAndCanBeRetried() {
        GameAnalysisJobRepository repository = mock(GameAnalysisJobRepository.class);
        GameAnalysisPlyRepository plies = mock(GameAnalysisPlyRepository.class);
        GamePositionAnalyzer analyzer = mock(GamePositionAnalyzer.class);
        EcoOpeningBook openings = mock(EcoOpeningBook.class);
        PlayerWeaknessEventRepository weaknessEvents = mock(PlayerWeaknessEventRepository.class);
        GameAnalysisJob job = new GameAnalysisJob(
                UUID.randomUUID(), "game-3", START, "e2e4,e7e5,e2e3", 16, 3, "WHITE", "10+0");
        when(repository.findById(job.id)).thenReturn(Optional.of(job));
        when(repository.save(any(GameAnalysisJob.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(repository.saveAndFlush(any(GameAnalysisJob.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(plies.findByJobIdAndPly(any(UUID.class), any(Integer.class))).thenReturn(Optional.empty());
        when(plies.save(any(GameAnalysisPly.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(analyzer.analyze(any(String.class), any(String.class), any(Integer.class)))
                .thenReturn(result());
        when(openings.find(any(String.class))).thenReturn(Optional.empty());

        RecommendationOutcomeResolver outcomes = mock(RecommendationOutcomeResolver.class);
        new GameAnalysisWorker(repository, plies, analyzer, openings, weaknessEvents, outcomes).process(job.id);

        assertEquals(AnalysisJobStatus.FAILED, job.status);
        assertEquals("INVALID_GAME", job.errorCode);
        assertEquals("Illegal move at ply 3.", job.errorMessage);
        assertEquals(2, job.analyzedPlies);
        verify(outcomes, times(0)).resolveFromCompletedGame(job);

        job.queueForRetry();
        assertEquals(AnalysisJobStatus.QUEUED, job.status);
        assertEquals(0, job.analyzedPlies);
    }

    private static PositionAnalysis result() {
        return new PositionAnalysis("e2e4", "Best", 0, 20, 20,
                null, null, List.of("e2e4", "e7e5"), "calculation", 16);
    }
}
