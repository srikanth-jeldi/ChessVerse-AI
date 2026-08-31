package com.epitomehub.chessverse.online;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.AssertTrue;
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

    record QueueRequest(
            @Min(3) @Max(15) int timeControlMinutes,
            @Pattern(regexp = "^(WORLDWIDE|COUNTRY)$") String region,
            @Min(0) @Max(800) int ratingRange,
            @Min(100) @Max(500) int entryCoins) {
        QueueRequest {
            if (timeControlMinutes == 0) timeControlMinutes = 10;
            if (region == null || region.isBlank()) region = "WORLDWIDE";
            if (entryCoins == 0) entryCoins = 100;
        }

        @AssertTrue(message = "Time control must be 3, 5, 10 or 15 minutes.")
        boolean supportedTimeControl() {
            return timeControlMinutes == 3 || timeControlMinutes == 5
                    || timeControlMinutes == 10 || timeControlMinutes == 15;
        }

        @AssertTrue(message = "Entry must be 100, 200 or 500 play coins.")
        boolean supportedEntry() {
            return entryCoins == 100 || entryCoins == 200 || entryCoins == 500;
        }
    }

    record PresenceDto(long onlinePlayers) {
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
            String disconnectedColor,
            Instant disconnectDeadline,
            String result,
            String resultReason,
            String drawOfferedByColor,
            boolean rematchRequestedByYou,
            UUID rematchMatchId,
            Integer ratingBefore,
            Integer ratingAfter,
            Instant createdAt,
            Instant startedAt,
            Instant finishedAt,
            Long durationSeconds,
            Instant updatedAt,
            String tournamentName,
            Integer tournamentRound,
            int entryCoins,
            int rewardPoolCoins,
            int coinsEarned) {
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
                    disconnectedColor(match),
                    disconnectDeadline(match),
                    match.result,
                    match.resultReason,
                    colorOf(match, match.drawOfferedBy),
                    playerId.equals(match.rematchRequestedBy),
                    match.rematchMatchId,
                    match.whitePlayerId.equals(playerId)
                            ? match.whiteRatingBefore : match.blackRatingBefore,
                    match.whitePlayerId.equals(playerId)
                            ? match.whiteRatingAfter : match.blackRatingAfter,
                    match.createdAt,
                    match.startedAt,
                    match.finishedAt,
                    durationSeconds(match),
                    match.updatedAt,
                    match.tournamentName,
                    match.tournamentRound,
                    match.entryCoins,
                    match.entryCoins * 2,
                    coinsEarned(match, playerId));
        }

        private static int coinsEarned(OnlineMatch match, UUID playerId) {
            if (match.status != OnlineMatchStatus.FINISHED) return 0;
            if (match.entryCoins > 0) {
                if ("1/2-1/2".equals(match.result)) {
                    return match.entryCoins;
                }
                boolean won = ("1-0".equals(match.result) && match.whitePlayerId.equals(playerId))
                        || ("0-1".equals(match.result) && playerId.equals(match.blackPlayerId));
                return won ? match.entryCoins * 2 : 0;
            }
            boolean won = ("1-0".equals(match.result) && match.whitePlayerId.equals(playerId))
                    || ("0-1".equals(match.result) && playerId.equals(match.blackPlayerId));
            return won ? 50 : 20;
        }

        private static Long durationSeconds(OnlineMatch match) {
            if (match.startedAt == null || match.finishedAt == null) return null;
            return Math.max(0, java.time.Duration.between(
                    match.startedAt, match.finishedAt).toSeconds());
        }

        private static String colorOf(OnlineMatch match, UUID playerId) {
            if (playerId == null) return null;
            return match.whitePlayerId.equals(playerId) ? "white" : "black";
        }

        private static String disconnectedColor(OnlineMatch match) {
            if (match.whiteDisconnectedAt != null) return "white";
            if (match.blackDisconnectedAt != null) return "black";
            return null;
        }

        private static Instant disconnectDeadline(OnlineMatch match) {
            Instant disconnectedAt = match.whiteDisconnectedAt != null
                    ? match.whiteDisconnectedAt : match.blackDisconnectedAt;
            return disconnectedAt == null
                    ? null : disconnectedAt.plus(OnlineMatchService.DISCONNECT_GRACE);
        }
    }
}
