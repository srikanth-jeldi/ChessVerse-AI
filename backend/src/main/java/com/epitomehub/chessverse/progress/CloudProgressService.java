package com.epitomehub.chessverse.progress;

import static com.epitomehub.chessverse.progress.CloudProgressDtos.*;

import java.time.Instant;
import java.util.UUID;
import com.epitomehub.chessverse.economy.EconomyService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class CloudProgressService {
    private final PlayerCloudProgressRepository progressRepository;
    private final EconomyService economyService;

    CloudProgressService(PlayerCloudProgressRepository progressRepository,
            EconomyService economyService) {
        this.progressRepository = progressRepository;
        this.economyService = economyService;
    }

    @Transactional
    ProgressResponse get(UUID playerId) {
        return ProgressResponse.from(progressRepository.findById(playerId)
                .orElseGet(() -> progressRepository.save(new PlayerCloudProgress(playerId))));
    }

    @Transactional
    ProgressResponse merge(UUID playerId, MergeRequest request) {
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
        int previousStreak = progress.dailyStreak;
        progress.dailyStreak = Math.max(progress.dailyStreak, request.dailyStreak());
        grantNewStreakMilestones(playerId, previousStreak, progress.dailyStreak);
        progress.openingWeakness = Math.max(progress.openingWeakness, zeroIfNull(request.openingWeakness()));
        progress.kingSafetyWeakness = Math.max(progress.kingSafetyWeakness, zeroIfNull(request.kingSafetyWeakness()));
        progress.hangingPiecesWeakness = Math.max(progress.hangingPiecesWeakness, zeroIfNull(request.hangingPiecesWeakness()));
        progress.missedCapturesWeakness = Math.max(progress.missedCapturesWeakness, zeroIfNull(request.missedCapturesWeakness()));
        progress.timeManagementWeakness = Math.max(progress.timeManagementWeakness, zeroIfNull(request.timeManagementWeakness()));
        progress.endgameWeakness = Math.max(progress.endgameWeakness, zeroIfNull(request.endgameWeakness()));
        if (request.lastDailyCompletedAt() != null
                && (progress.lastDailyCompletedAt == null
                || request.lastDailyCompletedAt().isAfter(progress.lastDailyCompletedAt))) {
            progress.lastDailyCompletedAt = request.lastDailyCompletedAt();
        }
        if (request.completedPuzzleIds() != null) {
            progress.completedPuzzleIds.addAll(request.completedPuzzleIds());
        }
        if (request.completedDailyChallengeIds() != null) {
            progress.completedDailyChallengeIds.addAll(request.completedDailyChallengeIds());
        }
        if (request.completedAcademyLessonIds() != null) {
            progress.completedAcademyLessonIds.addAll(request.completedAcademyLessonIds());
        }
        progress.updatedAt = Instant.now();
        return ProgressResponse.from(progressRepository.save(progress));
    }

    private int zeroIfNull(Integer value) {
        return value == null ? 0 : value;
    }

    private void grantNewStreakMilestones(UUID playerId, int previousStreak, int currentStreak) {
        int firstMilestone = ((Math.max(0, previousStreak) / 7) + 1) * 7;
        int safeCurrentStreak = Math.min(currentStreak, 3650);
        for (int milestone = firstMilestone; milestone <= safeCurrentStreak; milestone += 7) {
            economyService.grantCoins(playerId, 100, "DAILY_STREAK_BONUS",
                    "daily-streak:" + milestone,
                    milestone + " day Daily Puzzle streak bonus");
        }
    }
}
