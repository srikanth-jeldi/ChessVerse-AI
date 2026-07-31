package com.epitomehub.chessverse.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "guest_installation")
class GuestInstallation {
    @Id
    @Column(name = "installation_hash", length = 64)
    String installationHash;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "player_id", unique = true)
    PlayerAccount player;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "last_seen_at", nullable = false)
    Instant lastSeenAt;

    protected GuestInstallation() {
    }

    GuestInstallation(String installationHash, PlayerAccount player) {
        Instant now = Instant.now();
        this.installationHash = installationHash;
        this.player = player;
        this.createdAt = now;
        this.lastSeenAt = now;
    }
}
