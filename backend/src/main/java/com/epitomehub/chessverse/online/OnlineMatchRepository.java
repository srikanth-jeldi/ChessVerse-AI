package com.epitomehub.chessverse.online;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface OnlineMatchRepository extends JpaRepository<OnlineMatch, UUID> {
    Optional<OnlineMatch> findByRoomCodeIgnoreCase(String roomCode);

    Optional<OnlineMatch> findFirstByStatusAndWhitePlayerIdOrderByUpdatedAtDesc(
            String status, UUID playerId);

    Optional<OnlineMatch> findFirstByStatusAndWhitePlayerIdNotOrderByUpdatedAtDesc(
            String status, UUID playerId);

    List<OnlineMatch> findTop10ByWhitePlayerIdOrBlackPlayerIdOrderByUpdatedAtDesc(
            UUID whitePlayerId, UUID blackPlayerId);
}
