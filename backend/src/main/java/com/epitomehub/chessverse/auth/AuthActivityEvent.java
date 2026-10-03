package com.epitomehub.chessverse.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "auth_activity_event")
class AuthActivityEvent {
    @Id
    UUID id;

    @ManyToOne(optional = true)
    @JoinColumn(name = "player_id")
    PlayerAccount player;

    @Column(name = "event_type", nullable = false, length = 24)
    String eventType;

    @Column(name = "auth_method", nullable = false, length = 24)
    String authMethod;

    @Column(name = "device_name", length = 160)
    String deviceName;

    @Column(name = "client_platform", length = 120)
    String clientPlatform;

    @Column(name = "country_code", length = 8)
    String countryCode;

    @Column(name = "app_version", length = 40)
    String appVersion;

    @Column(name = "installation_fingerprint", length = 32)
    String installationFingerprint;

    @Column(name = "new_device", nullable = false)
    boolean newDevice;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "reported_at")
    Instant reportedAt;

    protected AuthActivityEvent() {}

    AuthActivityEvent(PlayerAccount player, String eventType, String authMethod,
            String deviceName, String clientPlatform, String countryCode,
            String appVersion, String installationFingerprint, boolean newDevice) {
        this.id = UUID.randomUUID();
        this.player = player;
        this.eventType = eventType;
        this.authMethod = authMethod;
        this.deviceName = deviceName;
        this.clientPlatform = clientPlatform;
        this.countryCode = countryCode;
        this.appVersion = appVersion;
        this.installationFingerprint = installationFingerprint;
        this.newDevice = newDevice;
        this.createdAt = Instant.now();
    }
}
