package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.economy.EconomyService;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ContentDisposition;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
class CommunityService {
    private final JdbcTemplate jdbc;
    private final FriendConnectionRepository friends;
    private final OnlinePresenceService presence;
    private final PlayerNotificationService notifications;
    private final Path attachmentRoot;
    private final AttachmentEncryptionService attachmentEncryption;
    private final EconomyService economy;

    CommunityService(JdbcTemplate jdbc, FriendConnectionRepository friends, OnlinePresenceService presence,
                     PlayerNotificationService notifications, AttachmentEncryptionService attachmentEncryption,
                     EconomyService economy,
                     @Value("${chessverse.attachments.directory:./data/chat-attachments}") String attachmentDirectory) {
        this.jdbc = jdbc; this.friends = friends; this.presence = presence; this.notifications = notifications;
        this.attachmentEncryption = attachmentEncryption;
        this.economy = economy;
        this.attachmentRoot = Path.of(attachmentDirectory).toAbsolutePath().normalize();
    }

    @Transactional
    CommunityDtos.HubDto hub(AuthenticatedPlayer player) {
        markDelivered(player);
        List<CommunityDtos.ClubDto> clubs = jdbc.query("""
                select c.id,c.name,c.description,c.rating_requirement,count(m.player_id) members,
                exists(select 1 from chess_club_member mine where mine.club_id=c.id and mine.player_id=?) joined
                from chess_club c left join chess_club_member m on m.club_id=c.id
                group by c.id,c.name,c.description,c.rating_requirement order by members desc,c.name
                """, (rs, row) -> new CommunityDtos.ClubDto(uuid(rs,"id"),rs.getString("name"),
                rs.getString("description"),rs.getInt("members"),rs.getInt("rating_requirement"),
                rs.getBoolean("joined")), player.id());
        List<CommunityDtos.TournamentDto> tournaments = jdbc.query("""
                select t.*,count(e.player_id) players,coalesce(sum(e.reserved_coins),0) prize_pool,
                exists(select 1 from chess_tournament_entry mine where mine.tournament_id=t.id and mine.player_id=? and mine.active=true) joined
                from chess_tournament t left join chess_tournament_entry e on e.tournament_id=t.id and e.active=true
                group by t.id order by t.starts_at
                """, (rs,row) -> new CommunityDtos.TournamentDto(uuid(rs,"id"),rs.getString("name"),
                rs.getString("description"),rs.getInt("time_control_minutes"),rs.getInt("players"),
                rs.getInt("capacity"),rs.getTimestamp("starts_at").toInstant(),rs.getTimestamp("ends_at").toInstant(),
                rs.getString("status"),rs.getBoolean("joined"),rs.getInt("entry_coins"),
                rs.getLong("prize_pool")), player.id());
        List<CommunityDtos.ConversationDto> conversations = jdbc.query("""
                select p.id,p.display_name,p.photo_url,
                (select d.body from direct_message d
                  where (d.sender_id=? and d.recipient_id=p.id) or (d.sender_id=p.id and d.recipient_id=?)
                  order by d.sent_at desc limit 1) body,
                (select d.sent_at from direct_message d
                  where (d.sender_id=? and d.recipient_id=p.id) or (d.sender_id=p.id and d.recipient_id=?)
                  order by d.sent_at desc limit 1) sent_at,
                (select count(*) from direct_message u where u.sender_id=p.id and u.recipient_id=? and u.read_at is null) unread
                from player_account p
                where exists(select 1 from friend_connection f where f.status='ACCEPTED'
                  and ((f.requester_id=? and f.addressee_id=p.id) or (f.addressee_id=? and f.requester_id=p.id)))
                  and exists(select 1 from direct_message d where
                    (d.sender_id=? and d.recipient_id=p.id) or (d.sender_id=p.id and d.recipient_id=?))
                order by sent_at desc limit 30
                """, (rs,row) -> new CommunityDtos.ConversationDto(uuid(rs,"id"),rs.getString("display_name"),
                rs.getString("photo_url"),presence.isOnline(uuid(rs,"id")),rs.getString("body"),
                rs.getTimestamp("sent_at").toInstant(),rs.getInt("unread")),
                player.id(),player.id(),player.id(),player.id(),player.id(),
                player.id(),player.id(),player.id(),player.id());
        Integer signals = jdbc.queryForObject("select count(*) from fair_play_signal where player_id=? and severity>=3", Integer.class, player.id());
        Integer circuitPoints = jdbc.queryForObject("""
                select
                  100 * (select count(*) from chess_tournament_entry where player_id=? and active=true) +
                  250 * (select count(*) from chess_tournament_pairing where winner_id=?) +
                  1000 * (select count(*) from chess_tournament where champion_id=?)
                """, Integer.class, player.id(), player.id(), player.id());
        return new CommunityDtos.HubDto(clubs,tournaments,conversations,
                Math.max(0,100-(signals == null ? 0 : signals*5)),
                circuitPoints == null ? 0 : circuitPoints);
    }

    @Transactional
    CommunityDtos.HubDto joinClub(AuthenticatedPlayer player, UUID clubId, boolean join) {
        requireExists("chess_club", clubId, "Club");
        if (join) {
            int added=jdbc.update("insert into chess_club_member(club_id,player_id,role,joined_at) values(?,?,'MEMBER',?) on conflict do nothing",clubId,player.id(),Timestamp.from(Instant.now()));
            if(added>0) notifications.create(player.id(),"CLUB_JOINED","Welcome to your new club","You joined a ChessVerseAI community club.","CLUB",clubId);
        }
        else jdbc.update("delete from chess_club_member where club_id=? and player_id=?",clubId,player.id());
        return hub(player);
    }

    @Transactional
    CommunityDtos.HubDto joinTournament(AuthenticatedPlayer player, UUID tournamentId, boolean join) {
        requireExists("chess_tournament", tournamentId, "Tournament");
        if (join) {
            Object[] tournament = jdbc.query("select status,starts_at,capacity,entry_coins from chess_tournament where id=? for update",
                    rs -> rs.next() ? new Object[]{rs.getString(1),rs.getTimestamp(2).toInstant(),rs.getInt(3),rs.getInt(4)} : null,
                    tournamentId);
            if (tournament == null || !"OPEN".equals(tournament[0]) || !((Instant)tournament[1]).isAfter(Instant.now()))
                throw new OnlineMatchException(HttpStatus.CONFLICT,"Tournament registration is closed.");
            Boolean active = jdbc.query("select active from chess_tournament_entry where tournament_id=? and player_id=? for update",
                    rs -> rs.next() ? rs.getBoolean(1) : null, tournamentId, player.id());
            if (Boolean.TRUE.equals(active)) return hub(player);
            Integer players = jdbc.queryForObject("select count(*) from chess_tournament_entry where tournament_id=? and active=true",Integer.class,tournamentId);
            if (players != null && players >= (Integer)tournament[2])
                throw new OnlineMatchException(HttpStatus.CONFLICT,"Tournament registration is full.");
            int entryCoins = (Integer)tournament[3];
            UUID reservationId = UUID.randomUUID();
            economy.spend(player.id(),"COINS",entryCoins,"TOURNAMENT_ENTRY_RESERVED",
                    "tournament:"+tournamentId+":entry:"+reservationId,"Tournament entry reserved");
            if (active == null) {
                jdbc.update("""
                        insert into chess_tournament_entry(tournament_id,player_id,joined_at,active,reserved_coins,reservation_id,refunded_at)
                        values(?,?,?,true,?,?,null)
                        """,tournamentId,player.id(),Timestamp.from(Instant.now()),entryCoins,reservationId);
            } else {
                jdbc.update("""
                        update chess_tournament_entry set joined_at=?,active=true,reserved_coins=?,
                        reservation_id=?,refunded_at=null where tournament_id=? and player_id=?
                        """,Timestamp.from(Instant.now()),entryCoins,reservationId,tournamentId,player.id());
            }
            notifications.create(player.id(),"TOURNAMENT_REGISTERED","Tournament registration confirmed",
                    entryCoins+" play coins reserved. Your entry is confirmed.","TOURNAMENT",tournamentId);
        }
        else {
            Object[] entry = jdbc.query("""
                    select e.reserved_coins,e.reservation_id from chess_tournament_entry e
                    join chess_tournament t on t.id=e.tournament_id
                    where e.tournament_id=? and e.player_id=? and e.active=true
                      and t.status='OPEN' and t.starts_at>? for update
                    """,rs -> rs.next() ? new Object[]{rs.getInt(1),rs.getObject(2,UUID.class)} : null,
                    tournamentId,player.id(),Timestamp.from(Instant.now()));
            if (entry == null) throw new OnlineMatchException(HttpStatus.CONFLICT,"Tournament entry can no longer be withdrawn.");
            jdbc.update("update chess_tournament_entry set active=false,refunded_at=? where tournament_id=? and player_id=?",
                    Timestamp.from(Instant.now()),tournamentId,player.id());
            if ((Integer)entry[0] > 0 && entry[1] != null) economy.grantCoins(player.id(),(Integer)entry[0],
                    "TOURNAMENT_ENTRY_REFUND","tournament:"+tournamentId+":refund:"+entry[1],"Tournament entry returned");
        }
        return hub(player);
    }

    @Transactional
    CommunityDtos.MessageDto send(AuthenticatedPlayer player, UUID recipientId, String body) {
        FriendConnection link = friends.between(player.id(), recipientId).orElse(null);
        if (link == null || !"ACCEPTED".equals(link.status)) throw new OnlineMatchException(HttpStatus.FORBIDDEN,"Messages are available between accepted friends only.");
        UUID id=UUID.randomUUID(); Instant now=Instant.now(); String clean=body.trim();
        jdbc.update("insert into direct_message(id,sender_id,recipient_id,body,sent_at) values(?,?,?,?,?)",id,player.id(),recipientId,clean,Timestamp.from(now));
        notifications.create(recipientId,"MESSAGE_RECEIVED","New message from "+player.displayName(),clean,"CHAT",player.id());
        return new CommunityDtos.MessageDto(id,player.id(),recipientId,clean,now,true,false,false,null,null,null);
    }

    @Transactional
    CommunityDtos.MessageDto sendAttachment(AuthenticatedPlayer player, UUID recipientId, String body, MultipartFile file) {
        requireFriends(player.id(), recipientId);
        if (file == null || file.isEmpty()) throw new OnlineMatchException(HttpStatus.BAD_REQUEST,"Choose a file to attach.");
        if (file.getSize() > AttachmentPolicy.MAX_BYTES) throw new OnlineMatchException(HttpStatus.PAYLOAD_TOO_LARGE,"Attachments must be 10 MB or smaller.");
        AttachmentPolicy.AcceptedAttachment accepted;
        try { accepted = AttachmentPolicy.inspect(file.getBytes(), file.getOriginalFilename()); }
        catch (IOException error) { throw new OnlineMatchException(HttpStatus.BAD_REQUEST,"The attachment could not be read."); }
        String original = accepted.filename();
        String type = accepted.mediaType();
        UUID id = UUID.randomUUID(); Instant now = Instant.now();
        String stored = id + accepted.extension();
        try {
            Files.createDirectories(attachmentRoot);
            Path destination = attachmentRoot.resolve(stored).normalize();
            if (!destination.startsWith(attachmentRoot)) throw new IOException("Invalid attachment path");
            Path temporary = Files.createTempFile(attachmentRoot, id.toString(), ".upload");
            try {
                Files.write(temporary, attachmentEncryption.encrypt(accepted.bytes(), id.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8)));
                Files.move(temporary, destination, StandardCopyOption.ATOMIC_MOVE);
            } finally {
                Files.deleteIfExists(temporary);
            }
        } catch (IOException error) {
            throw new OnlineMatchException(HttpStatus.INTERNAL_SERVER_ERROR,"The attachment could not be stored.");
        }
        String clean = body == null ? "" : body.trim();
        jdbc.update("insert into direct_message(id,sender_id,recipient_id,body,sent_at,attachment_name,attachment_type,attachment_size,attachment_path) values(?,?,?,?,?,?,?,?,?)",
                id,player.id(),recipientId,clean,Timestamp.from(now),original,type,(long)accepted.bytes().length,stored);
        notifications.create(recipientId,"MESSAGE_RECEIVED","New attachment from "+player.displayName(),original,"CHAT",player.id());
        return new CommunityDtos.MessageDto(id,player.id(),recipientId,clean,now,true,false,false,original,type,(long)accepted.bytes().length);
    }

    @Transactional
    void markDelivered(AuthenticatedPlayer player) {
        jdbc.update("update direct_message set delivered_at=? where recipient_id=? and delivered_at is null",Timestamp.from(Instant.now()),player.id());
    }

    @Transactional
    List<CommunityDtos.MessageDto> messages(AuthenticatedPlayer player, UUID friendId) {
        requireFriends(player.id(), friendId);
        jdbc.update("update direct_message set delivered_at=coalesce(delivered_at,?),read_at=? where sender_id=? and recipient_id=? and read_at is null",Timestamp.from(Instant.now()),Timestamp.from(Instant.now()),friendId,player.id());
        return jdbc.query("select * from direct_message where (sender_id=? and recipient_id=?) or (sender_id=? and recipient_id=?) order by sent_at desc limit 100",
                (rs,row)->new CommunityDtos.MessageDto(uuid(rs,"id"),uuid(rs,"sender_id"),uuid(rs,"recipient_id"),rs.getString("body"),rs.getTimestamp("sent_at").toInstant(),uuid(rs,"sender_id").equals(player.id()),rs.getTimestamp("delivered_at")!=null,rs.getTimestamp("read_at")!=null,rs.getString("attachment_name"),rs.getString("attachment_type"),(Long)rs.getObject("attachment_size")),
                player.id(),friendId,friendId,player.id()).reversed();
    }

    @Transactional(readOnly = true)
    ResponseEntity<Resource> attachment(AuthenticatedPlayer player, UUID messageId) {
        return jdbc.query("select sender_id,recipient_id,attachment_name,attachment_type,attachment_path from direct_message where id=? and attachment_path is not null",
                rs -> {
                    if (!rs.next()) throw new OnlineMatchException(HttpStatus.NOT_FOUND,"Attachment was not found.");
                    UUID sender = uuid(rs,"sender_id"), recipient = uuid(rs,"recipient_id");
                    if (!player.id().equals(sender) && !player.id().equals(recipient)) throw new OnlineMatchException(HttpStatus.FORBIDDEN,"This attachment is not available.");
                    Path path = attachmentRoot.resolve(rs.getString("attachment_path")).normalize();
                    if (!path.startsWith(attachmentRoot) || !Files.isRegularFile(path)) throw new OnlineMatchException(HttpStatus.NOT_FOUND,"Attachment was not found.");
                    byte[] plaintext;
                    try {
                        plaintext = attachmentEncryption.decrypt(Files.readAllBytes(path),
                                messageId.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
                    } catch (IOException | IllegalStateException error) {
                        throw new OnlineMatchException(HttpStatus.INTERNAL_SERVER_ERROR,"The attachment could not be decrypted.");
                    }
                    Resource resource = new ByteArrayResource(plaintext);
                    MediaType media;
                    try { media = MediaType.parseMediaType(rs.getString("attachment_type")); }
                    catch (Exception ignored) { media = MediaType.APPLICATION_OCTET_STREAM; }
                    ContentDisposition disposition = ContentDisposition.attachment()
                            .filename(rs.getString("attachment_name"), java.nio.charset.StandardCharsets.UTF_8).build();
                    return ResponseEntity.ok().contentType(media)
                            .header("Content-Disposition", disposition.toString())
                            .header("X-Content-Type-Options", "nosniff")
                            .header("Content-Security-Policy", "default-src 'none'; sandbox")
                            .header("Cache-Control", "private, no-store")
                            .body(resource);
                },messageId);
    }

    private void requireFriends(UUID first, UUID second) {
        FriendConnection link = friends.between(first, second).orElse(null);
        if (link == null || !"ACCEPTED".equals(link.status)) throw new OnlineMatchException(HttpStatus.FORBIDDEN,"This conversation is available between accepted friends only.");
    }

    private void requireExists(String table, UUID id, String label) {
        Integer found=jdbc.queryForObject("select count(*) from "+table+" where id=?",Integer.class,id);
        if(found==null||found==0) throw new OnlineMatchException(HttpStatus.NOT_FOUND,label+" was not found.");
    }
    private static UUID uuid(ResultSet rs,String name) throws SQLException { return rs.getObject(name,UUID.class); }
}
