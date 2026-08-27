package com.epitomehub.chessverse.engine;

import static com.epitomehub.chessverse.engine.AiCoachController.CoachRequest;
import static com.epitomehub.chessverse.engine.AiCoachController.CoachResponse;
import static com.epitomehub.chessverse.engine.AiCoachController.CoachImpact;
import static com.epitomehub.chessverse.engine.EngineController.MoveReviewRequest;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.HexFormat;
import java.util.Locale;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.jdbc.core.JdbcTemplate;

@Service
class AiCoachService {
    private final StockfishService stockfish;
    private final AiCoachResponseCacheRepository cache;
    private final AiCoachInteractionRepository interactions;
    private final JdbcTemplate jdbc;
    private final int dailyQuota;
    private final Duration cacheTtl;

    AiCoachService(
            StockfishService stockfish,
            AiCoachResponseCacheRepository cache,
            AiCoachInteractionRepository interactions,
            JdbcTemplate jdbc,
            @Value("${chessverse.coach.daily-quota:30}") int dailyQuota,
            @Value("${chessverse.coach.cache-hours:168}") long cacheHours) {
        this.stockfish = stockfish;
        this.cache = cache;
        this.interactions = interactions;
        this.jdbc = jdbc;
        this.dailyQuota = Math.max(1, dailyQuota);
        this.cacheTtl = Duration.ofHours(Math.max(1, cacheHours));
    }

    @Transactional
    CoachResponse ask(UUID playerId, CoachRequest request) {
        Instant startOfDay = LocalDate.now(ZoneOffset.UTC).atStartOfDay().toInstant(ZoneOffset.UTC);
        long used = interactions.countByPlayerIdAndCreatedAtAfter(playerId, startOfDay);
        if (used >= dailyQuota) {
            throw new EngineException(HttpStatus.TOO_MANY_REQUESTS,
                    "Your daily AI Coach limit is reached. Your saved analysis remains available.");
        }

        String candidate = cleanCandidate(request.candidateMove(), request.question());
        String moveToReview = candidate == null ? request.playedMove().toLowerCase(Locale.ROOT) : candidate;
        var evidence = stockfish.reviewMove(new MoveReviewRequest(request.fen(), moveToReview, 8));
        String normalizedQuestion = normalizeQuestion(request.question());
        String key = sha256(request.fen().trim() + "|" + moveToReview + "|" + normalizedQuestion);
        Instant now = Instant.now();
        AiCoachResponseCache cached = cache.findById(key)
                .filter(item -> item.expiresAt.isAfter(now))
                .orElse(null);
        boolean cacheHit = cached != null;
        String answer = cacheHit ? cached.answer : answer(normalizedQuestion, moveToReview, candidate, evidence);
        if (!cacheHit) {
            String engineEvidence = String.join(" ", evidence.principalVariation());
            cache.save(new AiCoachResponseCache(key, answer, engineEvidence, now, now.plus(cacheTtl)));
        }
        AiCoachInteraction interaction = interactions.save(
                new AiCoachInteraction(playerId, key, request.question().trim(), candidate, cacheHit));
        int remaining = Math.max(0, dailyQuota - (int) used - 1);
        return new CoachResponse(
                interaction.id, answer, evidence.classification(), evidence.bestMove(), candidate,
                evidence.centipawnLoss(), evidence.opponentThreat(), evidence.principalVariation(),
                cacheHit, remaining);
    }

    @Transactional
    void feedback(UUID playerId, UUID interactionId, boolean helpful) {
        AiCoachInteraction interaction = interactions.findById(interactionId)
                .filter(item -> item.playerId.equals(playerId))
                .orElseThrow(() -> new EngineException(HttpStatus.NOT_FOUND, "Coach interaction was not found."));
        interaction.helpful = helpful;
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

    private String answer(String question, String move, String candidate, EngineController.MoveReviewResponse evidence) {
        String best = pretty(evidence.bestMove());
        String played = pretty(move);
        String line = evidence.principalVariation().isEmpty()
                ? "No forcing continuation was returned."
                : "A concrete line is " + evidence.principalVariation().stream().limit(6).map(AiCoachService::pretty)
                        .reduce((a, b) -> a + " → " + b).orElse("") + ".";
        if (candidate != null || question.contains("what if") || question.contains("instead")) {
            return "If you play " + played + ", Stockfish grades it " + evidence.classification().toLowerCase(Locale.ROOT)
                    + " with a " + evidence.centipawnLoss() + " centipawn loss. "
                    + (evidence.centipawnLoss() <= 30 ? "It is a sound practical choice. " : "The stronger move is " + best + ". ")
                    + "The opponent's most forcing reply is " + pretty(evidence.opponentThreat()) + ". " + line;
        }
        if (question.contains("threat") || question.contains("opponent")) {
            return "The immediate engine threat is " + pretty(evidence.opponentThreat()) + ". " + line;
        }
        if (question.contains("simple") || question.contains("easy")) {
            return evidence.centipawnLoss() <= 30
                    ? played + " is a good move. It keeps the position under control."
                    : played + " gives the opponent a stronger reply. Prefer " + best + " and check their forcing move first.";
        }
        if (question.contains("best") || question.contains("play") || question.contains("plan")) {
            return "Play " + best + ". It preserves more of your position and meets the immediate reply "
                    + pretty(evidence.opponentThreat()) + ". " + line;
        }
        return played + " was graded " + evidence.classification().toLowerCase(Locale.ROOT) + ". "
                + evidence.explanation() + " " + line;
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
