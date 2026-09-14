import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/online/data/fen_archive_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = FenArchiveService();
  const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  test('imports and normalizes valid FEN positions', () {
    final positions = service.importPositions('# saved positions\n$start\n');
    expect(positions, <String>[start]);
  });

  test('rejects malformed and kingless positions', () {
    expect(
      () => service.importPositions('8/8/8/8/8/8/8/8 w - - 0 1'),
      throwsFormatException,
    );
    expect(() => service.importPositions('not a fen'), throwsFormatException);
  });

  test('exports imported and reviewed positions without duplicates', () {
    final output = service.exportPositions(<SavedGameRecord>[
      SavedGameRecord(
        mode: 'Imported FEN',
        result: '*',
        detail: 'Position',
        moves: const <String>[],
        playedAt: DateTime.utc(2026, 9, 14),
        whitePlayer: 'FEN position',
        blackPlayer: 'Analysis board',
        initialFen: start,
        moveReviews: const <SavedMoveReview>[
          SavedMoveReview(
            ply: 1,
            fenBefore: start,
            playedMove: 'e2e4',
            bestMove: 'e2e4',
            classification: 'Best',
            centipawnLoss: 0,
            opponentThreat: 'e7e5',
            explanation: 'Good move',
            principalVariation: <String>['e2e4', 'e7e5'],
          ),
        ],
      ),
    ]);
    expect(output, start);
  });
}
