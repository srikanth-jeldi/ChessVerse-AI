package com.epitomehub.chessverse.progress;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;

/** Private account backup, independent of academy sharing consent. */
@RestController
@RequestMapping("/api/v1/progress/mistakes")
class MistakeBackupController {
    record Item(@NotNull @Pattern(regexp = "^[0-9]{1,16}-[0-9]{1,5}$") String id,
            @NotNull Instant updatedAt, @NotNull Map<String, Object> game,
            Map<String, Object> practice) {}
    record Backup(@NotNull @Size(max = 100) List<@Valid Item> items) {}

    private final PlayerAuthenticationService authentication;
    private final JdbcTemplate jdbc;
    private final ObjectMapper json;

    MistakeBackupController(PlayerAuthenticationService authentication, JdbcTemplate jdbc, ObjectMapper json) {
        this.authentication = authentication;
        this.jdbc = jdbc;
        this.json = json;
    }

    @PutMapping
    @Transactional
    Backup merge(@RequestHeader("Authorization") String authorization, @Valid @RequestBody Backup request) {
        UUID playerId = authentication.requireBearer(authorization).id();
        // Serialize same-account merges, including the first empty-device restore.
        Boolean guest = jdbc.queryForObject("select guest_account from player_account where id = ? for update",
                Boolean.class, playerId);
        if (Boolean.TRUE.equals(guest)) throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        int bytes = 0;
        for (Item item : request.items()) {
            String encoded = json.writeValueAsString(item);
            int size = encoded.getBytes(StandardCharsets.UTF_8).length;
            bytes += size;
            if (size > 65536 || bytes > 2_000_000 || item.updatedAt().isAfter(Instant.now().plusSeconds(300))
                    || !(item.game().get("moveReviews") instanceof List<?> reviews) || reviews.size() != 1
                    || !(item.game().get("playedAt") instanceof String)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid mistake backup");
            }
            List<Timestamp> previous = jdbc.query("select updated_at from player_mistake_backup where player_id = ? and mistake_id = ?",
                    (rs, row) -> rs.getTimestamp(1), playerId, item.id());
            if (previous.isEmpty()) {
                jdbc.update("insert into player_mistake_backup(player_id,mistake_id,snapshot,updated_at) values(?,?,?,?)",
                        playerId, item.id(), encoded, Timestamp.from(item.updatedAt()));
            } else if (item.updatedAt().isAfter(previous.getFirst().toInstant())) {
                jdbc.update("update player_mistake_backup set snapshot = ?, updated_at = ? where player_id = ? and mistake_id = ?",
                        encoded, Timestamp.from(item.updatedAt()), playerId, item.id());
            }
        }
        List<String> ids = jdbc.query("select mistake_id from player_mistake_backup where player_id = ? order by updated_at desc, mistake_id desc",
                (rs, row) -> rs.getString(1), playerId);
        for (String id : ids.stream().skip(100).toList()) {
            jdbc.update("delete from player_mistake_backup where player_id = ? and mistake_id = ?", playerId, id);
        }
        // An empty upload NEVER deletes the account's backup.
        return new Backup(jdbc.query("select snapshot from player_mistake_backup where player_id = ? order by updated_at desc, mistake_id desc",
                (rs, row) -> json.readValue(rs.getString(1), Item.class), playerId));
    }
}
