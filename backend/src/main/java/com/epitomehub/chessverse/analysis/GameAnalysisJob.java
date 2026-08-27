package com.epitomehub.chessverse.analysis;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "game_analysis_job")
class GameAnalysisJob {
    @Id
    UUID id;
    UUID playerId;
    String clientRequestId;
    String initialFen;
    String movesJson;
    @Enumerated(EnumType.STRING)
    AnalysisJobStatus status;
    int requestedDepth;
    int totalPlies;
    int analyzedPlies;
    int attemptCount;
    String errorCode;
    String errorMessage;
    Instant createdAt;
    Instant startedAt;
    Instant completedAt;
    Instant updatedAt;
    String openingEco;
    String openingName;
    int bookPlies;
    Integer firstDeviationPly;
    String playerColor;
    String timeControl;

    protected GameAnalysisJob() {
    }

    GameAnalysisJob(UUID playerId, String clientRequestId, String initialFen, String movesJson, int requestedDepth,
            int totalPlies, String playerColor, String timeControl) {
        this.id = UUID.randomUUID();
        this.playerId = playerId;
        this.clientRequestId = clientRequestId;
        this.initialFen = initialFen;
        this.movesJson = movesJson;
        this.status = AnalysisJobStatus.QUEUED;
        this.requestedDepth = requestedDepth;
        this.totalPlies = totalPlies;
        this.playerColor = playerColor;
        this.timeControl = timeControl;
        this.analyzedPlies = 0;
        this.attemptCount = 0;
        this.createdAt = Instant.now();
        this.updatedAt = createdAt;
    }

    void start() {
        status = AnalysisJobStatus.ANALYZING;
        attemptCount++;
        analyzedPlies = 0;
        errorCode = null;
        errorMessage = null;
        startedAt = Instant.now();
        completedAt = null;
        updatedAt = startedAt;
    }

    void complete() {
        status = AnalysisJobStatus.COMPLETED;
        analyzedPlies = totalPlies;
        completedAt = Instant.now();
        updatedAt = completedAt;
    }

    void recognizeOpening(EcoOpeningBook.OpeningMatch opening) {
        if (opening.bookPlies() >= bookPlies) {
            openingEco = opening.eco();
            openingName = opening.name();
            bookPlies = opening.bookPlies();
        }
    }

    void finalizeOpening() {
        firstDeviationPly = bookPlies > 0 && totalPlies > bookPlies ? bookPlies + 1 : null;
    }

    void fail(String code, String message) {
        status = AnalysisJobStatus.FAILED;
        errorCode = code;
        errorMessage = message == null ? "Analysis failed." : message.substring(0, Math.min(500, message.length()));
        completedAt = Instant.now();
        updatedAt = completedAt;
    }

    void queueForRetry() {
        status = AnalysisJobStatus.QUEUED;
        analyzedPlies = 0;
        errorCode = null;
        errorMessage = null;
        startedAt = null;
        completedAt = null;
        updatedAt = Instant.now();
    }
}
