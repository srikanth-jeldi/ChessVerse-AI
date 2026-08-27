package com.epitomehub.chessverse.engine;

import java.time.Instant;
import java.util.UUID;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

interface AiCoachInteractionRepository extends JpaRepository<AiCoachInteraction, UUID> {
    long countByPlayerIdAndCreatedAtAfter(UUID playerId, Instant since);
    List<AiCoachInteraction> findTop10ByPlayerIdAndSessionIdOrderByCreatedAtDesc(UUID playerId, UUID sessionId);
}
