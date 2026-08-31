package com.epitomehub.chessverse.economy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class EconomyControllerTest {
    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired EconomyService economy;
    @Autowired PurchaseService purchases;

    @BeforeEach
    void schema() {
        jdbc.execute("create table if not exists player_wallet(player_id uuid primary key,coin_balance bigint not null,diamond_balance bigint not null,created_at timestamp with time zone not null,updated_at timestamp with time zone not null)");
        jdbc.execute("alter table player_wallet add column if not exists coin_debt bigint default 0 not null");
        jdbc.execute("create table if not exists economy_transaction(id uuid primary key,player_id uuid not null,currency varchar(16) not null,amount bigint not null,balance_after bigint not null,transaction_type varchar(40) not null,reference_key varchar(160) not null,description varchar(160) not null,created_at timestamp with time zone not null,unique(player_id,reference_key))");
        jdbc.execute("create table if not exists cosmetic_item(id uuid primary key,slug varchar(80),category varchar(24),name varchar(80),description varchar(200),price_currency varchar(16),price_amount bigint,primary_color varchar(9),secondary_color varchar(9),asset_key varchar(120),sort_order int,active boolean)");
        jdbc.execute("create table if not exists player_cosmetic_inventory(player_id uuid,item_id uuid,acquired_at timestamp with time zone,primary key(player_id,item_id))");
        jdbc.execute("create table if not exists player_cosmetic_loadout(player_id uuid primary key,board_item_id uuid,pieces_item_id uuid,effect_item_id uuid,frame_item_id uuid,updated_at timestamp with time zone)");
        jdbc.execute("create table if not exists purchase_product(id uuid primary key,sku varchar(80) unique,display_name varchar(100),description varchar(220),grant_currency varchar(16),grant_amount bigint,price_minor bigint,price_currency char(3),active boolean,sort_order int,created_at timestamp with time zone,updated_at timestamp with time zone)");
        jdbc.execute("create table if not exists purchase_order(id uuid primary key,player_id uuid,product_id uuid,provider varchar(24),status varchar(24),idempotency_key uuid,price_minor bigint,price_currency char(3),grant_currency varchar(16),grant_amount bigint,provider_order_id varchar(180),provider_transaction_hash char(64),failure_code varchar(80),created_at timestamp with time zone,updated_at timestamp with time zone,verified_at timestamp with time zone,fulfilled_at timestamp with time zone,unique(player_id,idempotency_key),unique(provider,provider_transaction_hash))");
        jdbc.execute("create table if not exists purchase_reversal(order_id uuid primary key,player_id uuid,coins_revoked bigint,coin_debt_added bigint,provider_event_hash char(64),created_at timestamp with time zone)");
        jdbc.execute("create table if not exists purchase_provider_event(id uuid primary key,provider varchar(24),event_id_hash char(64),event_type varchar(80),payload_hash char(64),processing_status varchar(24),received_at timestamp with time zone,processed_at timestamp with time zone,unique(provider,event_id_hash))");
        jdbc.execute("merge into cosmetic_item key(id) values('41000000-0000-0000-0000-000000000001','royal-walnut','BOARD','Royal Walnut','Classic','FREE',0,'#E7D6B0','#6E4128',null,10,true)");
        jdbc.execute("merge into cosmetic_item key(id) values('42000000-0000-0000-0000-000000000001','classic-staunton','PIECES','Classic Staunton','Classic','FREE',0,'#FFFFFF','#111111','staunton',10,true)");
        jdbc.execute("merge into cosmetic_item key(id) values('41000000-0000-0000-0000-000000000099','test-board','BOARD','Test Board','Test purchase','COINS',300,'#EEEEEE','#333333',null,99,true)");
        jdbc.execute("merge into purchase_product key(id) values('43000000-0000-0000-0000-000000000001','test_coins','Test Coins','Test pack','COINS',500,38000,'INR',true,1,current_timestamp,current_timestamp)");
    }

    @Test
    void createsWelcomeWalletOnceAndReturnsImmutableHistory() throws Exception {
        String token = guest(UUID.randomUUID().toString());

        mockMvc.perform(get("/api/v1/economy/wallet").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.coins").value(500))
                .andExpect(jsonPath("$.diamonds").value(10));
        mockMvc.perform(get("/api/v1/economy/wallet").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/v1/economy/history").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.transactions.length()").value(2));
    }

    @Test
    void idempotentRewardCannotBeClaimedTwice() throws Exception {
        String token = guest(UUID.randomUUID().toString());
        UUID playerId = UUID.fromString(json.readTree(mockMvc.perform(get("/api/auth/me")
                .header("Authorization", "Bearer " + token)).andReturn().getResponse().getContentAsString()).path("id").asText());

        org.junit.jupiter.api.Assertions.assertTrue(economy.grantCoins(playerId, 100, "REWARDED_AD", "ad:tx-1", "Rewarded video"));
        org.junit.jupiter.api.Assertions.assertFalse(economy.grantCoins(playerId, 100, "REWARDED_AD", "ad:tx-1", "Rewarded video"));
        mockMvc.perform(get("/api/v1/economy/wallet").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.coins").value(600));
    }

    @Test
    void purchaseIsPermanentAndDuplicateRequestDoesNotChargeTwice() throws Exception {
        String token = guest(UUID.randomUUID().toString());
        String authorization = "Bearer " + token;
        String item = "41000000-0000-0000-0000-000000000099";
        mockMvc.perform(post("/api/v1/shop/items/" + item + "/purchase").header("Authorization", authorization))
                .andExpect(status().isOk()).andExpect(jsonPath("$.wallet.coins").value(200))
                .andExpect(jsonPath("$.items[1].owned").value(true));
        mockMvc.perform(post("/api/v1/shop/items/" + item + "/purchase").header("Authorization", authorization))
                .andExpect(status().isOk()).andExpect(jsonPath("$.wallet.coins").value(200));
        mockMvc.perform(put("/api/v1/shop/loadout/BOARD").header("Authorization", authorization)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"itemId\":\"" + item + "\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.items[1].equipped").value(true));
    }

    @Test
    void realMoneyOrderUsesServerPriceAndIsIdempotent() throws Exception {
        String token = guest(UUID.randomUUID().toString());
        String authorization = "Bearer " + token;
        String product = "43000000-0000-0000-0000-000000000001";
        String key = UUID.randomUUID().toString();
        String request = "{\"productId\":\"" + product + "\",\"idempotencyKey\":\"" + key
                + "\",\"provider\":\"GOOGLE_PLAY\",\"priceMinor\":1}";
        String first = mockMvc.perform(post("/api/v1/purchases/orders").header("Authorization", authorization)
                        .contentType(MediaType.APPLICATION_JSON).content(request))
                .andExpect(status().isOk()).andExpect(jsonPath("$.priceMinor").value(38000))
                .andExpect(jsonPath("$.status").value("CREATED"))
                .andReturn().getResponse().getContentAsString();
        String second = mockMvc.perform(post("/api/v1/purchases/orders").header("Authorization", authorization)
                        .contentType(MediaType.APPLICATION_JSON).content(request))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        org.junit.jupiter.api.Assertions.assertEquals(json.readTree(first).path("id").asText(),
                json.readTree(second).path("id").asText());
    }

    @Test
    void disabledWebGatewayFailsClosedWithoutAttemptingPayment() throws Exception {
        String token = guest(UUID.randomUUID().toString());
        String request = "{\"productId\":\"43000000-0000-0000-0000-000000000001\","
                + "\"idempotencyKey\":\"" + UUID.randomUUID() + "\",\"provider\":\"RAZORPAY\"}";
        mockMvc.perform(post("/api/v1/purchases/orders").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content(request))
                .andExpect(status().isServiceUnavailable());
    }

    @Test
    void verifiedReceiptCreditsCoinsOnceAndNeverStoresRawTransactionId() throws Exception {
        String token = guest(UUID.randomUUID().toString());
        UUID playerId = UUID.fromString(json.readTree(mockMvc.perform(get("/api/auth/me")
                .header("Authorization", "Bearer " + token)).andReturn().getResponse().getContentAsString()).path("id").asText());
        String request = "{\"productId\":\"43000000-0000-0000-0000-000000000001\","
                + "\"idempotencyKey\":\"" + UUID.randomUUID() + "\",\"provider\":\"GOOGLE_PLAY\"}";
        UUID orderId = UUID.fromString(json.readTree(mockMvc.perform(post("/api/v1/purchases/orders")
                        .header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content(request))
                .andReturn().getResponse().getContentAsString()).path("id").asText());

        purchases.fulfillVerified(playerId, orderId, "GOOGLE_PLAY", "test_coins", "raw-secret-token-123");
        purchases.fulfillVerified(playerId, orderId, "GOOGLE_PLAY", "test_coins", "raw-secret-token-123");

        mockMvc.perform(get("/api/v1/economy/wallet").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.coins").value(1000));
        String stored = jdbc.queryForObject("select provider_transaction_hash from purchase_order where id=?",
                String.class, orderId);
        org.junit.jupiter.api.Assertions.assertNotEquals("raw-secret-token-123", stored);
        org.junit.jupiter.api.Assertions.assertEquals(64, stored.length());
    }

    @Test
    void unconfiguredGoogleVerifierFailsClosedAndDoesNotCreditCoins() throws Exception {
        String token = guest(UUID.randomUUID().toString());
        String authorization = "Bearer " + token;
        String request = "{\"productId\":\"43000000-0000-0000-0000-000000000001\","
                + "\"idempotencyKey\":\"" + UUID.randomUUID() + "\",\"provider\":\"GOOGLE_PLAY\"}";
        UUID orderId = UUID.fromString(json.readTree(mockMvc.perform(post("/api/v1/purchases/orders")
                        .header("Authorization", authorization).contentType(MediaType.APPLICATION_JSON).content(request))
                .andReturn().getResponse().getContentAsString()).path("id").asText());
        mockMvc.perform(post("/api/v1/purchases/orders/" + orderId + "/google-play/verify")
                        .header("Authorization", authorization).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"purchaseToken\":\"untrusted-client-value\"}"))
                .andExpect(status().isServiceUnavailable());
        mockMvc.perform(get("/api/v1/economy/wallet").header("Authorization", authorization))
                .andExpect(status().isOk()).andExpect(jsonPath("$.coins").value(500));
    }

    @Test
    void refundIsIdempotentAndSpentCoinsBecomeDebtBeforeFutureCredits() throws Exception {
        String token = guest(UUID.randomUUID().toString());
        UUID playerId = UUID.fromString(json.readTree(mockMvc.perform(get("/api/auth/me")
                .header("Authorization", "Bearer " + token)).andReturn().getResponse()
                .getContentAsString()).path("id").asText());
        UUID orderId = UUID.randomUUID();
        jdbc.update("""
                insert into purchase_order(id,player_id,product_id,provider,status,idempotency_key,
                price_minor,price_currency,grant_currency,grant_amount,provider_transaction_hash,
                created_at,updated_at,verified_at,fulfilled_at)
                values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                """, orderId, playerId, UUID.fromString("43000000-0000-0000-0000-000000000001"),
                "RAZORPAY", "FULFILLED", UUID.randomUUID(), 38000, "INR", "COINS", 500,
                PurchaseService.sha256("RAZORPAY:pay_refund_test"), java.sql.Timestamp.from(java.time.Instant.now()),
                java.sql.Timestamp.from(java.time.Instant.now()), java.sql.Timestamp.from(java.time.Instant.now()),
                java.sql.Timestamp.from(java.time.Instant.now()));
        economy.spend(playerId, "COINS", 400, "TEST_SPEND", "spend:" + orderId, "Test spend");

        purchases.refundVerified("RAZORPAY", "pay_refund_test", "event-refund-1");
        purchases.refundVerified("RAZORPAY", "pay_refund_test", "event-refund-1");
        org.junit.jupiter.api.Assertions.assertEquals(0L,
                jdbc.queryForObject("select coin_balance from player_wallet where player_id=?", Long.class, playerId));
        org.junit.jupiter.api.Assertions.assertEquals(400L,
                jdbc.queryForObject("select coin_debt from player_wallet where player_id=?", Long.class, playerId));

        economy.grantCoins(playerId, 100, "REWARDED_AD", "ad:debt", "Rewarded video");
        org.junit.jupiter.api.Assertions.assertEquals(0L,
                jdbc.queryForObject("select coin_balance from player_wallet where player_id=?", Long.class, playerId));
        org.junit.jupiter.api.Assertions.assertEquals(300L,
                jdbc.queryForObject("select coin_debt from player_wallet where player_id=?", Long.class, playerId));
    }

    private String guest(String installationId) throws Exception {
        var response = mockMvc.perform(post("/api/auth/guest").contentType(MediaType.APPLICATION_JSON)
                .content("{\"installationId\":\"" + installationId + "\"}"))
                .andExpect(status().isOk()).andReturn();
        return json.readTree(response.getResponse().getContentAsString()).path("token").asText();
    }
}
