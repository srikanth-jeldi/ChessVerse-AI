package com.epitomehub.chessverse.online;

import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;

/** Called while holding the tournament row lock. Existing boards never shuffle. */
final class TournamentPreviewSlots {
    private TournamentPreviewSlots() {}

    static List<UUID> sync(JdbcTemplate jdbc, UUID tournament) {
        jdbc.update("""
            delete from tournament_preview_slot s where tournament_id=? and not exists
            (select 1 from chess_tournament_entry e where e.tournament_id=s.tournament_id
             and e.player_id=s.player_id and e.active=true)
            """, tournament);
        Map<Integer, UUID> slots = new TreeMap<>();
        jdbc.query("select slot,player_id from tournament_preview_slot where tournament_id=?",
            rs -> { slots.put(rs.getInt(1), rs.getObject(2, UUID.class)); }, tournament);
        List<UUID> incoming = jdbc.query("""
            select e.player_id from chess_tournament_entry e where tournament_id=? and active=true
            and not exists(select 1 from tournament_preview_slot s
              where s.tournament_id=e.tournament_id and s.player_id=e.player_id)
            """, (rs, n) -> rs.getObject(1, UUID.class), tournament);
        Collections.shuffle(incoming, new java.security.SecureRandom());
        for (UUID player : incoming) {
            int slot = 0;
            while (slots.containsKey(slot)) slot++;
            jdbc.update("insert into tournament_preview_slot(tournament_id,player_id,slot) values(?,?,?)",
                tournament, player, slot);
            slots.put(slot, player);
        }
        if (slots.isEmpty()) return List.of();
        List<UUID> ordered = new ArrayList<>(Collections.nCopies(Collections.max(slots.keySet()) + 1, null));
        slots.forEach(ordered::set);
        return ordered;
    }
}
