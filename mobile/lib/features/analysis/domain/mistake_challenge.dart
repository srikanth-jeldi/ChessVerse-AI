import '../../../core/local_game_archive.dart';
import 'pgn_position_reconstructor.dart';

/// Keep only a contiguous, replayable solution. Never skip a broken reply and
/// accidentally ask the learner to play the opponent's next move.
List<String> mistakeChallengeLine(SavedMoveReview review) {
  final best = review.bestMove.trim().toLowerCase();
  final pv = review.principalVariation
      .map((move) => move.trim().toLowerCase())
      .toList();
  if (pv.isEmpty || pv.first != best) pv.insert(0, best);
  final result = <String>[];
  var fen = review.fenBefore;
  for (final move in pv.take(5)) {
    if (!RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(move)) break;
    final positions = replayUciLine(fen, [move], requireLegalMoves: true);
    if (positions.length != 2) break;
    result.add(move);
    fen = positions.last;
  }
  return result;
}
