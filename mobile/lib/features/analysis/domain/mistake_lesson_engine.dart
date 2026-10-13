import '../data/engine_candidates_api.dart';
import 'pgn_position_reconstructor.dart';

/// Scores from this endpoint are from the side-to-move perspective for both
/// colours. Only compare candidates returned for the very same position.
bool isComparableLessonMove(
  List<EngineCandidateLine> candidates,
  EngineCandidateLine candidate,
) {
  if (candidates.isEmpty) return false;
  final best = candidates.reduce(
    (a, b) => a.evaluationCp >= b.evaluationCp ? a : b,
  );
  if (best.mateIn != null || candidate.mateIn != null) {
    return best.mateIn != null && candidate.mateIn == best.mateIn;
  }
  return best.evaluationCp - candidate.evaluationCp <= 20;
}

List<String> validCandidateContinuation(
  String fen,
  EngineCandidateLine candidate,
) {
  final move = candidate.move.trim().toLowerCase();
  final moves = candidate.principalVariation
      .map((m) => m.trim().toLowerCase())
      .toList();
  if (moves.isEmpty || moves.first != move) moves.insert(0, move);
  final result = <String>[];
  var current = fen;
  for (final step in moves.take(5)) {
    final positions = replayUciLine(current, [step], requireLegalMoves: true);
    if (positions.length != 2) break;
    result.add(step);
    current = positions.last;
  }
  return result;
}
