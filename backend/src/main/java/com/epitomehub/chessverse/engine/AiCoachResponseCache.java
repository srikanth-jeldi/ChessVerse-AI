package com.epitomehub.chessverse.engine;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Column;
import java.time.Instant;

@Entity
@Table(name = "ai_coach_response_cache")
class AiCoachResponseCache {
    @Id String cacheKey;
    @Column(columnDefinition = "text") String answer;
    @Column(columnDefinition = "text") String engineEvidence;
    Instant createdAt;
    Instant expiresAt;

    protected AiCoachResponseCache() {}

    AiCoachResponseCache(String cacheKey, String answer, String engineEvidence, Instant now, Instant expiresAt) {
        this.cacheKey = cacheKey;
        this.answer = answer;
        this.engineEvidence = engineEvidence;
        this.createdAt = now;
        this.expiresAt = expiresAt;
    }
}
