package com.epitomehub.chessverse.game;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChessGameRepository extends JpaRepository<ChessGame, UUID> {
}

