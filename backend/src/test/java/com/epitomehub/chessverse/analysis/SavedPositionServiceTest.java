package com.epitomehub.chessverse.analysis;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;

class SavedPositionServiceTest {
    private static final String START =
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    @Test
    void savesAValidatedOwnedPositionWithStructuredTags() {
        UUID player = UUID.randomUUID();
        SavedChessPositionRepository positions = mock(SavedChessPositionRepository.class);
        when(positions.findByPlayerIdAndFenHash(any(), anyString())).thenReturn(Optional.empty());
        when(positions.save(any())).thenAnswer(call -> call.getArgument(0));
        SavedPositionService service = new SavedPositionService(
                positions, mock(GameAnalysisJobRepository.class), new ObjectMapper());

        var saved = service.save(player, new SavedPositionDtos.SavePositionRequest(
                START, "Opening", "FEN", null, null, List.of("opening", "retry")));

        assertEquals(START, saved.fen());
        assertEquals(List.of("opening", "retry"), saved.tags());
        verify(positions).save(any());
    }

    @Test
    void rejectsForeignSourceJob() {
        UUID player = UUID.randomUUID();
        UUID jobId = UUID.randomUUID();
        SavedChessPositionRepository positions = mock(SavedChessPositionRepository.class);
        GameAnalysisJobRepository jobs = mock(GameAnalysisJobRepository.class);
        when(positions.findByPlayerIdAndFenHash(any(), anyString())).thenReturn(Optional.empty());
        when(jobs.findByIdAndPlayerId(jobId, player)).thenReturn(Optional.empty());
        SavedPositionService service = new SavedPositionService(positions, jobs, new ObjectMapper());

        ResponseStatusException error = assertThrows(ResponseStatusException.class,
                () -> service.save(player, new SavedPositionDtos.SavePositionRequest(
                        START, null, "PGN", jobId, 1, List.of())));

        assertEquals(400, error.getStatusCode().value());
        verify(positions, never()).save(any());
    }
}
