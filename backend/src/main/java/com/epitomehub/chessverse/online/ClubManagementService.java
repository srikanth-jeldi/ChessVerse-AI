package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.sql.Timestamp;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ClubManagementService {
    private final JdbcTemplate jdbc;
    private final PlayerNotificationService notifications;

    ClubManagementService(JdbcTemplate jdbc, PlayerNotificationService notifications) {
        this.jdbc = jdbc;
        this.notifications = notifications;
    }

    @Transactional
    CommunityDtos.ClubDto create(AuthenticatedPlayer player, String rawName, String rawDescription) {
        String name = rawName.trim(), description = rawDescription.trim();
        if (name.length() < 3 || name.length() > 80 || description.length() > 240)
            throw new OnlineMatchException(HttpStatus.BAD_REQUEST, "Use a club name of 3–80 characters.");
        lockPlayer(player.id());
        Integer owned = jdbc.queryForObject(
                "select count(*) from chess_club_member where player_id=? and role='OWNER'",
                Integer.class, player.id());
        if (owned != null && owned >= 3)
            throw new OnlineMatchException(HttpStatus.CONFLICT, "You can own up to three clubs.");
        Integer duplicate = jdbc.queryForObject("select count(*) from chess_club where lower(name)=lower(?)",
                Integer.class, name);
        if (duplicate != null && duplicate > 0)
            throw new OnlineMatchException(HttpStatus.CONFLICT, "That club name is already in use.");
        UUID id = UUID.randomUUID();
        Timestamp now = Timestamp.from(Instant.now());
        try {
            jdbc.update("insert into chess_club(id,name,description,rating_requirement,created_at) values(?,?,?,0,?)",
                    id, name, description, now);
        } catch (DataIntegrityViolationException duplicateName) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "That club name is already in use.");
        }
        jdbc.update("insert into chess_club_member(club_id,player_id,role,joined_at) values(?,?,'OWNER',?)",
                id, player.id(), now);
        return new CommunityDtos.ClubDto(id, name, description, 1, 0, true);
    }

    @Transactional
    void invite(AuthenticatedPlayer player, UUID clubId, String rawIdentity) {
        String identity = rawIdentity.trim();
        if (identity.startsWith("@")) identity = identity.substring(1);
        if (identity.isBlank() || identity.length() > 254)
            throw new OnlineMatchException(HttpStatus.BAD_REQUEST, "Enter an email or @username.");
        lockPlayer(player.id());
        Integer member = jdbc.queryForObject(
                "select count(*) from chess_club_member where club_id=? and player_id=?",
                Integer.class, clubId, player.id());
        if (member == null || member != 1)
            throw new OnlineMatchException(HttpStatus.FORBIDDEN, "Join the club before inviting friends.");
        var recipients = jdbc.query(
                "select id from player_account where lower(username)=lower(?) or lower(email)=lower(?) limit 2",
                (rs, row) -> rs.getObject("id", UUID.class), identity, identity);
        if (recipients.size() != 1)
            throw new OnlineMatchException(HttpStatus.NOT_FOUND, "No matching player. Use their exact email or @username.");
        UUID recipient = recipients.getFirst();
        if (recipient.equals(player.id()))
            throw new OnlineMatchException(HttpStatus.BAD_REQUEST, "Choose another player.");
        Integer joined = jdbc.queryForObject(
                "select count(*) from chess_club_member where club_id=? and player_id=?",
                Integer.class, clubId, recipient);
        if (joined != null && joined > 0)
            throw new OnlineMatchException(HttpStatus.CONFLICT, "This player is already a club member.");
        String prefix = player.id() + ":" + LocalDate.now(ZoneOffset.UTC) + ":";
        Integer sent = jdbc.queryForObject("""
                select count(*) from notification_delivery_guard
                where notification_type='CLUB_INVITE' and delivery_key like ?
                """, Integer.class, prefix + "%");
        if (sent != null && sent >= 20)
            throw new OnlineMatchException(HttpStatus.TOO_MANY_REQUESTS, "Try more invitations tomorrow.");
        String name = jdbc.queryForObject("select name from chess_club where id=?", String.class, clubId);
        notifications.createOnce(recipient, "CLUB_INVITE", prefix + clubId,
                "Club invitation", player.displayName() + " invited you to join " + name + ".",
                "CLUB", clubId);
    }

    private void lockPlayer(UUID player) {
        jdbc.queryForObject("select id from player_account where id=? for update", UUID.class, player);
    }
}
