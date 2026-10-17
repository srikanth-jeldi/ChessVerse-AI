package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.github.bhlangonijr.chesslib.Board;
import com.github.bhlangonijr.chesslib.move.Move;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ClubActivityService {
    static final ZoneId ZONE = ZoneId.of("Asia/Kolkata");
    private final JdbcTemplate jdbc;
    private final OnlinePresenceService presence;
    private final List<Puzzle> puzzles;

    ClubActivityService(JdbcTemplate jdbc, OnlinePresenceService presence) {
        this.jdbc = jdbc;
        this.presence = presence;
        try (var stream = Objects.requireNonNull(getClass().getResourceAsStream("/club_daily_puzzles.txt"));
             var reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            puzzles = reader.lines().filter(s -> !s.isBlank() && !s.startsWith("#")).map(s -> {
                String[] fields = s.split("\\|");
                return new Puzzle(fields[0], fields[1], List.of(fields[2].split(",")));
            }).toList();
        } catch (Exception e) { throw new IllegalStateException("Club puzzle catalogue unavailable", e); }
    }

    record Puzzle(String id, String fen, List<String> moves) {}
    record Member(UUID id, String name, int rating, boolean online, boolean self) {}
    record Score(UUID id, String name, int puzzles, int wins, int draws, int points) {}
    record Detail(String name, LocalDate day, LocalDate weekStart, Instant resetsAt,
                  String fen, boolean completed, int completedMembers, List<Member> members, List<Score> leaderboard) {}
    record Attempt(boolean correct, boolean completed, String fen) {}

    void requireMember(UUID club, UUID player) {
        if (!Boolean.TRUE.equals(jdbc.queryForObject(
                "select exists(select 1 from chess_club_member where club_id=? and player_id=?)",
                Boolean.class, club, player))) {
            throw new OnlineMatchException(HttpStatus.FORBIDDEN, "Join this club to use its activities.");
        }
    }

    static LocalDate weekStart(LocalDate day) {
        return day.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    }

    Puzzle puzzle(LocalDate day) { return puzzles.get(Math.floorMod(day.toEpochDay(), puzzles.size())); }

    @Transactional(readOnly = true)
    Detail detail(AuthenticatedPlayer player, UUID club) {
        requireMember(club, player.id());
        LocalDate day = LocalDate.now(ZONE);
        LocalDate week = weekStart(day);
        List<Member> members = jdbc.query("""
                select p.id,p.display_name,coalesce(r.rating,1200) rating
                from chess_club_member m join player_account p on p.id=m.player_id
                left join online_player_rating r on r.player_id=p.id
                where m.club_id=? order by lower(p.display_name),p.id limit 100
                """, (rs, n) -> new Member(rs.getObject("id", UUID.class), rs.getString("display_name"),
                rs.getInt("rating"), presence.isOnline(rs.getObject("id", UUID.class)),
                player.id().equals(rs.getObject("id", UUID.class))), club);
        List<Score> scores = jdbc.query("""
                with results as (
                    select p.player_id, count(*)::int puzzles, 0::int wins, 0::int draws
                    from club_daily_completion p where p.club_id=? and p.puzzle_day between ? and ? group by p.player_id
                    union all
                    select v.player_id,0::int,
                        count(*) filter(where m.result=v.winning_result)::int,
                        count(*) filter(where m.result='1/2-1/2')::int
                    from club_activity_match c join online_match m on m.id=c.match_id
                    cross join lateral (values (m.white_player_id,'1-0'),(m.black_player_id,'0-1')) v(player_id,winning_result)
                    where c.club_id=? and m.status='FINISHED' and m.finished_at>=? and m.finished_at<?
                    group by v.player_id
                ), totals as (
                    select player_id,sum(puzzles)::int puzzles,sum(wins)::int wins,sum(draws)::int draws
                    from results group by player_id
                )
                select p.id,p.display_name,t.puzzles,t.wins,t.draws,(t.puzzles*10+t.wins*3+t.draws)::int points
                from totals t join player_account p on p.id=t.player_id
                join chess_club_member cm on cm.player_id=p.id and cm.club_id=?
                order by points desc,lower(p.display_name),p.id limit 50
                """, (rs, n) -> new Score(rs.getObject("id", UUID.class),rs.getString("display_name"),
                rs.getInt("puzzles"),rs.getInt("wins"),rs.getInt("draws"),rs.getInt("points")),
                club, Date.valueOf(week), Date.valueOf(day), club,
                java.sql.Timestamp.from(week.atStartOfDay(ZONE).toInstant()),
                java.sql.Timestamp.from(week.plusDays(7).atStartOfDay(ZONE).toInstant()), club);
        return new Detail(jdbc.queryForObject("select name from chess_club where id=?",String.class,club),
                day, week, day.plusDays(1).atStartOfDay(ZONE).toInstant(), puzzle(day).fen(),
                Boolean.TRUE.equals(jdbc.queryForObject("select exists(select 1 from club_daily_completion where club_id=? and player_id=? and puzzle_day=?)", Boolean.class,club,player.id(),Date.valueOf(day))),
                jdbc.queryForObject("select count(*) from club_daily_completion where club_id=? and puzzle_day=?",Integer.class,club,Date.valueOf(day)),
                members,scores);
    }

    // Every supplied human move must match the curated line. Opponent replies
    // are applied on the server; the client never supplies scores or solutions.
    static Attempt evaluate(Puzzle puzzle, List<String> humanMoves) {
        if (humanMoves.isEmpty() || humanMoves.size() > (puzzle.moves().size()+1)/2) {
            throw new OnlineMatchException(HttpStatus.BAD_REQUEST,"Invalid puzzle attempt.");
        }
        Board board = new Board();
        board.loadFromFen(puzzle.fen());
        int ply = 0;
        for (String human : humanMoves) {
            if (!puzzle.moves().get(ply).equals(human)) return new Attempt(false,false,board.getFen());
            for (int step=0; step<2 && ply<puzzle.moves().size(); step++,ply++) {
                Move move = new Move(puzzle.moves().get(ply),board.getSideToMove());
                if (!board.doMove(move,true)) throw new IllegalStateException("Invalid curated club puzzle");
            }
        }
        return new Attempt(true,ply==puzzle.moves().size(),board.getFen());
    }

    @Transactional
    Attempt attempt(AuthenticatedPlayer player, UUID club, LocalDate day, List<String> moves) {
        requireMember(club, player.id());
        if (!LocalDate.now(ZONE).equals(day)) throw new OnlineMatchException(HttpStatus.CONFLICT,"Today's puzzle changed. Refresh the club.");
        Attempt result = evaluate(puzzle(day), moves);
        if (result.completed()) jdbc.update("insert into club_daily_completion(club_id,player_id,puzzle_day) values (?,?,?) on conflict do nothing",club,player.id(),Date.valueOf(day));
        return result;
    }
}
