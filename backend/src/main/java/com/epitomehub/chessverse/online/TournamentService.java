package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class TournamentService {
    private final JdbcTemplate jdbc;
    private final OnlineMatchRepository matches;

    TournamentService(JdbcTemplate jdbc, OnlineMatchRepository matches) {
        this.jdbc = jdbc; this.matches = matches;
    }

    @Transactional
    public void startDueTournaments() {
        List<UUID> due = jdbc.query("select id from chess_tournament where status='OPEN' and starts_at<=?",
                (rs,row) -> rs.getObject(1, UUID.class), Timestamp.from(Instant.now()));
        due.forEach(this::startIfReady);
    }

    @Transactional
    TournamentDtos.DetailDto detail(AuthenticatedPlayer player, UUID id) {
        startIfReady(id);
        return load(player.id(), id);
    }

    @Transactional
    void startIfReady(UUID tournamentId) {
        var state = jdbc.query("select status,starts_at from chess_tournament where id=? for update", rs ->
                rs.next() ? new Object[]{rs.getString(1), rs.getTimestamp(2).toInstant()} : null, tournamentId);
        if (state == null) throw new OnlineMatchException(HttpStatus.NOT_FOUND, "Tournament was not found.");
        if (!"OPEN".equals(state[0]) || ((Instant) state[1]).isAfter(Instant.now())) return;
        List<UUID> players = jdbc.query("select player_id from chess_tournament_entry where tournament_id=? order by joined_at,player_id",
                (rs,row) -> rs.getObject(1, UUID.class), tournamentId);
        if (players.size() < 2) return;
        jdbc.update("update chess_tournament set status='ACTIVE',current_round=1 where id=?", tournamentId);
        createRound(tournamentId, 1, players);
    }

    @Transactional
    void recordResult(OnlineMatch match) {
        UUID pairingId = jdbc.query("select id from chess_tournament_pairing where online_match_id=? and status='ACTIVE' for update",
                rs -> rs.next() ? rs.getObject(1, UUID.class) : null, match.id);
        if (pairingId == null) return;
        if ("1/2-1/2".equals(match.result)) {
            PlayerRow white = player(match.whitePlayerId), black = player(match.blackPlayerId);
            OnlineMatch replay = createMatch(white, black, match.timeControlMinutes);
            jdbc.update("update chess_tournament_pairing set online_match_id=? where id=?", replay.id, pairingId);
            return;
        }
        UUID winner = "1-0".equals(match.result) ? match.whitePlayerId : match.blackPlayerId;
        jdbc.update("update chess_tournament_pairing set winner_id=?,status='FINISHED',completed_at=? where id=?",
                winner, Timestamp.from(Instant.now()), pairingId);
        advanceIfRoundComplete(pairingId);
    }

    private void createRound(UUID tournamentId, int number, List<UUID> playerIds) {
        UUID roundId = UUID.randomUUID();
        jdbc.update("insert into chess_tournament_round(id,tournament_id,round_number,status,created_at) values(?,?,?,'ACTIVE',?)",
                roundId,tournamentId,number,Timestamp.from(Instant.now()));
        int board=1;
        for (int i=0;i<playerIds.size();i+=2) {
            UUID whiteId=playerIds.get(i), blackId=i+1<playerIds.size()?playerIds.get(i+1):null;
            UUID pairingId=UUID.randomUUID();
            if (blackId == null) {
                jdbc.update("insert into chess_tournament_pairing(id,round_id,board_number,white_player_id,winner_id,status,created_at,completed_at) values(?,?,?,?,?,'BYE',?,?)",
                        pairingId,roundId,board++,whiteId,whiteId,Timestamp.from(Instant.now()),Timestamp.from(Instant.now()));
            } else {
                int minutes = jdbc.queryForObject("select time_control_minutes from chess_tournament where id=?",Integer.class,tournamentId);
                OnlineMatch online=createMatch(player(whiteId),player(blackId),minutes);
                jdbc.update("insert into chess_tournament_pairing(id,round_id,board_number,white_player_id,black_player_id,online_match_id,status,created_at) values(?,?,?,?,?,?,'ACTIVE',?)",
                        pairingId,roundId,board++,whiteId,blackId,online.id,Timestamp.from(Instant.now()));
            }
        }
        advanceRoundIfOnlyByes(roundId);
    }

    private OnlineMatch createMatch(PlayerRow white, PlayerRow black, int minutes) {
        OnlineMatch match = new OnlineMatch(UUID.randomUUID(), UUID.randomUUID().toString().replace("-","").substring(0,8).toUpperCase(),
                white.id,white.name,white.photo,false,minutes,"WORLDWIDE","Unknown",1200,0);
        match.blackPlayerId=black.id; match.blackPlayerName=black.name; match.blackPlayerPhotoUrl=black.photo;
        match.status=OnlineMatchStatus.ACTIVE; match.startedAt=Instant.now(); match.turnStartedAt=match.startedAt; match.updatedAt=match.startedAt;
        return matches.save(match);
    }

    private void advanceIfRoundComplete(UUID pairingId) {
        UUID roundId=jdbc.queryForObject("select round_id from chess_tournament_pairing where id=?",UUID.class,pairingId);
        Integer active=jdbc.queryForObject("select count(*) from chess_tournament_pairing where round_id=? and status='ACTIVE'",Integer.class,roundId);
        if(active!=null&&active==0) completeRound(roundId);
    }
    private void advanceRoundIfOnlyByes(UUID roundId) { advanceIfRoundComplete(jdbc.queryForObject("select id from chess_tournament_pairing where round_id=? limit 1",UUID.class,roundId)); }
    private void completeRound(UUID roundId) {
        Object[] state=jdbc.queryForObject("select tournament_id,round_number from chess_tournament_round where id=?",(rs,row)->new Object[]{rs.getObject(1,UUID.class),rs.getInt(2)},roundId);
        UUID tournamentId=(UUID)state[0]; int number=(Integer)state[1];
        jdbc.update("update chess_tournament_round set status='FINISHED',completed_at=? where id=?",Timestamp.from(Instant.now()),roundId);
        List<UUID>winners=jdbc.query("select winner_id from chess_tournament_pairing where round_id=? order by board_number",(rs,row)->rs.getObject(1,UUID.class),roundId);
        if(winners.size()==1){jdbc.update("update chess_tournament set status='FINISHED',champion_id=?,current_round=? where id=?",winners.get(0),number,tournamentId);return;}
        jdbc.update("update chess_tournament set current_round=? where id=?",number+1,tournamentId);
        createRound(tournamentId,number+1,winners);
    }

    private TournamentDtos.DetailDto load(UUID viewer, UUID id) {
        TournamentDtos.DetailDto base=jdbc.query("select t.*,count(e.player_id) players,exists(select 1 from chess_tournament_entry x where x.tournament_id=t.id and x.player_id=?) joined from chess_tournament t left join chess_tournament_entry e on e.tournament_id=t.id where t.id=? group by t.id",
                rs->{if(!rs.next())throw new OnlineMatchException(HttpStatus.NOT_FOUND,"Tournament was not found.");return new TournamentDtos.DetailDto(id,rs.getString("name"),rs.getString("description"),rs.getInt("time_control_minutes"),rs.getInt("players"),rs.getInt("capacity"),rs.getTimestamp("starts_at").toInstant(),rs.getTimestamp("ends_at").toInstant(),rs.getString("status"),rs.getBoolean("joined"),rs.getInt("current_round"),playerDto((UUID)rs.getObject("champion_id")),List.of());},viewer,id);
        List<TournamentDtos.RoundDto> rounds=jdbc.query("select id,round_number,status from chess_tournament_round where tournament_id=? order by round_number",(rs,row)->new TournamentDtos.RoundDto(rs.getInt("round_number"),rs.getString("status"),pairings(rs.getObject("id",UUID.class))),id);
        return new TournamentDtos.DetailDto(base.id(),base.name(),base.description(),base.timeControlMinutes(),base.players(),base.capacity(),base.startsAt(),base.endsAt(),base.status(),base.joined(),base.currentRound(),base.champion(),rounds);
    }
    private List<TournamentDtos.PairingDto> pairings(UUID roundId){return jdbc.query("select * from chess_tournament_pairing where round_id=? order by board_number",(rs,row)->new TournamentDtos.PairingDto(rs.getObject("id",UUID.class),rs.getInt("board_number"),playerDto((UUID)rs.getObject("white_player_id")),playerDto((UUID)rs.getObject("black_player_id")),(UUID)rs.getObject("online_match_id"),playerDto((UUID)rs.getObject("winner_id")),rs.getString("status")),roundId);}
    private PlayerRow player(UUID id){return jdbc.queryForObject("select id,display_name,photo_url from player_account where id=?",(rs,row)->new PlayerRow(rs.getObject(1,UUID.class),rs.getString(2),rs.getString(3)),id);}
    private TournamentDtos.PlayerDto playerDto(UUID id){if(id==null)return null;PlayerRow p=player(id);return new TournamentDtos.PlayerDto(p.id,p.name,p.photo);}
    private record PlayerRow(UUID id,String name,String photo){}
}
