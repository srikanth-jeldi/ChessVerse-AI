package com.epitomehub.chessverse.analytics;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class ProductAnalyticsControllerTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate db;

    @BeforeEach
    void schema() {
        db.execute("create table if not exists academy_super_admin(account_id uuid primary key)");
        db.execute("""
                create table if not exists product_analytics_event(
                id uuid primary key,player_id uuid not null,event_name varchar(48) not null,
                context_value varchar(48),occurred_at timestamp with time zone not null,
                received_at timestamp with time zone not null,unique(player_id,id))
                """);
        db.execute("""
                create table if not exists economy_transaction(
                id uuid primary key,player_id uuid not null,currency varchar(16) not null,
                amount bigint not null,balance_after bigint not null,transaction_type varchar(40) not null,
                reference_key varchar(160) not null,description varchar(160) not null,
                created_at timestamp with time zone not null,unique(player_id,reference_key))
                """);
        db.execute("""
                create table if not exists purchase_order(
                id uuid primary key,player_id uuid,product_id uuid,provider varchar(24),status varchar(24),
                idempotency_key uuid,price_minor bigint,price_currency char(3),grant_currency varchar(16),
                grant_amount bigint,created_at timestamp with time zone,updated_at timestamp with time zone,
                fulfilled_at timestamp with time zone)
                """);
        db.execute("delete from product_analytics_event");
        db.execute("delete from academy_super_admin");
    }

    @Test
    void eventIngestionIsAuthenticatedValidatedAndIdempotent() throws Exception {
        String token = guest();
        String id = UUID.randomUUID().toString();
        String body = "{\"id\":\"" + id
                + "\",\"name\":\"game_started\",\"context\":\"online\"}";
        for (int attempt = 0; attempt < 2; attempt++) {
            mvc.perform(post("/api/v1/analytics/events")
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isOk());
        }
        org.junit.jupiter.api.Assertions.assertEquals(1L,
                db.queryForObject("select count(*) from product_analytics_event", Long.class));
        mvc.perform(post("/api/v1/analytics/events")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"id\":\"" + UUID.randomUUID()
                        + "\",\"name\":\"email_captured\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void platformReportRequiresSuperAdminAndReturnsRetentionAndRevenueSignals() throws Exception {
        String token = guest();
        UUID player = UUID.fromString(json.readTree(mvc.perform(get("/api/auth/me")
                .header("Authorization", "Bearer " + token)).andReturn()
                .getResponse().getContentAsString()).path("id").asText());
        mvc.perform(post("/api/v1/analytics/events")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"id\":\"" + UUID.randomUUID()
                        + "\",\"name\":\"session_started\"}"))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/analytics/platform")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());
        db.update("insert into academy_super_admin(account_id) values(?)", player);
        mvc.perform(get("/api/v1/analytics/platform?days=30")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activeToday").value(1))
                .andExpect(jsonPath("$.activeInWindow").value(1))
                .andExpect(jsonPath("$.events[0].event_name").value("session_started"))
                .andExpect(jsonPath("$.rewardedAdsVerified").isNumber())
                .andExpect(jsonPath("$.purchases").isArray());
    }

    private String guest() throws Exception {
        var response = mvc.perform(post("/api/auth/guest")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"installationId\":\"" + UUID.randomUUID() + "\"}"))
                .andExpect(status().isOk()).andReturn();
        return json.readTree(response.getResponse().getContentAsString()).path("token").asText();
    }
}
