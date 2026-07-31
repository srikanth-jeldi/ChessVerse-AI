package com.epitomehub.chessverse.online;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class OnlineDtos {
    private OnlineDtos() {
    }

    record JoinRoomRequest(
            @NotBlank @Pattern(regexp = "^[A-Za-z0-9-]{4,8}$") String roomCode) {
    }

    record MoveRequest(
            @NotBlank
            @Pattern(regexp = "^[a-h][1-8][a-h][1-8][qrbn]?$") String uci,
            @Min(0) int expectedPly) {
    }

    record MoveDto(int ply, String uci) {
    }

    record DrawResponseRequest(boolean accept) {
    }

    record MatchDto(
            UUID id,
            String roomCode,
            OnlineMatchStatus status,
            String yourColor,
            String activeColor,
            String whitePlayerName,
            String blackPlayerName,
            String whitePlayerPhotoUrl,
            String blackPlayerPhotoUrl,
            String fen,
            List<MoveDto> moves,
            long whiteTimeMs,
            long blackTimeMs,
            Instant serverNow,
            Instant turnStartedAt,
            String result,
            String resultReason,
            String drawOfferedByColor,
            boolean rematchRequestedByYou,
            UUID rematchMatchId,
            Integer ratingBefore,
            Integer ratingAfter,
            Instant updatedAt) {
        static MatchDto from(OnlineMatch match, UUID playerId) {
            String yourColor = match.whitePlayerId.equals(playerId) ? "white" : "black";
            List<MoveDto> moves = java.util.stream.IntStream.range(0, match.moves.size())
                    .mapToObj(index -> new MoveDto(index, match.moves.get(index)))
                    .toList();
            return new MatchDto(
                    match.id,
                    match.roomCode,
                    match.status,
                    yourColor,
                    match.activeColor,
                    match.whitePlayerName,
                    match.blackPlayerName,
                    match.whitePlayerPhotoUrl,
                    match.blackPlayerPhotoUrl,
                    match.fen,
                    moves,
                    match.whiteTimeMs,
                    match.blackTimeMs,
                    Instant.now(),
                    match.turnStartedAt,
                    match.result,
                    match.resultReason,
                    colorOf(match, match.drawOfferedBy),
                    playerId.equals(match.rematchRequestedBy),
                    match.rematchMatchId,
                    match.whitePlayerId.equals(playerId)
                            ? match.whiteRatingBefore : match.blackRatingBefore,
                    match.whitePlayerId.equals(playerId)
                            ? match.whiteRatingAfter : match.blackRatingAfter,
                    match.updatedAt);
        }

        private static String colorOf(OnlineMatch match, UUID playerId) {
            if (playerId == null) return null;
            return match.whitePlayerId.equals(playerId) ? "white" : "black";
        }
    }
}
