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
@Table(name = "auth_session")
class AuthSession {
    @Id
    UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "player_id")
    PlayerAccount player;

    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    String tokenHash;

    @Column(name = "refresh_token_hash", unique = true, length = 64)
    String refreshTokenHash;

    @Column(name = "token_family_id")
    UUID tokenFamilyId;

    @Column(name = "device_id", length = 128)
    String deviceId;

    @Column(name = "device_name", length = 160)
    String deviceName;

    @Column(name = "last_used_at", nullable = false)
    Instant lastUsedAt;

    @Column(name = "revoked_at")
    Instant revokedAt;

    @Column(name = "expires_at", nullable = false)
    Instant expiresAt;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    protected AuthSession() {
    }

    AuthSession(PlayerAccount player, String tokenHash, String refreshTokenHash,
            UUID tokenFamilyId, String deviceId, String deviceName, Instant expiresAt) {
        this.id = UUID.randomUUID();
        this.player = player;
        this.tokenHash = tokenHash;
        this.refreshTokenHash = refreshTokenHash;
        this.tokenFamilyId = tokenFamilyId;
        this.deviceId = deviceId;
        this.deviceName = deviceName;
        this.expiresAt = expiresAt;
        this.createdAt = Instant.now();
        this.lastUsedAt = this.createdAt;
    }
}
