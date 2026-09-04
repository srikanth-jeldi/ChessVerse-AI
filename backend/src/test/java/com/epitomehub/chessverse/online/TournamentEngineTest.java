package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TournamentEngineTest {
    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired OnlineMatchRepository matches;
    @Autowired TournamentService tournaments;

    @BeforeEach
    void schema() {
        jdbc.execute("create table if not exists chess_tournament(id uuid primary key,name varchar(100),description varchar(300),time_control_minutes int,capacity int,starts_at timestamp with time zone,ends_at timestamp with time zone,status varchar(16),current_round int default 0,champion_id uuid,runner_up_id uuid,entry_coins int default 100,series_code varchar(32),occurrence_number int default 1,cadence_days int default 0,minimum_players int default 2,badge_code varchar(48),champion_bonus int default 0,runner_up_bonus int default 0,participation_bonus int default 0)");
        jdbc.execute("create table if not exists chess_tournament_entry(tournament_id uuid,player_id uuid,joined_at timestamp with time zone,active boolean default true,reserved_coins int default 0,reservation_id uuid,refunded_at timestamp with time zone,primary key(tournament_id,player_id))");
        jdbc.execute("create table if not exists chess_tournament_round(id uuid primary key,tournament_id uuid,round_number int,status varchar(16),created_at timestamp with time zone,completed_at timestamp with time zone)");
        jdbc.execute("create table if not exists chess_tournament_pairing(id uuid primary key,round_id uuid,board_number int,white_player_id uuid,black_player_id uuid,online_match_id uuid,winner_id uuid,status varchar(16),created_at timestamp with time zone,completed_at timestamp with time zone)");
        jdbc.execute("create table if not exists player_wallet(player_id uuid primary key,coin_balance bigint default 500,diamond_balance bigint default 10,coin_debt bigint default 0,created_at timestamp with time zone,updated_at timestamp with time zone)");
        jdbc.execute("create table if not exists economy_transaction(id uuid primary key,player_id uuid,currency varchar(16),amount bigint,balance_after bigint,transaction_type varchar(40),reference_key varchar(160),description varchar(160),created_at timestamp with time zone,unique(player_id,reference_key))");
        jdbc.execute("create table if not exists player_tournament_badge(player_id uuid,tournament_id uuid,badge_code varchar(48),placement varchar(20),awarded_at timestamp with time zone,primary key(player_id,tournament_id,badge_code))");
        jdbc.execute("create table if not exists player_notification(id uuid primary key,player_id uuid,type varchar(40),title varchar(120),body varchar(360),action_type varchar(32),action_id uuid,created_at timestamp with time zone,read_at timestamp with time zone)");
        jdbc.execute("create table if not exists chess_club(id uuid primary key,name varchar(80),description varchar(240),rating_requirement int,created_at timestamp with time zone)");
        jdbc.execute("create table if not exists chess_club_member(club_id uuid,player_id uuid,role varchar(16),joined_at timestamp with time zone,primary key(club_id,player_id))");
        jdbc.execute("create table if not exists direct_message(id uuid primary key,sender_id uuid,recipient_id uuid,body varchar(500),sent_at timestamp with time zone,read_at timestamp with time zone,delivered_at timestamp with time zone,attachment_name varchar(255),attachment_type varchar(120),attachment_size bigint,attachment_path varchar(255))");
        jdbc.execute("create table if not exists fair_play_signal(id uuid primary key,player_id uuid,match_id uuid,signal_type varchar(40),severity int,evidence varchar(500),created_at timestamp with time zone)");
        jdbc.update("merge into chess_tournament(id,name,description,time_control_minutes,capacity,starts_at,ends_at,status,current_round,entry_coins,badge_code,champion_bonus,runner_up_bonus,participation_bonus) key(id) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                UUID.fromString("22000000-0000-0000-0000-000000000001"),"Test Cup","Knockout",10,16,
                Timestamp.from(Instant.now().plusSeconds(3600)),Timestamp.from(Instant.now().plusSeconds(7200)),"OPEN",0,100,
                "TEST_CUP_BADGE",50,25,10);
    }

    @Test
    void createsBracketAndDeclaresChampionFromAuthoritativeMatch() throws Exception {
        String first=guest("71000000-0000-4000-8000-000000000001");
        String second=guest("71000000-0000-4000-8000-000000000002");
        UUID tournament=UUID.fromString("22000000-0000-0000-0000-000000000001");
        UUID firstId=UUID.fromString(json.readTree(mockMvc.perform(get("/api/auth/me").header("Authorization","Bearer "+first)).andReturn().getResponse().getContentAsString()).path("id").asText());
        UUID secondId=UUID.fromString(json.readTree(mockMvc.perform(get("/api/auth/me").header("Authorization","Bearer "+second)).andReturn().getResponse().getContentAsString()).path("id").asText());
        mockMvc.perform(put("/api/v1/community/tournaments/"+tournament+"?join=true")
                        .header("Authorization","Bearer "+first)).andExpect(status().isOk());
        mockMvc.perform(put("/api/v1/community/tournaments/"+tournament+"?join=true")
                        .header("Authorization","Bearer "+second)).andExpect(status().isOk());
        assertEquals(600L, jdbc.queryForObject("select coin_balance from player_wallet where player_id=?",Long.class,firstId));
        assertEquals(600L, jdbc.queryForObject("select coin_balance from player_wallet where player_id=?",Long.class,secondId));
        jdbc.update("update chess_tournament set starts_at=?,status='OPEN',champion_id=null,current_round=0 where id=?",
                Timestamp.from(Instant.now().minusSeconds(1)),tournament);

        var result=mockMvc.perform(get("/api/v1/community/tournaments/"+tournament)
                        .header("Authorization","Bearer "+first))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.rounds[0].pairings[0].matchId").isNotEmpty()).andReturn();
        UUID matchId=UUID.fromString(json.readTree(result.getResponse().getContentAsString())
                .path("rounds").get(0).path("pairings").get(0).path("matchId").asText());
        OnlineMatch match=matches.findById(matchId).orElseThrow();
        match.result="1/2-1/2"; match.resultReason="BOTH_DISCONNECTED";
        match.status=OnlineMatchStatus.FINISHED;
        tournaments.recordResult(match);
        UUID replayId=jdbc.queryForObject("select online_match_id from chess_tournament_pairing where round_id in (select id from chess_tournament_round where tournament_id=?)",UUID.class,tournament);
        org.junit.jupiter.api.Assertions.assertNotEquals(matchId,replayId);
        assertEquals(600L, jdbc.queryForObject("select coin_balance from player_wallet where player_id=?",Long.class,firstId));
        OnlineMatch replay=matches.findById(replayId).orElseThrow();
        replay.result="1-0"; replay.resultReason="CHECKMATE"; replay.status=OnlineMatchStatus.FINISHED;
        tournaments.recordResult(replay);

        mockMvc.perform(get("/api/v1/community/tournaments/"+tournament)
                        .header("Authorization","Bearer "+first))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("FINISHED"))
                .andExpect(jsonPath("$.champion.id").value(replay.whitePlayerId.toString()))
                .andExpect(jsonPath("$.prizePool").value(200));
        assertEquals(860L, jdbc.queryForObject("select coin_balance from player_wallet where player_id=?",Long.class,replay.whitePlayerId));
        assertEquals(635L, jdbc.queryForObject("select coin_balance from player_wallet where player_id=?",Long.class,replay.blackPlayerId));
        assertEquals(1, jdbc.queryForObject("select count(*) from player_tournament_badge where player_id=? and placement='CHAMPION'",Integer.class,replay.whitePlayerId));
        assertEquals(1, jdbc.queryForObject("select count(*) from player_tournament_badge where player_id=? and placement='RUNNER_UP'",Integer.class,replay.blackPlayerId));
    }
    private String guest(String installation) throws Exception {var r=mockMvc.perform(post("/api/auth/guest").contentType(MediaType.APPLICATION_JSON).content("{\"installationId\":\""+installation+"\"}")) .andExpect(status().isOk()).andReturn();return json.readTree(r.getResponse().getContentAsString()).path("token").asText();}
}
