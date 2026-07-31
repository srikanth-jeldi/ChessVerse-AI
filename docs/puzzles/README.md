# ChessVerseAI curated puzzle dataset

The application ships a pinned set of 150 independent checkmate puzzles:

- 50 Easy: source rating 800–1300
- 50 Medium: source rating 1301–1800
- 50 Hard: source rating 1801–2400

## Source and license

Positions come from the official Lichess open puzzle database, published under
CC0. The source puzzle id, rating, themes, reconstructed FEN, and complete UCI
solution are retained in the generated Dart manifest.

## Admission rules

A candidate is admitted only when all of these checks pass:

1. The source blunder is legal from the source FEN.
2. The reconstructed training position is legal and White is to move.
3. It has no castling or en-passant dependency unsupported by the local puzzle
   state model.
4. Every stored UCI move is legal in sequence.
5. The solution has alternating player/defender moves and ends in checkmate.
6. The position signature and source id are unique across all 150 entries.
7. The puzzle has at least 100 source plays and at least 80 popularity.
8. Stockfish depth 16 confirms that the stored first move preserves a forced
   mate.

The machine-readable result is in
`stockfish_validation_report.json` (150 passed, zero failures).

## Reproduction

1. `tools/curate_lichess_puzzles.py` validates and selects the pinned JSON.
2. `tools/generate_puzzle_dart.py` produces `puzzle_data.g.dart`.
3. `tools/validate_puzzles_stockfish.py` runs the independent engine gate.

Generated layouts must never be substituted for validated chess positions.
