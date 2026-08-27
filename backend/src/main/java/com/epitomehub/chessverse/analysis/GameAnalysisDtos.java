package com.epitomehub.chessverse.analysis;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class GameAnalysisDtos {
    private GameAnalysisDtos() {
    }

    record CreateRequest(
            @NotBlank @Size(max = 64) String clientRequestId,
            @NotBlank @Size(max = 120) String initialFen,
            @NotEmpty @Size(max = 400) List<@Pattern(regexp = "[a-h][1-8][a-h][1-8][qrbn]?", flags = Pattern.Flag.CASE_INSENSITIVE) String> moves,
            @Min(8) @Max(22) int depth,
            @Pattern(regexp = "WHITE|BLACK", flags = Pattern.Flag.CASE_INSENSITIVE) String playerColor,
            @Size(max = 20) String timeControl) {
    }

    record JobResponse(
            UUID id,
            AnalysisJobStatus status,
            int requestedDepth,
            int totalPlies,
            int analyzedPlies,
            int attemptCount,
            String errorCode,
            String errorMessage,
            String openingEco,
            String openingName,
            int bookPlies,
            Integer firstDeviationPly,
            Instant createdAt,
            Instant startedAt,
            Instant completedAt,
            Instant updatedAt) {
    }

    record PlyResponse(int ply, String fenBefore, String playedMove,
            String bestMove, String classification, int centipawnLoss,
            String coachingTheme,
            int evaluationBeforeCp, int evaluationAfterCp,
            Integer mateBefore, Integer mateAfter,
            List<String> principalVariation, int depth) {
    }

    record JobDetailResponse(JobResponse job, List<PlyResponse> plies) {
    }

    record WeaknessEventResponse(int ply, String category, int severity,
            String classification, int centipawnLoss, String playedMove,
            String bestMove, String playerColor, String timeControl,
            String openingEco, Instant occurredAt) {
    }

    record WeaknessHistoryResponse(int sampleSize,
            java.util.Map<String, Integer> categoryCounts,
            List<WeaknessEventResponse> events) {
    }

    record WindowTrend(int games, int moves, int averageAccuracy,
            int averageCentipawnLoss, int mistakes, int blunders) {}

    record RecommendationDimension(String dimension, String value,
            int recommendations, int accepted, int resolved,
            int improved, int successPercent) {}

    record AnalysisTrendsResponse(
            java.util.Map<String, WindowTrend> windows,
            List<RecommendationDimension> recommendationOutcomes) {}
}
