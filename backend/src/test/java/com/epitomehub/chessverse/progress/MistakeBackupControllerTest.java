package com.epitomehub.chessverse.progress;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MistakeBackupControllerTest {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;
    @MockitoBean PlayerAuthenticationService authentication;
    UUID owner;

    @BeforeEach void setup() {
        jdbc.execute("create table if not exists player_mistake_backup(player_id uuid references player_account(id) on delete cascade, mistake_id varchar(100), snapshot text not null, updated_at timestamp with time zone not null, primary key(player_id,mistake_id))");
        owner = account("A");
        account("B");
    }

    UUID account(String token) {
        UUID id = UUID.randomUUID();
        jdbc.update("insert into player_account(id,username,display_name,email,password_hash,verified,guest_account,failed_login_attempts,created_at,updated_at) values(?,?,?,?,?,true,false,0,current_timestamp,current_timestamp)",
                id, id.toString(), "Tester", id + "@test.invalid", "unused");
        when(authentication.requireBearer("Bearer " + token)).thenReturn(new AuthenticatedPlayer(id,"tester","Tester",null));
        return id;
    }

    Map<String,Object> item(String date, int stage) {
        return Map.of("id","1791849600000-1", "updatedAt",date,
                "game",Map.of("playedAt","2026-10-13T00:00:00Z", "moveReviews",List.of(Map.of("ply",1))),
                "practice",Map.of("stage",stage,"assistedCompletions",2));
    }

    org.springframework.test.web.servlet.ResultActions sync(String token, List<?> items) throws Exception {
        return mvc.perform(put("/api/v1/progress/mistakes").header("Authorization","Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of("items",items))));
    }

    @Test void reinstallRestoresBackupAndProgressWithoutCrossAccountLeak() throws Exception {
        sync("A",List.of(item("2026-10-12T10:00:00Z",3))).andExpect(status().isOk());
        sync("A",List.of()).andExpect(status().isOk()).andExpect(jsonPath("$.items.length()").value(1))
                .andExpect(jsonPath("$.items[0].practice.stage").value(3))
                .andExpect(jsonPath("$.items[0].practice.assistedCompletions").value(2));
        sync("B",List.of()).andExpect(status().isOk()).andExpect(jsonPath("$.items.length()").value(0));
    }

    @Test void staleDeviceAndDuplicateRetriesDoNotOverwriteNewerProgress() throws Exception {
        sync("A",List.of(item("2026-10-12T10:00:00Z",3))).andExpect(status().isOk());
        sync("A",List.of(item("2026-10-11T10:00:00Z",1))).andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].practice.stage").value(3));
        sync("A",List.of(item("2026-10-12T10:00:00Z",3))).andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1));
    }

    @Test void invalidBackupRollsBackWholeMergeAndGuestsCannotUpload() throws Exception {
        sync("A",List.of(item("2026-10-12T10:00:00Z",3),item("2099-10-12T10:00:00Z",4)))
                .andExpect(status().isBadRequest());
        sync("A",List.of()).andExpect(jsonPath("$.items.length()").value(0));
        jdbc.update("update player_account set guest_account = true where id = ?", owner);
        sync("A",List.of()).andExpect(status().isForbidden());
    }

    @Test void accountDeletionRemovesPrivateBackup() throws Exception {
        sync("A",List.of(item("2026-10-12T10:00:00Z",3))).andExpect(status().isOk());
        jdbc.update("delete from player_account where id = ?", owner);
        assertEquals(0,jdbc.queryForObject("select count(*) from player_mistake_backup where player_id = ?",Integer.class,owner));
    }
}
