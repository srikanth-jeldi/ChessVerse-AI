package com.epitomehub.chessverse.game;

import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
public class ChessGame {

    public static final String STARTING_FEN =
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    @Id
    private UUID id;

    @Enumerated(EnumType.STRING)
    private GameMode mode;

    @Enumerated(EnumType.STRING)
    private GameStatus status;

    private String fen;
    private String activeColor;
    private Instant createdAt;
    private Instant updatedAt;

    @ElementCollection(fetch = FetchType.EAGER)
    private List<String> moves = new ArrayList<>();

    protected ChessGame() {
    }

    public ChessGame(UUID id, GameMode mode) {
        this.id = id;
        this.mode = mode;
        this.status = GameStatus.ACTIVE;
        this.fen = STARTING_FEN;
        this.activeColor = "white";
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
    }

    public UUID getId() {
        return id;
    }

    public GameMode getMode() {
        return mode;
    }

    public GameStatus getStatus() {
        return status;
    }

    public String getFen() {
        return fen;
    }

    public String getActiveColor() {
        return activeColor;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public List<String> getMoves() {
        return List.copyOf(moves);
    }

    public void recordMove(String uciMove) {
        moves.add(uciMove);
        activeColor = activeColor.equals("white") ? "black" : "white";
        updatedAt = Instant.now();
    }
}

