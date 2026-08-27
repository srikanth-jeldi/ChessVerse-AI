package com.epitomehub.chessverse.analysis;

import java.util.List;

public record PositionAnalysis(String bestMove, String classification,
        int centipawnLoss, int evaluationBeforeCp, int evaluationAfterCp,
        Integer mateBefore, Integer mateAfter, List<String> principalVariation,
        String coachingTheme, int depth) {
}
