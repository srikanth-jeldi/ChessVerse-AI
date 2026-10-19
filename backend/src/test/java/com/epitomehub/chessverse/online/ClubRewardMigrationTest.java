package com.epitomehub.chessverse.online;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import static org.junit.jupiter.api.Assertions.*;

class ClubRewardMigrationTest {
    @Test void preservesIndependentCompletionHistoryWithoutRegrantingCoins() {
        var source = new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DB_CLOSE_DELAY=-1", "sa", "");
        var jdbc = new JdbcTemplate(source);
        jdbc.execute("create table player_account(id uuid primary key)");
        jdbc.execute("create table chess_club(id uuid primary key)");
        jdbc.execute("create table club_daily_completion(player_id uuid,club_id uuid,puzzle_day date,completed_at timestamp)");
        jdbc.execute("create table club_daily_reward(player_id uuid,reward_day date,streak integer,coins integer)");
        var player=UUID.randomUUID(); var a=UUID.randomUUID(); var b=UUID.randomUUID();
        jdbc.update("insert into player_account values(?)",player);
        jdbc.update("insert into chess_club values(?),(?)",a,b);
        jdbc.update("insert into club_daily_completion values(?,?,'2026-10-17','2026-10-17 10:00:00'),(?,?,'2026-10-18','2026-10-18 10:00:00'),(?,?,'2026-10-18','2026-10-18 11:00:00'),(?,?,'2026-10-20','2026-10-20 10:00:00')",player,a,player,a,player,b,player,b);
        jdbc.update("insert into club_daily_reward values(?,'2026-10-17',1,5),(?,'2026-10-18',2,10)",player,player);
        new ResourceDatabasePopulator(new ClassPathResource("db/migration/V89__club_scoped_daily_rewards.sql")).execute(source);
        assertEquals(2,jdbc.queryForObject("select streak from club_daily_reward_by_club where club_id=? and reward_day='2026-10-18'",Integer.class,a));
        assertEquals(1,jdbc.queryForObject("select streak from club_daily_reward_by_club where club_id=? and reward_day='2026-10-18'",Integer.class,b));
        assertEquals(1,jdbc.queryForObject("select streak from club_daily_reward_by_club where club_id=? and reward_day='2026-10-20'",Integer.class,b));
        assertEquals(0,jdbc.queryForObject("select coins from club_daily_reward_by_club where club_id=? and reward_day='2026-10-18'",Integer.class,b));
        assertEquals(15,jdbc.queryForObject("select sum(coins) from club_daily_reward_by_club",Integer.class));
        assertEquals(2,jdbc.queryForObject("select count(*) from club_daily_reward",Integer.class));
    }
}
