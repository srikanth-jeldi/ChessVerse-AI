package com.epitomehub.chessverse.game;

import java.util.UUID;

public class GameNotFoundException extends RuntimeException {

    public GameNotFoundException(UUID id) {
        super("Game not found: " + id);
    }
}

