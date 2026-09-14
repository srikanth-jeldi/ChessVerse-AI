package com.epitomehub.chessverse.analysis;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "saved_chess_position")
class SavedChessPosition {
    @Id UUID id;
    UUID playerId;
    String fen;
    String fenHash;
    String label;
    String sourceFormat;
    UUID sourceJobId;
    Integer sourcePly;
    String tagsJson;
    Instant createdAt;
    Instant updatedAt;

    protected SavedChessPosition() {}

    SavedChessPosition(UUID playerId, String fen, String fenHash, String label,
            String sourceFormat, UUID sourceJobId, Integer sourcePly, String tagsJson) {
        this.id = UUID.randomUUID();
        this.playerId = playerId;
        this.fen = fen;
        this.fenHash = fenHash;
        this.label = label;
        this.sourceFormat = sourceFormat;
        this.sourceJobId = sourceJobId;
        this.sourcePly = sourcePly;
        this.tagsJson = tagsJson;
        this.createdAt = Instant.now();
        this.updatedAt = createdAt;
    }
}
