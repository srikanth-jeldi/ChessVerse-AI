package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.economy.EconomyService;
import java.sql.Timestamp;
import java.time.*;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class TournamentEveningScheduleTest {
    @Test void reminderKeyStaysStableAsTheEventApproaches() {
        var db = new JdbcTemplate(new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_UPPER=false;DB_CLOSE_DELAY=-1","sa",""));
        db.execute("create table chess_tournament(id uuid primary key,name varchar(100),series_code varchar(32),starts_at timestamp with time zone,ends_at timestamp with time zone,status varchar(16))");
        db.execute("create table chess_tournament_entry(tournament_id uuid,player_id uuid,active boolean)");
        var notifications=mock(PlayerNotificationService.class);
        var service=new TournamentService(db,mock(OnlineMatchRepository.class),mock(EconomyService.class),notifications);
        UUID event=UUID.randomUUID(), player=UUID.randomUUID();
        Instant start=Instant.now().plusSeconds(3600).truncatedTo(java.time.temporal.ChronoUnit.SECONDS);
        db.update("insert into chess_tournament values(?,?,null,?,?,'OPEN')",event,"Club Cup",Timestamp.from(start),Timestamp.from(start.plusSeconds(7200)));
        db.update("insert into chess_tournament_entry values(?,?,true)",event,player);
        service.sendDueReminders();
        service.sendDueReminders();
        verify(notifications,times(2)).createOnce(eq(player),eq("TOURNAMENT_REMINDER"),
                eq("tournament:"+event+":start:"+start),anyString(),anyString(),eq("TOURNAMENT"),eq(event));
    }
    @Test void movesOnlyUpcomingOpenCityEventsAndNotifiesActiveEntrantsOnce() {
        var db = new JdbcTemplate(new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_UPPER=false;DB_CLOSE_DELAY=-1","sa",""));
        db.execute("create table chess_tournament(id uuid primary key,name varchar(100),series_code varchar(32),starts_at timestamp with time zone,ends_at timestamp with time zone,status varchar(16))");
        db.execute("create table chess_tournament_entry(tournament_id uuid,player_id uuid,active boolean)");
        var notifications = mock(PlayerNotificationService.class);
        var service = new TournamentService(db,mock(OnlineMatchRepository.class),mock(EconomyService.class),notifications);
        UUID player = UUID.randomUUID();
        Instant future = Instant.now().plus(Duration.ofDays(5)).truncatedTo(java.time.temporal.ChronoUnit.SECONDS);
        for (String series : new String[]{"HYDERABAD_ROYAL","DUBAI_GOLD","TOKYO_NEON","LONDON_CLASSIC","NEW_YORK_FINAL"}) {
            UUID id = UUID.randomUUID();
            Instant start = future.atZone(TournamentService.seriesZone(series)).withHour(0).withMinute(0).withSecond(0).withNano(0).toInstant();
            db.update("insert into chess_tournament values(?,?,?,?,?,'OPEN')",id,series,series,Timestamp.from(start),Timestamp.from(start.plusSeconds(7200)));
            db.update("insert into chess_tournament_entry values(?,?,true)",id,player);
            db.update("insert into chess_tournament_entry values(?,?,false)",id,UUID.randomUUID());
        }
        UUID active=UUID.randomUUID(), custom=UUID.randomUUID(), past=UUID.randomUUID();
        for (UUID id : new UUID[]{active,custom,past}) db.update("insert into chess_tournament values(?,?,?,?,?,?)",id,"Unchanged",id.equals(custom)?null:"DUBAI_GOLD",Timestamp.from(id.equals(past)?Instant.EPOCH:future),Timestamp.from(future.plusSeconds(7200)),id.equals(active)?"ACTIVE":"OPEN");
        service.rescheduleUpcomingEvenings();
        service.rescheduleUpcomingEvenings();
        db.query("select * from chess_tournament where id not in (?,?,?)",rs -> {
            var start=rs.getTimestamp("starts_at").toInstant();
            assertEquals(LocalTime.of(19,0),start.atZone(TournamentService.seriesZone(rs.getString("series_code"))).toLocalTime());
            assertEquals(7200,Duration.between(start,rs.getTimestamp("ends_at").toInstant()).getSeconds());
        },active,custom,past);
        assertEquals(future,db.queryForObject("select starts_at from chess_tournament where id=?",Timestamp.class,active).toInstant());
        assertEquals(future,db.queryForObject("select starts_at from chess_tournament where id=?",Timestamp.class,custom).toInstant());
        assertEquals(Instant.EPOCH,db.queryForObject("select starts_at from chess_tournament where id=?",Timestamp.class,past).toInstant());
        verify(notifications,times(5)).createOnce(eq(player),eq("TOURNAMENT_RESCHEDULED"),anyString(),anyString(),contains("7:00 pm"),eq("TOURNAMENT"),any());
    }
    @Test void eveningScheduleUsesCityZoneAcrossDaylightSavingChanges() {
        var next=TournamentService.nextEveningStart("LONDON_CLASSIC",Instant.parse("2026-10-24T18:00:00Z"),1,Instant.parse("2026-10-24T20:00:00Z"));
        assertEquals(Instant.parse("2026-10-25T19:00:00Z"),next);
    }
}
