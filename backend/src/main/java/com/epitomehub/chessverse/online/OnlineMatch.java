package com.epitomehub.chessverse.online;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "online_match")
class OnlineMatch {
    @Id
    UUID id;

    @Column(name = "room_code", nullable = false, unique = true, length = 8)
    String roomCode;

    @Column(name = "white_player_id", nullable = false)
    UUID whitePlayerId;

    @Column(name = "white_player_name", nullable = false, length = 80)
    String whitePlayerName;

    @Column(name = "black_player_id")
    UUID blackPlayerId;

    @Column(name = "black_player_name", length = 80)
    String blackPlayerName;

    @Column(nullable = false, length = 16)
    String status;

    @Column(name = "active_color", nullable = false, length = 5)
    String activeColor;

    @Column(name = "ply_count", nullable = false)
    int plyCount;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    protected OnlineMatch() {
    }

    OnlineMatch(String roomCode, UUID creatorId, String creatorName) {
        Instant now = Instant.now();
        this.id = UUID.randomUUID();
        this.roomCode = roomCode;
        this.whitePlayerId = creatorId;
        this.whitePlayerName = creatorName;
        this.status = "WAITING";
        this.activeColor = "WHITE";
        this.createdAt = now;
        this.updatedAt = now;
    }
}

