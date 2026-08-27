package com.epitomehub.chessverse.engine;

import static com.epitomehub.chessverse.engine.EngineController.BestMoveRequest;
import static com.epitomehub.chessverse.engine.EngineController.BestMoveResponse;
import static com.epitomehub.chessverse.engine.EngineController.AnalyzeRequest;
import static com.epitomehub.chessverse.engine.EngineController.AnalyzeResponse;
import static com.epitomehub.chessverse.engine.EngineController.MoveReviewRequest;
import static com.epitomehub.chessverse.engine.EngineController.MoveReviewResponse;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.time.Duration;
import java.util.List;
import java.util.ArrayList;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.regex.Pattern;
import java.util.Locale;
import com.epitomehub.chessverse.analysis.GamePositionAnalyzer;
import com.epitomehub.chessverse.analysis.PositionAnalysis;
import com.github.bhlangonijr.chesslib.Board;
import com.github.bhlangonijr.chesslib.Piece;
import com.github.bhlangonijr.chesslib.Side;
import com.github.bhlangonijr.chesslib.Square;
import com.github.bhlangonijr.chesslib.move.Move;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class StockfishService implements GamePositionAnalyzer {
    private static final Pattern SAFE_FEN =
            Pattern.compile("^[prnbqkPRNBQK1-8/]+ [wb] (?:-|[KQkq]+) (?:-|[a-h][36]) \\d+ \\d+$");
    private static final Pattern SAFE_UCI_MOVE = Pattern.compile("^[a-h][1-8][a-h][1-8][qrbn]?$", Pattern.CASE_INSENSITIVE);
    private static final List<Integer> ELO_LEVELS =
            List.of(1320, 1400, 1500, 1600, 1750, 1900, 2100, 2300, 2600, 3000);
    private static final List<Integer> MOVE_TIMES_MS =
            List.of(100, 130, 170, 230, 320, 450, 650, 900, 1200, 1600);
    private static final List<Integer> ANALYSIS_DEPTHS =
            List.of(8, 9, 10, 11, 12, 13, 14, 16, 18, 20);

    private final String stockfishPath;
    private final Duration responseTimeout;

    StockfishService(
            @Value("${chessverse.engine.stockfish-path:stockfish}") String stockfishPath,
            @Value("${chessverse.engine.response-timeout-seconds:5}") long responseTimeoutSeconds) {
        this.stockfishPath = stockfishPath;
        this.responseTimeout = Duration.ofSeconds(responseTimeoutSeconds);
    }

    BestMoveResponse bestMove(BestMoveRequest request) {
        String fen = request.fen().trim();
        if (!SAFE_FEN.matcher(fen).matches()) {
            throw new EngineException(HttpStatus.BAD_REQUEST, "The supplied chess position is invalid.");
        }

        int levelIndex = request.level() - 1;
        int targetElo = ELO_LEVELS.get(levelIndex);
        int moveTimeMs = MOVE_TIMES_MS.get(levelIndex);
        Process process = startEngine();

        try (BufferedWriter input = new BufferedWriter(new OutputStreamWriter(
                process.getOutputStream(), StandardCharsets.UTF_8));
                BufferedReader output = new BufferedReader(new InputStreamReader(
                        process.getInputStream(), StandardCharsets.UTF_8))) {
            send(input, "uci");
            send(input, "setoption name Threads value 1");
            send(input, "setoption name Hash value 32");
            send(input, "setoption name UCI_LimitStrength value true");
            send(input, "setoption name UCI_Elo value " + targetElo);
            send(input, "isready");
            send(input, "position fen " + fen);
            send(input, "go movetime " + moveTimeMs);

            String bestMove = CompletableFuture.supplyAsync(() -> readBestMove(output))
                    .get(responseTimeout.toMillis(), TimeUnit.MILLISECONDS);
            if (bestMove == null || bestMove.equals("(none)")) {
                throw new EngineException(HttpStatus.UNPROCESSABLE_ENTITY, "No legal engine move is available.");
            }
            return new BestMoveResponse(
                    bestMove,
                    "Stockfish",
                    request.level(),
                    targetElo,
                    moveTimeMs);
        } catch (TimeoutException exception) {
            throw new EngineException(HttpStatus.GATEWAY_TIMEOUT, "Stockfish took too long to respond.");
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new EngineException(HttpStatus.SERVICE_UNAVAILABLE, "Stockfish request was interrupted.");
        } catch (ExecutionException | IOException exception) {
            throw new EngineException(HttpStatus.SERVICE_UNAVAILABLE, "Stockfish could not calculate a move.");
        } finally {
            process.destroyForcibly();
        }
    }

    AnalyzeResponse analyze(AnalyzeRequest request) {
        String fen = request.fen().trim();
        if (!SAFE_FEN.matcher(fen).matches()) {
            throw new EngineException(HttpStatus.BAD_REQUEST, "The supplied chess position is invalid.");
        }
        int depth = ANALYSIS_DEPTHS.get(request.level() - 1);
        Process process = startEngine();
        try (BufferedWriter input = new BufferedWriter(new OutputStreamWriter(
                process.getOutputStream(), StandardCharsets.UTF_8));
                BufferedReader output = new BufferedReader(new InputStreamReader(
                        process.getInputStream(), StandardCharsets.UTF_8))) {
            send(input, "uci");
            send(input, "setoption name Threads value 1");
            send(input, "setoption name Hash value 32");
            send(input, "isready");
            send(input, "position fen " + fen);
            send(input, "go depth " + depth);
            AnalysisLine line = CompletableFuture.supplyAsync(() -> readAnalysis(output))
                    .get(responseTimeout.toMillis(), TimeUnit.MILLISECONDS);
            if (line.bestMove() == null || line.bestMove().equals("(none)")) {
                throw new EngineException(HttpStatus.UNPROCESSABLE_ENTITY, "No legal engine move is available.");
            }
            return new AnalyzeResponse(
                    line.bestMove(),
                    "Stockfish",
                    line.evaluationCp(),
                    line.mateIn(),
                    line.principalVariation(),
                    depth);
        } catch (TimeoutException exception) {
            throw new EngineException(HttpStatus.GATEWAY_TIMEOUT, "Stockfish analysis took too long.");
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new EngineException(HttpStatus.SERVICE_UNAVAILABLE, "Stockfish analysis was interrupted.");
        } catch (ExecutionException | IOException exception) {
            throw new EngineException(HttpStatus.SERVICE_UNAVAILABLE, "Stockfish could not analyze the position.");
        } finally {
            process.destroyForcibly();
        }
    }

    MoveReviewResponse reviewMove(MoveReviewRequest request) {
        String fen = request.fen().trim();
        String playedMove = request.playedMove().trim().toLowerCase();
        if (!SAFE_FEN.matcher(fen).matches()) {
            throw new EngineException(HttpStatus.BAD_REQUEST, "The supplied chess position is invalid.");
        }
        if (!SAFE_UCI_MOVE.matcher(playedMove).matches()) {
            throw new EngineException(HttpStatus.BAD_REQUEST, "The supplied chess move is invalid.");
        }
        if (!isLegalMove(fen, playedMove)) {
            throw new EngineException(HttpStatus.UNPROCESSABLE_ENTITY, "That move is not legal in this position.");
        }

        int depth = ANALYSIS_DEPTHS.get(request.level() - 1);
        AnalysisLine before = analyzeLine(fen, depth, List.of());
        AnalysisLine after = analyzeLine(fen, depth, List.of(playedMove));
        if (before.bestMove() == null || after.bestMove() == null) {
            throw new EngineException(HttpStatus.UNPROCESSABLE_ENTITY, "The move could not be reviewed.");
        }

        int moverEvaluationAfter = -after.evaluationCp();
        int centipawnLoss = Math.max(0, before.evaluationCp() - moverEvaluationAfter);
        boolean bestMove = before.bestMove().equalsIgnoreCase(playedMove);
        String classification = classifyMove(bestMove, centipawnLoss);
        String threat = after.principalVariation().isEmpty()
                ? after.bestMove()
                : after.principalVariation().getFirst();
        String explanation = explainMove(classification, before.bestMove(), threat, centipawnLoss);
        String coachingTheme = coachingTheme(fen, after, centipawnLoss);
        return new MoveReviewResponse(
                playedMove,
                before.bestMove(),
                classification,
                centipawnLoss,
                before.evaluationCp(),
                moverEvaluationAfter,
                coachingTheme,
                threat,
                explanation,
                before.principalVariation(),
                depth);
    }

    @Override
    public PositionAnalysis analyze(String fen, String playedMove, int requestedDepth) {
        String cleanFen = fen.trim();
        String cleanMove = playedMove.trim().toLowerCase();
        if (!SAFE_FEN.matcher(cleanFen).matches() || !SAFE_UCI_MOVE.matcher(cleanMove).matches()) {
            throw new EngineException(HttpStatus.BAD_REQUEST, "The supplied game evidence is invalid.");
        }
        if (!isLegalMove(cleanFen, cleanMove)) {
            throw new EngineException(HttpStatus.UNPROCESSABLE_ENTITY, "The recorded move is not legal in this position.");
        }
        int depth = Math.max(8, Math.min(22, requestedDepth));
        AnalysisLine before = analyzeLine(cleanFen, depth, List.of());
        AnalysisLine after = analyzeLine(cleanFen, depth, List.of(cleanMove));
        if (before.bestMove() == null || after.bestMove() == null) {
            throw new EngineException(HttpStatus.UNPROCESSABLE_ENTITY, "The recorded move could not be analyzed.");
        }
        int evaluationAfter = -after.evaluationCp();
        int loss = Math.max(0, before.evaluationCp() - evaluationAfter);
        boolean whiteMover = cleanFen.split("\\s+")[1].equals("w");
        int whiteEvaluationBefore = whiteMover ? before.evaluationCp() : -before.evaluationCp();
        int whiteEvaluationAfter = whiteMover ? evaluationAfter : -evaluationAfter;
        Integer moverMateBefore = before.mateIn();
        Integer moverMateAfter = after.mateIn() == null ? null : -after.mateIn();
        return new PositionAnalysis(
                before.bestMove(),
                classifyMove(before.bestMove().equalsIgnoreCase(cleanMove), loss),
                loss,
                whiteEvaluationBefore,
                whiteEvaluationAfter,
                moverMateBefore == null ? null : (whiteMover ? moverMateBefore : -moverMateBefore),
                moverMateAfter == null ? null : (whiteMover ? moverMateAfter : -moverMateAfter),
                before.principalVariation(),
                coachingTheme(cleanFen, after, loss),
                depth);
    }

    private AnalysisLine analyzeLine(String fen, int depth, List<String> moves) {
        Process process = startEngine();
        try (BufferedWriter input = new BufferedWriter(new OutputStreamWriter(
                process.getOutputStream(), StandardCharsets.UTF_8));
                BufferedReader output = new BufferedReader(new InputStreamReader(
                        process.getInputStream(), StandardCharsets.UTF_8))) {
            send(input, "uci");
            send(input, "setoption name Threads value 1");
            send(input, "setoption name Hash value 32");
            send(input, "isready");
            send(input, "position fen " + fen + (moves.isEmpty() ? "" : " moves " + String.join(" ", moves)));
            send(input, "go depth " + depth);
            return CompletableFuture.supplyAsync(() -> readAnalysis(output))
                    .get(responseTimeout.toMillis(), TimeUnit.MILLISECONDS);
        } catch (TimeoutException exception) {
            throw new EngineException(HttpStatus.GATEWAY_TIMEOUT, "Stockfish move review took too long.");
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new EngineException(HttpStatus.SERVICE_UNAVAILABLE, "Stockfish move review was interrupted.");
        } catch (ExecutionException | IOException exception) {
            throw new EngineException(HttpStatus.SERVICE_UNAVAILABLE, "Stockfish could not review the move.");
        } finally {
            process.destroyForcibly();
        }
    }

    static String classifyMove(boolean bestMove, int centipawnLoss) {
        if (bestMove || centipawnLoss <= 10) return "Best";
        if (centipawnLoss <= 30) return "Great";
        if (centipawnLoss <= 70) return "Inaccuracy";
        if (centipawnLoss <= 160) return "Mistake";
        return "Blunder";
    }

    static String explainMove(String classification, String bestMove, String threat, int centipawnLoss) {
        if (classification.equals("Best")) {
            return "You found the engine's strongest continuation and kept control of the position.";
        }
        String impact = centipawnLoss >= 160
                ? "This gives the opponent a major tactical opportunity."
                : centipawnLoss >= 70
                        ? "This concedes a clear advantage that can be avoided."
                        : "The move is playable, but it misses a more accurate continuation.";
        return impact + " " + bestMove + " was stronger; the immediate opponent threat is " + threat + ".";
    }

    static String coachingTheme(String fen, AnalysisLine after, int centipawnLoss) {
        String[] fields = fen.split("\\s+");
        int fullMove = fields.length > 5 ? Integer.parseInt(fields[5]) : 1;
        if (after.mateIn() != null || Math.abs(after.evaluationCp()) >= 800) return "kingSafety";
        if (fullMove <= 10) return "opening";
        if (fullMove >= 30) return "endgame";
        if (centipawnLoss >= 160) return "hangingPieces";
        if (centipawnLoss >= 70) return "tactics";
        return "calculation";
    }

    static boolean isLegalMove(String fen, String uci) {
        try {
            Board board = new Board();
            board.loadFromFen(fen);
            Square from = Square.valueOf(uci.substring(0, 2).toUpperCase(Locale.ROOT));
            Square to = Square.valueOf(uci.substring(2, 4).toUpperCase(Locale.ROOT));
            Move move = uci.length() == 5
                    ? new Move(from, to, promotion(uci.charAt(4), board.getSideToMove()))
                    : new Move(from, to);
            return board.legalMoves().contains(move);
        } catch (RuntimeException exception) {
            return false;
        }
    }

    private static Piece promotion(char code, Side side) {
        return switch (Character.toLowerCase(code)) {
            case 'q' -> side == Side.WHITE ? Piece.WHITE_QUEEN : Piece.BLACK_QUEEN;
            case 'r' -> side == Side.WHITE ? Piece.WHITE_ROOK : Piece.BLACK_ROOK;
            case 'b' -> side == Side.WHITE ? Piece.WHITE_BISHOP : Piece.BLACK_BISHOP;
            case 'n' -> side == Side.WHITE ? Piece.WHITE_KNIGHT : Piece.BLACK_KNIGHT;
            default -> throw new IllegalArgumentException("Invalid promotion piece");
        };
    }

    private Process startEngine() {
        try {
            return new ProcessBuilder(Path.of(stockfishPath).toString())
                    .redirectErrorStream(true)
                    .start();
        } catch (IOException exception) {
            throw new EngineException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Stockfish is not installed on this server.");
        }
    }

    private void send(BufferedWriter input, String command) throws IOException {
        input.write(command);
        input.newLine();
        input.flush();
    }

    private String readBestMove(BufferedReader output) {
        try {
            String line;
            while ((line = output.readLine()) != null) {
                if (line.startsWith("bestmove ")) {
                    return line.split("\\s+")[1];
                }
            }
        } catch (IOException ignored) {
            return null;
        }
        return null;
    }

    private AnalysisLine readAnalysis(BufferedReader output) {
        int evaluationCp = 0;
        Integer mateIn = null;
        List<String> pv = List.of();
        try {
            String line;
            while ((line = output.readLine()) != null) {
                if (line.startsWith("info ") && line.contains(" score ") && line.contains(" pv ")) {
                    String[] tokens = line.split("\\s+");
                    for (int index = 0; index < tokens.length - 2; index++) {
                        if (tokens[index].equals("score")) {
                            if (tokens[index + 1].equals("cp")) {
                                evaluationCp = Integer.parseInt(tokens[index + 2]);
                                mateIn = null;
                            } else if (tokens[index + 1].equals("mate")) {
                                mateIn = Integer.parseInt(tokens[index + 2]);
                                evaluationCp = mateIn > 0 ? 100000 : -100000;
                            }
                        }
                        if (tokens[index].equals("pv")) {
                            List<String> moves = new ArrayList<>();
                            for (int moveIndex = index + 1;
                                    moveIndex < tokens.length && moves.size() < 8;
                                    moveIndex++) {
                                moves.add(tokens[moveIndex]);
                            }
                            pv = List.copyOf(moves);
                            break;
                        }
                    }
                } else if (line.startsWith("bestmove ")) {
                    return new AnalysisLine(line.split("\\s+")[1], evaluationCp, mateIn, pv);
                }
            }
        } catch (IOException | NumberFormatException ignored) {
            // The caller converts an empty best move into a service error.
        }
        return new AnalysisLine(null, evaluationCp, mateIn, pv);
    }

    private record AnalysisLine(
            String bestMove,
            int evaluationCp,
            Integer mateIn,
            List<String> principalVariation) {
    }
}
