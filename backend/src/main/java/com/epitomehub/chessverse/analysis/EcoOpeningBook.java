package com.epitomehub.chessverse.analysis;

import com.github.bhlangonijr.chesslib.move.MoveList;
import jakarta.annotation.PostConstruct;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import org.springframework.stereotype.Component;

@Component
class EcoOpeningBook {
    private final Map<String, OpeningMatch> positions = new HashMap<>();

    @PostConstruct
    void load() {
        for (char volume = 'a'; volume <= 'e'; volume++) {
            loadVolume("/openings/" + volume + ".tsv");
        }
        if (positions.size() < 3000) {
            throw new IllegalStateException("The complete ECO database was not loaded.");
        }
    }

    Optional<OpeningMatch> find(String fen) {
        return Optional.ofNullable(positions.get(positionKey(fen)));
    }

    int size() {
        return positions.size();
    }

    private void loadVolume(String resource) {
        InputStream stream = EcoOpeningBook.class.getResourceAsStream(resource);
        if (stream == null) throw new IllegalStateException("Missing ECO resource " + resource);
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            reader.readLine();
            String line;
            while ((line = reader.readLine()) != null) {
                String[] fields = line.split("\\t", 3);
                if (fields.length != 3) continue;
                try {
                    MoveList moves = new MoveList();
                    moves.loadFromSan(fields[2]);
                    OpeningMatch match = new OpeningMatch(fields[0], fields[1], moves.size());
                    positions.merge(positionKey(moves.getFen()), match,
                            (left, right) -> right.bookPlies() >= left.bookPlies() ? right : left);
                } catch (RuntimeException ignored) {
                    // Upstream is validated, but one malformed row must not disable all openings.
                }
            }
        } catch (IOException exception) {
            throw new IllegalStateException("Could not load ECO resource " + resource, exception);
        }
    }

    private static String positionKey(String fen) {
        String[] fields = fen.trim().split("\\s+");
        if (fields.length < 4) return fen.trim();
        return String.join(" ", fields[0], fields[1], fields[2], fields[3]);
    }

    record OpeningMatch(String eco, String name, int bookPlies) {
    }
}
