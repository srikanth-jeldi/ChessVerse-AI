package com.epitomehub.chessverse.engine;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface AiRecommendationOutcomeRepository extends JpaRepository<AiRecommendationOutcome, UUID> {
    Optional<AiRecommendationOutcome> findByInteractionIdAndPlayerId(UUID interactionId, UUID playerId);
}
