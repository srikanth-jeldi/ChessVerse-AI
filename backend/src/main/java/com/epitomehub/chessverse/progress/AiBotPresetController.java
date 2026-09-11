package com.epitomehub.chessverse.progress;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/ai-bot-presets")
public class AiBotPresetController {
    private static final Set<String> STYLES = Set.of("balanced", "aggressive", "defensive");
    private final PlayerAuthenticationService authentication;
    private final JdbcTemplate jdbc;

    public AiBotPresetController(PlayerAuthenticationService authentication, JdbcTemplate jdbc) {
        this.authentication = authentication;
        this.jdbc = jdbc;
    }

    public record Preset(UUID id, String name, int rating, String style) {}
    public record Save(String name, int rating, String style) {}

    @GetMapping
    public List<Preset> list(@RequestHeader("Authorization") String authorization) {
        UUID player = authentication.requireBearer(authorization).id();
        return jdbc.query("SELECT id, name, rating, style FROM ai_bot_presets WHERE player_id = ? ORDER BY updated_at DESC",
                (rs, row) -> new Preset(rs.getObject(1, UUID.class), rs.getString(2), rs.getInt(3), rs.getString(4)), player);
    }

    @PostMapping
    @Transactional
    public Preset save(@RequestHeader("Authorization") String authorization, @RequestBody Save request) {
        UUID player = authentication.requireBearer(authorization).id();
        String name = request.name() == null ? "" : request.name().trim();
        if (name.isEmpty() || name.length() > 30 || request.rating() < 400 || request.rating() > 3000 || !STYLES.contains(request.style())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid AI bot preset");
        }
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM ai_bot_presets WHERE player_id = ?", Integer.class, player);
        if (count != null && count >= 5) throw new ResponseStatusException(HttpStatus.CONFLICT, "Maximum five presets");
        UUID id = UUID.randomUUID();
        try {
            jdbc.update("INSERT INTO ai_bot_presets(id, player_id, name, rating, style) VALUES (?, ?, ?, ?, ?)", id, player, name, request.rating(), request.style());
        } catch (org.springframework.dao.DataIntegrityViolationException duplicate) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Preset name already exists");
        }
        return new Preset(id, name, request.rating(), request.style());
    }

    @DeleteMapping("/{id}")
    public void delete(@RequestHeader("Authorization") String authorization, @PathVariable UUID id) {
        UUID player = authentication.requireBearer(authorization).id();
        if (jdbc.update("DELETE FROM ai_bot_presets WHERE id = ? AND player_id = ?", id, player) != 1) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Preset not found");
        }
    }
}
