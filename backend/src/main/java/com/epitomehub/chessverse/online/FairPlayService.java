package com.epitomehub.chessverse.online;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
class FairPlayService {
    private final JdbcTemplate jdbc;
    FairPlayService(JdbcTemplate jdbc) { this.jdbc = jdbc; }
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    void record(UUID playerId, UUID matchId, String type, int severity, String evidence) {
        jdbc.update("insert into fair_play_signal(id,player_id,match_id,signal_type,severity,evidence,created_at) values(?,?,?,?,?,?,?)",
                UUID.randomUUID(),playerId,matchId,type,severity,evidence,Timestamp.from(Instant.now()));
    }
}
