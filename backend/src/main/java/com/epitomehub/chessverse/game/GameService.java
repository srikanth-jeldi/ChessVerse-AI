package com.epitomehub.chessverse.game;

import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GameService {

    private final ChessGameRepository repository;

    public GameService(ChessGameRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public ChessGame create(GameMode mode) {
        return repository.save(new ChessGame(UUID.randomUUID(), mode));
    }

    @Transactional(readOnly = true)
    public ChessGame get(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new GameNotFoundException(id));
    }

    @Transactional
    public ChessGame submitMove(UUID id, String move) {
        ChessGame game = get(id);
        game.recordMove(move);
        return repository.save(game);
    }
}

