package com.epitomehub.chessverse.progression;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/puzzle-sprints")
class PuzzleSprintController {
    private final PlayerAuthenticationService authentication;
    private final JdbcTemplate jdbc;

    PuzzleSprintController(PlayerAuthenticationService authentication, JdbcTemplate jdbc) {
        this.authentication = authentication;
        this.jdbc = jdbc;
    }

    @PostMapping
    SprintResult record(@RequestHeader("Authorization") String authorization,
                        @Valid @RequestBody RecordRequest request) {
        AuthenticatedPlayer player = authentication.requireBearer(authorization);
        if (request.score() > request.attempted()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Score cannot exceed attempts.");
        }
        UUID id = UUID.randomUUID();
        Instant playedAt = Instant.now();
        jdbc.update("insert into puzzle_sprint_result(id,player_id,mode,score,attempted,duration_seconds,played_at) values(?,?,?,?,?,?,?)",
                id, player.id(), request.mode(), request.score(), request.attempted(),
                request.durationSeconds(), java.sql.Timestamp.from(playedAt));
        return new SprintResult(id, player.id(), player.displayName(), request.mode(),
                request.score(), request.attempted(), request.durationSeconds(), playedAt);
    }

    @GetMapping("/history")
    List<SprintResult> history(@RequestHeader("Authorization") String authorization) {
        AuthenticatedPlayer player = authentication.requireBearer(authorization);
        return jdbc.query("""
                select r.*,p.display_name from puzzle_sprint_result r
                join player_account p on p.id=r.player_id
                where r.player_id=? order by r.played_at desc limit 50
                """, (rs, row) -> map(rs), player.id());
    }

    @GetMapping("/leaderboard")
    List<SprintResult> leaderboard(@RequestHeader("Authorization") String authorization,
                                   @RequestParam(defaultValue = "RUSH")
                                   @Pattern(regexp = "^(RUSH|SURVIVAL|MATE_IN_ONE)$") String mode) {
        authentication.requireBearer(authorization);
        return jdbc.query("""
                select r.*,p.display_name from puzzle_sprint_result r
                join player_account p on p.id=r.player_id
                where r.mode=? order by r.score desc,r.duration_seconds asc,r.played_at asc limit 50
                """, (rs, row) -> map(rs), mode);
    }

    private SprintResult map(java.sql.ResultSet rs) throws java.sql.SQLException {
        return new SprintResult(rs.getObject("id", UUID.class),
                rs.getObject("player_id", UUID.class), rs.getString("display_name"),
                rs.getString("mode"), rs.getInt("score"), rs.getInt("attempted"),
                rs.getInt("duration_seconds"), rs.getTimestamp("played_at").toInstant());
    }

    record RecordRequest(
            @Pattern(regexp = "^(RUSH|SURVIVAL|MATE_IN_ONE)$") String mode,
            @Min(0) @Max(1000) int score,
            @Min(0) @Max(1000) int attempted,
            @Min(0) @Max(3600) int durationSeconds) {}

    record SprintResult(UUID id, UUID playerId, String playerName, String mode,
                        int score, int attempted, int durationSeconds, Instant playedAt) {}
}
