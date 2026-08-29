package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class WebSocketTicketService {
    static final Duration LIFETIME = Duration.ofSeconds(30);
    private static final SecureRandom RANDOM = new SecureRandom();
    private final JdbcTemplate jdbc;
    private final OnlineMatchService matches;

    WebSocketTicketService(JdbcTemplate jdbc, OnlineMatchService matches) {
        this.jdbc = jdbc;
        this.matches = matches;
    }

    @Transactional
    Ticket issue(AuthenticatedPlayer player, UUID matchId) {
        if (!matches.isParticipant(player.id(), matchId)) {
            throw new OnlineMatchException(HttpStatus.FORBIDDEN, "You are not a player in this match.");
        }
        byte[] random = new byte[32];
        RANDOM.nextBytes(random);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(random);
        Instant now = Instant.now();
        Instant expiresAt = now.plus(LIFETIME);
        jdbc.update("insert into websocket_access_ticket(token_hash,player_id,match_id,expires_at,created_at) values(?,?,?,?,?)",
                sha256(token), player.id(), matchId, Timestamp.from(expiresAt), Timestamp.from(now));
        if (ThreadLocalRandom.current().nextInt(128) == 0) {
            jdbc.update("delete from websocket_access_ticket where expires_at < ?", Timestamp.from(now.minus(Duration.ofMinutes(5))));
        }
        return new Ticket(token, expiresAt);
    }

    @Transactional
    UUID consume(String token, UUID matchId) {
        if (token == null || token.length() < 40 || token.length() > 80) return null;
        Instant now = Instant.now();
        return jdbc.query("""
                update websocket_access_ticket
                set used_at=?
                where token_hash=? and match_id=? and used_at is null and expires_at>?
                returning player_id
                """, rs -> rs.next() ? rs.getObject("player_id", UUID.class) : null,
                Timestamp.from(now), sha256(token), matchId, Timestamp.from(now));
    }

    private static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception impossible) {
            throw new IllegalStateException(impossible);
        }
    }

    record Ticket(String ticket, Instant expiresAt) {}
}
