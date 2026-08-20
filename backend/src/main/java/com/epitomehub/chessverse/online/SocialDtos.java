package com.epitomehub.chessverse.online;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class SocialDtos {
    private SocialDtos() {}

    record FriendRequest(@NotBlank @Size(max = 80) String username) {}
    record ChallengeRequest(@NotNull UUID friendId, @Min(3) @Max(15) int timeControlMinutes) {}
    record PlayerDto(UUID connectionId, UUID playerId, String username, String displayName, String photoUrl,
                     String country, int rating, int gamesPlayed, int wins, int draws, int losses,
                     int peakRating, boolean online, String relationship) {}
    record ChallengeDto(UUID id, UUID challengerId, UUID challengedId, String opponentName,
                        String opponentPhotoUrl, int timeControlMinutes, String roomCode,
                        UUID matchId, String status, boolean incoming, Instant expiresAt) {}
    record SocialHubDto(List<PlayerDto> friends, List<PlayerDto> incomingRequests,
                        List<PlayerDto> outgoingRequests, List<ChallengeDto> challenges) {}
}
