package com.epitomehub.chessverse.engine;

import java.time.Instant;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface AiCoachInteractionRepository extends JpaRepository<AiCoachInteraction, UUID> {
    long countByPlayerIdAndCreatedAtAfter(UUID playerId, Instant since);
}
