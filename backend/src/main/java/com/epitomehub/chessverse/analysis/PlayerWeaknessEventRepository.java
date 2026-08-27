package com.epitomehub.chessverse.analysis;

import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

interface PlayerWeaknessEventRepository extends JpaRepository<PlayerWeaknessEvent, UUID> {
    boolean existsByJobIdAndPly(UUID jobId, int ply);
    List<PlayerWeaknessEvent> findByJobId(UUID jobId);
    List<PlayerWeaknessEvent> findByPlayerIdOrderByOccurredAtDesc(UUID playerId, Pageable pageable);
}
