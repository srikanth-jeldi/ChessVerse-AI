package com.epitomehub.chessverse.analysis;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class SavedPositionDtos {
    private SavedPositionDtos() {}

    record SavePositionRequest(
            @NotBlank @Size(max = 120) String fen,
            @Size(max = 120) String label,
            @Pattern(regexp = "FEN|PGN|CHESSVERSE", flags = Pattern.Flag.CASE_INSENSITIVE) String sourceFormat,
            UUID sourceJobId,
            Integer sourcePly,
            @Size(max = 12) List<@Size(max = 40) String> tags) {}

    record SavedPositionResponse(UUID id, String fen, String label, String sourceFormat,
            UUID sourceJobId, Integer sourcePly, List<String> tags,
            Instant createdAt, Instant updatedAt) {}
}
