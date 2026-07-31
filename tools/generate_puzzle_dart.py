"""Generate the checked-in Dart puzzle manifest from validated JSON."""

import argparse
import json
from pathlib import Path


def quote(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("output")
    args = parser.parse_args()
    puzzles = json.loads(Path(args.input).read_text(encoding="utf-8"))
    lines = [
        "// GENERATED FILE. Source: official Lichess CC0 puzzle database.",
        "// Regenerate with tools/curate_lichess_puzzles.py and this script.",
        "part of 'puzzle_catalog.dart';",
        "",
        "const List<ChessPuzzle> _curatedPuzzles = <ChessPuzzle>[",
    ]
    for item in puzzles:
        themes = ", ".join(quote(theme) for theme in item["themes"])
        solution = ", ".join(quote(move) for move in item["solution"])
        lines.extend([
            "  ChessPuzzle(",
            f"    id: {quote(item['id'])},",
            f"    sourceId: {quote(item['sourceId'])},",
            f"    number: {item['number']},",
            f"    difficulty: PuzzleDifficulty.{item['difficulty']},",
            f"    rating: {item['rating']},",
            f"    fen: {quote(item['fen'])},",
            f"    solution: <String>[{solution}],",
            f"    themes: <String>[{themes}],",
            "  ),",
        ])
    lines.extend(["];", ""])
    Path(args.output).write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    main()
