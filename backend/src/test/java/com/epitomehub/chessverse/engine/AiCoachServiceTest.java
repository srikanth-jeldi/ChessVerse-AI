package com.epitomehub.chessverse.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class AiCoachServiceTest {
    private StockfishService stockfish;
    private AiCoachResponseCacheRepository cache;
    private AiCoachInteractionRepository interactions;
    private UUID playerId;
    private JdbcTemplate jdbc;
    private AiRecommendationOutcomeRepository outcomes;
    private AiCoachMetrics metrics;

    @BeforeEach
    void setUp() {
        stockfish = mock(StockfishService.class);
        cache = mock(AiCoachResponseCacheRepository.class);
        interactions = mock(AiCoachInteractionRepository.class);
        playerId = UUID.randomUUID();
        jdbc = mock(JdbcTemplate.class);
        outcomes = mock(AiRecommendationOutcomeRepository.class);
        metrics = mock(AiCoachMetrics.class);
        when(jdbc.queryForObject(anyString(), any(Class.class), any(), any(), any())).thenReturn(1);
        when(interactions.findTop10ByPlayerIdAndSessionIdOrderByCreatedAtDesc(any(), any()))
                .thenReturn(List.of());
        when(interactions.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(cache.findById(any())).thenReturn(Optional.empty());
        when(cache.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(stockfish.reviewMove(any())).thenReturn(new EngineController.MoveReviewResponse(
                "f2f3", "g1f3", "Blunder", 286, 20, -266,
                "kingSafety", "d8h4", "The move exposes the king.",
                List.of("g1f3", "d7d5", "e2e3"), 16));
    }

    @Test
    void answersFreeTextWhatIfWithStockfishEvidence() {
        AiCoachService service = new AiCoachService(stockfish, cache, interactions, outcomes, jdbc,
                List.of(), metrics, 30, 168);
        var response = service.ask(playerId, new AiCoachController.CoachRequest(
                "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                "e2e4", "What if I play f2f3 instead?", "f2f3", null, List.of("f2f3")));

        assertThat(response.answer()).contains("f2 → f3", "286 centipawn", "g1 → f3", "d8 → h4");
        assertThat(response.candidateMove()).isEqualTo("f2f3");
        assertThat(response.remainingToday()).isEqualTo(29);
        assertThat(response.cacheHit()).isFalse();
    }

    @Test
    void enforcesPerPlayerDailyQuotaBeforeRunningStockfish() {
        when(jdbc.queryForObject(anyString(), any(Class.class), any(), any(), any())).thenReturn(null);
        AiCoachService service = new AiCoachService(stockfish, cache, interactions, outcomes, jdbc,
                List.of(), metrics, 3, 168);

        assertThatThrownBy(() -> service.ask(playerId, new AiCoachController.CoachRequest(
                "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                "e2e4", "Why?", null, null, List.of())))
                .isInstanceOf(EngineException.class)
                .hasMessageContaining("daily AI Coach limit");
    }

    @Test
    void passesPriorQuestionsAndAnswersToTheOptionalLanguageProvider() {
        UUID sessionId = UUID.randomUUID();
        EngineController.MoveReviewResponse evidence = new EngineController.MoveReviewResponse(
                "e2e4", "g1f3", "Inaccuracy", 45, 20, -25,
                "development", "d7d5", "Develop a piece.", List.of("g1f3", "d7d5"), 16);
        AiCoachInteraction prior = new AiCoachInteraction(
                playerId, sessionId, "key", "Why develop first?", null, false,
                "Because active pieces control more squares.", evidence);
        when(interactions.findTop10ByPlayerIdAndSessionIdOrderByCreatedAtDesc(playerId, sessionId))
                .thenReturn(List.of(prior));
        CoachLanguageProvider language = mock(CoachLanguageProvider.class);
        when(language.enabled()).thenReturn(true);
        when(language.explain(any())).thenReturn("The follow-up uses the earlier development plan.");
        AiCoachService service = new AiCoachService(
                stockfish, cache, interactions, outcomes, jdbc, List.of(language), metrics, 30, 168);

        var response = service.ask(playerId, new AiCoachController.CoachRequest(
                "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                "e2e4", "What should I do next?", null, sessionId, List.of()));

        ArgumentCaptor<CoachLanguageProvider.CoachLanguageContext> context =
                ArgumentCaptor.forClass(CoachLanguageProvider.CoachLanguageContext.class);
        verify(language).explain(context.capture());
        assertThat(context.getValue().previousQuestion())
                .contains("Why develop first?", "Because active pieces control more squares.");
        assertThat(response.sessionId()).isEqualTo(sessionId);
        assertThat(response.conversationTurns()).isEqualTo(2);
    }
}
