package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ClubEmailInvitationServiceTest {
    JdbcTemplate db;
    ClubEmailInvitationService service;
    final ClubInvitationMailService mail = mock(ClubInvitationMailService.class);
    final PlayerNotificationService notifications = mock(PlayerNotificationService.class);
    final AuthenticatedPlayer sender = player("owner");
    final UUID club = UUID.randomUUID();
    static AuthenticatedPlayer player(String name) { return new AuthenticatedPlayer(UUID.randomUUID(),name,name,null); }

    @BeforeEach void setup() {
        db = new JdbcTemplate(new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_UPPER=false;DB_CLOSE_DELAY=-1","sa",""));
        db.execute("create table player_account(id uuid primary key,email varchar(254),display_name varchar(80),verified boolean,guest_account boolean)");
        db.execute("create table chess_club(id uuid primary key,name varchar(80))");
        db.execute("create table chess_club_member(club_id uuid,player_id uuid,role varchar(20),joined_at timestamp with time zone,primary key(club_id,player_id))");
        db.execute("create table club_email_invitation(id uuid primary key,club_id uuid,sender_id uuid,recipient_email varchar(254),status varchar(16) default 'PENDING',created_at timestamp with time zone,expires_at timestamp with time zone,responded_by uuid,responded_at timestamp with time zone,sent_at timestamp with time zone,mail_attempts int default 0,last_mail_attempt_at timestamp with time zone)");
        account(sender,"owner@example.com",true,false);
        db.update("insert into chess_club values(?,?)",club,"Chess friends");
        db.update("insert into chess_club_member values(?,?,'OWNER',?)",club,sender.id(),Timestamp.from(Instant.now()));
        service = new ClubEmailInvitationService(db,mail,notifications);
    }

    void account(AuthenticatedPlayer player, String email, boolean verified, boolean guest) {
        db.update("insert into player_account values(?,?,?,?,?)",player.id(),email,player.displayName(),verified,guest);
    }
    UUID invite() {
        service.invite(sender,club," Future@Example.com ");
        return db.queryForObject("select id from club_email_invitation",UUID.class);
    }

    @Test void externalRecipientCanRegisterLaterAndExplicitlyAcceptExactlyOnce() {
        UUID id = invite();
        assertEquals(1,db.queryForObject("select count(*) from player_account",Integer.class));
        assertEquals(1,db.queryForObject("select count(*) from chess_club_member",Integer.class));
        var recipient = player("new friend"); account(recipient,"future@example.com",true,false);
        assertEquals(id,service.incoming(recipient).getFirst().id());
        assertEquals(club,service.respond(recipient,id,true));
        assertEquals(club,service.respond(recipient,id,true));
        assertEquals(2,db.queryForObject("select count(*) from chess_club_member",Integer.class));
        assertTrue(service.incoming(recipient).isEmpty());
        verify(notifications,times(1)).createOnce(eq(recipient.id()),eq("CLUB_JOINED"),eq(id.toString()),anyString(),anyString(),eq("CLUB"),eq(club));
    }
    @Test void duplicateInviteDoesNotQueueAnotherEmail() {
        UUID id = invite(); service.invite(sender,club,"future@example.com");
        assertEquals(id,db.queryForObject("select id from club_email_invitation",UUID.class));
    }
    @Test void wrongAccountUnverifiedAccountAndGuestCannotAccept() {
        UUID id = invite();
        for (int n=0;n<3;n++) {
            var player = player("blocked"+n);
            account(player,n==0 ? "other@example.com" : "future@example.com",n!=1,n==2);
            assertTrue(service.incoming(player).isEmpty());
            assertThrows(OnlineMatchException.class,() -> service.respond(player,id,true));
        }
        assertEquals(1,db.queryForObject("select count(*) from chess_club_member",Integer.class));
    }
    @Test void declineNeverJoinsAndExpiredInvitationCannotJoin() {
        UUID id = invite(); var recipient=player("friend"); account(recipient,"future@example.com",true,false);
        service.respond(recipient,id,false);
        assertThrows(OnlineMatchException.class,() -> service.respond(recipient,id,true));
        db.update("update club_email_invitation set status='PENDING',expires_at=?",Timestamp.from(Instant.now().minusSeconds(1)));
        assertThrows(OnlineMatchException.class,() -> service.respond(recipient,id,true));
        assertEquals(1,db.queryForObject("select count(*) from chess_club_member",Integer.class));
    }
    @Test void onlyMembersCanInviteAndInvalidAddressesNeverQueue() {
        var outsider=player("outsider"); account(outsider,"outside@example.com",true,false);
        assertThrows(OnlineMatchException.class,() -> service.invite(outsider,club,"future@example.com"));
        for (String bad : new String[]{null,"not-email","a@identity.chessverse.invalid","a@example.com\r\nBcc:x@example.com"})
            assertThrows(OnlineMatchException.class,() -> service.invite(sender,club,bad));
        assertEquals(0,db.queryForObject("select count(*) from club_email_invitation",Integer.class));
    }
    @Test void limitsInvitesToTwentyPerSenderPerDay() {
        for (int i=0;i<20;i++) service.invite(sender,club,"friend"+i+"@example.com");
        assertThrows(OnlineMatchException.class,() -> service.invite(sender,club,"extra@example.com"));
    }
    @Test void declineSuppressesOtherMembersInvitesForSevenDays() {
        UUID id = invite();
        var recipient = player("friend"); account(recipient,"future@example.com",true,false);
        service.respond(recipient,id,false);
        var other = player("other member"); account(other,"other@example.com",true,false);
        db.update("insert into chess_club_member values(?,?,'MEMBER',?)",club,other.id(),Timestamp.from(Instant.now()));
        service.invite(other,club,"future@example.com");
        assertEquals(1,db.queryForObject("select count(*) from club_email_invitation",Integer.class));
        db.update("update club_email_invitation set responded_at=? where id=?",Timestamp.from(Instant.now().minusSeconds(8*86400)),id);
        service.invite(other,club,"future@example.com");
        assertEquals(2,db.queryForObject("select count(*) from club_email_invitation",Integer.class));
    }
    @Test void outboxRecordsDeliveryAndDoesNotSendAgain() throws Exception {
        UUID id=invite();
        service.deliverPending(); service.deliverPending();
        verify(mail,times(1)).send(eq("future@example.com"),eq("Chess friends"),eq("owner"),eq(id));
        assertNotNull(db.queryForObject("select sent_at from club_email_invitation",Timestamp.class));
    }
    @Test void mailFailureRetainsInvitationAndBacksOffBeforeRetry() throws Exception {
        invite(); doThrow(new IllegalStateException("offline")).when(mail).send(anyString(),anyString(),anyString(),any());
        service.deliverPending(); service.deliverPending();
        verify(mail,times(1)).send(anyString(),anyString(),anyString(),any());
        assertNull(db.queryForObject("select sent_at from club_email_invitation",Timestamp.class));
        assertEquals(1,db.queryForObject("select mail_attempts from club_email_invitation",Integer.class));
        assertEquals("PENDING",db.queryForObject("select status from club_email_invitation",String.class));
    }
}
