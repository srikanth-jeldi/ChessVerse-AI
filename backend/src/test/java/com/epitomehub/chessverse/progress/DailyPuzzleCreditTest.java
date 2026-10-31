package com.epitomehub.chessverse.progress;

import com.epitomehub.chessverse.economy.EconomyService;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class DailyPuzzleCreditTest {
    final UUID player = UUID.randomUUID();
    final DriverManagerDataSource source = new DriverManagerDataSource(
            "jdbc:h2:mem:" + UUID.randomUUID() + ";DB_CLOSE_DELAY=-1;LOCK_TIMEOUT=10000", "sa", "");
    final JdbcTemplate jdbc = new JdbcTemplate(source);
    final TransactionTemplate tx = new TransactionTemplate(new DataSourceTransactionManager(source));
    final PlayerCloudProgressRepository repository = mock(PlayerCloudProgressRepository.class);
    final PlayerCloudProgress progress = new PlayerCloudProgress(player);
    final CloudProgressService service = new CloudProgressService(repository, new EconomyService(jdbc), jdbc);
    DailyPuzzleCreditTest() {
        jdbc.execute("create table player_account(id uuid primary key)");
        jdbc.execute("create table player_wallet(player_id uuid primary key,coin_balance bigint,coin_debt bigint default 0 not null,diamond_balance bigint,created_at timestamp with time zone,updated_at timestamp with time zone)");
        jdbc.execute("create table economy_transaction(id uuid primary key,player_id uuid,currency varchar(20),amount bigint,balance_after bigint,transaction_type varchar(50),reference_key varchar(160),description varchar(300),created_at timestamp with time zone,unique(player_id,reference_key))");
        jdbc.update("insert into player_account values(?)",player);
        when(repository.findById(player)).thenReturn(Optional.of(progress));
        when(repository.save(any())).thenAnswer(call -> call.getArgument(0));
    }
    CloudProgressDtos.MergeRequest request(Map<String,List<String>> proofs) {
        return new CloudProgressDtos.MergeRequest(null,null,0,0,null,999,
            null,null,null,null,null,null,null,List.of(),new ArrayList<>(proofs.keySet()),List.of(),proofs);
    }
    Map<String,List<String>> proof(LocalDate day, boolean hard) {
        var puzzle = DailyPuzzleRewards.puzzle(day,hard);
        return Map.of(day+"-v8-"+puzzle.id(),puzzle.moves());
    }
    void merge(Map<String,List<String>> proofs) { tx.execute(s -> service.merge(player,request(proofs))); }
    long rewards() {
        return jdbc.queryForObject("select coalesce(sum(amount),0) from economy_transaction where transaction_type='DAILY_PUZZLE_REWARD'",Long.class);
    }
    @Test void sevenDaysCreditExpectedAmountsAndRetriesOrOtherDifficultyDoNotPayTwice() {
        LocalDate today=LocalDate.now(ZoneOffset.UTC);
        var proofs = new TreeMap<String,List<String>>();
        for(int i=6;i>=0;i--) proofs.putAll(proof(today.minusDays(i),false));
        merge(proofs); merge(proofs); merge(proof(today,true));
        assertEquals(175,rewards());
        assertEquals(275,jdbc.queryForObject("select coin_balance from player_wallet where player_id=?",Long.class,player));
        assertEquals(7,progress.dailyStreak);
    }
    @Test void invalidOrFutureProofCannotCredit() {
        LocalDate today=LocalDate.now(ZoneOffset.UTC);
        var valid=proof(today,false);
        merge(Map.of(valid.keySet().iterator().next(),List.of("a2a3")));
        merge(proof(today.plusDays(1),false));
        assertEquals(0,rewards());
        assertEquals(0,progress.dailyStreak);
    }
    @Test void simultaneousDevicesCreditOnlyOnce() throws Exception {
        var proofs=proof(LocalDate.now(ZoneOffset.UTC),false);
        var gate=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)) {
            Callable<Void> work=()->{gate.await();merge(proofs);return null;};
            var a=pool.submit(work);var b=pool.submit(work);gate.countDown();
            a.get(10,TimeUnit.SECONDS);b.get(10,TimeUnit.SECONDS);
            assertEquals(10,rewards());
        }
    }
    @Test void missedDayResetsRewardDespiteInflatedClientStreak() {
        var today=LocalDate.now(ZoneOffset.UTC);
        merge(proof(today.minusDays(2),false));
        merge(proof(today,false));
        assertEquals(20,rewards());
        assertEquals(1,progress.dailyStreak);
    }
}
