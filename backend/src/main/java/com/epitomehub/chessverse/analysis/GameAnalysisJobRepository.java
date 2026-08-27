package com.epitomehub.chessverse.analysis;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

interface GameAnalysisJobRepository extends JpaRepository<GameAnalysisJob, UUID> {
    Optional<GameAnalysisJob> findByIdAndPlayerId(UUID id, UUID playerId);
    Optional<GameAnalysisJob> findByPlayerIdAndClientRequestId(UUID playerId, String clientRequestId);
    List<GameAnalysisJob> findByPlayerIdOrderByCreatedAtDesc(UUID playerId, Pageable pageable);
    List<GameAnalysisJob> findByStatusInAndUpdatedAtBefore(List<AnalysisJobStatus> statuses, Instant before);
}
