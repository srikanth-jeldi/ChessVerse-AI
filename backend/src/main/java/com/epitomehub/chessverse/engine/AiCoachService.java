package com.epitomehub.chessverse.engine;

import static com.epitomehub.chessverse.engine.AiCoachController.CoachRequest;
import static com.epitomehub.chessverse.engine.AiCoachController.CoachResponse;
import static com.epitomehub.chessverse.engine.AiCoachController.CoachImpact;
import static com.epitomehub.chessverse.engine.AiCoachController.CandidateComparison;
import static com.epitomehub.chessverse.engine.AiCoachController.BoardAnnotation;
import static com.epitomehub.chessverse.engine.AiCoachController.RecommendationOutcomeRequest;
import static com.epitomehub.chessverse.engine.EngineController.MoveReviewRequest;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HexFormat;
import java.util.Locale;
import java.util.UUID;
import java.util.List;
import java.util.LinkedHashSet;
import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.dao.EmptyResultDataAccessException;

@Service
class AiCoachService {
    private final StockfishService stockfish;
    private final AiCoachResponseCacheRepository cache;
    private final AiCoachInteractionRepository interactions;
    private final AiRecommendationOutcomeRepository outcomes;
    private final JdbcTemplate jdbc;
    private final List<CoachLanguageProvider> languageProviders;
    private final AiCoachMetrics metrics;
    private final int dailyQuota;
    private final Duration cacheTtl;
    private final Cache<String, EngineController.MoveReviewResponse> moveReviewCache;

    AiCoachService(
            StockfishService stockfish,
            AiCoachResponseCacheRepository cache,
            AiCoachInteractionRepository interactions,
            AiRecommendationOutcomeRepository outcomes,
            JdbcTemplate jdbc,
            List<CoachLanguageProvider> languageProviders,
            AiCoachMetrics metrics,
            @Value("${chessverse.coach.daily-quota:30}") int dailyQuota,
            @Value("${chessverse.coach.cache-hours:168}") long cacheHours) {
        this.stockfish = stockfish;
        this.cache = cache;
        this.interactions = interactions;
        this.outcomes = outcomes;
        this.jdbc = jdbc;
        this.languageProviders = languageProviders;
        this.metrics = metrics;
        this.dailyQuota = Math.max(1, dailyQuota);
        this.cacheTtl = Duration.ofHours(Math.max(1, cacheHours));
        this.moveReviewCache = Caffeine.newBuilder()
                .maximumSize(10_000)
                .expireAfterAccess(this.cacheTtl)
                .build();
    }

    @Transactional
    CoachResponse ask(UUID playerId, CoachRequest request) {
        metrics.request();
        Integer used;
        try {
            used = jdbc.queryForObject(
                    "with usage as (insert into ai_coach_daily_usage(player_id, usage_date, used_count) "
                            + "values (?, ?, 1) on conflict(player_id, usage_date) do update "
                            + "set used_count=ai_coach_daily_usage.used_count+1 "
                            + "where ai_coach_daily_usage.used_count < ? returning used_count) "
                            + "select used_count from usage",
                    Integer.class, playerId, LocalDate.now(java.time.ZoneOffset.UTC), dailyQuota);
        } catch (EmptyResultDataAccessException exhausted) {
            used = null;
        }
        if (used == null) {
            metrics.quotaRejected();
            throw new EngineException(HttpStatus.TOO_MANY_REQUESTS,
                    "Your daily AI Coach limit is reached. Your saved analysis remains available.");
        }

        UUID sessionId = request.sessionId() == null ? UUID.randomUUID() : request.sessionId();
        List<AiCoachInteraction> history = interactions
                .findTop10ByPlayerIdAndSessionIdOrderByCreatedAtDesc(playerId, sessionId);
        String context = conversationContext(history);
        String latestQuestion = history.isEmpty() ? "" : history.getFirst().question;
        String candidate = cleanCandidate(request.candidateMove(), request.question());
        String moveToReview = candidate == null ? request.playedMove().toLowerCase(Locale.ROOT) : candidate;
        var evidence = reviewCached(request.fen(), moveToReview);
        String normalizedQuestion = normalizeQuestion(request.question());
        String key = sha256(request.fen().trim() + "|" + moveToReview + "|" + normalizedQuestion + "|" + context);
        Instant now = Instant.now();
        AiCoachResponseCache cached = cache.findById(key)
                .filter(item -> item.expiresAt.isAfter(now))
                .orElse(null);
        boolean cacheHit = cached != null;
        if (cacheHit) metrics.cacheHit();
        String answer = cacheHit ? cached.answer : naturalAnswer(
                request, normalizedQuestion, moveToReview, candidate, evidence, context, latestQuestion);
        if (!cacheHit) {
            String engineEvidence = String.join(" ", evidence.principalVariation());
            cache.save(new AiCoachResponseCache(key, answer, engineEvidence, now, now.plus(cacheTtl)));
        }
        List<CandidateComparison> comparisons = compareCandidates(request, evidence);
        List<BoardAnnotation> annotations = annotations(evidence, candidate);
        AiCoachInteraction interaction = interactions.save(new AiCoachInteraction(
                playerId, sessionId, key, request.question().trim(), candidate, cacheHit, answer, evidence));
        int remaining = Math.max(0, dailyQuota - used);
        return new CoachResponse(
                interaction.id, sessionId, answer, evidence.classification(), evidence.bestMove(), candidate,
                evidence.centipawnLoss(), evidence.opponentThreat(), evidence.principalVariation(),
                comparisons, annotations, history.size() + 1, cacheHit, remaining);
    }

    private String naturalAnswer(CoachRequest request, String normalizedQuestion, String move,
            String candidate, EngineController.MoveReviewResponse evidence, String conversationContext,
            String latestQuestion) {
        CoachLanguageProvider provider = languageProviders.stream()
                .filter(CoachLanguageProvider::enabled)
                .findFirst()
                .orElse(null);
        if (provider != null) {
            try {
                String generated = provider.explain(new CoachLanguageProvider.CoachLanguageContext(
                        request.fen().trim(), request.question().trim(), conversationContext, move, candidate,
                        evidence.classification(), evidence.bestMove(), evidence.centipawnLoss(),
                        evidence.opponentThreat(), evidence.principalVariation()));
                if (generated != null && !generated.isBlank()) {
                    return generated.trim();
                }
            } catch (RuntimeException ignored) {
                // A language provider is optional. Stockfish-grounded structured coaching remains available.
            }
        }
        metrics.structuredFallback();
        return answer(normalizedQuestion, move, candidate, evidence, latestQuestion);
    }

    private static String conversationContext(List<AiCoachInteraction> history) {
        if (history.isEmpty()) return "";
        return history.reversed().stream().limit(6).map(turn -> {
            String question = turn.question == null ? "" : turn.question.trim();
            String response = turn.answer == null ? "" : turn.answer.trim();
            return "User: " + question.substring(0, Math.min(question.length(), 180))
                    + "\nCoach: " + response.substring(0, Math.min(response.length(), 280));
        }).reduce((left, right) -> left + "\n" + right).orElse("");
    }

    @Transactional
    void feedback(UUID playerId, UUID interactionId, boolean helpful) {
        AiCoachInteraction interaction = interactions.findById(interactionId)
                .filter(item -> item.playerId.equals(playerId))
                .orElseThrow(() -> new EngineException(HttpStatus.NOT_FOUND, "Coach interaction was not found."));
        interaction.helpful = helpful;
    }

    @Transactional
    void recordOutcome(UUID playerId, UUID interactionId, RecommendationOutcomeRequest request) {
        AiCoachInteraction interaction = interactions.findById(interactionId)
                .filter(item -> item.playerId.equals(playerId))
                .orElseThrow(() -> new EngineException(HttpStatus.NOT_FOUND, "Coach interaction was not found."));
        AiRecommendationOutcome outcome = outcomes.findByInteractionIdAndPlayerId(interactionId, playerId)
                .orElseGet(() -> new AiRecommendationOutcome(
                        playerId, interactionId, request.recommendationType(), request.openingEco(),
                        request.playerColor(), request.timeControl(), request.accepted(),
                        interaction.centipawnLoss == null ? 0 : interaction.centipawnLoss,
                        request.followupCentipawnLoss()));
        outcome.accepted = request.accepted();
        if (request.followupCentipawnLoss() != null) {
            outcome.followupCentipawnLoss = request.followupCentipawnLoss();
            outcome.resolvedAt = Instant.now();
        }
        outcomes.save(outcome);
    }

    @Transactional(readOnly = true)
    CoachImpact impact(UUID playerId) {
        Integer games = jdbc.queryForObject(
                "select count(*) from game_analysis_job where player_id = ? and status = 'COMPLETED'",
                Integer.class, playerId);
        Integer moves = jdbc.queryForObject(
                "select count(*) from game_analysis_ply p join game_analysis_job j on j.id=p.job_id "
                        + "where j.player_id=? and j.status='COMPLETED'",
                Integer.class, playerId);
        var averages = jdbc.query(
                "with ranked as (select p.centipawn_loss, row_number() over(order by j.created_at desc, p.ply desc) rn "
                        + "from game_analysis_ply p join game_analysis_job j on j.id=p.job_id "
                        + "where j.player_id=? and j.status='COMPLETED') "
                        + "select coalesce(round(avg(centipawn_loss) filter(where rn<=50)),0), "
                        + "coalesce(round(avg(centipawn_loss) filter(where rn>50 and rn<=100)),0) from ranked",
                (rs, row) -> new int[]{rs.getInt(1), rs.getInt(2)}, playerId).getFirst();
        var feedback = jdbc.query(
                "select count(helpful), coalesce(sum(case when helpful then 1 else 0 end),0) "
                        + "from ai_coach_interaction where player_id=?",
                (rs, row) -> new int[]{rs.getInt(1), rs.getInt(2)}, playerId).getFirst();
        int improvement = averages[1] <= 0 ? 0
                : Math.round(((averages[1] - averages[0]) * 100f) / averages[1]);
        int helpfulPercent = feedback[0] == 0 ? 0 : Math.round(feedback[1] * 100f / feedback[0]);
        boolean enough = games != null && games >= 10 && moves != null && moves >= 100;
        return new CoachImpact(
                games == null ? 0 : games,
                moves == null ? 0 : moves,
                averages[0], averages[1], improvement,
                feedback[0], helpfulPercent, enough,
                enough
                        ? "Measured from your latest 100 engine-reviewed moves. Lower centipawn loss means improvement."
                        : "Complete at least 10 analyzed games and 100 reviewed moves before improvement is claimed.");
    }

    private String answer(String question, String move, String candidate,
            EngineController.MoveReviewResponse evidence, String previousQuestion) {
        String best = pretty(evidence.bestMove());
        String played = pretty(move);
        String line = evidence.principalVariation().isEmpty()
                ? "No forcing continuation was returned."
                : "A concrete line is " + evidence.principalVariation().stream().limit(6).map(AiCoachService::pretty)
                        .reduce((a, b) -> a + " → " + b).orElse("") + ".";
        String memory = previousQuestion.isBlank() ? "" : "Following your earlier question, \""
                + previousQuestion.substring(0, Math.min(90, previousQuestion.length())) + "\": ";
        if (candidate != null || question.contains("what if") || question.contains("instead")) {
            return memory + "If you play " + played + ", Stockfish grades it " + evidence.classification().toLowerCase(Locale.ROOT)
                    + " with a " + evidence.centipawnLoss() + " centipawn loss. "
                    + (evidence.centipawnLoss() <= 30 ? "It is a sound practical choice. " : "The stronger move is " + best + ". ")
                    + "The opponent's most forcing reply is " + pretty(evidence.opponentThreat()) + ". " + line;
        }
        if (question.contains("threat") || question.contains("opponent")) {
            return memory + "The immediate engine threat is " + pretty(evidence.opponentThreat()) + ". " + line;
        }
        if (question.contains("simple") || question.contains("easy")) {
            return memory + (evidence.centipawnLoss() <= 30
                    ? played + " is a good move. It keeps the position under control."
                    : played + " gives the opponent a stronger reply. Prefer " + best + " and check their forcing move first.");
        }
        if (question.contains("best") || question.contains("play") || question.contains("plan")) {
            return memory + "Play " + best + ". It preserves more of your position and meets the immediate reply "
                    + pretty(evidence.opponentThreat()) + ". " + line;
        }
        return memory + played + " was graded " + evidence.classification().toLowerCase(Locale.ROOT) + ". "
                + evidence.explanation() + " " + line;
    }

    private List<CandidateComparison> compareCandidates(CoachRequest request,
            EngineController.MoveReviewResponse primary) {
        LinkedHashSet<String> moves = new LinkedHashSet<>();
        if (request.candidateMoves() != null) {
            request.candidateMoves().stream().map(value -> value.toLowerCase(Locale.ROOT)).forEach(moves::add);
        }
        if (request.candidateMove() != null && !request.candidateMove().isBlank()) {
            moves.add(request.candidateMove().toLowerCase(Locale.ROOT));
        }
        return moves.stream().limit(3).map(move -> {
            EngineController.MoveReviewResponse reviewed = move.equalsIgnoreCase(primary.playedMove())
                    ? primary
                    : reviewCached(request.fen(), move);
            return new CandidateComparison(move, reviewed.classification(), reviewed.centipawnLoss(),
                    reviewed.opponentThreat(), reviewed.principalVariation());
        }).toList();
    }

    private EngineController.MoveReviewResponse reviewCached(String fen, String move) {
        String key = sha256(fen.trim() + "|" + move.toLowerCase(Locale.ROOT) + "|8");
        EngineController.MoveReviewResponse existing = moveReviewCache.getIfPresent(key);
        if (existing != null) {
            metrics.engineReviewCacheHit();
            return existing;
        }
        return moveReviewCache.get(key,
                ignored -> stockfish.reviewMove(new MoveReviewRequest(fen, move, 8)));
    }

    private static List<BoardAnnotation> annotations(EngineController.MoveReviewResponse evidence, String candidate) {
        java.util.ArrayList<BoardAnnotation> result = new java.util.ArrayList<>();
        addArrow(result, evidence.bestMove(), "best", "Best move");
        addArrow(result, evidence.opponentThreat(), "threat", "Opponent threat");
        if (candidate != null) addArrow(result, candidate, "candidate", "Your candidate");
        return List.copyOf(result);
    }

    private static void addArrow(List<BoardAnnotation> target, String move, String kind, String label) {
        if (move != null && move.length() >= 4) {
            target.add(new BoardAnnotation(move.substring(0, 2), move.substring(2, 4), kind, label));
        }
    }

    private static String cleanCandidate(String explicit, String question) {
        if (explicit != null && !explicit.isBlank()) return explicit.trim().toLowerCase(Locale.ROOT);
        var matcher = java.util.regex.Pattern.compile("(?i)\\b([a-h][1-8][a-h][1-8][qrbn]?)\\b").matcher(question);
        return matcher.find() ? matcher.group(1).toLowerCase(Locale.ROOT) : null;
    }

    private static String normalizeQuestion(String question) {
        return question.trim().toLowerCase(Locale.ROOT).replaceAll("\\s+", " ");
    }

    private static String pretty(String move) {
        if (move == null || move.isBlank()) return "no single forcing move";
        return move.length() >= 4 ? move.substring(0, 2) + " → " + move.substring(2) : move;
    }

    private static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException(exception);
        }
    }
}
