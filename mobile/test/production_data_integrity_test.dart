import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('career outcome integrity', () {
    test('white and black results respect the human side', () {
      expect(
        playerOutcomeForResult(
          'White wins',
          humanPlaysWhite: true,
          tracksPlayer: true,
        ),
        'win',
      );
      expect(
        playerOutcomeForResult(
          'White wins',
          humanPlaysWhite: false,
          tracksPlayer: true,
        ),
        'loss',
      );
      expect(
        playerOutcomeForResult(
          'Black wins',
          humanPlaysWhite: false,
          tracksPlayer: true,
        ),
        'win',
      );
      expect(
        playerOutcomeForResult(
          'Black wins',
          humanPlaysWhite: true,
          tracksPlayer: true,
        ),
        'loss',
      );
    });

    test('pass-and-play games do not become personal wins or losses', () {
      expect(
        playerOutcomeForResult(
          'White wins',
          humanPlaysWhite: true,
          tracksPlayer: false,
        ),
        'untracked',
      );
    });
  });

  group('daily streak integrity', () {
    test('starts at one and increments on the next UTC calendar day', () {
      expect(
        dailyStreakAfterCompletion(
          currentStreak: 0,
          previousCompletion: null,
          completion: DateTime.utc(2026, 8, 15, 8),
        ),
        1,
      );
      expect(
        dailyStreakAfterCompletion(
          currentStreak: 4,
          previousCompletion: DateTime.utc(2026, 8, 14, 23),
          completion: DateTime.utc(2026, 8, 15, 1),
        ),
        5,
      );
    });

    test('same-day completion is idempotent and missed days reset', () {
      expect(
        dailyStreakAfterCompletion(
          currentStreak: 4,
          previousCompletion: DateTime.utc(2026, 8, 15, 1),
          completion: DateTime.utc(2026, 8, 15, 20),
        ),
        4,
      );
      expect(
        dailyStreakAfterCompletion(
          currentStreak: 4,
          previousCompletion: DateTime.utc(2026, 8, 12),
          completion: DateTime.utc(2026, 8, 15),
        ),
        1,
      );
    });
  });
}
