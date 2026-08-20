package com.epitomehub.chessverse.engine;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.epitomehub.chessverse.engine.EngineController.BestMoveRequest;
import com.epitomehub.chessverse.engine.EngineController.MoveReviewRequest;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class StockfishServiceTest {
    @Test
    void rejectsUnsafeFenBeforeStartingEngine() {
        StockfishService service = new StockfishService("missing-stockfish", 1);

        EngineException exception = assertThrows(
                EngineException.class,
                () -> service.bestMove(new BestMoveRequest("startpos\nquit", 4)));

        assertEquals(HttpStatus.BAD_REQUEST, exception.status());
    }

    @Test
    void rejectsUnsafeMoveBeforeStartingEngine() {
        StockfishService service = new StockfishService("missing-stockfish", 1);
        String fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

        EngineException exception = assertThrows(
                EngineException.class,
                () -> service.reviewMove(new MoveReviewRequest(fen, "e2e4 quit", 4)));

        assertEquals(HttpStatus.BAD_REQUEST, exception.status());
    }

    @Test
    void classifiesCentipawnLossWithoutInventingBrilliantMoves() {
        assertEquals("Best", StockfishService.classifyMove(true, 0));
        assertEquals("Great", StockfishService.classifyMove(false, 24));
        assertEquals("Inaccuracy", StockfishService.classifyMove(false, 55));
        assertEquals("Mistake", StockfishService.classifyMove(false, 120));
        assertEquals("Blunder", StockfishService.classifyMove(false, 240));
    }

    @Test
    void validatesMoveAgainstTheSuppliedPositionBeforeRunningStockfish() {
        String start = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
        assertEquals(true, StockfishService.isLegalMove(start, "e2e4"));
        assertEquals(false, StockfishService.isLegalMove(start, "e2e5"));
        assertEquals(false, StockfishService.isLegalMove(start, "e7e5"));
    }
}
