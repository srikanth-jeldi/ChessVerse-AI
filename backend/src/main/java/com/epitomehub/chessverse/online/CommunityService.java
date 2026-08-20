package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class CommunityService {
    private final JdbcTemplate jdbc;
    private final FriendConnectionRepository friends;
    private final OnlinePresenceService presence;
    private final PlayerNotificationService notifications;

    CommunityService(JdbcTemplate jdbc, FriendConnectionRepository friends, OnlinePresenceService presence,
                     PlayerNotificationService notifications) {
        this.jdbc = jdbc; this.friends = friends; this.presence = presence; this.notifications = notifications;
    }

    @Transactional(readOnly = true)
    CommunityDtos.HubDto hub(AuthenticatedPlayer player) {
        List<CommunityDtos.ClubDto> clubs = jdbc.query("""
                select c.id,c.name,c.description,c.rating_requirement,count(m.player_id) members,
                exists(select 1 from chess_club_member mine where mine.club_id=c.id and mine.player_id=?) joined
                from chess_club c left join chess_club_member m on m.club_id=c.id
                group by c.id,c.name,c.description,c.rating_requirement order by members desc,c.name
                """, (rs, row) -> new CommunityDtos.ClubDto(uuid(rs,"id"),rs.getString("name"),
                rs.getString("description"),rs.getInt("members"),rs.getInt("rating_requirement"),
                rs.getBoolean("joined")), player.id());
        List<CommunityDtos.TournamentDto> tournaments = jdbc.query("""
                select t.*,count(e.player_id) players,
                exists(select 1 from chess_tournament_entry mine where mine.tournament_id=t.id and mine.player_id=?) joined
                from chess_tournament t left join chess_tournament_entry e on e.tournament_id=t.id
                group by t.id order by t.starts_at
                """, (rs,row) -> new CommunityDtos.TournamentDto(uuid(rs,"id"),rs.getString("name"),
                rs.getString("description"),rs.getInt("time_control_minutes"),rs.getInt("players"),
                rs.getInt("capacity"),rs.getTimestamp("starts_at").toInstant(),rs.getTimestamp("ends_at").toInstant(),
                rs.getString("status"),rs.getBoolean("joined")), player.id());
        List<CommunityDtos.ConversationDto> conversations = jdbc.query("""
                select p.id,p.display_name,p.photo_url,m.body,m.sent_at,
                (select count(*) from direct_message u where u.sender_id=p.id and u.recipient_id=? and u.read_at is null) unread
                from player_account p join lateral (
                  select body,sent_at from direct_message d
                  where (d.sender_id=? and d.recipient_id=p.id) or (d.sender_id=p.id and d.recipient_id=?)
                  order by sent_at desc limit 1
                ) m on true
                where exists(select 1 from friend_connection f where f.status='ACCEPTED'
                  and ((f.requester_id=? and f.addressee_id=p.id) or (f.addressee_id=? and f.requester_id=p.id)))
                order by m.sent_at desc limit 30
                """, (rs,row) -> new CommunityDtos.ConversationDto(uuid(rs,"id"),rs.getString("display_name"),
                rs.getString("photo_url"),presence.isOnline(uuid(rs,"id")),rs.getString("body"),
                rs.getTimestamp("sent_at").toInstant(),rs.getInt("unread")),
                player.id(),player.id(),player.id(),player.id(),player.id());
        Integer signals = jdbc.queryForObject("select count(*) from fair_play_signal where player_id=? and severity>=3", Integer.class, player.id());
        return new CommunityDtos.HubDto(clubs,tournaments,conversations,Math.max(0,100-(signals == null ? 0 : signals*5)));
    }

    @Transactional
    CommunityDtos.HubDto joinClub(AuthenticatedPlayer player, UUID clubId, boolean join) {
        requireExists("chess_club", clubId, "Club");
        if (join) {
            int added=jdbc.update("insert into chess_club_member(club_id,player_id,role,joined_at) values(?,?,'MEMBER',?) on conflict do nothing",clubId,player.id(),Instant.now());
            if(added>0) notifications.create(player.id(),"CLUB_JOINED","Welcome to your new club","You joined a ChessVerseAI community club.","CLUB",clubId);
        }
        else jdbc.update("delete from chess_club_member where club_id=? and player_id=?",clubId,player.id());
        return hub(player);
    }

    @Transactional
    CommunityDtos.HubDto joinTournament(AuthenticatedPlayer player, UUID tournamentId, boolean join) {
        requireExists("chess_tournament", tournamentId, "Tournament");
        if (join) {
            int added=jdbc.update("insert into chess_tournament_entry(tournament_id,player_id,joined_at) values(?,?,?) on conflict do nothing",tournamentId,player.id(),Instant.now());
            if(added>0) notifications.create(player.id(),"TOURNAMENT_REGISTERED","Tournament registration confirmed","We will remind you before your ChessVerseAI tournament starts.","TOURNAMENT",tournamentId);
        }
        else jdbc.update("delete from chess_tournament_entry where tournament_id=? and player_id=?",tournamentId,player.id());
        return hub(player);
    }

    @Transactional
    CommunityDtos.MessageDto send(AuthenticatedPlayer player, UUID recipientId, String body) {
        FriendConnection link = friends.between(player.id(), recipientId).orElse(null);
        if (link == null || !"ACCEPTED".equals(link.status)) throw new OnlineMatchException(HttpStatus.FORBIDDEN,"Messages are available between accepted friends only.");
        UUID id=UUID.randomUUID(); Instant now=Instant.now(); String clean=body.trim();
        jdbc.update("insert into direct_message(id,sender_id,recipient_id,body,sent_at) values(?,?,?,?,?)",id,player.id(),recipientId,clean,now);
        notifications.create(recipientId,"MESSAGE_RECEIVED","New message from "+player.displayName(),clean,"CHAT",player.id());
        return new CommunityDtos.MessageDto(id,player.id(),recipientId,clean,now,true);
    }

    @Transactional
    List<CommunityDtos.MessageDto> messages(AuthenticatedPlayer player, UUID friendId) {
        FriendConnection link = friends.between(player.id(), friendId).orElse(null);
        if (link == null || !"ACCEPTED".equals(link.status)) throw new OnlineMatchException(HttpStatus.FORBIDDEN,"This conversation is not available.");
        jdbc.update("update direct_message set read_at=? where sender_id=? and recipient_id=? and read_at is null",Instant.now(),friendId,player.id());
        return jdbc.query("select * from direct_message where (sender_id=? and recipient_id=?) or (sender_id=? and recipient_id=?) order by sent_at desc limit 100",
                (rs,row)->new CommunityDtos.MessageDto(uuid(rs,"id"),uuid(rs,"sender_id"),uuid(rs,"recipient_id"),rs.getString("body"),rs.getTimestamp("sent_at").toInstant(),uuid(rs,"sender_id").equals(player.id())),
                player.id(),friendId,friendId,player.id()).reversed();
    }

    private void requireExists(String table, UUID id, String label) {
        Integer found=jdbc.queryForObject("select count(*) from "+table+" where id=?",Integer.class,id);
        if(found==null||found==0) throw new OnlineMatchException(HttpStatus.NOT_FOUND,label+" was not found.");
    }
    private static UUID uuid(ResultSet rs,String name) throws SQLException { return rs.getObject(name,UUID.class); }
}
