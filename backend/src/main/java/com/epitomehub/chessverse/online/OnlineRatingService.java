package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OnlineRatingService {
    private static final int K_FACTOR = 32;
    private static final int MAX_PAGE_SIZE = 100;

    private final OnlinePlayerRatingRepository ratings;

    public OnlineRatingService(OnlinePlayerRatingRepository ratings) {
        this.ratings = ratings;
    }

    @Transactional
    public void settle(OnlineMatch match) {
        if (match.ratedAt != null || match.blackPlayerId == null || match.result == null) return;

        List<PlayerSeed> seeds = new ArrayList<>(List.of(
                new PlayerSeed(match.whitePlayerId, match.whitePlayerName),
                new PlayerSeed(match.blackPlayerId, match.blackPlayerName)));
        seeds.sort(Comparator.comparing(seed -> seed.id().toString()));
        OnlinePlayerRating first = lockOrCreate(seeds.get(0));
        OnlinePlayerRating second = lockOrCreate(seeds.get(1));
        OnlinePlayerRating white = first.playerId.equals(match.whitePlayerId) ? first : second;
        OnlinePlayerRating black = first.playerId.equals(match.blackPlayerId) ? first : second;

        int whiteBefore = white.rating;
        int blackBefore = black.rating;
        double whiteScore = switch (match.result) {
            case "1-0" -> 1.0;
            case "0-1" -> 0.0;
            default -> 0.5;
        };
        double expectedWhite = 1.0 / (1.0 + Math.pow(10.0, (blackBefore - whiteBefore) / 400.0));
        int whiteDelta = (int) Math.round(K_FACTOR * (whiteScore - expectedWhite));
        int blackDelta = -whiteDelta;

        apply(white, whiteScore, whiteDelta);
        apply(black, 1.0 - whiteScore, blackDelta);
        ratings.saveAll(List.of(white, black));

        match.whiteRatingBefore = whiteBefore;
        match.whiteRatingAfter = white.rating;
        match.blackRatingBefore = blackBefore;
        match.blackRatingAfter = black.rating;
        match.ratedAt = Instant.now();
    }

    @Transactional
    public LeaderboardDtos.PlayerRatingDto profile(AuthenticatedPlayer player) {
        return profileDto(lockOrCreate(new PlayerSeed(player.id(), player.displayName())));
    }

    @Transactional
    public LeaderboardDtos.PlayerRatingDto updateCountry(
            AuthenticatedPlayer player, String rawCountry) {
        OnlinePlayerRating rating =
                lockOrCreate(new PlayerSeed(player.id(), player.displayName()));
        rating.country = normalizeCountry(rawCountry);
        rating.updatedAt = Instant.now();
        return profileDto(ratings.save(rating));
    }

    @Transactional
    public LeaderboardDtos.LeaderboardDto leaderboard(
            AuthenticatedPlayer player, String rawScope, String requestedCountry,
            int requestedPage, int requestedSize) {
        OnlinePlayerRating you =
                lockOrCreate(new PlayerSeed(player.id(), player.displayName()));
        String scope = "country".equalsIgnoreCase(rawScope) ? "country" : "global";
        String country = requestedCountry == null || requestedCountry.isBlank()
                ? you.country
                : normalizeCountry(requestedCountry);
        int pageNumber = Math.max(0, requestedPage);
        int pageSize = Math.max(1, Math.min(MAX_PAGE_SIZE, requestedSize));
        Page<OnlinePlayerRating> result = scope.equals("country")
                ? ratings.byCountry(country, PageRequest.of(pageNumber, pageSize))
                : ratings.global(PageRequest.of(pageNumber, pageSize));
        List<OnlinePlayerRating> rows = result.getContent();
        List<LeaderboardDtos.LeaderboardEntryDto> entries = new ArrayList<>();
        for (int index = 0; index < rows.size(); index++) {
            OnlinePlayerRating row = rows.get(index);
            entries.add(new LeaderboardDtos.LeaderboardEntryDto(
                    (long) pageNumber * pageSize + index + 1L,
                    row.playerId, row.displayName, row.country, row.rating,
                    row.gamesPlayed, row.wins, row.draws, row.losses,
                    row.playerId.equals(player.id())));
        }
        return new LeaderboardDtos.LeaderboardDto(
                scope, scope.equals("country") ? country : null, profileDto(you),
                pageNumber, pageSize, result.getTotalElements(), result.hasNext(), entries);
    }

    private OnlinePlayerRating lockOrCreate(PlayerSeed seed) {
        ratings.ensureExists(seed.id(), seed.name());
        return ratings.lockByPlayerId(seed.id()).map(existing -> {
            if (!existing.displayName.equals(seed.name())) {
                existing.displayName = seed.name();
                existing.updatedAt = Instant.now();
            }
            return existing;
        }).orElseThrow(() ->
                new IllegalStateException("Rating profile could not be initialized."));
    }

    private void apply(OnlinePlayerRating rating, double score, int delta) {
        rating.rating = Math.max(100, rating.rating + delta);
        rating.peakRating = Math.max(rating.peakRating, rating.rating);
        rating.gamesPlayed++;
        if (score == 1.0) rating.wins++;
        else if (score == 0.0) rating.losses++;
        else rating.draws++;
        rating.updatedAt = Instant.now();
    }

    private LeaderboardDtos.PlayerRatingDto profileDto(OnlinePlayerRating rating) {
        long globalRank = rating.gamesPlayed == 0 ? 0
                : ratings.countGlobalPlayersAhead(
                        rating.rating, rating.wins, rating.gamesPlayed, rating.playerId) + 1;
        long countryRank = rating.gamesPlayed == 0 ? 0
                : ratings.countCountryPlayersAhead(
                        rating.country, rating.rating, rating.wins,
                        rating.gamesPlayed, rating.playerId) + 1;
        return new LeaderboardDtos.PlayerRatingDto(
                rating.playerId, rating.displayName, rating.country, rating.rating,
                rating.peakRating, rating.gamesPlayed, rating.wins, rating.draws, rating.losses,
                globalRank, countryRank);
    }

    private String normalizeCountry(String rawCountry) {
        String country = rawCountry == null ? "" : rawCountry.trim();
        if (country.isBlank()) return "Unknown";
        return country.substring(0, Math.min(64, country.length()));
    }

    private record PlayerSeed(UUID id, String name) {
    }
}
