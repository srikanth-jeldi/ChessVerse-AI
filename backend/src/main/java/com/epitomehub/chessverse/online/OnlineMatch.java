package com.epitomehub.chessverse.online;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "online_match")
class OnlineMatch {
    @Id
    UUID id;

    @Column(name = "room_code", nullable = false, unique = true, length = 8)
    String roomCode;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    OnlineMatchStatus status;

    @Column(name = "white_player_id", nullable = false)
    UUID whitePlayerId;

    @Column(name = "white_player_name", nullable = false, length = 80)
    String whitePlayerName;

    @Column(name = "white_player_photo_url", length = 1024)
    String whitePlayerPhotoUrl;

    @Column(name = "black_player_id")
    UUID blackPlayerId;

    @Column(name = "black_player_name", length = 80)
    String blackPlayerName;

    @Column(name = "black_player_photo_url", length = 1024)
    String blackPlayerPhotoUrl;

    @Column(name = "random_queue", nullable = false)
    boolean randomQueue;

    @Column(name = "time_control_minutes", nullable = false)
    int timeControlMinutes;

    @Column(name = "queue_region", nullable = false, length = 16)
    String queueRegion;

    @Column(name = "queue_country", nullable = false, length = 64)
    String queueCountry;

    @Column(name = "queue_rating", nullable = false)
    int queueRating;

    @Column(name = "rating_range", nullable = false)
    int ratingRange;

    @Column(name = "active_color", nullable = false, length = 8)
    String activeColor;

    @Column(nullable = false, length = 128)
    String fen;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "online_match_move", joinColumns = @JoinColumn(name = "match_id"))
    @OrderColumn(name = "ply_index")
    @Column(name = "uci", nullable = false, length = 8)
    List<String> moves = new ArrayList<>();

    @Column(name = "created_at", nullable = false)
    Instant createdAt;

    @Column(name = "started_at")
    Instant startedAt;

    @Column(name = "finished_at")
    Instant finishedAt;

    @Column(name = "updated_at", nullable = false)
    Instant updatedAt;

    @Column(name = "white_time_ms", nullable = false)
    long whiteTimeMs;

    @Column(name = "black_time_ms", nullable = false)
    long blackTimeMs;

    @Column(name = "turn_started_at")
    Instant turnStartedAt;

    @Column(name = "white_disconnected_at")
    Instant whiteDisconnectedAt;

    @Column(name = "black_disconnected_at")
    Instant blackDisconnectedAt;

    @Column(length = 16)
    String result;

    @Column(name = "result_reason", length = 32)
    String resultReason;

    @Column(name = "draw_offered_by")
    UUID drawOfferedBy;

    @Column(name = "rematch_requested_by")
    UUID rematchRequestedBy;

    @Column(name = "rematch_match_id")
    UUID rematchMatchId;

    @Column(name = "rated_at")
    Instant ratedAt;

    @Column(name = "white_rating_before")
    Integer whiteRatingBefore;

    @Column(name = "white_rating_after")
    Integer whiteRatingAfter;

    @Column(name = "black_rating_before")
    Integer blackRatingBefore;

    @Column(name = "black_rating_after")
    Integer blackRatingAfter;

    @Column(name = "tournament_name", length = 100)
    String tournamentName;

    @Column(name = "tournament_round")
    Integer tournamentRound;

    @Column(name = "entry_coins", nullable = false)
    int entryCoins;

    @Column(name = "coin_pool_settled", nullable = false)
    boolean coinPoolSettled;

    @Version
    long version;

    protected OnlineMatch() {
    }

    OnlineMatch(
            UUID id,
            String roomCode,
            UUID playerId,
            String playerName,
            String playerPhotoUrl,
            boolean randomQueue) {
        this(id, roomCode, playerId, playerName, playerPhotoUrl, randomQueue,
                10, "WORLDWIDE", "Unknown", 1200, 0);
    }

    OnlineMatch(
            UUID id,
            String roomCode,
            UUID playerId,
            String playerName,
            String playerPhotoUrl,
            boolean randomQueue,
            int timeControlMinutes,
            String queueRegion,
            String queueCountry,
            int queueRating,
            int ratingRange) {
        this.id = id;
        this.roomCode = roomCode;
        this.status = OnlineMatchStatus.WAITING;
        this.whitePlayerId = playerId;
        this.whitePlayerName = playerName;
        this.whitePlayerPhotoUrl = playerPhotoUrl;
        this.randomQueue = randomQueue;
        this.entryCoins = 0;
        this.coinPoolSettled = false;
        this.timeControlMinutes = timeControlMinutes;
        this.queueRegion = queueRegion;
        this.queueCountry = queueCountry;
        this.queueRating = queueRating;
        this.ratingRange = ratingRange;
        this.activeColor = "white";
        this.fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
        this.createdAt = Instant.now();
        this.updatedAt = createdAt;
        this.whiteTimeMs = timeControlMinutes * 60 * 1000L;
        this.blackTimeMs = timeControlMinutes * 60 * 1000L;
    }

    boolean contains(UUID playerId) {
        return whitePlayerId.equals(playerId) || playerId.equals(blackPlayerId);
    }
}
