package com.epitomehub.chessverse.progress;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "player_cloud_progress")
class PlayerCloudProgress {
    @Id
    @Column(name = "player_id")
    UUID playerId;

    @Column(name = "profile_username", length = 24)
    String profileUsername;

    @Column(nullable = false, length = 64)
    String country = "India";

    @Column(name = "chess_level", nullable = false)
    int chessLevel;

    @Column(nullable = false)
    int avatar;

    @Column(name = "profile_updated_at")
    Instant profileUpdatedAt;

    @Column(name = "daily_streak", nullable = false)
    int dailyStreak;

    @Column(name = "opening_weakness", nullable = false)
    int openingWeakness;

    @Column(name = "king_safety_weakness", nullable = false)
    int kingSafetyWeakness;

    @Column(name = "hanging_pieces_weakness", nullable = false)
    int hangingPiecesWeakness;

    @Column(name = "missed_captures_weakness", nullable = false)
    int missedCapturesWeakness;

    @Column(name = "time_management_weakness", nullable = false)
    int timeManagementWeakness;

    @Column(name = "endgame_weakness", nullable = false)
    int endgameWeakness;

    @Column(name = "last_daily_completed_at")
    Instant lastDailyCompletedAt;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "player_completed_puzzle", joinColumns = @JoinColumn(name = "player_id"))
    @Column(name = "puzzle_id", nullable = false, length = 64)
    Set<String> completedPuzzleIds = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "player_completed_daily_challenge", joinColumns = @JoinColumn(name = "player_id"))
    @Column(name = "challenge_id", nullable = false, length = 64)
    Set<String> completedDailyChallengeIds = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "player_completed_academy_lesson", joinColumns = @JoinColumn(name = "player_id"))
    @Column(name = "lesson_id", nullable = false, length = 64)
    Set<String> completedAcademyLessonIds = new HashSet<>();

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    protected PlayerCloudProgress() {
    }

    PlayerCloudProgress(UUID playerId) {
        this.playerId = playerId;
        this.createdAt = Instant.now();
        this.updatedAt = createdAt;
    }
}
