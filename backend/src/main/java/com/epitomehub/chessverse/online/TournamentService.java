package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.economy.EconomyService;
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
    private final EconomyService economy;

    TournamentService(JdbcTemplate jdbc, OnlineMatchRepository matches, EconomyService economy) {
        this.jdbc = jdbc; this.matches = matches; this.economy = economy;
    }

    @Transactional
    public void startDueTournaments() {
        List<UUID> due = jdbc.query("select id from chess_tournament where status='OPEN' and starts_at<=?",
                (rs,row) -> rs.getObject(1, UUID.class), Timestamp.from(Instant.now()));
        due.forEach(this::startIfReady);
    }

    @Transactional
    public void scheduleNextOccurrences() {
        List<SeriesRow> terminal = jdbc.query("""
                select distinct on (series_code) id,series_code,occurrence_number,name,description,
                       time_control_minutes,capacity,starts_at,ends_at,cadence_days,minimum_players,
                       entry_coins,badge_code,champion_bonus,runner_up_bonus,participation_bonus,status
                from chess_tournament
                where series_code is not null
                order by series_code,occurrence_number desc
                """, (rs,row) -> new SeriesRow(
                rs.getObject("id",UUID.class),rs.getString("series_code"),rs.getInt("occurrence_number"),
                rs.getString("name"),rs.getString("description"),rs.getInt("time_control_minutes"),
                rs.getInt("capacity"),rs.getTimestamp("starts_at").toInstant(),
                rs.getTimestamp("ends_at").toInstant(),rs.getInt("cadence_days"),
                rs.getInt("minimum_players"),rs.getInt("entry_coins"),rs.getString("badge_code"),
                rs.getInt("champion_bonus"),rs.getInt("runner_up_bonus"),
                rs.getInt("participation_bonus"),rs.getString("status")));
        for (SeriesRow previous : terminal) {
            if (!"FINISHED".equals(previous.status) && !"CANCELLED".equals(previous.status)) continue;
            Instant nextStart = previous.startsAt.plus(previous.cadenceDays, java.time.temporal.ChronoUnit.DAYS);
            while (!nextStart.isAfter(Instant.now().plus(1, java.time.temporal.ChronoUnit.DAYS))) {
                nextStart = nextStart.plus(previous.cadenceDays, java.time.temporal.ChronoUnit.DAYS);
            }
            Instant nextEnd = nextStart.plus(java.time.Duration.between(previous.startsAt, previous.endsAt));
            jdbc.update("""
                    insert into chess_tournament(id,name,description,time_control_minutes,capacity,starts_at,
                    ends_at,status,current_round,entry_coins,series_code,occurrence_number,cadence_days,
                    minimum_players,badge_code,champion_bonus,runner_up_bonus,participation_bonus)
                    values(?,?,?,?,?,?,?,'OPEN',0,?,?,?,?,?,?,?,?,?) on conflict do nothing
                    """,UUID.randomUUID(),previous.name,previous.description,previous.minutes,previous.capacity,
                    Timestamp.from(nextStart),Timestamp.from(nextEnd),previous.entryCoins,previous.seriesCode,
                    previous.occurrence+1,previous.cadenceDays,previous.minimumPlayers,previous.badgeCode,
                    previous.championBonus,previous.runnerUpBonus,previous.participationBonus);
        }
    }

    @Transactional
    TournamentDtos.DetailDto detail(AuthenticatedPlayer player, UUID id) {
        startIfReady(id);
        return load(player.id(), id);
    }

    @Transactional
    void startIfReady(UUID tournamentId) {
        var state = jdbc.query("select status,starts_at,minimum_players from chess_tournament where id=? for update", rs ->
                rs.next() ? new Object[]{rs.getString(1), rs.getTimestamp(2).toInstant(),rs.getInt(3)} : null, tournamentId);
        if (state == null) throw new OnlineMatchException(HttpStatus.NOT_FOUND, "Tournament was not found.");
        if (!"OPEN".equals(state[0]) || ((Instant) state[1]).isAfter(Instant.now())) return;
        List<UUID> players = jdbc.query("select player_id from chess_tournament_entry where tournament_id=? and active=true order by joined_at,player_id",
                (rs,row) -> rs.getObject(1, UUID.class), tournamentId);
        if (players.size() < (Integer)state[2]) {
            jdbc.update("update chess_tournament set status='CANCELLED' where id=?", tournamentId);
            refundCancelledEntries(tournamentId);
            return;
        }
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
            Object[] context = jdbc.queryForObject("""
                    select r.tournament_id,r.round_number
                    from chess_tournament_pairing p
                    join chess_tournament_round r on r.id=p.round_id
                    where p.id=?
                    """, (rs,row) -> new Object[]{rs.getObject(1,UUID.class),rs.getInt(2)}, pairingId);
            OnlineMatch replay = createMatch(white, black, match.timeControlMinutes,
                    (UUID)context[0], (Integer)context[1]);
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
                OnlineMatch online=createMatch(player(whiteId),player(blackId),minutes,tournamentId,number);
                jdbc.update("insert into chess_tournament_pairing(id,round_id,board_number,white_player_id,black_player_id,online_match_id,status,created_at) values(?,?,?,?,?,?,'ACTIVE',?)",
                        pairingId,roundId,board++,whiteId,blackId,online.id,Timestamp.from(Instant.now()));
            }
        }
        advanceRoundIfOnlyByes(roundId);
    }

    private OnlineMatch createMatch(PlayerRow white, PlayerRow black, int minutes,
            UUID tournamentId, int tournamentRound) {
        OnlineMatch match = new OnlineMatch(UUID.randomUUID(), UUID.randomUUID().toString().replace("-","").substring(0,8).toUpperCase(),
                white.id,white.name,white.photo,false,minutes,"WORLDWIDE","Unknown",1200,0);
        match.blackPlayerId=black.id; match.blackPlayerName=black.name; match.blackPlayerPhotoUrl=black.photo;
        match.tournamentName=jdbc.queryForObject(
                "select name from chess_tournament where id=?",String.class,tournamentId);
        match.tournamentRound=tournamentRound;
        match.status=OnlineMatchStatus.ACTIVE; match.startedAt=Instant.now(); match.turnStartedAt=match.startedAt; match.updatedAt=match.startedAt;
        // Pairings are inserted through JDBC in the same transaction, so the
        // JPA insert must reach the database before its foreign key is used.
        return matches.saveAndFlush(match);
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
        if(winners.size()==1){
            UUID champion = winners.get(0);
            UUID runnerUp = jdbc.query("select case when white_player_id=? then black_player_id else white_player_id end from chess_tournament_pairing where round_id=? and status='FINISHED' limit 1",
                    rs -> rs.next() ? rs.getObject(1,UUID.class) : null,champion,roundId);
            jdbc.update("update chess_tournament set status='FINISHED',champion_id=?,runner_up_id=?,current_round=? where id=?",champion,runnerUp,number,tournamentId);
            Long prizePool = jdbc.queryForObject("select coalesce(sum(reserved_coins),0) from chess_tournament_entry where tournament_id=? and active=true",Long.class,tournamentId);
            if (prizePool != null && prizePool > 0) economy.grantCoins(champion, prizePool,
                    "TOURNAMENT_CHAMPION_POOL", "tournament:" + tournamentId + ":champion-pool",
                    "Tournament champion prize pool");
            awardTournamentRewards(tournamentId, champion, runnerUp);
            return;
        }
        jdbc.update("update chess_tournament set current_round=? where id=?",number+1,tournamentId);
        createRound(tournamentId,number+1,winners);
    }

    private void awardTournamentRewards(UUID tournamentId, UUID champion, UUID runnerUp) {
        Object[] rewards=jdbc.queryForObject("select badge_code,champion_bonus,runner_up_bonus,participation_bonus from chess_tournament where id=?",
                (rs,row)->new Object[]{rs.getString(1),rs.getInt(2),rs.getInt(3),rs.getInt(4)},tournamentId);
        String badge=(String)rewards[0]; int championBonus=(Integer)rewards[1],runnerBonus=(Integer)rewards[2],participation=(Integer)rewards[3];
        List<UUID> entrants=jdbc.query("select player_id from chess_tournament_entry where tournament_id=? and active=true",
                (rs,row)->rs.getObject(1,UUID.class),tournamentId);
        for(UUID playerId:entrants){
            if(participation>0) economy.grantCoins(playerId,participation,"TOURNAMENT_PARTICIPATION",
                    "tournament:"+tournamentId+":participation:"+playerId,"Tournament participation reward");
            if(badge!=null&&!badge.isBlank()) jdbc.update("insert into player_tournament_badge(player_id,tournament_id,badge_code,placement,awarded_at) values(?,?,?,?,?) on conflict do nothing",
                    playerId,tournamentId,badge,playerId.equals(champion)?"CHAMPION":playerId.equals(runnerUp)?"RUNNER_UP":"PARTICIPANT",Timestamp.from(Instant.now()));
        }
        if(championBonus>0) economy.grantCoins(champion,championBonus,"TOURNAMENT_CHAMPION_BONUS",
                "tournament:"+tournamentId+":champion-bonus","Tournament champion bonus");
        if(runnerUp!=null&&runnerBonus>0) economy.grantCoins(runnerUp,runnerBonus,"TOURNAMENT_RUNNER_UP_BONUS",
                "tournament:"+tournamentId+":runner-up-bonus","Tournament runner-up bonus");
    }

    private TournamentDtos.DetailDto load(UUID viewer, UUID id) {
        TournamentDtos.DetailDto base=jdbc.query("select t.*,count(e.player_id) players,coalesce(sum(e.reserved_coins),0) prize_pool,exists(select 1 from chess_tournament_entry x where x.tournament_id=t.id and x.player_id=? and x.active=true) joined from chess_tournament t left join chess_tournament_entry e on e.tournament_id=t.id and e.active=true where t.id=? group by t.id",
                rs->{if(!rs.next())throw new OnlineMatchException(HttpStatus.NOT_FOUND,"Tournament was not found.");int players=rs.getInt("players"),entryCoins=rs.getInt("entry_coins");return new TournamentDtos.DetailDto(id,rs.getString("name"),rs.getString("description"),rs.getInt("time_control_minutes"),players,rs.getInt("capacity"),rs.getTimestamp("starts_at").toInstant(),rs.getTimestamp("ends_at").toInstant(),rs.getString("status"),rs.getBoolean("joined"),entryCoins,rs.getLong("prize_pool"),rs.getInt("current_round"),rs.getInt("cadence_days"),rs.getInt("minimum_players"),rs.getString("badge_code"),rs.getInt("champion_bonus"),rs.getInt("runner_up_bonus"),rs.getInt("participation_bonus"),playerDto((UUID)rs.getObject("champion_id")),playerDto((UUID)rs.getObject("runner_up_id")),List.of());},viewer,id);
        List<TournamentDtos.RoundDto> rounds=jdbc.query("select id,round_number,status from chess_tournament_round where tournament_id=? order by round_number",(rs,row)->new TournamentDtos.RoundDto(rs.getInt("round_number"),rs.getString("status"),pairings(rs.getObject("id",UUID.class))),id);
        return new TournamentDtos.DetailDto(base.id(),base.name(),base.description(),base.timeControlMinutes(),base.players(),base.capacity(),base.startsAt(),base.endsAt(),base.status(),base.joined(),base.entryCoins(),base.prizePool(),base.currentRound(),base.cadenceDays(),base.minimumPlayers(),base.badgeCode(),base.championBonus(),base.runnerUpBonus(),base.participationBonus(),base.champion(),base.runnerUp(),rounds);
    }

    private void refundCancelledEntries(UUID tournamentId) {
        List<Object[]> entries = jdbc.query("select player_id,reserved_coins,reservation_id from chess_tournament_entry where tournament_id=? and active=true and refunded_at is null for update",
                (rs,row)->new Object[]{rs.getObject(1,UUID.class),rs.getInt(2),rs.getObject(3,UUID.class)},tournamentId);
        Instant now = Instant.now();
        for (Object[] entry : entries) {
            UUID playerId=(UUID)entry[0], reservationId=(UUID)entry[2]; int coins=(Integer)entry[1];
            if (coins > 0 && reservationId != null) economy.grantCoins(playerId,coins,"TOURNAMENT_CANCELLED_REFUND",
                    "tournament:"+tournamentId+":cancel-refund:"+reservationId,"Cancelled tournament entry returned");
        }
        jdbc.update("update chess_tournament_entry set active=false,refunded_at=? where tournament_id=? and active=true",
                Timestamp.from(now),tournamentId);
    }
    private List<TournamentDtos.PairingDto> pairings(UUID roundId){return jdbc.query("select * from chess_tournament_pairing where round_id=? order by board_number",(rs,row)->new TournamentDtos.PairingDto(rs.getObject("id",UUID.class),rs.getInt("board_number"),playerDto((UUID)rs.getObject("white_player_id")),playerDto((UUID)rs.getObject("black_player_id")),(UUID)rs.getObject("online_match_id"),playerDto((UUID)rs.getObject("winner_id")),rs.getString("status")),roundId);}
    private PlayerRow player(UUID id){return jdbc.queryForObject("select id,display_name,photo_url from player_account where id=?",(rs,row)->new PlayerRow(rs.getObject(1,UUID.class),rs.getString(2),rs.getString(3)),id);}
    private TournamentDtos.PlayerDto playerDto(UUID id){if(id==null)return null;PlayerRow p=player(id);return new TournamentDtos.PlayerDto(p.id,p.name,p.photo);}
    private record PlayerRow(UUID id,String name,String photo){}
    private record SeriesRow(UUID id,String seriesCode,int occurrence,String name,String description,
            int minutes,int capacity,Instant startsAt,Instant endsAt,int cadenceDays,int minimumPlayers,
            int entryCoins,String badgeCode,int championBonus,int runnerUpBonus,int participationBonus,String status){}
}
