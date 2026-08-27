package com.epitomehub.chessverse.analysis;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "game_analysis_ply")
class GameAnalysisPly {
    @Id UUID id;
    UUID jobId;
    int ply;
    String fenBefore;
    String playedMove;
    String bestMove;
    String classification;
    String coachingTheme;
    int centipawnLoss;
    int evaluationBeforeCp;
    int evaluationAfterCp;
    Integer mateBefore;
    Integer mateAfter;
    String principalVariation;
    int depth;
    Instant createdAt;

    protected GameAnalysisPly() {}

    GameAnalysisPly(UUID jobId, int ply, String fenBefore, String playedMove, PositionAnalysis result) {
        this.id = UUID.randomUUID();
        this.jobId = jobId;
        this.ply = ply;
        this.fenBefore = fenBefore;
        this.playedMove = playedMove;
        this.bestMove = result.bestMove();
        this.classification = result.classification();
        this.coachingTheme = result.coachingTheme();
        this.centipawnLoss = result.centipawnLoss();
        this.evaluationBeforeCp = result.evaluationBeforeCp();
        this.evaluationAfterCp = result.evaluationAfterCp();
        this.mateBefore = result.mateBefore();
        this.mateAfter = result.mateAfter();
        this.principalVariation = String.join(",", result.principalVariation());
        this.depth = result.depth();
        this.createdAt = Instant.now();
    }

    List<String> variation() {
        return principalVariation.isBlank() ? List.of() : List.of(principalVariation.split(","));
    }
}
