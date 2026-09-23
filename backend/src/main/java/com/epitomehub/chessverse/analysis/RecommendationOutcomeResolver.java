package com.epitomehub.chessverse.analysis;

import java.util.UUID;
import java.sql.Timestamp;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import com.epitomehub.chessverse.engine.AiCoachMetrics;

@Component
class RecommendationOutcomeResolver {
    private final JdbcTemplate jdbc;
    private final AiCoachMetrics metrics;

    RecommendationOutcomeResolver(JdbcTemplate jdbc, AiCoachMetrics metrics) {
        this.jdbc = jdbc;
        this.metrics = metrics;
    }

    void resolveFromCompletedGame(GameAnalysisJob job) {
        Integer parity = job.playerColor == null ? null : (job.playerColor.equals("WHITE") ? 1 : 0);
        Integer averageLoss = jdbc.queryForObject(
                "select coalesce(round(avg(centipawn_loss)),0) from game_analysis_ply "
                        + "where job_id=? and (? is null or mod(ply,2)=?)",
                Integer.class, job.id, parity, parity);
        if (averageLoss == null) return;
        List<UUID> pending = jdbc.query(connection -> {
            var statement = connection.prepareStatement(
                    "select id from ai_recommendation_outcome "
                            + "where player_id=? and accepted=true and resolved_at is null and created_at < ? "
                            + "order by created_at desc limit 10");
            statement.setObject(1, job.playerId);
            statement.setTimestamp(2, Timestamp.from(job.createdAt));
            return statement;
        }, (result, row) -> result.getObject("id", UUID.class));
        int resolved = 0;
        for (UUID outcomeId : pending) {
            resolved += jdbc.update(
                    "update ai_recommendation_outcome set followup_centipawn_loss=?, resolved_at=now() where id=?",
                    averageLoss, outcomeId);
        }
        metrics.outcomesResolved(resolved);
    }
}
