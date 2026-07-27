package com.epitomehub.chessverse.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(
        name = "oauth_identity",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_oauth_identity_provider_subject",
                columnNames = {"provider", "subject"}))
class OAuthIdentity {
    @Id
    UUID id;

    @Column(nullable = false, length = 20)
    String provider;

    @Column(nullable = false, length = 255)
    String subject;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "player_id", nullable = false)
    PlayerAccount player;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    protected OAuthIdentity() {
    }

    OAuthIdentity(String provider, String subject, PlayerAccount player) {
        this.id = UUID.randomUUID();
        this.provider = provider;
        this.subject = subject;
        this.player = player;
        this.createdAt = Instant.now();
    }
}
