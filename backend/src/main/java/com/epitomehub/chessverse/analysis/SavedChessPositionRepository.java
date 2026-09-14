package com.epitomehub.chessverse.analysis;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

interface SavedChessPositionRepository extends JpaRepository<SavedChessPosition, UUID> {
    Optional<SavedChessPosition> findByPlayerIdAndFenHash(UUID playerId, String fenHash);
    Optional<SavedChessPosition> findByIdAndPlayerId(UUID id, UUID playerId);
    List<SavedChessPosition> findByPlayerIdOrderByCreatedAtDesc(UUID playerId, Pageable pageable);
}
