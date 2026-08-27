package com.epitomehub.chessverse.analysis;

import static com.epitomehub.chessverse.analysis.GameAnalysisDtos.*;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class AnalysisTrendsService {
    private final JdbcTemplate jdbc;

    AnalysisTrendsService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    AnalysisTrendsResponse trends(UUID playerId) {
        Map<String, WindowTrend> windows = new LinkedHashMap<>();
        for (int size : List.of(10, 30, 100)) {
            windows.put("last" + size, window(playerId, size));
        }
        List<RecommendationDimension> dimensions = new ArrayList<>();
        dimensions.addAll(dimension(playerId, "opening", "coalesce(opening_eco, 'unknown')"));
        dimensions.addAll(dimension(playerId, "color", "coalesce(player_color, 'unknown')"));
        dimensions.addAll(dimension(playerId, "timeControl", "coalesce(time_control, 'unknown')"));
        return new AnalysisTrendsResponse(windows, dimensions);
    }

    private WindowTrend window(UUID playerId, int limit) {
        String sql = "with selected_jobs as (select id from game_analysis_job "
                + "where player_id=? and status='COMPLETED' order by completed_at desc limit ?), "
                + "moves as (select p.* from game_analysis_ply p join selected_jobs j on j.id=p.job_id) "
                + "select (select count(*) from selected_jobs), count(*), "
                + "coalesce(round(avg(greatest(0,100-least(100,centipawn_loss/3.0)))),0), "
                + "coalesce(round(avg(centipawn_loss)),0), "
                + "count(*) filter(where classification='Mistake'), "
                + "count(*) filter(where classification='Blunder') from moves";
        return jdbc.query(sql, rs -> {
            rs.next();
            return new WindowTrend(rs.getInt(1), rs.getInt(2), rs.getInt(3),
                    rs.getInt(4), rs.getInt(5), rs.getInt(6));
        }, playerId, limit);
    }

    private List<RecommendationDimension> dimension(UUID playerId, String dimension, String expression) {
        String sql = "select " + expression + " value, count(*), "
                + "count(*) filter(where accepted), count(followup_centipawn_loss), "
                + "count(*) filter(where followup_centipawn_loss < baseline_centipawn_loss), "
                + "case when count(followup_centipawn_loss)=0 then 0 else round(100.0 * "
                + "count(*) filter(where followup_centipawn_loss < baseline_centipawn_loss) / "
                + "count(followup_centipawn_loss)) end "
                + "from ai_recommendation_outcome where player_id=? group by value order by count(*) desc limit 20";
        return jdbc.query(sql, (rs, row) -> new RecommendationDimension(
                dimension, rs.getString(1), rs.getInt(2), rs.getInt(3),
                rs.getInt(4), rs.getInt(5), rs.getInt(6)), playerId);
    }
}
