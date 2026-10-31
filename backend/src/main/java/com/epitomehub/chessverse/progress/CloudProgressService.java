package com.epitomehub.chessverse.progress;

import static com.epitomehub.chessverse.progress.CloudProgressDtos.*;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.UUID;
import com.epitomehub.chessverse.economy.EconomyService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class CloudProgressService {
    private final PlayerCloudProgressRepository progressRepository;
    private final EconomyService economyService;
    private final JdbcTemplate jdbc;

    CloudProgressService(PlayerCloudProgressRepository progressRepository,
            EconomyService economyService, JdbcTemplate jdbc) {
        this.jdbc = jdbc;
        this.progressRepository = progressRepository;
        this.economyService = economyService;
    }

    @Transactional
    ProgressResponse get(UUID playerId) {
        PlayerCloudProgress progress = progressRepository.findById(playerId)
                .orElseGet(() -> progressRepository.save(new PlayerCloudProgress(playerId)));
        progress.dailyStreak = DailyPuzzleRewards.streak(progress.completedDailyChallengeIds, LocalDate.now(ZoneOffset.UTC));
        return ProgressResponse.from(progress);
    }

    @Transactional
    ProgressResponse merge(UUID playerId, MergeRequest request) {
        // Serialize concurrent device merges before loading progress or awarding coins.
        jdbc.queryForObject("select id from player_account where id=? for update", UUID.class, playerId);
        PlayerCloudProgress progress = progressRepository.findById(playerId)
                .orElseGet(() -> new PlayerCloudProgress(playerId));
        if (request.profileUpdatedAt() != null
                && (progress.profileUpdatedAt == null
                || request.profileUpdatedAt().isAfter(progress.profileUpdatedAt))) {
            if (request.profileUsername() != null && !request.profileUsername().isBlank()) {
                progress.profileUsername = request.profileUsername().trim();
            }
            if (request.country() != null && !request.country().isBlank()) {
                progress.country = request.country().trim();
            }
            progress.chessLevel = request.chessLevel();
            progress.avatar = request.avatar();
            progress.profileUpdatedAt = request.profileUpdatedAt();
        }
        progress.openingWeakness = Math.max(progress.openingWeakness, zeroIfNull(request.openingWeakness()));
        progress.kingSafetyWeakness = Math.max(progress.kingSafetyWeakness, zeroIfNull(request.kingSafetyWeakness()));
        progress.hangingPiecesWeakness = Math.max(progress.hangingPiecesWeakness, zeroIfNull(request.hangingPiecesWeakness()));
        progress.missedCapturesWeakness = Math.max(progress.missedCapturesWeakness, zeroIfNull(request.missedCapturesWeakness()));
        progress.timeManagementWeakness = Math.max(progress.timeManagementWeakness, zeroIfNull(request.timeManagementWeakness()));
        progress.endgameWeakness = Math.max(progress.endgameWeakness, zeroIfNull(request.endgameWeakness()));
        if (request.lastDailyCompletedAt() != null
                && !request.lastDailyCompletedAt().isAfter(Instant.now())
                && (progress.lastDailyCompletedAt == null
                || request.lastDailyCompletedAt().isAfter(progress.lastDailyCompletedAt))) {
            progress.lastDailyCompletedAt = request.lastDailyCompletedAt();
        }
        if (request.completedPuzzleIds() != null) {
            progress.completedPuzzleIds.addAll(request.completedPuzzleIds());
        }
        if (request.completedDailyChallengeIds() != null) {
            for (String id : request.completedDailyChallengeIds()) {
                if (!id.contains("-v8-") || DailyPuzzleRewards.eligible(id,
                        request.dailyCompletionMoves() == null ? null : request.dailyCompletionMoves().get(id),
                        LocalDate.now(ZoneOffset.UTC))) progress.completedDailyChallengeIds.add(id);
            }
        }
        if (request.completedAcademyLessonIds() != null) {
            progress.completedAcademyLessonIds.addAll(request.completedAcademyLessonIds());
        }
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        progress.dailyStreak = DailyPuzzleRewards.streak(progress.completedDailyChallengeIds, today);
        if (request.dailyCompletionMoves() != null) {
            for (var proof : new java.util.TreeMap<>(request.dailyCompletionMoves()).entrySet()) {
                String id = proof.getKey();
                if (!progress.completedDailyChallengeIds.contains(id) || !DailyPuzzleRewards.eligible(id, proof.getValue(), today)) continue;
                LocalDate day = LocalDate.parse(id.substring(0, 10));
                int streak = DailyPuzzleRewards.streak(progress.completedDailyChallengeIds, day);
                economyService.grantCoins(playerId, DailyPuzzleRewards.coins(streak),
                        "DAILY_PUZZLE_REWARD", "daily-puzzle:" + day,
                        "Daily Puzzle day " + ((streak - 1) % 7 + 1));
            }
        }
        progress.updatedAt = Instant.now();
        return ProgressResponse.from(progressRepository.save(progress));
    }

    private int zeroIfNull(Integer value) {
        return value == null ? 0 : value;
    }

}
