package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.economy.EconomyService;
import java.sql.Timestamp;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CoinLeagueService {
    static final ZoneId ZONE = ZoneId.of("Asia/Kolkata");
    private final JdbcTemplate db;
    private final EconomyService economy;
    public CoinLeagueService(JdbcTemplate db, EconomyService economy) {
        this.db=db; this.economy=economy;
    }
    static LocalDate weekAt(Instant now) {
        return now.atZone(ZONE).toLocalDate().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    }
    static int prize(int place) { return switch(place) { case 1 -> 500; case 2 -> 300; case 3 -> 200; default -> 0; }; }
    record Entry(long rank, UUID playerId, String displayName, String photoUrl, long coinsWon, int wins) {}
    record Winner(LocalDate weekStart, int place, String displayName, long coinsWon, int prize) {}
    record Board(String period, LocalDate weekStart, Instant endsAt, LocalDate firstPrizeWeek,
                 List<Entry> entries, Entry you, List<Winner> previousWinners) {}

    // Only settled, played, coin-entry wins count. Returned stake, purchases,
    // advertisements, grants and weekly prizes never feed this score.
    static final String SCORE = """
        with wins as (
          select m.id, m.finished_at, m.entry_coins,
            case when m.result='1-0' then m.white_player_id else m.black_player_id end player_id,
            case when m.result='1-0' then m.black_player_id else m.white_player_id end opponent_id
          from online_match m
          where m.status='FINISHED' and m.coin_pool_settled=true and m.entry_coins>0
            and m.result in ('1-0','0-1') and m.white_player_id<>m.black_player_id
            and m.finished_at>=? and m.finished_at<?
            and (select count(*) from online_match_move mm where mm.match_id=m.id)>=4
        ), eligible as (
          select w.*, row_number() over(partition by w.player_id,w.opponent_id,
             cast(w.finished_at at time zone 'Asia/Kolkata' as date) order by w.finished_at,w.id) pair_win
          from wins w
          where not exists(select 1 from coin_league_excluded_player e
                            where e.player_id=w.player_id or e.player_id=w.opponent_id)
        ), totals as (
          select player_id,sum(entry_coins) coins_won,count(*) wins,max(finished_at) last_win
          from eligible where pair_win<=3 group by player_id
        ), ranked as (
          select row_number() over(order by t.coins_won desc,t.wins desc,t.last_win,t.player_id) rank,
            t.player_id,a.display_name,a.photo_url,t.coins_won,t.wins
          from totals t join player_account a on a.id=t.player_id
        )
        """;
    List<Entry> entries(Instant start, Instant end, UUID player) {
        String filter=player==null ? " order by rank limit 50" : " where player_id=?";
        Object[] args=player==null ? new Object[]{Timestamp.from(start),Timestamp.from(end)}
                : new Object[]{Timestamp.from(start),Timestamp.from(end),player};
        return db.query(SCORE+"select * from ranked"+filter, (rs,n)->new Entry(
            rs.getLong("rank"),rs.getObject("player_id",UUID.class),rs.getString("display_name"),
            rs.getString("photo_url"),rs.getLong("coins_won"),rs.getInt("wins")),args);
    }
    @Transactional(readOnly=true)
    public Board board(UUID player,String requested) {
        Instant now=Instant.now(); LocalDate week=weekAt(now);
        String period="overall".equals(requested)?"overall":"weekly";
        Instant start=period.equals("overall")?Instant.EPOCH:week.atStartOfDay(ZONE).toInstant();
        List<Entry> own=entries(start,now,player);
        LocalDate first=db.queryForObject("select first_week from coin_league_config where id=1",LocalDate.class);
        List<Winner> winners=db.query("""
            select p.*,a.display_name from coin_league_prize p join player_account a on a.id=p.player_id
            where p.week_start=(select max(week_start) from coin_league_week) order by p.place
            """,(rs,n)->new Winner(rs.getObject("week_start",LocalDate.class),rs.getInt("place"),
                 rs.getString("display_name"),rs.getLong("coins_won"),rs.getInt("prize")));
        return new Board(period,week,week.plusWeeks(1).atStartOfDay(ZONE).toInstant(),first,
                entries(start,now,null),own.isEmpty()?null:own.getFirst(),winners);
    }
    @Transactional
    public void settleCompletedWeeks() {
        // Transaction-scoped lock covers all replicas; ledger and rewards commit together.
        db.execute("select pg_advisory_xact_lock(92500300200)");
        LocalDate first=db.queryForObject("select first_week from coin_league_config where id=1",LocalDate.class);
        LocalDate current=weekAt(Instant.now());
        for(LocalDate week=first;week.isBefore(current);week=week.plusWeeks(1)) {
            int inserted=db.update("insert into coin_league_week values (?,now()) on conflict do nothing",week);
            if(inserted==0) continue;
            List<Entry> top=entries(week.atStartOfDay(ZONE).toInstant(),week.plusWeeks(1).atStartOfDay(ZONE).toInstant(),null);
            for(Entry row:top.stream().limit(3).toList()) {
                int place=(int)row.rank(); int reward=prize(place);
                economy.grantCoins(row.playerId(),reward,"WEEKLY_COIN_PRIZE","coin-league:"+week,
                        "Weekly coin league #"+place);
                db.update("insert into coin_league_prize values (?,?,?,?,?)",week,place,row.playerId(),row.coinsWon(),reward);
            }
        }
    }
}
