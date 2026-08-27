package com.epitomehub.chessverse.analysis;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface GameAnalysisPlyRepository extends JpaRepository<GameAnalysisPly, UUID> {
    Optional<GameAnalysisPly> findByJobIdAndPly(UUID jobId, int ply);
    List<GameAnalysisPly> findByJobIdOrderByPly(UUID jobId);
}
