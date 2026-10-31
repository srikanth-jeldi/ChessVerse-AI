package com.epitomehub.chessverse.economy;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.time.LocalDate;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

class BadgeAchievementsTest {
    JdbcTemplate db; BadgeAchievements badges; UUID player, item;
    @BeforeEach void setup() {
        db=new JdbcTemplate(new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DB_CLOSE_DELAY=-1","sa",""));
        db.execute("create table player_account(id uuid primary key)");
        db.execute("create table cosmetic_item(id uuid primary key,slug varchar,category varchar,active boolean,name varchar,price_currency varchar,price_amount bigint)");
        db.execute("create table player_cosmetic_inventory(player_id uuid,item_id uuid,acquired_at timestamp,primary key(player_id,item_id))");
        db.execute("create table player_badge_achievement(player_id uuid,item_id uuid,earned_at timestamp,primary key(player_id,item_id))");
        db.execute("create table player_completed_puzzle(player_id uuid,puzzle_id varchar,primary key(player_id,puzzle_id))");
        db.execute("create table player_completed_academy_lesson(player_id uuid,lesson_id varchar)");
        db.execute("create table player_completed_daily_challenge(player_id uuid,challenge_id varchar)");
        db.execute("create table online_match(white_player_id uuid,black_player_id uuid,result varchar,result_reason varchar)");
        player=UUID.randomUUID();item=UUID.randomUUID();db.update("insert into player_account values(?)",player);
        db.update("insert into cosmetic_item values(?,'puzzle-hunter','FRAME',true,'Puzzle Hunter','COINS',500)",item);
        badges=new BadgeAchievements(db);
    }
    @Test void thresholdAwardsOnceAndKeepsOtherAccountsSeparate() {
        for(int i=0;i<24;i++) db.update("insert into player_completed_puzzle values(?,?)",player,"easy-"+i);
        assertFalse(badges.reconcile(player).get("puzzle-hunter").earned());
        db.update("insert into player_completed_puzzle values(?,'easy-24')",player);
        assertTrue(badges.reconcile(player).get("puzzle-hunter").newlyEarned());
        assertFalse(badges.reconcile(player).get("puzzle-hunter").newlyEarned());
        assertEquals(1,db.queryForObject("select count(*) from player_cosmetic_inventory",Integer.class));
        UUID other=UUID.randomUUID();db.update("insert into player_account values(?)",other);
        assertEquals(0,badges.reconcile(other).get("puzzle-hunter").current());
    }
    @Test void purchaseOwnershipIsNotAchievement() {
        db.update("insert into player_cosmetic_inventory values(?,?,current_timestamp)",player,item);
        assertFalse(badges.reconcile(player).get("puzzle-hunter").earned());
        assertEquals(1,db.queryForObject("select count(*) from player_cosmetic_inventory",Integer.class));
    }
    @Test void achievementPurchaseDoesNotSpendCoinsEvenIfLegacyPriceExists() {
        var economy=mock(EconomyService.class);
        var shop=new ShopService(db,economy,badges);
        var account=new com.epitomehub.chessverse.auth.AuthenticatedPlayer(player,"test","Test",null);
        var error=assertThrows(org.springframework.web.server.ResponseStatusException.class,
                ()->shop.purchase(account,item));
        assertEquals(409,error.getStatusCode().value());
        verifyNoInteractions(economy);
        assertEquals(0,db.queryForObject("select count(*) from player_cosmetic_inventory",Integer.class));
    }
    @Test void streakCountsDistinctConsecutiveDaysNotClubsOrFutureDates() {
        assertEquals(2,BadgeAchievements.longestStreak(List.of("2026-10-01-a","2026-10-01-b","2026-10-02-c","2026-10-04-d","2026-11-01-e"),LocalDate.of(2026,10,30)));
    }
    @Test void checkmateRequiresWinningSideAndReason() {
        db.update("update cosmetic_item set slug='checkmate-crown'");
        db.update("insert into online_match values(?,?,'0-1','CHECKMATE')",player,UUID.randomUUID());
        db.update("insert into online_match values(?,?,'1-0','RESIGNATION')",player,UUID.randomUUID());
        db.update("insert into online_match values(?,?,'1-0','CHECKMATE')",player,UUID.randomUUID());
        assertEquals(1,badges.reconcile(player).get("checkmate-crown").current());
    }
}
