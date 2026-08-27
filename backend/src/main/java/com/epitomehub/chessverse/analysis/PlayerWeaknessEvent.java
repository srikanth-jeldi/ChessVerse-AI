package com.epitomehub.chessverse.analysis;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "player_weakness_event")
class PlayerWeaknessEvent {
    @Id UUID id;
    UUID playerId;
    UUID jobId;
    int ply;
    String category;
    int severity;
    String classification;
    int centipawnLoss;
    String playedMove;
    String bestMove;
    String playerColor;
    String timeControl;
    String openingEco;
    Instant occurredAt;

    protected PlayerWeaknessEvent() {}

    PlayerWeaknessEvent(GameAnalysisJob job, int ply, String playedMove, PositionAnalysis result) {
        id = UUID.randomUUID();
        playerId = job.playerId;
        jobId = job.id;
        this.ply = ply;
        category = result.coachingTheme();
        severity = Math.min(100, Math.max(1, result.centipawnLoss() / 2));
        classification = result.classification();
        centipawnLoss = result.centipawnLoss();
        this.playedMove = playedMove;
        bestMove = result.bestMove();
        playerColor = job.playerColor;
        timeControl = job.timeControl;
        openingEco = job.openingEco;
        occurredAt = Instant.now();
    }
}
