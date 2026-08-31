package com.epitomehub.chessverse.online;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

final class LeaderboardDtos {
    private LeaderboardDtos() {
    }

    record CountryRequest(@NotBlank @Size(max = 64) String country) {
    }

    record PlayerRatingDto(
            UUID playerId,
            String displayName,
            String country,
            int rating,
            int peakRating,
            int gamesPlayed,
            int wins,
            int draws,
            int losses,
            long careerCoinsWon,
            long globalRank,
            long countryRank) {
    }

    record LeaderboardEntryDto(
            long rank,
            UUID playerId,
            String displayName,
            String country,
            int rating,
            int gamesPlayed,
            int wins,
            int draws,
            int losses,
            long careerCoinsWon,
            boolean you) {
    }

    record LeaderboardDto(
            String scope,
            String country,
            PlayerRatingDto you,
            int page,
            int pageSize,
            long totalPlayers,
            boolean hasNext,
            List<LeaderboardEntryDto> entries) {
    }
}
