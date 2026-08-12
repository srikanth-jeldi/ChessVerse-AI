import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/domain/player_learning_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recommends king safety after repeated games without castling', () {
    final SavedGameRecord game = SavedGameRecord(
      mode: 'Play vs AI',
      result: 'Opponent wins',
      detail: 'Checkmate',
      moves: List<String>.generate(
          28, (int index) => 'a${index % 8 + 1}a${(index + 1) % 8 + 1}'),
      playedAt: DateTime(2026),
      whitePlayer: 'Player',
      blackPlayer: 'AI',
    );
    final PlayerLearningProfile profile =
        PlayerLearningProfile.fromGames(<SavedGameRecord>[game, game]);
    expect(profile.primaryWeakness, ChessWeakness.kingSafety);
    expect(profile.recommendedLesson, 'Castling safely');
  });
}
