package com.epitomehub.chessverse.engine;

import java.util.List;

/**
 * Optional language layer for the coach. Implementations receive chess evidence only;
 * authentication data, profile fields and tokens must never be added to this context.
 */
public interface CoachLanguageProvider {
    boolean enabled();

    String explain(CoachLanguageContext context);

    record CoachLanguageContext(
            String fen,
            String question,
            String previousQuestion,
            String playedMove,
            String candidateMove,
            String classification,
            String bestMove,
            int centipawnLoss,
            String opponentThreat,
            List<String> principalVariation) {}
}
