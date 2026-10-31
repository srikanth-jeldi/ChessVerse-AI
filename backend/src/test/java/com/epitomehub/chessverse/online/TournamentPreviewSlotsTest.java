package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

class TournamentPreviewSlotsTest {
    @Test void onlyRegisteredPlayersKeepTheirSlotsAcrossRefreshJoinAndWithdrawal() {
        var jdbc = new JdbcTemplate(new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";DB_CLOSE_DELAY=-1", "sa", ""));
        jdbc.execute("create table chess_tournament_entry(tournament_id uuid,player_id uuid,active boolean)");
        jdbc.execute("create table tournament_preview_slot(tournament_id uuid,player_id uuid,slot int,primary key(tournament_id,player_id),unique(tournament_id,slot))");
        UUID t=UUID.randomUUID(), a=UUID.randomUUID(), b=UUID.randomUUID(), c=UUID.randomUUID();
        jdbc.update("insert into chess_tournament_entry values(?,?,true),(?,?,true)",t,a,t,b);
        var initial=TournamentPreviewSlots.sync(jdbc,t);
        assertEquals(Set.of(a,b),new HashSet<>(initial));
        assertEquals(initial,TournamentPreviewSlots.sync(jdbc,t));
        jdbc.update("insert into chess_tournament_entry values(?,?,true)",t,c);
        var next=TournamentPreviewSlots.sync(jdbc,t);
        assertEquals(initial,next.subList(0,2));
        assertEquals(c,next.get(2));
        jdbc.update("update chess_tournament_entry set active=false where player_id=?",initial.get(0));
        var withdrawn=TournamentPreviewSlots.sync(jdbc,t);
        assertNull(withdrawn.get(0));
        assertEquals(initial.get(1),withdrawn.get(1));
        UUID replacement=UUID.randomUUID();
        jdbc.update("insert into chess_tournament_entry values(?,?,true)",t,replacement);
        var filled=TournamentPreviewSlots.sync(jdbc,t);
        assertEquals(replacement,filled.get(0));
        assertEquals(c,filled.get(2));
        assertEquals(3,new HashSet<>(filled).size());
    }
}
