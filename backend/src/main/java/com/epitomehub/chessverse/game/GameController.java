package com.epitomehub.chessverse.game;

import com.epitomehub.chessverse.game.GameDtos.CreateGameRequest;
import com.epitomehub.chessverse.game.GameDtos.GameResponse;
import com.epitomehub.chessverse.game.GameDtos.SubmitMoveRequest;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/games")
public class GameController {

    private final GameService service;

    public GameController(GameService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<GameResponse> create(@Valid @RequestBody CreateGameRequest request) {
        ChessGame game = service.create(request.mode());
        return ResponseEntity.created(URI.create("/api/v1/games/" + game.getId()))
                .body(GameResponse.from(game));
    }

    @GetMapping("/{id}")
    public GameResponse get(@PathVariable UUID id) {
        return GameResponse.from(service.get(id));
    }

    @PostMapping("/{id}/moves")
    public GameResponse submitMove(@PathVariable UUID id, @Valid @RequestBody SubmitMoveRequest request) {
        return GameResponse.from(service.submitMove(id, request.move()));
    }
}

