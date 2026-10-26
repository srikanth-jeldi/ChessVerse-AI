package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ClubEmailInvitationService {
    private static final Logger log = LoggerFactory.getLogger(ClubEmailInvitationService.class);
    private final JdbcTemplate db;
    private final ClubInvitationMailService mail;
    private final PlayerNotificationService notifications;

    ClubEmailInvitationService(JdbcTemplate db, ClubInvitationMailService mail, PlayerNotificationService notifications) {
        this.db = db; this.mail = mail; this.notifications = notifications;
    }

    static String normalizeEmail(String raw) {
        String value = raw == null ? "" : raw.trim().toLowerCase(Locale.ROOT);
        if (value.length() > 254 || !value.matches("[^\\s@<>]+@[^\\s@<>]+\\.[^\\s@<>]+") || value.endsWith(".invalid"))
            throw new OnlineMatchException(HttpStatus.BAD_REQUEST, "Enter a valid email address.");
        return value;
    }

    @Transactional
    void invite(AuthenticatedPlayer sender, UUID clubId, String rawEmail) {
        String email = normalizeEmail(rawEmail);
        Integer eligible = db.queryForObject("select count(*) from player_account where id=? and guest_account=false and verified=true",
                Integer.class, sender.id());
        if (eligible == null || eligible == 0) throw new OnlineMatchException(HttpStatus.FORBIDDEN, "Sign in to invite friends.");
        db.queryForObject("select id from player_account where id=? for update", UUID.class, sender.id());
        Integer member = db.queryForObject("select count(*) from chess_club_member where club_id=? and player_id=?", Integer.class, clubId, sender.id());
        if (member == null || member == 0) throw new OnlineMatchException(HttpStatus.FORBIDDEN, "Join the club before inviting friends.");
        Instant now = Instant.now();
        // Expired invitations may be replaced, but repeated taps cannot send repeated mail.
        db.update("update club_email_invitation set status='EXPIRED' where club_id=? and recipient_email=? and status='PENDING' and expires_at<=?",
                clubId, email, Timestamp.from(now));
        Integer pending = db.queryForObject("select count(*) from club_email_invitation where club_id=? and recipient_email=? and status='PENDING'", Integer.class, clubId, email);
        if (pending != null && pending > 0) return;
        // Respect a recipient's decline even when another member sends the invite.
        Integer declined = db.queryForObject("select count(*) from club_email_invitation where club_id=? and recipient_email=? and status='DECLINED' and responded_at>?",
                Integer.class, clubId, email, Timestamp.from(now.minus(Duration.ofDays(7))));
        if (declined != null && declined > 0) return;
        Integer recent = db.queryForObject("select count(*) from club_email_invitation where sender_id=? and created_at>?", Integer.class, sender.id(), Timestamp.from(now.minus(Duration.ofDays(1))));
        if (recent != null && recent >= 20) throw new OnlineMatchException(HttpStatus.TOO_MANY_REQUESTS, "Try more invitations tomorrow.");
        // Uniform response for registered and external addresses; no account enumeration.
        Integer alreadyMember = db.queryForObject("select count(*) from chess_club_member m join player_account p on p.id=m.player_id where m.club_id=? and lower(p.email)=?", Integer.class, clubId, email);
        if (alreadyMember != null && alreadyMember > 0) return;
        db.update("""
                insert into club_email_invitation(id,club_id,sender_id,recipient_email,created_at,expires_at)
                values(?,?,?,?,?,?) on conflict do nothing
                """, UUID.randomUUID(), clubId, sender.id(), email, Timestamp.from(now), Timestamp.from(now.plus(Duration.ofDays(7))));
    }

    @Transactional(readOnly = true)
    List<Invitation> incoming(AuthenticatedPlayer player) {
        return db.query("""
                select i.id,i.club_id,c.name,p.display_name,i.expires_at from club_email_invitation i
                join chess_club c on c.id=i.club_id join player_account p on p.id=i.sender_id
                join player_account recipient on lower(recipient.email)=i.recipient_email
                where recipient.id=? and recipient.verified=true and recipient.guest_account=false
                  and i.status='PENDING' and i.expires_at>?
                order by i.created_at desc limit 50
                """, (rs,n) -> new Invitation(rs.getObject(1,UUID.class),rs.getObject(2,UUID.class),rs.getString(3),rs.getString(4),rs.getTimestamp(5).toInstant()), player.id(),Timestamp.from(Instant.now()));
    }

    @Transactional
    UUID respond(AuthenticatedPlayer player, UUID invitationId, boolean accept) {
        // The link is a navigation hint, not an authentication credential. Only the
        // verified owner of the invited email can accept, including a new account.
        var rows = db.query("""
                select i.club_id,i.status,i.expires_at from club_email_invitation i
                where i.id=? and exists(select 1 from player_account p where lower(p.email)=i.recipient_email
                  and p.id=? and p.verified=true and p.guest_account=false) for update
                """, (rs,n) -> new ResponseRow(rs.getObject(1,UUID.class),rs.getString(2),rs.getTimestamp(3).toInstant()), invitationId,player.id());
        if (rows.isEmpty()) throw new OnlineMatchException(HttpStatus.NOT_FOUND, "Sign in with the email that received this invitation.");
        ResponseRow invite = rows.getFirst();
        if ("ACCEPTED".equals(invite.status()) && accept) return invite.clubId();
        if (!"PENDING".equals(invite.status()) || !invite.expiresAt().isAfter(Instant.now()))
            throw new OnlineMatchException(HttpStatus.CONFLICT, "This invitation has expired or was already answered.");
        if (accept) db.update("insert into chess_club_member(club_id,player_id,role,joined_at) values(?,?,'MEMBER',?) on conflict do nothing", invite.clubId(),player.id(),Timestamp.from(Instant.now()));
        db.update("update club_email_invitation set status=?,responded_by=?,responded_at=? where id=?",
                accept ? "ACCEPTED" : "DECLINED",player.id(),Timestamp.from(Instant.now()),invitationId);
        if (accept) notifications.createOnce(player.id(),"CLUB_JOINED",invitationId.toString(),"Welcome to your new club","Your club invitation was accepted.","CLUB",invite.clubId());
        return invite.clubId();
    }

    // Durable outbox: send only committed invitations, including after a restart.
    @Transactional
    public void deliverPending() {
        var rows = db.query("""
                select i.id,i.recipient_email,c.name,p.display_name from club_email_invitation i
                join chess_club c on c.id=i.club_id join player_account p on p.id=i.sender_id
                where i.status='PENDING' and i.sent_at is null and i.mail_attempts<3 and i.expires_at>?
                  and (i.last_mail_attempt_at is null or i.last_mail_attempt_at<?)
                order by i.created_at limit 20 for update of i skip locked
                """, (rs,n) -> new MailRow(rs.getObject(1,UUID.class),rs.getString(2),rs.getString(3),rs.getString(4)), Timestamp.from(Instant.now()),Timestamp.from(Instant.now().minus(Duration.ofMinutes(5))));
        for (MailRow row : rows) {
            db.update("update club_email_invitation set mail_attempts=mail_attempts+1,last_mail_attempt_at=? where id=?",Timestamp.from(Instant.now()),row.id());
            try {
                mail.send(row.email(),row.club(),row.sender(),row.id());
                db.update("update club_email_invitation set sent_at=? where id=?",Timestamp.from(Instant.now()),row.id());
            } catch (Exception failure) {
                log.warn("Club invitation {} mail failed: {}",row.id(),failure.getClass().getSimpleName());
            }
        }
    }

    record Invitation(UUID id, UUID clubId, String clubName, String inviterName, Instant expiresAt) {}
    record ResponseRow(UUID clubId, String status, Instant expiresAt) {}
    record MailRow(UUID id, String email, String club, String sender) {}
}
