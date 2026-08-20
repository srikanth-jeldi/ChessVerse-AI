package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class PlayerNotificationService {
    private final JdbcTemplate jdbc;
    private final FirebasePushService push;
    PlayerNotificationService(JdbcTemplate jdbc, FirebasePushService push) { this.jdbc = jdbc; this.push = push; }

    void create(UUID playerId, String type, String title, String body,
                String actionType, UUID actionId) {
        jdbc.update("insert into player_notification(id,player_id,type,title,body,action_type,action_id,created_at) values(?,?,?,?,?,?,?,?)",
                UUID.randomUUID(), playerId, type, title, body, actionType, actionId, Instant.now());
        push.send(playerId, title, body, actionType, actionId);
    }

    @Transactional(readOnly = true)
    PlayerNotificationDtos.InboxDto inbox(AuthenticatedPlayer player, int requestedLimit) {
        int limit = Math.max(1, Math.min(100, requestedLimit));
        Long unread = jdbc.queryForObject("select count(*) from player_notification where player_id=? and read_at is null", Long.class, player.id());
        List<PlayerNotificationDtos.NotificationDto> rows = jdbc.query(
                "select * from player_notification where player_id=? order by created_at desc limit ?",
                this::map, player.id(), limit);
        return new PlayerNotificationDtos.InboxDto(unread == null ? 0 : unread, rows);
    }

    @Transactional
    PlayerNotificationDtos.InboxDto read(AuthenticatedPlayer player, UUID id) {
        jdbc.update("update player_notification set read_at=coalesce(read_at,?) where id=? and player_id=?", Instant.now(), id, player.id());
        return inbox(player, 50);
    }

    @Transactional
    PlayerNotificationDtos.InboxDto readAll(AuthenticatedPlayer player) {
        jdbc.update("update player_notification set read_at=? where player_id=? and read_at is null", Instant.now(), player.id());
        return inbox(player, 50);
    }

    private PlayerNotificationDtos.NotificationDto map(ResultSet rs, int row) throws SQLException {
        return new PlayerNotificationDtos.NotificationDto(
                rs.getObject("id", UUID.class), rs.getString("type"), rs.getString("title"),
                rs.getString("body"), rs.getString("action_type"),
                rs.getObject("action_id", UUID.class), rs.getTimestamp("created_at").toInstant(),
                rs.getTimestamp("read_at") != null);
    }
}
