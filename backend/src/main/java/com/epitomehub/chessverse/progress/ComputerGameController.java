package com.epitomehub.chessverse.progress;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

/** One resumable, non-rated computer game per authenticated account. */
@RestController
@RequestMapping("/api/v1/computer-game")
public class ComputerGameController {
    private final PlayerAuthenticationService authentication;
    private final JdbcTemplate jdbc;
    private final ObjectMapper mapper;
    public ComputerGameController(PlayerAuthenticationService authentication, JdbcTemplate jdbc, ObjectMapper mapper) {
        this.authentication = authentication; this.jdbc = jdbc; this.mapper = mapper;
    }
    public record Slot(long revision, JsonNode draft) {}
    public record Update(long revision, JsonNode draft) {}
    @PostMapping("/history/import")
    @Transactional
    public void importHistory(@RequestHeader("Authorization") String authorization, @RequestBody java.util.List<JsonNode> drafts) {
        UUID player = authentication.requireBearer(authorization).id();
        if (drafts == null || drafts.size() > 25) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid history batch");
        for (JsonNode draft : drafts) {
            if (!draft.path("id").isTextual() || draft.path("id").asText().length() > 80 ||
                    !draft.path("state").path("result").isTextual() || draft.toString().length() > 2000000) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid history record");
            }
            jdbc.update("INSERT INTO computer_game_history(player_id, game_id, draft) VALUES (?, ?, ?) ON CONFLICT (player_id, game_id) DO NOTHING", player, draft.path("id").asText(), draft.toString());
        }
    }
    @GetMapping("/history")
    public java.util.List<JsonNode> history(@RequestHeader("Authorization") String authorization) {
        UUID player = authentication.requireBearer(authorization).id();
        return jdbc.query("SELECT draft FROM computer_game_history WHERE player_id = ? ORDER BY created_at DESC", (rs, row) -> {
            try { return mapper.readTree(rs.getString(1)); }
            catch (Exception e) { throw new IllegalStateException(e); }
        }, player);
    }
    @PostMapping("/finish")
    @Transactional
    public Slot finish(@RequestHeader("Authorization") String authorization, @RequestBody Update request) {
        UUID player = authentication.requireBearer(authorization).id();
        JsonNode draft = request.draft();
        if (draft == null || !draft.path("id").isTextual() || draft.path("id").asText().length() > 80 ||
                !draft.path("state").path("result").isTextual() || draft.toString().length() > 2000000) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid finished game");
        }
        // Retry after a lost response is safe and never clears a newer game.
        if (jdbc.queryForObject("SELECT COUNT(*) FROM computer_game_history WHERE player_id = ? AND game_id = ?", Long.class, player, draft.path("id").asText()) > 0) return new Slot(request.revision() + 1, null);
        int changed = jdbc.update("UPDATE computer_game_slot SET revision = revision + 1, draft = NULL, updated_at = CURRENT_TIMESTAMP WHERE player_id = ? AND revision = ?", player, request.revision());
        if (changed != 1) throw new ResponseStatusException(HttpStatus.CONFLICT, "Game changed on another device");
        jdbc.update("INSERT INTO computer_game_history(player_id, game_id, draft) VALUES (?, ?, ?)", player, draft.path("id").asText(), draft.toString());
        return read(player);
    }
    private Slot read(UUID player) {
        return jdbc.query("SELECT revision, draft FROM computer_game_slot WHERE player_id = ?", (rs, row) -> {
            try { return new Slot(rs.getLong(1), rs.getString(2) == null ? null : mapper.readTree(rs.getString(2))); }
            catch (Exception e) { throw new IllegalStateException("Invalid saved game", e); }
        }, player).stream().findFirst().orElse(new Slot(0, null));
    }
    @GetMapping
    public Slot get(@RequestHeader("Authorization") String authorization) {
        return read(authentication.requireBearer(authorization).id());
    }
    @PutMapping
    @Transactional
    public Slot update(@RequestHeader("Authorization") String authorization, @RequestBody Update request) {
        UUID player = authentication.requireBearer(authorization).id();
        JsonNode draft = request.draft();
        if (request.revision() < 0 || (draft != null && !draft.isNull() &&
                (!draft.isObject() || !draft.path("id").isTextual() || draft.path("id").asText().length() > 80 ||
                !draft.path("state").isObject() || draft.toString().length() > 2000000))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid computer game");
        }
        jdbc.update("INSERT INTO computer_game_slot(player_id, revision) VALUES (?, 0) ON CONFLICT (player_id) DO NOTHING", player);
        int updated = jdbc.update("UPDATE computer_game_slot SET revision = revision + 1, draft = ?, updated_at = CURRENT_TIMESTAMP WHERE player_id = ? AND revision = ?",
                draft == null || draft.isNull() ? null : draft.toString(), player, request.revision());
        if (updated != 1) throw new ResponseStatusException(HttpStatus.CONFLICT, "Game changed on another device. Reload My Games.");
        return read(player);
    }
}
