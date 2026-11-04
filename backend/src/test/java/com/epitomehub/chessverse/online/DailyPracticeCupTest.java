package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import static org.junit.jupiter.api.Assertions.*;

class DailyPracticeCupTest {
    @Test void soloStartRealJoinResumeAndLegalTurns() throws Exception {
        var ds=new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+
                ";MODE=PostgreSQL;NON_KEYWORDS=DAY;DB_CLOSE_DELAY=-1","sa","");
        var db=new JdbcTemplate(ds);
        db.execute("create table player_account(id uuid primary key)");
        new ResourceDatabasePopulator(new ClassPathResource(
                "db/migration/V97__daily_practice_cup.sql"),new ClassPathResource(
                "db/migration/V98__practice_cup_lobby_and_finish.sql"),new ClassPathResource(
                "db/migration/V99__practice_cup_reply_delay.sql")).execute(ds);
        var alice=new AuthenticatedPlayer(UUID.randomUUID(),"alice","Alice",null);
        var bob=new AuthenticatedPlayer(UUID.randomUUID(),"bob","Bob",null);
        db.update("insert into player_account values(?),(?)",alice.id(),bob.id());
        var service=new DailyPracticeCup(db);
        var auth=mock(PlayerAuthenticationService.class);
        when(auth.requireBearer("Bearer test")).thenReturn(alice);
        var mvc=MockMvcBuilders.standaloneSetup(new DailyPracticeCupController(auth,service)).build();
        String api="/api/v1/community/practice-cups";
        mvc.perform(post(api+"/today").header("Authorization","Bearer test"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.mySeat").value(0))
                .andExpect(jsonPath("$.seats.length()").value(1))
                .andExpect(jsonPath("$.seats[0].bot").value(false))
                .andExpect(jsonPath("$.games.length()").value(0));
        var cup=service.join(alice);
        assertEquals(1,cup.seats().size());
        assertTrue(cup.lobbySeconds()>0 && cup.lobbySeconds()<=60);
        assertTrue(cup.games().isEmpty());
        UUID cupId=cup.id();
        assertThrows(OnlineMatchException.class,()->service.enter(cupId,1,alice.id(),null,null));
        // Age the same live cup instead of sleeping a minute in the test.
        for (int elapsed : new int[]{9,10,19,20,30,40,50,59}) {
            db.update("update practice_cup set starts_at=? where id=?",
                    java.sql.Timestamp.from(java.time.Instant.now().plusSeconds(60-elapsed)), cupId);
            var roster=service.standings(cupId,alice.id());
            assertEquals(elapsed/10,roster.seats().stream().filter(DailyPracticeCup.Seat::isBot).count());
            assertTrue(roster.games().isEmpty());
        }
        db.update("update practice_cup set starts_at=? where id=?",
                java.sql.Timestamp.from(java.time.Instant.now().plusSeconds(39)), cupId);
        var visibleBots=service.standings(cupId,alice.id()).seats().stream()
                .filter(DailyPracticeCup.Seat::isBot).toList();
        var lobby=service.join(bob);
        assertEquals(cup.id(),lobby.id());
        assertEquals(4,lobby.seats().size());
        assertTrue(lobby.seats().containsAll(visibleBots));
        assertTrue(lobby.seats().stream().anyMatch(seat -> bob.id().equals(seat.player())));
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
        mvc.perform(post(api+"/"+cupId+"/boards/1").header("Authorization","Bearer test")
                .contentType("application/json").content("{}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.cup.seats[5].bot").value(true))
                .andExpect(jsonPath("$.legal").isArray()).andExpect(jsonPath("$.ply").value(0));
        var next=service.enter(cup.id(),1,alice.id(),"e2e4",0);
        assertEquals(1,next.ply());
        var due=db.queryForObject("select bot_reply_at from practice_cup_game where cup_id=? and board_no=1",
                java.sql.Timestamp.class,cupId);
        assertTrue(due.toInstant().isAfter(java.time.Instant.now()));
        assertEquals(next.fen(),service.enter(cupId,1,alice.id(),null,null).fen());
        assertEquals(due,db.queryForObject("select bot_reply_at from practice_cup_game where cup_id=? and board_no=1",
                java.sql.Timestamp.class,cupId));
        db.update("update practice_cup_game set bot_reply_at=? where cup_id=? and board_no=1",
                java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(1)),cupId);
        next=service.enter(cupId,1,alice.id(),null,null);
        assertEquals(2,next.ply());
        assertThrows(OnlineMatchException.class,()->service.enter(cupId,1,alice.id(),"e2e4",0));
        assertEquals(next.fen(),service.enter(cup.id(),1,alice.id(),null,null).fen());
        var joined=service.join(bob);
        assertEquals(cup.id(),joined.id());
        assertEquals(1,joined.mySeat());
        var controller = new DailyPracticeCupController(auth, service);
        org.mockito.Mockito.when(auth.requireBearer("Bearer second")).thenReturn(bob);
        assertEquals("", controller.standings("Bearer second", cupId).games().stream()
                .filter(g -> g.number() == 1).findFirst().orElseThrow().moves());
        assertTrue(controller.standings("Bearer test", cupId).games().stream()
                .filter(g -> g.number() == 1).findFirst().orElseThrow().moves().startsWith("e2e4"));
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
