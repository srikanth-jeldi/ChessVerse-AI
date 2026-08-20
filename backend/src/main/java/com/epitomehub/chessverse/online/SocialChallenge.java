package com.epitomehub.chessverse.online;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "social_challenge")
class SocialChallenge {
    @Id UUID id;
    @Column(name = "challenger_id", nullable = false) UUID challengerId;
    @Column(name = "challenged_id", nullable = false) UUID challengedId;
    @Column(name = "match_id", nullable = false) UUID matchId;
    @Column(name = "room_code", nullable = false, length = 8) String roomCode;
    @Column(name = "time_control_minutes", nullable = false) int timeControlMinutes;
    @Column(nullable = false, length = 16) String status;
    @Column(name = "expires_at", nullable = false) Instant expiresAt;
    @Column(name = "created_at", nullable = false) Instant createdAt;
    @Column(name = "updated_at", nullable = false) Instant updatedAt;

    protected SocialChallenge() {}

    SocialChallenge(UUID challengerId, UUID challengedId, UUID matchId, String roomCode, int minutes) {
        this.id = UUID.randomUUID();
        this.challengerId = challengerId;
        this.challengedId = challengedId;
        this.matchId = matchId;
        this.roomCode = roomCode;
        this.timeControlMinutes = minutes;
        this.status = "PENDING";
        this.createdAt = Instant.now();
        this.updatedAt = createdAt;
        this.expiresAt = createdAt.plusSeconds(15 * 60);
    }
}
