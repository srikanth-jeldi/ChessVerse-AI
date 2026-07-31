"""Independent Stockfish gate for the pinned ChessVerseAI puzzle manifest."""

import argparse
import json
from pathlib import Path

import chess
import chess.engine


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest")
    parser.add_argument("--stockfish", default="/usr/games/stockfish")
    parser.add_argument("--depth", type=int, default=16)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    puzzles = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    failures = []
    tier_counts = {"easy": 0, "medium": 0, "hard": 0}
    engine = chess.engine.SimpleEngine.popen_uci(args.stockfish)
    try:
        for index, puzzle in enumerate(puzzles, 1):
            board = chess.Board(puzzle["fen"])
            first = chess.Move.from_uci(puzzle["solution"][0])
            if first not in board.legal_moves:
                failures.append({"id": puzzle["id"], "reason": "illegal first move"})
                continue
            analysis = engine.analyse(
                board,
                chess.engine.Limit(depth=args.depth),
                root_moves=[first],
            )
            mate = analysis["score"].pov(board.turn).mate()
            if mate is None or mate <= 0:
                failures.append({
                    "id": puzzle["id"],
                    "reason": "stored first move does not preserve forced mate",
                    "score": str(analysis["score"]),
                })
                continue
            replay = board.copy()
            valid = True
            for uci in puzzle["solution"]:
                move = chess.Move.from_uci(uci)
                if move not in replay.legal_moves:
                    failures.append({"id": puzzle["id"], "reason": f"illegal line move {uci}"})
                    valid = False
                    break
                replay.push(move)
            if valid and not replay.is_checkmate():
                failures.append({"id": puzzle["id"], "reason": "line does not end in checkmate"})
                valid = False
            if valid:
                tier_counts[puzzle["difficulty"]] += 1
            if index % 10 == 0:
                print(f"validated {index}/{len(puzzles)}", flush=True)
    finally:
        engine.quit()

    report = {
        "engine": "Stockfish",
        "depth": args.depth,
        "total": len(puzzles),
        "passed": len(puzzles) - len(failures),
        "tierCounts": tier_counts,
        "failures": failures,
    }
    Path(args.report).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
