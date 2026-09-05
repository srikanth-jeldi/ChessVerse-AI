import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/social/domain/tournament_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

SavedGameRecord game(String outcome, {String detail = 'Checkmate'}) =>
    SavedGameRecord(
      mode: 'Online',
      result: outcome == 'win' ? 'You win' : 'Opponent wins',
      detail: detail,
      moves: const <String>['e4', 'e5'],
      playedAt: DateTime(2026),
      whitePlayer: 'You',
      blackPlayer: 'Rival',
      playerOutcome: outcome,
      openingName: 'Italian Game',
    );

void main() {
  test('does not fabricate a readiness percentage with too little evidence',
      () {
    final readiness = TournamentReadiness.fromGames(<SavedGameRecord>[
      game('win'),
      game('loss'),
    ]);
    expect(readiness.score, isNull);
    expect(readiness.confidence, 'BUILDING PROFILE');
  });

  test('uses results and clock evidence for tournament guidance', () {
    final readiness = TournamentReadiness.fromGames(<SavedGameRecord>[
      game('win'),
      game('win'),
      game('draw'),
      game('loss', detail: 'Match ended on time'),
    ]);
    expect(readiness.score, inInclusiveRange(0, 100));
    expect(readiness.openingInsight, contains('Opening'));
    expect(readiness.timeAdvice, contains('ended on time'));
    expect(readiness.timeControlAdvice, contains('practice games'));
  });
}
