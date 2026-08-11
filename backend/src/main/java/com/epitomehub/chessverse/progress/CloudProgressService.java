package com.epitomehub.chessverse.progress;

import static com.epitomehub.chessverse.progress.CloudProgressDtos.*;

import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class CloudProgressService {
    private final PlayerCloudProgressRepository progressRepository;

    CloudProgressService(PlayerCloudProgressRepository progressRepository) {
        this.progressRepository = progressRepository;
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
        progress.dailyStreak = Math.max(progress.dailyStreak, request.dailyStreak());
        progress.openingWeakness = Math.max(progress.openingWeakness, request.openingWeakness());
        progress.kingSafetyWeakness = Math.max(progress.kingSafetyWeakness, request.kingSafetyWeakness());
        progress.hangingPiecesWeakness = Math.max(progress.hangingPiecesWeakness, request.hangingPiecesWeakness());
        progress.missedCapturesWeakness = Math.max(progress.missedCapturesWeakness, request.missedCapturesWeakness());
        progress.timeManagementWeakness = Math.max(progress.timeManagementWeakness, request.timeManagementWeakness());
        progress.endgameWeakness = Math.max(progress.endgameWeakness, request.endgameWeakness());
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
        progress.updatedAt = Instant.now();
        return ProgressResponse.from(progressRepository.save(progress));
    }
}
