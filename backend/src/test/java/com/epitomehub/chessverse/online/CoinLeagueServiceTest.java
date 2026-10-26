package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.time.*;
import java.sql.Timestamp;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import com.epitomehub.chessverse.economy.EconomyService;

class CoinLeagueServiceTest {
 JdbcTemplate db; UUID winner=UUID.randomUUID(), other=UUID.randomUUID();
 @BeforeEach void schema(){
  db=new JdbcTemplate(new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DB_CLOSE_DELAY=-1","sa",""));
  db.execute("create table player_account(id uuid primary key,display_name varchar,photo_url varchar)");
  db.execute("create table coin_league_excluded_player(player_id uuid primary key)");
  db.execute("create table online_match(id uuid primary key,white_player_id uuid,black_player_id uuid,result varchar,status varchar,coin_pool_settled boolean,entry_coins int,finished_at timestamp with time zone)");
  db.execute("create table online_match_move(match_id uuid,ply_index int)");
  db.update("insert into player_account values (?,'Winner',null),(?,'Opponent',null)",winner,other);
 }
 void match(int entry,String result,boolean settled,int moves,Instant finished){
  UUID id=UUID.randomUUID();db.update("insert into online_match values (?,?,?,?,'FINISHED',?,?,?)",id,winner,other,result,settled,entry,Timestamp.from(finished));
  for(int i=0;i<moves;i++)db.update("insert into online_match_move values (?,?)",id,i);
 }
 List<Map<String,Object>> scores(Instant start,Instant end){return db.queryForList(CoinLeagueService.SCORE+"select * from ranked",Timestamp.from(start),Timestamp.from(end));}
 @Test void countsNetWinsNotDrawsUnsettledOrNoShowsAndCapsRepeatedOpponent(){
  Instant now=Instant.parse("2026-11-03T10:00:00Z");
  for(int i=0;i<4;i++)match(100,"1-0",true,4,now.plusSeconds(i));
  match(900,"1/2-1/2",true,4,now);match(900,"1-0",false,4,now);match(900,"1-0",true,0,now);
  var rows=scores(now.minusSeconds(1),now.plusSeconds(10));assertEquals(1,rows.size());
  assertEquals(300,((Number)rows.getFirst().get("COINS_WON")).longValue());
 }
 @Test void periodIsHalfOpenAndTestAccountsDoNotScore(){
  Instant start=Instant.parse("2026-11-01T18:30:00Z"),end=start.plusSeconds(604800);
  match(100,"1-0",true,4,start);match(500,"1-0",true,4,end);
  assertEquals(100,((Number)scores(start,end).getFirst().get("COINS_WON")).longValue());
  db.update("insert into coin_league_excluded_player values (?)",other);
  assertTrue(scores(start,end).isEmpty());
 }
 @Test void indiaMondayBoundaryAndPrizes(){
  assertEquals(LocalDate.of(2026,10,26),CoinLeagueService.weekAt(Instant.parse("2026-11-01T18:29:59Z")));
  assertEquals(LocalDate.of(2026,11,2),CoinLeagueService.weekAt(Instant.parse("2026-11-01T18:30:00Z")));
  assertEquals(500,CoinLeagueService.prize(1));assertEquals(300,CoinLeagueService.prize(2));assertEquals(200,CoinLeagueService.prize(3));assertEquals(0,CoinLeagueService.prize(4));
 }
 @Test void alreadySettledWeekCannotAwardTwice(){
  JdbcTemplate mockDb=mock(JdbcTemplate.class);EconomyService economy=mock(EconomyService.class);
  LocalDate last=CoinLeagueService.weekAt(Instant.now()).minusWeeks(1);
  when(mockDb.queryForObject("select first_week from coin_league_config where id=1",LocalDate.class)).thenReturn(last);
  when(mockDb.update("insert into coin_league_week values (?,now()) on conflict do nothing",last)).thenReturn(0);
  new CoinLeagueService(mockDb,economy).settleCompletedWeeks();
  new CoinLeagueService(mockDb,economy).settleCompletedWeeks();
  verifyNoInteractions(economy);
 }

 @Test void awardsThreePlacesOnceWithStableLedgerReferences(){
  JdbcTemplate ledger=mock(JdbcTemplate.class);EconomyService economy=mock(EconomyService.class);
  LocalDate week=CoinLeagueService.weekAt(Instant.now()).minusWeeks(1);
  when(ledger.queryForObject("select first_week from coin_league_config where id=1",LocalDate.class)).thenReturn(week);
  when(ledger.update("insert into coin_league_week values (?,now()) on conflict do nothing",week)).thenReturn(1,0);
  CoinLeagueService service=spy(new CoinLeagueService(ledger,economy));
  UUID third=UUID.randomUUID();
  doReturn(List.of(new CoinLeagueService.Entry(1,winner,"A",null,500,5),
    new CoinLeagueService.Entry(2,other,"B",null,400,4),new CoinLeagueService.Entry(3,third,"C",null,300,3)))
    .when(service).entries(week.atStartOfDay(CoinLeagueService.ZONE).toInstant(),week.plusWeeks(1).atStartOfDay(CoinLeagueService.ZONE).toInstant(),null);
  service.settleCompletedWeeks();service.settleCompletedWeeks();
  verify(economy).grantCoins(winner,500,"WEEKLY_COIN_PRIZE","coin-league:"+week,"Weekly coin league #1");
  verify(economy).grantCoins(other,300,"WEEKLY_COIN_PRIZE","coin-league:"+week,"Weekly coin league #2");
  verify(economy).grantCoins(third,200,"WEEKLY_COIN_PRIZE","coin-league:"+week,"Weekly coin league #3");
  verifyNoMoreInteractions(economy);
 }
}
