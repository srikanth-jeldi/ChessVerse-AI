package com.epitomehub.chessverse.economy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class PremiumSubscriptionControllerTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate db;

    @BeforeEach
    void schema() {
        db.execute("""
                create table if not exists premium_entitlement(
                player_id uuid primary key,status varchar(16) not null,source varchar(24) not null,
                product_id varchar(80),base_plan_id varchar(80),started_at timestamp with time zone not null,
                expires_at timestamp with time zone not null,auto_renewing boolean not null,
                provider_token_hash char(64),updated_at timestamp with time zone not null,
                unique(source,provider_token_hash))
                """);
        db.execute("""
                create table if not exists premium_trial_installation(
                installation_hash char(64) primary key,player_id uuid not null,
                claimed_at timestamp with time zone not null)
                """);
        db.execute("""
                create table if not exists premium_plan_catalog(
                base_plan_id varchar(80) primary key,product_id varchar(80) not null,
                billing_period varchar(16) not null,india_price_minor bigint not null,
                currency char(3) not null,active boolean not null,updated_at timestamp with time zone not null)
                """);
        db.update("delete from premium_trial_installation");
        db.update("delete from premium_entitlement");
        db.update("delete from premium_plan_catalog");
        db.update("""
                insert into premium_plan_catalog values
                ('monthly','chessverse_premium','MONTHLY',9900,'INR',true,current_timestamp),
                ('yearly','chessverse_premium','YEARLY',99900,'INR',true,current_timestamp)
                """);
    }

    @Test
    void trialIsGrantedOncePerAccountAndInstallation() throws Exception {
        String first = guest();
        String second = guest();
        String sharedInstallation = UUID.randomUUID().toString();

        mvc.perform(post("/api/v1/subscriptions/trial")
                .header("Authorization", "Bearer " + first)
                .header("X-Device-Id", sharedInstallation))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.premium").value(true))
                .andExpect(jsonPath("$.status").value("TRIAL"))
                .andExpect(jsonPath("$.trialDays").value(7));

        mvc.perform(post("/api/v1/subscriptions/trial")
                .header("Authorization", "Bearer " + first)
                .header("X-Device-Id", UUID.randomUUID().toString()))
                .andExpect(status().isConflict());

        mvc.perform(post("/api/v1/subscriptions/trial")
                .header("Authorization", "Bearer " + second)
                .header("X-Device-Id", sharedInstallation))
                .andExpect(status().isConflict());
    }

    @Test
    void statusPublishesLaunchPlansWithoutStartingTrial() throws Exception {
        String token = guest();
        mvc.perform(get("/api/v1/subscriptions")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.premium").value(false))
                .andExpect(jsonPath("$.status").value("NONE"))
                .andExpect(jsonPath("$.plans[0].indiaPriceMinor").value(9900))
                .andExpect(jsonPath("$.plans[1].indiaPriceMinor").value(99900));
    }

    private String guest() throws Exception {
        var response = mvc.perform(post("/api/auth/guest")
                .contentType("application/json")
                .content("{\"installationId\":\"" + UUID.randomUUID() + "\"}"))
                .andExpect(status().isOk()).andReturn();
        return json.readTree(response.getResponse().getContentAsString()).path("token").asText();
    }
}
