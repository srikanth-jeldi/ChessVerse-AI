package com.epitomehub.chessverse.online;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "online_player_rating")
class OnlinePlayerRating {
    @Id
    @Column(name = "player_id")
    UUID playerId;

    @Column(name = "display_name", nullable = false, length = 80)
    String displayName;

    @Column(nullable = false, length = 64)
    String country;

    @Column(nullable = false)
    int rating;

    @Column(name = "peak_rating", nullable = false)
    int peakRating;

    @Column(name = "games_played", nullable = false)
    int gamesPlayed;

    @Column(nullable = false)
    int wins;

    @Column(nullable = false)
    int draws;

    @Column(nullable = false)
    int losses;

    @Column(name = "career_coins_won", nullable = false)
    long careerCoinsWon;

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    protected OnlinePlayerRating() {
    }

    OnlinePlayerRating(UUID playerId, String displayName) {
        this.playerId = playerId;
        this.displayName = displayName;
        this.country = "Unknown";
        this.rating = 1200;
        this.peakRating = 1200;
        this.createdAt = Instant.now();
        this.updatedAt = createdAt;
    }
}
