# AI game-analysis corpus validation — 2026-08-27

Source: Lichess broadcast database, July 2020 (`lichess_db_broadcast_2020-07.pgn.zst`).
The source is published by Lichess under CC BY-SA 4.0.

Validation configuration:

- 100 clean completed games selected from 106 source records
- 6 malformed PGN records excluded before counting
- 1 middlegame/endgame position sampled from every accepted game
- ChessVerseAI production analysis depth: Stockfish 16
- Independent reference depth: Stockfish 20
- Mate scores normalized to 100,000 centipawns

Results:

- Engine failures: 0
- Best-move agreement: 82%
- Exact five-class agreement: 79%
- Severity agreement (exact or adjacent class): 94%
- Mean absolute centipawn-loss difference: 10.3 cp
- Severe classification disagreement: 6%

The initial depth-12 versus depth-16 experiment did not pass: exact class agreement
was 80.5% against an 85% threshold. It was retained as diagnostic evidence and was
not used to represent production, because completed-game analysis runs at depth 16.

The production-depth gate passes when requiring at least 75% exact-class agreement,
90% severity agreement, 55% best-move agreement, and zero engine failures. Exact
class agreement is reported separately because small evaluation changes near the
10/30/70/160 cp label boundaries can legitimately move a result by one adjacent class.
