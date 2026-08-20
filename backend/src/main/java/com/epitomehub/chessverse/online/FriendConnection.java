package com.epitomehub.chessverse.online;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "friend_connection")
class FriendConnection {
    @Id UUID id;
    @Column(name = "requester_id", nullable = false) UUID requesterId;
    @Column(name = "addressee_id", nullable = false) UUID addresseeId;
    @Column(nullable = false, length = 16) String status;
    @Column(name = "created_at", nullable = false) Instant createdAt;
    @Column(name = "updated_at", nullable = false) Instant updatedAt;

    protected FriendConnection() {}

    FriendConnection(UUID requesterId, UUID addresseeId) {
        this.id = UUID.randomUUID();
        this.requesterId = requesterId;
        this.addresseeId = addresseeId;
        this.status = "PENDING";
        this.createdAt = Instant.now();
        this.updatedAt = createdAt;
    }

    boolean contains(UUID playerId) {
        return requesterId.equals(playerId) || addresseeId.equals(playerId);
    }

    UUID other(UUID playerId) {
        return requesterId.equals(playerId) ? addresseeId : requesterId;
    }
}
