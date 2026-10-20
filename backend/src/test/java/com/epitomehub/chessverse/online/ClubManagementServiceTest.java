package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.util.UUID;
import java.util.List;
import java.sql.ResultSet;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ClubManagementServiceTest {
    final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    final PlayerNotificationService notifications = mock(PlayerNotificationService.class);
    final ClubManagementService service = new ClubManagementService(jdbc, notifications);
    final AuthenticatedPlayer player = new AuthenticatedPlayer(UUID.randomUUID(), "owner", "Owner", null);

    @Test void createsClubAndOwnerMembershipTogether() {
        var club = service.create(player, "  Friendly chess  ", "Practice together");
        assertEquals("Friendly chess", club.name());
        assertTrue(club.joined());
        verify(jdbc).update(contains("insert into chess_club_member"), eq(club.id()), eq(player.id()), any());
    }

    @Test void preventsFourthOwnedClub() {
        when(jdbc.queryForObject(contains("role='OWNER'"), eq(Integer.class), eq(player.id()))).thenReturn(3);
        assertThrows(OnlineMatchException.class, () -> service.create(player, "Another club", ""));
        verify(jdbc, never()).update(contains("insert into chess_club"), any(Object[].class));
    }

    @Test void rejectsInvitationFromNonMember() {
        assertThrows(OnlineMatchException.class, () -> service.invite(player, UUID.randomUUID(), "@friend"));
        verifyNoInteractions(notifications);
    }

    @Test void rejectsInvalidClubNameBeforeDatabaseWork() {
        assertThrows(OnlineMatchException.class, () -> service.create(player, " a ", ""));
        verifyNoInteractions(jdbc);
    }

    @Test void resolvesExactEmailAndCreatesDeduplicatedInvitationWithoutJoining() throws Exception {
        var club = UUID.randomUUID();
        var recipient = UUID.randomUUID();
        when(jdbc.queryForObject(contains("chess_club_member"), eq(Integer.class), eq(club), eq(player.id()))).thenReturn(1);
        var rs = mock(ResultSet.class);
        when(rs.getObject("id", UUID.class)).thenReturn(recipient);
        doAnswer(call -> List.of(((RowMapper<?>) call.getArgument(1)).mapRow(rs, 0)))
                .when(jdbc).query(contains("lower(email)"), any(RowMapper.class), eq("friend@example.com"), eq("friend@example.com"));
        when(jdbc.queryForObject(contains("select name"), eq(String.class), eq(club))).thenReturn("Chess friends");
        service.invite(player, club, " friend@example.com ");
        verify(notifications).createOnce(eq(recipient), eq("CLUB_INVITE"),
                endsWith(club.toString()), eq("Club invitation"), contains("Chess friends"), eq("CLUB"), eq(club));
        verify(jdbc, never()).update(contains("insert into chess_club_member"), any(Object[].class));
    }
}
