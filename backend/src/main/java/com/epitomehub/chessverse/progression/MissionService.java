package com.epitomehub.chessverse.progression;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.economy.EconomyService;
import java.sql.Date;
import java.sql.Timestamp;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
class MissionService {
    private final JdbcTemplate jdbc;
    private final EconomyService economy;

    MissionService(JdbcTemplate jdbc, EconomyService economy) {
        this.jdbc = jdbc;
        this.economy = economy;
    }

    @Transactional(readOnly = true)
    MissionDtos.MissionBoardDto board(AuthenticatedPlayer player) {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        LocalDate week = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        Instant dayStart = today.atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant weekStart = week.atStartOfDay().toInstant(ZoneOffset.UTC);
        int dailyGames = finishedMatches(player, dayStart);
        int dailyWins = wins(player, dayStart);
        int weeklyGames = finishedMatches(player, weekStart);
        int weeklyWins = wins(player, weekStart);
        int weeklyTournamentGames = tournamentGames(player, weekStart);
        return new MissionDtos.MissionBoardDto(
                List.of(
                        mission(player, "DAILY_PLAY", "DAILY", "Make your move",
                                "Complete one verified online game.", dailyGames, 1, 25,
                                today, dayStart.plusSeconds(86_400)),
                        mission(player, "DAILY_WIN", "DAILY", "Winning focus",
                                "Win one verified online game.", dailyWins, 1, 40,
                                today, dayStart.plusSeconds(86_400))),
                List.of(
                        mission(player, "WEEKLY_GAMES", "WEEKLY", "Weekly competitor",
                                "Complete five verified online games.", weeklyGames, 5, 100,
                                week, weekStart.plusSeconds(7 * 86_400L)),
                        mission(player, "WEEKLY_WINS", "WEEKLY", "Strong week",
                                "Win three verified online games.", weeklyWins, 3, 125,
                                week, weekStart.plusSeconds(7 * 86_400L)),
                        mission(player, "WEEKLY_TOURNAMENT", "WEEKLY", "Circuit player",
                                "Complete one tournament pairing.", weeklyTournamentGames, 1, 150,
                                week, weekStart.plusSeconds(7 * 86_400L))));
    }

    @Transactional
    MissionDtos.ClaimDto claim(AuthenticatedPlayer player, String requestedCode) {
        String code = requestedCode == null ? "" : requestedCode.trim().toUpperCase();
        MissionDtos.MissionBoardDto current = board(player);
        MissionDtos.MissionDto mission = all(current).stream()
                .filter(item -> item.code().equals(code)).findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Mission was not found."));
        if (!mission.completed()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Complete this mission before claiming its reward.");
        }
        LocalDate period = periodStart(code);
        int inserted = jdbc.update("""
                insert into player_mission_claim(player_id,mission_code,period_start,reward_coins,claimed_at)
                values(?,?,?,?,?) on conflict do nothing
                """, player.id(), code, Date.valueOf(period), mission.rewardCoins(),
                Timestamp.from(Instant.now()));
        if (inserted == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "This mission reward has already been claimed.");
        }
        economy.grantCoins(player.id(), mission.rewardCoins(), "MISSION_REWARD",
                "mission:" + code + ":" + period, mission.title() + " reward");
        return new MissionDtos.ClaimDto(code, true, mission.rewardCoins(), board(player));
    }

    private List<MissionDtos.MissionDto> all(MissionDtos.MissionBoardDto board) {
        return java.util.stream.Stream.concat(board.daily().stream(), board.weekly().stream()).toList();
    }

    private MissionDtos.MissionDto mission(AuthenticatedPlayer player, String code,
            String cadence, String title, String description, int progress, int target,
            int reward, LocalDate period, Instant resetsAt) {
        Integer count = jdbc.queryForObject("""
                select count(*) from player_mission_claim
                where player_id=? and mission_code=? and period_start=?
                """, Integer.class, player.id(), code, Date.valueOf(period));
        return new MissionDtos.MissionDto(code, cadence, title, description,
                Math.min(progress, target), target, reward, progress >= target,
                count != null && count > 0, resetsAt);
    }

    private int finishedMatches(AuthenticatedPlayer player, Instant since) {
        return count("""
                select count(*) from online_match where status='FINISHED' and finished_at>=?
                and (white_player_id=? or black_player_id=?)
                """, since, player);
    }

    private int wins(AuthenticatedPlayer player, Instant since) {
        return count("""
                select count(*) from online_match where status='FINISHED' and finished_at>=?
                and ((white_player_id=? and result='1-0') or (black_player_id=? and result='0-1'))
                """, since, player);
    }

    private int tournamentGames(AuthenticatedPlayer player, Instant since) {
        return count("""
                select count(*) from online_match where status='FINISHED' and finished_at>=?
                and tournament_name is not null and (white_player_id=? or black_player_id=?)
                """, since, player);
    }

    private int count(String sql, Instant since, AuthenticatedPlayer player) {
        Integer value = jdbc.queryForObject(sql, Integer.class, Timestamp.from(since),
                player.id(), player.id());
        return value == null ? 0 : value;
    }

    private LocalDate periodStart(String code) {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        return code.startsWith("WEEKLY_")
                ? today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)) : today;
    }
}
