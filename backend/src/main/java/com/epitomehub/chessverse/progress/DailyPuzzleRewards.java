package com.epitomehub.chessverse.progress;

import java.time.*;
import java.util.*;

final class DailyPuzzleRewards {
    private DailyPuzzleRewards() {}
    static int coins(int streak) { return streak <= 0 ? 0 : 10 + ((streak - 1) % 7) * 5; }
    static Set<LocalDate> days(Collection<String> ids, LocalDate today) {
        Set<LocalDate> result = new HashSet<>();
        for (String id : ids) {
            if (id == null || id.length() < 10) continue;
            try {
                LocalDate day = LocalDate.parse(id.substring(0, 10));
                if (!day.isAfter(today)) result.add(day);
            } catch (java.time.format.DateTimeParseException ignored) {}
        }
        return result;
    }
    static int streak(Collection<String> ids, LocalDate today) {
        Set<LocalDate> dates = days(ids, today);
        LocalDate cursor = dates.contains(today) ? today : today.minusDays(1);
        int streak = 0;
        while (dates.contains(cursor)) { streak++; cursor = cursor.minusDays(1); }
        return streak;
    }
    record Puzzle(String id, List<String> moves) {}
    private static final List<Puzzle> PUZZLES = loadPuzzles();
    private static List<Puzzle> loadPuzzles() {
        try (var stream = Objects.requireNonNull(DailyPuzzleRewards.class.getResourceAsStream("/daily_puzzle_rewards.txt"));
             var reader = new java.io.BufferedReader(new java.io.InputStreamReader(stream, java.nio.charset.StandardCharsets.UTF_8))) {
            return reader.lines().filter(line -> !line.isBlank()).map(line -> {
                String[] fields = line.split("\\|");
                return new Puzzle(fields[0], List.of(fields[2].split(",")));
            }).toList();
        } catch (java.io.IOException ex) { throw new IllegalStateException("Daily catalogue unavailable", ex); }
    }
    static Puzzle puzzle(LocalDate day, boolean hard) {
        var pool = PUZZLES.stream().filter(p -> p.id().startsWith(hard ? "hard-" : "medium-")).toList();
        return pool.get(Math.floorMod(day.toEpochDay(), pool.size()));
    }
    static boolean eligible(String id, List<String> moves, LocalDate today) {
        if (id == null || !id.matches("[0-9]{4}-[0-9]{2}-[0-9]{2}-v8-(medium|hard)-[0-9]{3}") || moves == null) return false;
        try {
            LocalDate day = LocalDate.parse(id.substring(0, 10));
            if (day.isAfter(today) || day.isBefore(today.minusDays(6))) return false;
            Puzzle selected = puzzle(day, id.contains("-hard-"));
            return id.equals(day + "-v8-" + selected.id()) && moves.equals(selected.moves());
        } catch (java.time.format.DateTimeParseException ex) { return false; }
    }
}
