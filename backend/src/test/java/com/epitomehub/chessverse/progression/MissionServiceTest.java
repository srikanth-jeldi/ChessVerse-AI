package com.epitomehub.chessverse.progression;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.economy.EconomyService;
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

class MissionServiceTest {
    private EmbeddedDatabase database;
    private JdbcTemplate jdbc;
    private EconomyService economy;
    private MissionService service;
    private AuthenticatedPlayer player;

    @BeforeEach
    void setUp() {
        database = new EmbeddedDatabaseBuilder().generateUniqueName(true)
                .setType(EmbeddedDatabaseType.H2).build();
        jdbc = new JdbcTemplate(database);
        economy = mock(EconomyService.class);
        service = new MissionService(jdbc, economy);
        player = new AuthenticatedPlayer(UUID.randomUUID(), "mission-player", "Mission Player", null);
        jdbc.execute("create table online_match (id uuid primary key, status varchar(20), "
                + "white_player_id uuid, black_player_id uuid, result varchar(10), finished_at timestamp, "
                + "tournament_name varchar(160))");
        jdbc.execute("create table player_mission_claim (player_id uuid not null, mission_code varchar(50) not null, "
                + "period_start date not null, reward_coins integer not null, claimed_at timestamp not null, "
                + "primary key(player_id, mission_code, period_start))");
    }

    @AfterEach
    void tearDown() {
        database.shutdown();
    }

    @Test
    void calculatesDailyWeeklyAndTournamentProgressFromVerifiedMatches() {
        jdbc.update("insert into online_match(id,status,white_player_id,result,finished_at,tournament_name) "
                        + "values(?,?,?,?,?,?)", UUID.randomUUID(), "FINISHED", player.id(), "1-0",
                Timestamp.from(Instant.now()), "Hyderabad Royal Cup");

        MissionDtos.MissionBoardDto board = service.board(player);

        assertThat(board.daily()).allSatisfy(mission -> assertThat(mission.completed()).isTrue());
        assertThat(board.weekly()).filteredOn(mission -> mission.code().equals("WEEKLY_TOURNAMENT"))
                .allSatisfy(mission -> assertThat(mission.completed()).isTrue());

        assertThat(board.daily()).filteredOn(mission -> mission.code().equals("DAILY_PLAY"))
                .allSatisfy(mission -> {
                    assertThat(mission.progress()).isEqualTo(1);
                    assertThat(mission.rewardCoins()).isEqualTo(25);
                    assertThat(mission.claimed()).isFalse();
                });
    }
}
