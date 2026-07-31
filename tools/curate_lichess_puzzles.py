"""Build ChessVerseAI's pinned CC0 puzzle set from the official Lichess API.

The output is deterministic after collection: candidates are sorted by rating,
solution length, and source id before the first 50 in each tier are selected.
Every accepted puzzle is reconstructed from its game PGN and validated with
python-chess. Only legal, white-to-move, forced mate lines with no castling or
en-passant dependency are admitted, matching the app's local rules engine.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import time
import urllib.request
from pathlib import Path

import chess
import chess.pgn

ENDPOINT = "https://lichess.org/api/puzzle/next"


def tier_for(rating: int) -> str | None:
    if 800 <= rating <= 1300:
        return "easy"
    if 1301 <= rating <= 1800:
        return "medium"
    if 1801 <= rating <= 2400:
        return "hard"
    return None


def candidate(payload: dict) -> dict | None:
    puzzle = payload["puzzle"]
    tier = tier_for(int(puzzle["rating"]))
    if tier is None or "mate" not in puzzle["themes"]:
        return None
    if int(puzzle.get("plays", 0)) < 100:
        return None

    game = chess.pgn.read_game(io.StringIO(payload["game"]["pgn"]))
    if game is None:
        return None
    moves = list(game.mainline_moves())
    initial_count = int(puzzle["initialPly"]) + 1
    if initial_count > len(moves):
        return None
    board = game.board()
    for move in moves[:initial_count]:
        board.push(move)
    if board.turn != chess.WHITE or board.castling_rights or board.ep_square:
        return None
    if board.is_checkmate() or board.is_stalemate():
        return None

    start_fen = board.fen()
    solution = [str(move).lower() for move in puzzle["solution"]]
    if not solution or len(solution) % 2 == 0:
        return None
    for uci in solution:
        try:
            move = chess.Move.from_uci(uci)
        except ValueError:
            return None
        if move not in board.legal_moves:
            return None
        board.push(move)
    if not board.is_checkmate():
        return None

    return {
        "sourceId": puzzle["id"],
        "difficulty": tier,
        "rating": int(puzzle["rating"]),
        "themes": sorted(puzzle["themes"]),
        "fen": start_fen,
        "solution": solution,
        "playerMoveGoal": (len(solution) + 1) // 2,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--target", type=int, default=50)
    parser.add_argument("--max-requests", type=int, default=5000)
    parser.add_argument("--delay", type=float, default=0.12)
    parser.add_argument("--csv")
    args = parser.parse_args()

    output = Path(args.output)
    buckets: dict[str, dict[str, dict]] = {
        "easy": {}, "medium": {}, "hard": {}
    }
    if output.exists():
        for item in json.loads(output.read_text(encoding="utf-8")):
            buckets[item["difficulty"]][item["sourceId"]] = item

    if args.csv:
        with Path(args.csv).open(newline="", encoding="utf-8") as source:
            for row in csv.reader(source):
                source_id, fen, moves_text, rating, _, popularity, plays, themes, *_ = row
                tier = tier_for(int(rating))
                if tier is None:
                    continue
                moves = moves_text.lower().split()
                if len(moves) < 2:
                    continue
                if any(len(move) != 4 for move in moves):
                    continue
                board = chess.Board(fen)
                try:
                    blunder = chess.Move.from_uci(moves[0])
                    if blunder not in board.legal_moves:
                        continue
                    board.push(blunder)
                    start_fen = board.fen()
                    solution = moves[1:]
                    if board.turn != chess.WHITE or board.castling_rights or board.ep_square:
                        continue
                    for uci in solution:
                        move = chess.Move.from_uci(uci)
                        if move not in board.legal_moves:
                            raise ValueError("illegal solution")
                        board.push(move)
                    if not board.is_checkmate():
                        continue
                except ValueError:
                    continue
                signature = " ".join(start_fen.split()[:4])
                if any(signature == " ".join(x["fen"].split()[:4])
                       for group in buckets.values() for x in group.values()):
                    continue
                buckets[tier][source_id] = {
                    "sourceId": source_id,
                    "difficulty": tier,
                    "rating": int(rating),
                    "popularity": int(popularity),
                    "plays": int(plays),
                    "themes": sorted(themes.split()),
                    "fen": start_fen,
                    "solution": solution,
                    "playerMoveGoal": (len(solution) + 1) // 2,
                }
        counts = {key: len(value) for key, value in buckets.items()}
        if not all(count >= args.target for count in counts.values()):
            raise SystemExit(f"not enough valid CSV candidates: {counts}")
    for request_number in range(1, 1 if args.csv else args.max_requests + 1):
        if all(len(items) >= args.target for items in buckets.values()):
            break
        request = urllib.request.Request(
            ENDPOINT,
            headers={"Accept": "application/json", "User-Agent": "ChessVerseAI/0.1"},
        )
        try:
            with urllib.request.urlopen(request, timeout=20) as response:
                item = candidate(json.load(response))
        except Exception as error:
            print(f"request {request_number}: {error}", flush=True)
            time.sleep(1.0)
            continue
        if item is not None:
            signature = " ".join(item["fen"].split()[:4])
            if not any(signature == " ".join(x["fen"].split()[:4])
                       for group in buckets.values() for x in group.values()):
                buckets[item["difficulty"]][item["sourceId"]] = item
                counts = {key: len(value) for key, value in buckets.items()}
                print(f"accepted {item['sourceId']} {item['difficulty']} {counts}", flush=True)
                current = [x for group in buckets.values() for x in group.values()]
                output.write_text(json.dumps(current, indent=2) + "\n", encoding="utf-8")
        time.sleep(args.delay)
    else:
        if args.csv:
            pass
        elif not all(len(items) >= args.target for items in buckets.values()):
            raise SystemExit("request limit reached before all tiers were filled")

    selected = []
    for tier in ("easy", "medium", "hard"):
        ordered = sorted(
            buckets[tier].values(),
            key=lambda item: (item["rating"], item["playerMoveGoal"], item["sourceId"]),
        )[:args.target]
        for number, item in enumerate(ordered, 1):
            item["id"] = f"{tier}-{number:03d}"
            item["number"] = number
            selected.append(item)
    output.write_text(json.dumps(selected, indent=2) + "\n", encoding="utf-8")
    print({tier: sum(x["difficulty"] == tier for x in selected)
           for tier in ("easy", "medium", "hard")})


if __name__ == "__main__":
    main()
