package com.epitomehub.chessverse.progress;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;

final class CloudProgressDtos {
    private CloudProgressDtos() {
    }

    record MergeRequest(
            @Size(max = 24)
            @Pattern(regexp = "^[A-Za-z0-9_.-]{3,24}$")
            String profileUsername,
            @Size(min = 2, max = 64) String country,
            @Min(0) @Max(4) int chessLevel,
            @Min(0) @Max(5) int avatar,
            Instant profileUpdatedAt,
            @Min(0) int dailyStreak,
            Instant lastDailyCompletedAt,
            @Size(max = 150) List<@Pattern(regexp = "^(easy|medium|hard)-[0-9]{1,3}$") String> completedPuzzleIds,
            @Size(max = 400) List<@Size(min = 1, max = 64) String> completedDailyChallengeIds) {
    }

    record ProgressResponse(
            String profileUsername,
            String country,
            int chessLevel,
            int avatar,
            Instant profileUpdatedAt,
            int dailyStreak,
            Instant lastDailyCompletedAt,
            List<String> completedPuzzleIds,
            List<String> completedDailyChallengeIds,
            Instant updatedAt) {
        static ProgressResponse from(PlayerCloudProgress progress) {
            return new ProgressResponse(
                    progress.profileUsername,
                    progress.country,
                    progress.chessLevel,
                    progress.avatar,
                    progress.profileUpdatedAt,
                    progress.dailyStreak,
                    progress.lastDailyCompletedAt,
                    progress.completedPuzzleIds.stream().sorted().toList(),
                    progress.completedDailyChallengeIds.stream().sorted().toList(),
                    progress.updatedAt);
        }
    }
}
