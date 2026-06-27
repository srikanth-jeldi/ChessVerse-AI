package com.epitomehub.chessverse.engine;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.epitomehub.chessverse.engine.EngineController.BestMoveRequest;
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
}
