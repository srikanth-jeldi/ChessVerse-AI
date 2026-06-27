package com.epitomehub.chessverse.engine;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/engine")
class EngineController {
    private final StockfishService stockfish;

    EngineController(StockfishService stockfish) {
        this.stockfish = stockfish;
    }

    @PostMapping("/best-move")
    BestMoveResponse bestMove(@Valid @RequestBody BestMoveRequest request) {
        return stockfish.bestMove(request);
    }

    record BestMoveRequest(
            @NotBlank @Size(max = 120) String fen,
            @Min(1) @Max(10) int level) {
    }

    record BestMoveResponse(
            String move,
            String engine,
            int level,
            int targetElo,
            int moveTimeMs) {
    }
}
