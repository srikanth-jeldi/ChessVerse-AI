package com.epitomehub.chessverse.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "email_verification")
class EmailVerification {
    @Id
    UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "player_id")
    PlayerAccount player;

    @Column(name = "code_hash", nullable = false, length = 100)
    String codeHash;

    @Column(name = "expires_at", nullable = false)
    Instant expiresAt;

    @Column(name = "consumed_at")
    Instant consumedAt;

    @Column(nullable = false)
    int attempts;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    protected EmailVerification() {
    }

    EmailVerification(PlayerAccount player, String codeHash, Instant expiresAt) {
        this.id = UUID.randomUUID();
        this.player = player;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.createdAt = Instant.now();
    }
}
