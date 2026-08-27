package com.epitomehub.chessverse.engine;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_recommendation_outcome")
class AiRecommendationOutcome {
    @Id UUID id;
    UUID playerId;
    UUID interactionId;
    String recommendationType;
    String openingEco;
    String playerColor;
    String timeControl;
    boolean accepted;
    int baselineCentipawnLoss;
    Integer followupCentipawnLoss;
    Instant createdAt;
    Instant resolvedAt;

    protected AiRecommendationOutcome() {}

    AiRecommendationOutcome(UUID playerId, UUID interactionId, String recommendationType,
            String openingEco, String playerColor, String timeControl, boolean accepted,
            int baselineCentipawnLoss, Integer followupCentipawnLoss) {
        id = UUID.randomUUID();
        this.playerId = playerId;
        this.interactionId = interactionId;
        this.recommendationType = recommendationType;
        this.openingEco = openingEco;
        this.playerColor = playerColor;
        this.timeControl = timeControl;
        this.accepted = accepted;
        this.baselineCentipawnLoss = baselineCentipawnLoss;
        this.followupCentipawnLoss = followupCentipawnLoss;
        createdAt = Instant.now();
        resolvedAt = followupCentipawnLoss == null ? null : createdAt;
    }
}
