package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.ResultSet;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ClubChallengeTest {
    @Test void flushesNewJpaMatchBeforeInsertingJdbcClubForeignKey() throws Exception {
        var jdbc=mock(JdbcTemplate.class);
        var challenges=mock(SocialChallengeRepository.class);
        var matches=mock(OnlineMatchService.class);
        var service=new SocialService(mock(FriendConnectionRepository.class),challenges,matches,
                mock(OnlinePlayerRatingRepository.class),mock(OnlinePresenceService.class),jdbc,mock(PlayerNotificationService.class));
        var player=new AuthenticatedPlayer(UUID.randomUUID(),"qa","QA",null);
        var club=UUID.randomUUID(); var other=UUID.randomUUID(); var match=UUID.randomUUID();
        when(jdbc.queryForObject(anyString(),eq(Integer.class),eq(club),eq(player.id()),eq(other))).thenReturn(2);
        var room=mock(OnlineDtos.MatchDto.class);
        when(room.id()).thenReturn(match); when(room.roomCode()).thenReturn("QATEST");
        when(matches.createChallengeRoom(player,5)).thenReturn(room);
        when(challenges.save(any())).thenAnswer(call->call.getArgument(0));
        var rs=mock(ResultSet.class);
        when(rs.getObject("id",UUID.class)).thenReturn(other);
        when(rs.getString("username")).thenReturn("other");
        when(rs.getString("display_name")).thenReturn("Other");
        doAnswer(call->List.of(((RowMapper<?>)call.getArgument(1)).mapRow(rs,0)))
                .when(jdbc).query(anyString(),any(RowMapper.class),eq(other));
        assertEquals(match,service.clubChallenge(player,club,other,5).matchId());
        var order=inOrder(challenges,jdbc);
        order.verify(challenges).flush();
        order.verify(jdbc).update(contains("insert into club_activity_match"),eq(match),eq(club));
    }
}
