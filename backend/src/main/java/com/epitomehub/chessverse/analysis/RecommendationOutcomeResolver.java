package com.epitomehub.chessverse.analysis;

import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
class RecommendationOutcomeResolver {
    private final JdbcTemplate jdbc;

    RecommendationOutcomeResolver(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    void resolveFromCompletedGame(GameAnalysisJob job) {
        Integer parity = job.playerColor == null ? null : (job.playerColor.equals("WHITE") ? 1 : 0);
        Integer averageLoss = jdbc.queryForObject(
                "select coalesce(round(avg(centipawn_loss)),0) from game_analysis_ply "
                        + "where job_id=? and (? is null or mod(ply,2)=?)",
                Integer.class, job.id, parity, parity);
        if (averageLoss == null) return;
        jdbc.update(
                "update ai_recommendation_outcome set followup_centipawn_loss=?, resolved_at=now() "
                        + "where id in (select id from ai_recommendation_outcome "
                        + "where player_id=? and accepted=true and resolved_at is null and created_at < ? "
                        + "order by created_at desc limit 10)",
                averageLoss, job.playerId, job.createdAt);
    }
}
