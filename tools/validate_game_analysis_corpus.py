"""Validate genuine PGN games and export a reproducible Stockfish evidence report."""

import argparse
import json
from pathlib import Path

import chess.engine
import chess.pgn


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pgn")
    parser.add_argument("--stockfish", default="/usr/games/stockfish")
    parser.add_argument("--games", type=int, default=100)
    parser.add_argument("--depth", type=int, default=18)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    totals = {"games": 0, "plies": 0, "legalPlies": 0, "engineFailures": 0, "mateScores": 0}
    failures = []
    engine = chess.engine.SimpleEngine.popen_uci(args.stockfish)
    try:
        with Path(args.pgn).open(encoding="utf-8", errors="replace") as source:
            while totals["games"] < args.games:
                game = chess.pgn.read_game(source)
                if game is None:
                    break
                totals["games"] += 1
                board = game.board()
                for ply, move in enumerate(game.mainline_moves(), 1):
                    totals["plies"] += 1
                    if move not in board.legal_moves:
                        failures.append({"game": totals["games"], "ply": ply, "reason": "illegal PGN move"})
                        break
                    try:
                        info = engine.analyse(board, chess.engine.Limit(depth=args.depth), multipv=3)
                        lines = info if isinstance(info, list) else [info]
                        if any(line["score"].pov(board.turn).is_mate() for line in lines):
                            totals["mateScores"] += 1
                        totals["legalPlies"] += 1
                    except (chess.engine.EngineError, chess.engine.EngineTerminatedError) as error:
                        totals["engineFailures"] += 1
                        failures.append({"game": totals["games"], "ply": ply, "reason": str(error)})
                    board.push(move)
                print(f"validated {totals['games']}/{args.games} games", flush=True)
    finally:
        engine.quit()
    report = {"engine": "Stockfish", "depth": args.depth, **totals, "failures": failures[:100]}
    Path(args.report).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    if totals["games"] < args.games or totals["engineFailures"] or failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
