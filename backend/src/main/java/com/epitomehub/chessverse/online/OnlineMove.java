package com.epitomehub.chessverse.online;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "online_move")
class OnlineMove {
    @Id
    UUID id;

    @Column(name = "match_id", nullable = false)
    UUID matchId;

    @Column(nullable = false)
    int ply;

    @Column(nullable = false, length = 5)
    String uci;

    @Column(name = "player_id", nullable = false)
    UUID playerId;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    protected OnlineMove() {
    }

    OnlineMove(UUID matchId, int ply, String uci, UUID playerId) {
        this.id = UUID.randomUUID();
        this.matchId = matchId;
        this.ply = ply;
        this.uci = uci;
        this.playerId = playerId;
        this.createdAt = Instant.now();
    }
}

