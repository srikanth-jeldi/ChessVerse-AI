package com.epitomehub.chessverse.online;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PositiveOrZero;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class OnlineDtos {
    private OnlineDtos() {
    }

    record JoinRoomRequest(
            @NotBlank @Pattern(regexp = "^[A-Za-z0-9]{6,8}$") String roomCode) {
    }

    record SubmitMoveRequest(
            @NotBlank @Pattern(regexp = "^[a-h][1-8][a-h][1-8][qrbn]?$") String uci,
            @PositiveOrZero int expectedPly) {
    }

    record MoveResponse(int ply, String uci, UUID playerId, Instant createdAt) {
        static MoveResponse from(OnlineMove move) {
            return new MoveResponse(move.ply, move.uci, move.playerId, move.createdAt);
        }
    }

    record MatchResponse(
            UUID id,
            String roomCode,
            String status,
            String yourColor,
            String activeColor,
            int plyCount,
            String whitePlayerName,
            String blackPlayerName,
            List<MoveResponse> moves,
            Instant updatedAt) {
    }
}

