package com.epitomehub.chessverse.game;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class GameDtos {

    private GameDtos() {
    }

    public record CreateGameRequest(@NotNull GameMode mode) {
    }

    public record SubmitMoveRequest(
            @NotBlank
            @Pattern(regexp = "^[a-h][1-8][a-h][1-8][qrbn]?$", message = "Move must be UCI format, for example e2e4 or e7e8q")
            String move) {
    }

    public record GameResponse(
            UUID id,
            GameMode mode,
            GameStatus status,
            String fen,
            String activeColor,
            List<String> moves,
            Instant createdAt,
            Instant updatedAt) {

        public static GameResponse from(ChessGame game) {
            return new GameResponse(
                    game.getId(),
                    game.getMode(),
                    game.getStatus(),
                    game.getFen(),
                    game.getActiveColor(),
                    game.getMoves(),
                    game.getCreatedAt(),
                    game.getUpdatedAt());
        }
    }
}

