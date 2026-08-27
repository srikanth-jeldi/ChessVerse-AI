package com.epitomehub.chessverse.engine;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Column;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_coach_interaction")
class AiCoachInteraction {
    @Id UUID id;
    UUID playerId;
    UUID sessionId;
    String cacheKey;
    @Column(length = 500) String question;
    String candidateMove;
    boolean cacheHit;
    @Column(columnDefinition = "text") String answer;
    String classification;
    String bestMove;
    Integer centipawnLoss;
    String opponentThreat;
    @Column(columnDefinition = "text") String principalVariation;
    Boolean helpful;
    Instant createdAt;

    protected AiCoachInteraction() {}

    AiCoachInteraction(UUID playerId, UUID sessionId, String cacheKey, String question, String candidateMove,
            boolean cacheHit, String answer, EngineController.MoveReviewResponse evidence) {
        id = UUID.randomUUID();
        this.playerId = playerId;
        this.sessionId = sessionId;
        this.cacheKey = cacheKey;
        this.question = question;
        this.candidateMove = candidateMove;
        this.cacheHit = cacheHit;
        this.answer = answer;
        classification = evidence.classification();
        bestMove = evidence.bestMove();
        centipawnLoss = evidence.centipawnLoss();
        opponentThreat = evidence.opponentThreat();
        principalVariation = String.join(" ", evidence.principalVariation());
        createdAt = Instant.now();
    }
}
