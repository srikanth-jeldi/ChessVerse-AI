package com.epitomehub.chessverse.analysis;

public interface GamePositionAnalyzer {
    PositionAnalysis analyze(String fen, String playedMove, int depth);
}
