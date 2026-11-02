package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import static org.junit.jupiter.api.Assertions.*;

class DailyPracticeCupTest {
    @Test void soloStartRealJoinResumeAndLegalTurns() {
        var ds=new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+
                ";MODE=PostgreSQL;NON_KEYWORDS=DAY;DB_CLOSE_DELAY=-1","sa","");
        var db=new JdbcTemplate(ds);
        db.execute("create table player_account(id uuid primary key)");
        new ResourceDatabasePopulator(new ClassPathResource(
                "db/migration/V97__daily_practice_cup.sql"),new ClassPathResource(
                "db/migration/V98__practice_cup_lobby_and_finish.sql")).execute(ds);
        var alice=new AuthenticatedPlayer(UUID.randomUUID(),"alice","Alice",null);
        var bob=new AuthenticatedPlayer(UUID.randomUUID(),"bob","Bob",null);
        db.update("insert into player_account values(?),(?)",alice.id(),bob.id());
        var service=new DailyPracticeCup(db);
        var cup=service.join(alice);
        assertEquals(1,cup.seats().size());
        assertTrue(cup.lobbySeconds()>0 && cup.lobbySeconds()<=60);
        assertTrue(cup.games().isEmpty());
        UUID cupId=cup.id();
        assertThrows(OnlineMatchException.class,()->service.enter(cupId,1,alice.id(),null,null));
        var lobby=service.join(bob);
        assertEquals(cup.id(),lobby.id());
        assertEquals(2,lobby.seats().size());
        db.update("update practice_cup set starts_at=? where id=?",java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(1)),cupId);
        cup=service.standings(cupId,alice.id());
        assertEquals(4,cup.seats().stream().filter(DailyPracticeCup.Seat::isBot).count());
        var late=new AuthenticatedPlayer(UUID.randomUUID(),"late","Late",null);
        db.update("insert into player_account values(?)",late.id());
        assertNotEquals(cupId,service.join(late).id());
        assertEquals(15,cup.games().stream().map(g->Math.min(g.white(),g.black())+":"+
                Math.max(g.white(),g.black())).distinct().count());
        var game=service.enter(cup.id(),1,alice.id(),null,null);
        assertEquals(0,game.ply());
        var next=service.enter(cup.id(),1,alice.id(),"e2e4",0);
        assertEquals(2,next.ply());
        assertThrows(OnlineMatchException.class,()->service.enter(cupId,1,alice.id(),"e2e4",0));
        assertEquals(next.fen(),service.enter(cup.id(),1,alice.id(),null,null).fen());
        var joined=service.join(bob);
        assertEquals(cup.id(),joined.id());
        assertEquals(1,joined.mySeat());
        assertTrue(joined.seats().get(5).isBot());
        assertThrows(OnlineMatchException.class,()->service.enter(cupId,1,bob.id(),null,null));
        assertEquals(cup.id(),service.join(alice).id());
        var shared=cup.games().stream().filter(g -> (g.white()==0 && g.black()==1)
                || (g.white()==1 && g.black()==0)).findFirst().orElseThrow();
        UUID white=shared.white()==0?alice.id():bob.id();
        UUID black=shared.black()==0?alice.id():bob.id();
        var waiting=service.enter(cup.id(),shared.number(),white,"e2e4",0);
        assertEquals(1,waiting.ply());
        assertThrows(OnlineMatchException.class,()->service.enter(cupId,shared.number(),white,"e7e5",1));
        assertEquals(2,service.enter(cup.id(),shared.number(),black,"e7e5",1).ply());
        db.update("update practice_cup_game set result='1/2-1/2',started=true where cup_id=? and 0 in (white_seat,black_seat)",cupId);
        UUID nextCup=service.join(alice).id();
        assertNotEquals(cupId,nextCup);
        assertEquals(cupId,service.join(bob).id());
        // Once human games are settled, the remaining AI pairs play legal
        // chess in bounded batches and the next refresh resumes their moves.
        db.update("update practice_cup_game set result='1/2-1/2',started=true where cup_id=? and (white_seat in (0,1) or black_seat in (0,1))",cup.id());
        var first=service.standings(cup.id(),alice.id());
        var again=service.standings(cup.id(),bob.id());
        for(var g:first.games()) {
            if(g.white()<2 || g.black()<2) continue;
            assertTrue(g.started());
            assertTrue(g.moves().split(" ").length<=24);
            var continuation=again.games().get(g.number()-1);
            assertTrue(continuation.moves().startsWith(g.moves()));
            var board=new com.github.bhlangonijr.chesslib.Board();
            for(var move:continuation.moves().split(" ")) DailyPracticeCup.apply(board,move);
            assertEquals(DailyPracticeCup.result(board),continuation.result());
        }
        assertTrue(service.recentWinners().isEmpty());
        // Force a completed fixture with a human and a bot sharing the lead.
        db.update("update practice_cup_game set result=case when white_seat in (0,5) and black_seat not in (0,5) then '1-0' when black_seat in (0,5) and white_seat not in (0,5) then '0-1' else '1/2-1/2' end where cup_id=?",cupId);
        service.finishReadyCups();
        var winners=service.recentWinners();
        assertEquals(2,winners.size());
        assertTrue(winners.stream().anyMatch(w->w.bot()));
        assertTrue(winners.stream().anyMatch(w->w.name().equals("Alice")));
        var replay=service.join(alice);
        assertEquals(nextCup,replay.id());
        assertEquals(replay.id(),service.join(alice).id());
        assertEquals(replay.id(),service.join(bob).id());
        assertEquals(winners,service.recentWinners());
    }
}
