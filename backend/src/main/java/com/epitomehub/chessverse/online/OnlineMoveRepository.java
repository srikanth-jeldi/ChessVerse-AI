package com.epitomehub.chessverse.online;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface OnlineMoveRepository extends JpaRepository<OnlineMove, UUID> {
    List<OnlineMove> findByMatchIdOrderByPlyAsc(UUID matchId);
}

