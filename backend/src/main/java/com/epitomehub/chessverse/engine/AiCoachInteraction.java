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
    String cacheKey;
    @Column(length = 500) String question;
    String candidateMove;
    boolean cacheHit;
    Boolean helpful;
    Instant createdAt;

    protected AiCoachInteraction() {}

    AiCoachInteraction(UUID playerId, String cacheKey, String question, String candidateMove, boolean cacheHit) {
        id = UUID.randomUUID();
        this.playerId = playerId;
        this.cacheKey = cacheKey;
        this.question = question;
        this.candidateMove = candidateMove;
        this.cacheHit = cacheHit;
        createdAt = Instant.now();
    }
}
