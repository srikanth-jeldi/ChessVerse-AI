package com.epitomehub.chessverse.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "player_account")
class PlayerAccount {
    @Id
    UUID id;

    @Column(nullable = false, unique = true, length = 40)
    String username;

    @Column(name = "display_name", nullable = false, length = 80)
    String displayName;

    @Column(unique = true, length = 254)
    String email;

    @Column(unique = true, length = 20)
    String phone;

    @Column(name = "password_hash", nullable = false, length = 100)
    String passwordHash;

    @Column(nullable = false)
    boolean verified;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    protected PlayerAccount() {
    }

    PlayerAccount(
            String username,
            String displayName,
            String email,
            String phone,
            String passwordHash) {
        Instant now = Instant.now();
        this.id = UUID.randomUUID();
        this.username = username;
        this.displayName = displayName;
        this.email = email;
        this.phone = phone;
        this.passwordHash = passwordHash;
        this.createdAt = now;
        this.updatedAt = now;
    }
}
