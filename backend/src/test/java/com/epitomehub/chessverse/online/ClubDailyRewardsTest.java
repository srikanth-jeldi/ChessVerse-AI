package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.economy.EconomyService;
import java.time.LocalDate;
import java.util.UUID;
import java.util.concurrent.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ClubDailyRewardsTest {
    final UUID player=UUID.randomUUID();
    final UUID club=UUID.randomUUID();
    final UUID otherClub=UUID.randomUUID();
    final DriverManagerDataSource source=new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";DB_CLOSE_DELAY=-1;LOCK_TIMEOUT=10000","sa","");
    final JdbcTemplate jdbc=new JdbcTemplate(source);
    final TransactionTemplate tx=new TransactionTemplate(new DataSourceTransactionManager(source));
    final EconomyService economy=mock(EconomyService.class);
    final ClubDailyRewards service=new ClubDailyRewards(jdbc,economy);
    ClubDailyRewardsTest(){
        jdbc.execute("create table player_account(id uuid primary key)");
        jdbc.execute("create table club_daily_reward_by_club(player_id uuid, club_id uuid, reward_day date, streak int, coins int, primary key(player_id,club_id,reward_day))");
        jdbc.update("insert into player_account values(?)",player);
        doReturn(true).when(economy).grantCoins(any(),anyLong(),anyString(),anyString(),anyString());
    }
    ClubDailyRewards.Status award(LocalDate day){return tx.execute(s->service.award(player,club,day));}
    @Test void retriesInSameClubAwardOnce(){
        LocalDate day=LocalDate.of(2026,10,18);
        assertEquals(5,award(day).awardedCoins());
        assertEquals(0,award(day).awardedCoins());
        assertEquals(1,service.status(player,club,day).streak());
        verify(economy,times(1)).grantCoins(eq(player),eq(5L),eq("CLUB_DAILY_STREAK"),eq("club-daily:"+club+":"+day),anyString());
    }
    @Test void sevenDayCycleAndMissedDayResetAreServerCalculated(){
        LocalDate day=LocalDate.of(2026,10,18);
        int[] expected={5,10,15,15,15,15,25,5};
        for(int n=0;n<expected.length;n++){
            var status=award(day.plusDays(n));
            assertEquals(expected[n],status.awardedCoins());
            assertEquals(n+1,status.streak());
        }
        assertEquals(0,service.status(player,club,day.plusDays(9)).streak());
        assertEquals(5,award(day.plusDays(9)).awardedCoins());
        assertEquals(1,service.status(player,club,day.plusDays(9)).streak());
    }
    @Test void simultaneousClubCompletionsCannotDoubleCredit() throws Exception {
        var gate=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)){
            Callable<Integer> work=()->{gate.await();return award(LocalDate.of(2026,10,18)).awardedCoins();};
            var a=pool.submit(work);var b=pool.submit(work);gate.countDown();
            assertEquals(5,a.get(10,TimeUnit.SECONDS)+b.get(10,TimeUnit.SECONDS));
            assertEquals(1,jdbc.queryForObject("select count(*) from club_daily_reward_by_club",Integer.class));
        }
    }
    @Test void FailedWalletGrantRollsBackRewardAndCanRetry(){
        var day=LocalDate.of(2026,10,18);
        when(economy.grantCoins(any(),anyLong(),anyString(),anyString(),anyString())).thenThrow(new IllegalStateException("offline"));
        assertThrows(IllegalStateException.class,()->award(day));
        assertFalse(service.status(player,club,day).earnedToday());
        doReturn(true).when(economy).grantCoins(any(),anyLong(),anyString(),anyString(),anyString());
        assertEquals(5,award(day).awardedCoins());
    }
    @Test void clubsHaveIndependentStreaksAndRewards() {
        var day=LocalDate.of(2026,10,18);
        award(day.minusDays(1));
        assertEquals(10,award(day).awardedCoins());
        assertEquals(0,service.status(player,otherClub,day).streak());
        assertFalse(service.status(player,otherClub,day).earnedToday());
        var second=tx.execute(s->service.award(player,otherClub,day));
        assertEquals(1,second.streak());
        assertEquals(5,second.awardedCoins());
        assertEquals(2,service.status(player,club,day).streak());
        assertEquals(0,tx.execute(s->service.award(player,otherClub,day)).awardedCoins());
        verify(economy).grantCoins(eq(player),eq(5L),eq("CLUB_DAILY_STREAK"),eq("club-daily:"+otherClub+":"+day),anyString());
    }
    @Test void missedDayInOneClubDoesNotResetAnotherClub() {
        var day=LocalDate.of(2026,10,18);
        award(day);
        tx.execute(s->service.award(player,otherClub,day));
        award(day.plusDays(1));
        assertEquals(3,award(day.plusDays(2)).streak());
        assertEquals(1,tx.execute(s->service.award(player,otherClub,day.plusDays(2))).streak());
    }
}
