package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.economy.EconomyService;
import java.sql.Date;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** Called inside the activity transaction. Account lock also serializes wallet grants. */
@Service
class ClubDailyRewards {
    private final JdbcTemplate jdbc;
    private final EconomyService economy;
    ClubDailyRewards(JdbcTemplate jdbc, EconomyService economy) { this.jdbc=jdbc; this.economy=economy; }
    record Status(int streak, boolean earnedToday, int nextCoins, int awardedCoins, int creditedCoins) {}
    record Entry(LocalDate day, int streak, int coins) {}
    static int coins(int streak) { int day=(streak-1)%7+1; return day==1 ? 5 : day==2 ? 10 : day==7 ? 25 : 15; }
    Status status(UUID player, UUID club, LocalDate day) {
        var rows=jdbc.query("select reward_day,streak,coins from club_daily_reward_by_club where player_id=? and club_id=? order by reward_day desc limit 1",
                (rs,n)->new Entry(rs.getDate("reward_day").toLocalDate(),rs.getInt("streak"),rs.getInt("coins")),player,club);
        Entry last=rows.isEmpty()?null:rows.getFirst();
        boolean today=last!=null && last.day().equals(day);
        int streak=last!=null && !last.day().isBefore(day.minusDays(1)) ? last.streak() : 0;
        return new Status(streak,today,coins(streak+1),0,today ? last.coins() : 0);
    }
    Status award(UUID player, UUID club, LocalDate day) {
        jdbc.queryForObject("select id from player_account where id=? for update",UUID.class,player);
        Status before=status(player,club,day);
        if(before.earnedToday()) return before;
        int streak=before.streak()+1, amount=coins(streak);
        jdbc.update("insert into club_daily_reward_by_club(player_id,club_id,reward_day,streak,coins) values(?,?,?,?,?)",
                player,club,Date.valueOf(day),streak,amount);
        boolean granted=economy.grantCoins(player,amount,"CLUB_DAILY_STREAK","club-daily:"+club+":"+day,
                "Club daily puzzle · day "+streak);
        return new Status(streak,true,coins(streak+1),granted?amount:0,amount);
    }
}
