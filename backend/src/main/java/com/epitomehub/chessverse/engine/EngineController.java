package com.epitomehub.chessverse.engine;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;
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

    @PostMapping("/analyze")
    AnalyzeResponse analyze(@Valid @RequestBody AnalyzeRequest request) {
        return stockfish.analyze(request);
    }

    @PostMapping("/review-move")
    MoveReviewResponse reviewMove(@Valid @RequestBody MoveReviewRequest request) {
        return stockfish.reviewMove(request);
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

    record AnalyzeRequest(
            @NotBlank @Size(max = 120) String fen,
            @Min(1) @Max(10) int level) {
    }

    record AnalyzeResponse(
            String bestMove,
            String engine,
            int evaluationCp,
            Integer mateIn,
            List<String> principalVariation,
            int depth) {
    }

    record MoveReviewRequest(
            @NotBlank @Size(max = 120) String fen,
            @NotBlank @Size(min = 4, max = 5) String playedMove,
            @Min(1) @Max(10) int level) {
    }

    record MoveReviewResponse(
            String playedMove,
            String bestMove,
            String classification,
            int centipawnLoss,
            int evaluationBeforeCp,
            int evaluationAfterCp,
            String coachingTheme,
            String opponentThreat,
            String explanation,
            List<String> principalVariation,
            int depth) {
    }
}
