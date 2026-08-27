package com.epitomehub.chessverse.analysis;

import com.github.bhlangonijr.chesslib.Board;
import com.github.bhlangonijr.chesslib.Piece;
import com.github.bhlangonijr.chesslib.Side;
import com.github.bhlangonijr.chesslib.Square;
import com.github.bhlangonijr.chesslib.move.Move;
import com.epitomehub.chessverse.engine.EngineException;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Component
class GameAnalysisWorker {
    private final GameAnalysisJobRepository jobs;
    private final GameAnalysisPlyRepository plies;
    private final GamePositionAnalyzer analyzer;
    private final EcoOpeningBook openings;
    private final PlayerWeaknessEventRepository weaknessEvents;
    private final RecommendationOutcomeResolver outcomeResolver;

    GameAnalysisWorker(GameAnalysisJobRepository jobs, GameAnalysisPlyRepository plies,
            GamePositionAnalyzer analyzer, EcoOpeningBook openings,
            PlayerWeaknessEventRepository weaknessEvents,
            RecommendationOutcomeResolver outcomeResolver) {
        this.jobs = jobs;
        this.plies = plies;
        this.analyzer = analyzer;
        this.openings = openings;
        this.weaknessEvents = weaknessEvents;
        this.outcomeResolver = outcomeResolver;
    }

    @Async("gameAnalysisExecutor")
    public void process(UUID jobId) {
        GameAnalysisJob job = jobs.findById(jobId).orElse(null);
        if (job == null || job.status != AnalysisJobStatus.QUEUED) return;
        job.start();
        jobs.saveAndFlush(job);
        try {
            List<String> moves = job.movesJson.isBlank()
                    ? List.of()
                    : List.of(job.movesJson.split(","));
            Board board = new Board();
            board.loadFromFen(job.initialFen);
            for (int index = 0; index < moves.size(); index++) {
                String uci = moves.get(index);
                Move move = toMove(uci, board.getSideToMove());
                if (!board.legalMoves().contains(move)) {
                    throw new IllegalArgumentException("Illegal move at ply " + (index + 1) + ".");
                }
                int plyNumber = index + 1;
                String fenBefore = board.getFen();
                PositionAnalysis newResult = null;
                if (plies.findByJobIdAndPly(job.id, plyNumber).isEmpty()) {
                    newResult = analyzer.analyze(fenBefore, uci, job.requestedDepth);
                    plies.save(new GameAnalysisPly(job.id, plyNumber, fenBefore, uci, newResult));
                }
                board.doMove(move);
                openings.find(board.getFen()).ifPresent(job::recognizeOpening);
                boolean playerPly = job.playerColor == null ||
                        (plyNumber % 2 == 1 && job.playerColor.equals("WHITE")) ||
                        (plyNumber % 2 == 0 && job.playerColor.equals("BLACK"));
                if (playerPly && newResult != null && newResult.centipawnLoss() > 30 &&
                        !weaknessEvents.existsByJobIdAndPly(job.id, plyNumber)) {
                    weaknessEvents.save(new PlayerWeaknessEvent(job, plyNumber, uci, newResult));
                }
                job.analyzedPlies = plyNumber;
                job.updatedAt = java.time.Instant.now();
                jobs.save(job);
            }
            job.finalizeOpening();
            if (job.openingEco != null) {
                List<PlayerWeaknessEvent> gameEvents = weaknessEvents.findByJobId(job.id);
                gameEvents.forEach(event -> event.openingEco = job.openingEco);
                weaknessEvents.saveAll(gameEvents);
            }
            job.complete();
            outcomeResolver.resolveFromCompletedGame(job);
        } catch (EngineException exception) {
            job.fail("ENGINE_UNAVAILABLE", exception.getMessage());
        } catch (Exception exception) {
            job.fail("INVALID_GAME", exception.getMessage());
        }
        jobs.save(job);
    }

    private static Move toMove(String uci, Side side) {
        Square from = Square.valueOf(uci.substring(0, 2).toUpperCase(Locale.ROOT));
        Square to = Square.valueOf(uci.substring(2, 4).toUpperCase(Locale.ROOT));
        if (uci.length() == 4) return new Move(from, to);
        Piece promotion = switch (Character.toLowerCase(uci.charAt(4))) {
            case 'q' -> side == Side.WHITE ? Piece.WHITE_QUEEN : Piece.BLACK_QUEEN;
            case 'r' -> side == Side.WHITE ? Piece.WHITE_ROOK : Piece.BLACK_ROOK;
            case 'b' -> side == Side.WHITE ? Piece.WHITE_BISHOP : Piece.BLACK_BISHOP;
            case 'n' -> side == Side.WHITE ? Piece.WHITE_KNIGHT : Piece.BLACK_KNIGHT;
            default -> throw new IllegalArgumentException("Invalid promotion piece.");
        };
        return new Move(from, to, promotion);
    }
}
