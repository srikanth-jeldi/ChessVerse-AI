package com.epitomehub.chessverse.analysis;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.github.bhlangonijr.chesslib.move.MoveList;
import org.junit.jupiter.api.Test;

class EcoOpeningBookTest {
    @Test
    void loadsAllFiveEcoVolumesAndRecognizesTransposedPositions() throws Exception {
        EcoOpeningBook book = new EcoOpeningBook();
        book.load();

        assertTrue(book.size() >= 3000);
        MoveList najdorf = new MoveList();
        najdorf.loadFromSan("1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6");
        EcoOpeningBook.OpeningMatch match = book.find(najdorf.getFen()).orElseThrow();
        assertEquals("B90", match.eco());
        assertTrue(match.name().contains("Najdorf"));
        assertEquals(10, match.bookPlies());
    }
}
