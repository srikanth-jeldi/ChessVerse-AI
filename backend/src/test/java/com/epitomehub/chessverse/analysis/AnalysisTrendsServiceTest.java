package com.epitomehub.chessverse.analysis;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.embedded.EmbeddedDatabase;
import org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseBuilder;
import org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseType;

class AnalysisTrendsServiceTest {
    private EmbeddedDatabase database;
    private JdbcTemplate jdbc;
    private UUID playerId;

    @BeforeEach
    void setUp() {
        database = new EmbeddedDatabaseBuilder()
                .generateUniqueName(true)
                .setType(EmbeddedDatabaseType.H2)
                .build();
        jdbc = new JdbcTemplate(database);
        playerId = UUID.randomUUID();
        jdbc.execute("create table game_analysis_job (id uuid primary key, player_id uuid not null, "
                + "status varchar(20) not null, completed_at timestamp)");
        jdbc.execute("create table game_analysis_ply (job_id uuid not null, centipawn_loss integer not null, "
                + "classification varchar(20) not null)");
        jdbc.execute("create table ai_recommendation_outcome (player_id uuid not null, opening_eco varchar(3), "
                + "player_color varchar(10), time_control varchar(20), accepted boolean not null, "
                + "baseline_centipawn_loss integer not null, followup_centipawn_loss integer)");
    }

    @AfterEach
    void tearDown() {
        database.shutdown();
    }

    @Test
    void calculatesTenThirtyHundredGameWindowsAndRecommendationDimensions() {
        Instant base = Instant.parse("2026-08-01T00:00:00Z");
        for (int index = 1; index <= 12; index++) {
            UUID jobId = UUID.randomUUID();
            jdbc.update("insert into game_analysis_job(id, player_id, status, completed_at) values(?,?,?,?)",
                    jobId, playerId, "COMPLETED", Timestamp.from(base.plusSeconds(index)));
            jdbc.update("insert into game_analysis_ply(job_id, centipawn_loss, classification) values(?,?,?)",
                    jobId, index * 10, index % 4 == 0 ? "Blunder" : index % 3 == 0 ? "Mistake" : "Best");
        }
        UUID other = UUID.randomUUID();
        jdbc.update("insert into game_analysis_job(id, player_id, status, completed_at) values(?,?,?,?)",
                UUID.randomUUID(), other, "COMPLETED", Timestamp.from(base.plusSeconds(99)));
        insertOutcome("B20", "white", "10+0", true, 120, 60);
        insertOutcome("B20", "white", "10+0", true, 100, 130);
        insertOutcome("C50", "black", "5+0", false, 80, null);

        var trends = new AnalysisTrendsService(jdbc).trends(playerId);

        assertThat(trends.windows()).containsOnlyKeys("last10", "last30", "last100");
        assertThat(trends.windows().get("last10").games()).isEqualTo(10);
        assertThat(trends.windows().get("last10").moves()).isEqualTo(10);
        assertThat(trends.windows().get("last30").games()).isEqualTo(12);
        assertThat(trends.windows().get("last100").games()).isEqualTo(12);
        assertThat(trends.recommendationOutcomes())
                .anySatisfy(item -> {
                    assertThat(item.dimension()).isEqualTo("opening");
                    assertThat(item.value()).isEqualTo("B20");
                    assertThat(item.recommendations()).isEqualTo(2);
                    assertThat(item.accepted()).isEqualTo(2);
                    assertThat(item.resolved()).isEqualTo(2);
                    assertThat(item.improved()).isEqualTo(1);
                    assertThat(item.successPercent()).isEqualTo(50);
                })
                .anySatisfy(item -> {
                    assertThat(item.dimension()).isEqualTo("timeControl");
                    assertThat(item.value()).isEqualTo("10+0");
                    assertThat(item.successPercent()).isEqualTo(50);
                });
    }

    private void insertOutcome(String eco, String color, String timeControl,
            boolean accepted, int baseline, Integer followup) {
        jdbc.update("insert into ai_recommendation_outcome(player_id, opening_eco, player_color, time_control, "
                        + "accepted, baseline_centipawn_loss, followup_centipawn_loss) values(?,?,?,?,?,?,?)",
                playerId, eco, color, timeControl, accepted, baseline, followup);
    }
}
