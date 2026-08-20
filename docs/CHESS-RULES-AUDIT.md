# ChessVerseAI Gameplay Rules Audit

Date: 2026-08-15

## Reported video finding

The move shown in `131146-720x1560.mp4` is `d5-d6`. The pawn on d5 was
blocking the diagonal `b3-c4-d5-e6-f7`. Moving it to d6 opens the white
queen's line from b3 to the black king on f7. This is a legal **discovered
check by the queen**, not a direct pawn check.

The position is now covered by an automated regression test. The AI Coach
also identifies the revealing piece, attacker, source square, and king square
instead of describing the move as an unexplained pawn check.

## Confirmed defects fixed

1. Attack-map semantics did not count a square occupied by an attacker's own
   piece as defended. Piece-specific attack geometry now handles pawns,
   knights, kings, bishops, rooks, and queens independently from move targets.
2. Puzzle/daily-defense replies generated castling and en-passant moves but
   did not apply the rook move or remove the en-passant pawn. Both are now
   applied to the board state.
3. Puzzle/daily-defense promotion and remote-engine underpromotion were not
   preserved. Promotion to queen, rook, bishop, or knight is now applied and
   recorded.
4. Castling rights could be regained after a king returned to its home square,
   because castling notation was not treated as king/rook movement. Historical
   castling and home-rook captures now permanently invalidate the relevant
   right.

## Verified rule areas

- White and black pawn movement and diagonal attack direction
- Knight, bishop, rook, queen, and king attack geometry
- Sliding-piece blockers and defended occupied squares
- Self-check rejection and pinned-piece movement
- Adjacent-king exclusion
- Check, checkmate, stalemate, blocking, capturing, and king escapes
- Castling path safety and persistent castling rights
- En passant board application and king-safety validation
- Promotion and engine underpromotion
- All curated puzzle solutions and final checkmates
- Standard initial-position perft counts: depth 1 = 20, depth 2 = 400,
  depth 3 = 8902

## Verification results

- Flutter static analysis: no issues
- Full Flutter test suite: 116 passed
- Dedicated new chess-rules audit tests: 9 passed
- Curated puzzle legality test: passed
- Portrait, landscape, game-state, online-replay, and UI regression tests:
  passed as part of the full suite

## Remaining status

No reproducible unresolved chess-rule defect remains in the audited local game,
computer game, puzzle-defense, or replay paths. This is not a claim that future
or server-side defects are impossible; any new position should be captured as
FEN/move history and added as another permanent regression test.
