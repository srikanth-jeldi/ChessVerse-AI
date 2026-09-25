import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_bank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SavedGameRecord game(DateTime playedAt, List<SavedMoveReview> reviews) =>
      SavedGameRecord(
        mode: 'Computer',
        result: 'White wins',
        detail: 'Checkmate',
        moves: const <String>['e2e4'],
        playedAt: playedAt,
        whitePlayer: 'Player',
        blackPlayer: 'ChessVerseAI',
        moveReviews: reviews,
      );

  SavedMoveReview review({
    required int ply,
    required String classification,
    required int loss,
    String fen = '8/8/8/8/8/8/4K3/7k w - - 0 1',
  }) => SavedMoveReview(
    ply: ply,
    fenBefore: fen,
    playedMove: 'e2e3',
    bestMove: 'e2e4',
    classification: classification,
    centipawnLoss: loss,
    opponentThreat: '',
    explanation: 'Improve the move.',
    principalVariation: const <String>['e2e4', 'h1h2'],
  );

  test(
    'weekly bank keeps playable mistakes and ranks biggest losses first',
    () {
      final DateTime now = DateTime.utc(2026, 9, 10);
      final List<MistakeBankItem> items = MistakeBank.weekly(<SavedGameRecord>[
        game(now.subtract(const Duration(days: 1)), <SavedMoveReview>[
          review(ply: 4, classification: 'Mistake', loss: 90),
          review(ply: 8, classification: 'Best', loss: 0),
          review(ply: 10, classification: 'Blunder', loss: 220),
        ]),
      ], now: now);

      expect(items, hasLength(2));
      expect(items.first.review.centipawnLoss, 220);
      expect(items.first.choices, contains(items.first.review.bestMove));
    },
  );

  test('bank falls back to older reviewed games when this week is empty', () {
    final DateTime now = DateTime.utc(2026, 9, 10);
    final List<MistakeBankItem> items = MistakeBank.weekly(<SavedGameRecord>[
      game(now.subtract(const Duration(days: 20)), <SavedMoveReview>[
        review(ply: 2, classification: 'Inaccuracy', loss: 45),
      ]),
    ], now: now);

    expect(items.single.review.classification, 'Inaccuracy');
  });

  test(
    'bank returns every playable mistake unless a batch limit is requested',
    () {
      final DateTime now = DateTime.utc(2026, 9, 10);
      final List<SavedMoveReview> reviews = List<SavedMoveReview>.generate(
        8,
        (int index) =>
            review(ply: index + 1, classification: 'Mistake', loss: 50 + index),
      );
      final List<SavedGameRecord> games = <SavedGameRecord>[
        game(now.subtract(const Duration(days: 1)), reviews),
      ];

      expect(MistakeBank.weekly(games, now: now), hasLength(8));
      expect(MistakeBank.weekly(games, now: now, limit: 5), hasLength(5));
    },
  );

  test('bank keeps only the newest 100 trainable mistakes', () {
    final DateTime now = DateTime.utc(2026, 9, 10);
    final List<SavedGameRecord> games = List<SavedGameRecord>.generate(
      105,
      (int index) =>
          game(now.subtract(Duration(minutes: index)), <SavedMoveReview>[
            review(ply: index + 1, classification: 'Mistake', loss: index + 1),
          ]),
    );

    final List<MistakeBankItem> items = MistakeBank.weekly(games, now: now);

    expect(items, hasLength(MistakeBank.maxItems));
    expect(
      items.any((MistakeBankItem item) => item.review.centipawnLoss == 105),
      isFalse,
    );
    expect(
      items.any((MistakeBankItem item) => item.review.centipawnLoss == 100),
      isTrue,
    );
  });
}
