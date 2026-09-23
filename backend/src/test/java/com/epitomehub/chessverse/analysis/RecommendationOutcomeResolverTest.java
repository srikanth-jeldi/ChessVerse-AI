package com.epitomehub.chessverse.analysis;

import static org.assertj.core.api.Assertions.assertThat;

import com.epitomehub.chessverse.engine.AiCoachMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
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

class RecommendationOutcomeResolverTest {
    private EmbeddedDatabase database;
    private JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        database = new EmbeddedDatabaseBuilder()
                .generateUniqueName(true)
                .setType(EmbeddedDatabaseType.H2)
                .build();
        jdbc = new JdbcTemplate(database);
        jdbc.execute("create table game_analysis_ply (job_id uuid not null, ply integer not null, "
                + "centipawn_loss integer not null)");
        jdbc.execute("create table ai_recommendation_outcome (id uuid primary key, player_id uuid not null, "
                + "accepted boolean not null, baseline_centipawn_loss integer not null, "
                + "followup_centipawn_loss integer, created_at timestamp not null, resolved_at timestamp)");
    }

    @AfterEach
    void tearDown() {
        database.shutdown();
    }

    @Test
    void resolvesRecentAcceptedOutcomesWithoutUpdatingFromSameTableSubquery() {
        UUID playerId = UUID.randomUUID();
        GameAnalysisJob job = new GameAnalysisJob(
                playerId, "online-match", "start", "[]", 16, 2, "WHITE", null);
        jdbc.update("insert into game_analysis_ply(job_id, ply, centipawn_loss) values(?,?,?)",
                job.id, 1, 60);
        jdbc.update("insert into game_analysis_ply(job_id, ply, centipawn_loss) values(?,?,?)",
                job.id, 2, 20);
        UUID accepted = UUID.randomUUID();
        jdbc.update("insert into ai_recommendation_outcome(id, player_id, accepted, "
                        + "baseline_centipawn_loss, created_at) values(?,?,?,?,?)",
                accepted, playerId, true, 100, Timestamp.from(job.createdAt.minusSeconds(30)));
        jdbc.update("insert into ai_recommendation_outcome(id, player_id, accepted, "
                        + "baseline_centipawn_loss, created_at) values(?,?,?,?,?)",
                UUID.randomUUID(), playerId, false, 100, Timestamp.from(job.createdAt.minusSeconds(20)));
        jdbc.update("insert into ai_recommendation_outcome(id, player_id, accepted, "
                        + "baseline_centipawn_loss, created_at) values(?,?,?,?,?)",
                UUID.randomUUID(), playerId, true, 100, Timestamp.from(Instant.now().plusSeconds(30)));

        new RecommendationOutcomeResolver(
                jdbc, new AiCoachMetrics(new SimpleMeterRegistry())).resolveFromCompletedGame(job);

        assertThat(jdbc.queryForObject(
                "select followup_centipawn_loss from ai_recommendation_outcome where id=?",
                Integer.class, accepted)).isEqualTo(60);
        assertThat(jdbc.queryForObject(
                "select count(*) from ai_recommendation_outcome where resolved_at is not null",
                Integer.class)).isEqualTo(1);
    }
}
