"""Compare ChessVerseAI-depth analysis with a deeper Stockfish reference on real PGNs."""

import argparse
import json
from pathlib import Path

import chess.engine
import chess.pgn

CLASSIFICATION_RANK = {"Best": 0, "Great": 1, "Inaccuracy": 2, "Mistake": 3, "Blunder": 4}


def classification(best_move: bool, loss: int) -> str:
    if best_move or loss <= 10:
        return "Best"
    if loss <= 30:
        return "Great"
    if loss <= 70:
        return "Inaccuracy"
    if loss <= 160:
        return "Mistake"
    return "Blunder"


def score_cp(info: dict, turn: chess.Color) -> int:
    value = info["score"].pov(turn).score(mate_score=100_000)
    return 0 if value is None else value


def review(engine: chess.engine.SimpleEngine, board: chess.Board, move: chess.Move, depth: int) -> dict:
    best = engine.analyse(board, chess.engine.Limit(depth=depth))
    played = engine.analyse(board, chess.engine.Limit(depth=depth), root_moves=[move])
    best_move = best["pv"][0] if best.get("pv") else None
    loss = max(0, score_cp(best, board.turn) - score_cp(played, board.turn))
    return {
        "bestMove": None if best_move is None else best_move.uci(),
        "loss": loss,
        "classification": classification(best_move == move, loss),
        "mate": best["score"].pov(board.turn).is_mate() or played["score"].pov(board.turn).is_mate(),
    }


def sample_indices(total: int, count: int) -> set[int]:
    start = min(8, max(0, total - 1))
    usable = max(1, total - start)
    return {start + min(usable - 1, round((slot + 1) * usable / (count + 1))) for slot in range(count)}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pgn")
    parser.add_argument("--stockfish", default="/usr/games/stockfish")
    parser.add_argument("--games", type=int, default=100)
    parser.add_argument("--positions-per-game", type=int, default=2)
    parser.add_argument("--app-depth", type=int, default=12)
    parser.add_argument("--reference-depth", type=int, default=16)
    parser.add_argument("--min-classification-agreement", type=float, default=0.75)
    parser.add_argument("--min-severity-agreement", type=float, default=0.90)
    parser.add_argument("--min-best-move-agreement", type=float, default=0.55)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    totals = {"sourceRecords": 0, "sourceRecordsSkipped": 0,
              "games": 0, "plies": 0, "positionsCompared": 0,
              "classificationMatches": 0, "severityMatches": 0, "bestMoveMatches": 0,
              "matePositions": 0, "engineFailures": 0, "absoluteLossDeltaCp": 0}
    disagreements = []
    engine = chess.engine.SimpleEngine.popen_uci(args.stockfish)
    engine.configure({"Threads": 1, "Hash": 64})
    try:
        with Path(args.pgn).open(encoding="utf-8", errors="replace") as source:
            while totals["games"] < args.games:
                game = chess.pgn.read_game(source)
                if game is None:
                    break
                totals["sourceRecords"] += 1
                if game.errors:
                    totals["sourceRecordsSkipped"] += 1
                    continue
                moves = list(game.mainline_moves())
                if not moves:
                    totals["sourceRecordsSkipped"] += 1
                    continue
                totals["games"] += 1
                selected = sample_indices(len(moves), args.positions_per_game)
                board = game.board()
                for index, move in enumerate(moves):
                    totals["plies"] += 1
                    if move not in board.legal_moves:
                        disagreements.append({"game": totals["games"], "ply": index + 1,
                                              "reason": "illegal PGN move"})
                        break
                    if index in selected:
                        try:
                            app = review(engine, board, move, args.app_depth)
                            reference = review(engine, board, move, args.reference_depth)
                            totals["positionsCompared"] += 1
                            totals["classificationMatches"] += app["classification"] == reference["classification"]
                            totals["severityMatches"] += abs(
                                CLASSIFICATION_RANK[app["classification"]]
                                - CLASSIFICATION_RANK[reference["classification"]]) <= 1
                            totals["bestMoveMatches"] += app["bestMove"] == reference["bestMove"]
                            totals["matePositions"] += app["mate"] or reference["mate"]
                            totals["absoluteLossDeltaCp"] += abs(app["loss"] - reference["loss"])
                            if app["classification"] != reference["classification"]:
                                disagreements.append({"game": totals["games"], "ply": index + 1,
                                    "fen": board.fen(), "played": move.uci(),
                                    "app": app, "reference": reference})
                        except (chess.engine.EngineError, chess.engine.EngineTerminatedError) as error:
                            totals["engineFailures"] += 1
                            disagreements.append({"game": totals["games"], "ply": index + 1,
                                                  "reason": str(error)})
                    board.push(move)
                print(f"validated {totals['games']}/{args.games} games", flush=True)
    finally:
        engine.quit()
    compared = max(1, totals["positionsCompared"])
    class_agreement = totals["classificationMatches"] / compared
    severity_agreement = totals["severityMatches"] / compared
    best_agreement = totals["bestMoveMatches"] / compared
    report = {"source": Path(args.pgn).name, "engine": "Stockfish",
              "appDepth": args.app_depth, "referenceDepth": args.reference_depth,
              **totals,
              "classificationAgreementPercent": round(class_agreement * 100, 2),
              "severityAgreementPercent": round(severity_agreement * 100, 2),
              "bestMoveAgreementPercent": round(best_agreement * 100, 2),
              "meanAbsoluteLossDeltaCp": round(totals["absoluteLossDeltaCp"] / compared, 2),
              "sampleDisagreements": disagreements[:100]}
    Path(args.report).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    if (totals["games"] < args.games or totals["engineFailures"]
            or class_agreement < args.min_classification_agreement
            or severity_agreement < args.min_severity_agreement
            or best_agreement < args.min_best_move_agreement):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
