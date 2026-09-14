package com.epitomehub.chessverse.analysis;

import static com.epitomehub.chessverse.analysis.SavedPositionDtos.*;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.bhlangonijr.chesslib.Board;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class SavedPositionService {
    private final SavedChessPositionRepository positions;
    private final GameAnalysisJobRepository jobs;
    private final ObjectMapper json;

    SavedPositionService(SavedChessPositionRepository positions, GameAnalysisJobRepository jobs, ObjectMapper json) {
        this.positions = positions;
        this.jobs = jobs;
        this.json = json;
    }

    @Transactional
    SavedPositionResponse save(UUID playerId, SavePositionRequest request) {
        String fen = normalizeFen(request.fen());
        String hash = sha256(fen);
        SavedChessPosition existing = positions.findByPlayerIdAndFenHash(playerId, hash).orElse(null);
        if (existing != null) return response(existing);
        if (request.sourceJobId() != null && jobs.findByIdAndPlayerId(request.sourceJobId(), playerId).isEmpty()) {
            throw new AnalysisJobException(HttpStatus.BAD_REQUEST, "The source analysis job is not yours.");
        }
        try {
            String tags = json.writeValueAsString(request.tags() == null ? List.of() : request.tags().stream()
                    .map(String::trim).filter(value -> !value.isBlank()).distinct().toList());
            return response(positions.save(new SavedChessPosition(playerId, fen, hash,
                    blankToNull(request.label()), request.sourceFormat() == null ? "FEN" :
                            request.sourceFormat().toUpperCase(Locale.ROOT),
                    request.sourceJobId(), request.sourcePly(), tags)));
        } catch (JsonProcessingException impossible) {
            throw new IllegalStateException(impossible);
        }
    }

    @Transactional(readOnly = true)
    List<SavedPositionResponse> list(UUID playerId, int limit) {
        return positions.findByPlayerIdOrderByCreatedAtDesc(playerId, PageRequest.of(0, limit))
                .stream().map(this::response).toList();
    }

    @Transactional(readOnly = true)
    String exportFen(UUID playerId) {
        return positions.findByPlayerIdOrderByCreatedAtDesc(playerId, PageRequest.of(0, 500))
                .stream().map(position -> position.fen).distinct()
                .reduce((left, right) -> left + "\n" + right).orElse("");
    }

    @Transactional
    void delete(UUID playerId, UUID id) {
        SavedChessPosition position = positions.findByIdAndPlayerId(id, playerId)
                .orElseThrow(() -> new AnalysisJobException(HttpStatus.NOT_FOUND, "Saved position was not found."));
        positions.delete(position);
    }

    private SavedPositionResponse response(SavedChessPosition position) {
        try {
            List<String> tags = json.readValue(position.tagsJson, new TypeReference<List<String>>() {});
            return new SavedPositionResponse(position.id, position.fen, position.label, position.sourceFormat,
                    position.sourceJobId, position.sourcePly, tags, position.createdAt, position.updatedAt);
        } catch (JsonProcessingException corrupt) {
            throw new IllegalStateException("Saved position tags are invalid.", corrupt);
        }
    }

    private static String normalizeFen(String input) {
        String fen = String.join(" ", input.trim().split("\\s+"));
        try {
            Board board = new Board();
            board.loadFromFen(fen);
            return board.getFen();
        } catch (RuntimeException invalid) {
            throw new AnalysisJobException(HttpStatus.BAD_REQUEST, "Invalid FEN position.");
        }
    }

    private static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException impossible) {
            throw new IllegalStateException(impossible);
        }
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
