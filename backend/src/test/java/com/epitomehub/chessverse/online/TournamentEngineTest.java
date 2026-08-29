package com.epitomehub.chessverse.online;

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
        jdbc.execute("create table if not exists chess_tournament(id uuid primary key,name varchar(100),description varchar(300),time_control_minutes int,capacity int,starts_at timestamp with time zone,ends_at timestamp with time zone,status varchar(16),current_round int default 0,champion_id uuid)");
        jdbc.execute("create table if not exists chess_tournament_entry(tournament_id uuid,player_id uuid,joined_at timestamp with time zone,primary key(tournament_id,player_id))");
        jdbc.execute("create table if not exists chess_tournament_round(id uuid primary key,tournament_id uuid,round_number int,status varchar(16),created_at timestamp with time zone,completed_at timestamp with time zone)");
        jdbc.execute("create table if not exists chess_tournament_pairing(id uuid primary key,round_id uuid,board_number int,white_player_id uuid,black_player_id uuid,online_match_id uuid,winner_id uuid,status varchar(16),created_at timestamp with time zone,completed_at timestamp with time zone)");
        jdbc.update("merge into chess_tournament(id,name,description,time_control_minutes,capacity,starts_at,ends_at,status,current_round) key(id) values(?,?,?,?,?,?,?,?,?)",
                UUID.fromString("22000000-0000-0000-0000-000000000001"),"Test Cup","Knockout",10,16,
                Timestamp.from(Instant.now().plusSeconds(3600)),Timestamp.from(Instant.now().plusSeconds(7200)),"OPEN",0);
    }

    @Test
    void createsBracketAndDeclaresChampionFromAuthoritativeMatch() throws Exception {
        String first=guest("71000000-0000-4000-8000-000000000001");
        String second=guest("71000000-0000-4000-8000-000000000002");
        UUID tournament=UUID.fromString("22000000-0000-0000-0000-000000000001");
        UUID firstId=UUID.fromString(json.readTree(mockMvc.perform(get("/api/auth/me").header("Authorization","Bearer "+first)).andReturn().getResponse().getContentAsString()).path("id").asText());
        UUID secondId=UUID.fromString(json.readTree(mockMvc.perform(get("/api/auth/me").header("Authorization","Bearer "+second)).andReturn().getResponse().getContentAsString()).path("id").asText());
        jdbc.update("insert into chess_tournament_entry values(?,?,?)",tournament,firstId,Timestamp.from(Instant.now()));
        jdbc.update("insert into chess_tournament_entry values(?,?,?)",tournament,secondId,Timestamp.from(Instant.now()));
        jdbc.update("update chess_tournament set starts_at=?,status='OPEN',champion_id=null,current_round=0 where id=?",
                Timestamp.from(Instant.now().minusSeconds(1)),tournament);

        var result=mockMvc.perform(get("/api/v1/community/tournaments/"+tournament)
                        .header("Authorization","Bearer "+first))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.rounds[0].pairings[0].matchId").isNotEmpty()).andReturn();
        UUID matchId=UUID.fromString(json.readTree(result.getResponse().getContentAsString())
                .path("rounds").get(0).path("pairings").get(0).path("matchId").asText());
        OnlineMatch match=matches.findById(matchId).orElseThrow();
        match.result="1-0"; match.status=OnlineMatchStatus.FINISHED;
        tournaments.recordResult(match);

        mockMvc.perform(get("/api/v1/community/tournaments/"+tournament)
                        .header("Authorization","Bearer "+first))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("FINISHED"))
                .andExpect(jsonPath("$.champion.id").value(match.whitePlayerId.toString()));
    }
    private String guest(String installation) throws Exception {var r=mockMvc.perform(post("/api/auth/guest").contentType(MediaType.APPLICATION_JSON).content("{\"installationId\":\""+installation+"\"}")) .andExpect(status().isOk()).andReturn();return json.readTree(r.getResponse().getContentAsString()).path("token").asText();}
}
