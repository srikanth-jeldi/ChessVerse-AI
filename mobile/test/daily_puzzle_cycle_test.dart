import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/domain/pgn_position_reconstructor.dart';
import 'package:chessverse_ai/main.dart' show ChessRules, ChessPiece;
import 'package:chessverse_ai/features/puzzles/domain/puzzle_catalog.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all rotating daily solutions are legal and finish in checkmate', () {
    final checked = <String>{};
    for (final hard in [false, true]) {
      for (var day = 0; day < 200; day++) {
        final puzzle = dailyPuzzleForDate(DateTime.utc(2026,1,1).add(Duration(days:day)),hard:hard);
        if (!checked.add(puzzle.id)) continue;
        final positions = replayUciLine(puzzle.fen,puzzle.solution,requireLegalMoves:true);
        expect(positions.length,puzzle.solution.length+1,reason:puzzle.id);
        final pieces = <String,ChessPiece>{};
        final ranks = positions.last.split(' ').first.split('/');
        for (var row=0;row<8;row++) {
          var file=0;
          for (final token in ranks[row].split('')) {
            final empty=int.tryParse(token);
            if(empty!=null) {file+=empty;} else {
              pieces['${String.fromCharCode(97+file)}${8-row}']=ChessPiece(token.toUpperCase(),token==token.toUpperCase());
              file++;
            }
          }
        }
        expect(ChessRules.isCheckmate(false,pieces),true,reason:puzzle.id);
      }
    }
    expect(checked.length,118);
  });
  test('local reward estimate follows cycle without duplicate day credit', () {
    final day=DateTime.utc(2026,10,29);
    final ids=List.generate(8,(i)=>'${day.subtract(Duration(days:7-i)).toIso8601String().substring(0,10)}-v8-medium-001');
    expect(dailyPuzzleActivityCoins([...ids,ids.last.replaceFirst('medium','hard')],day),185);
    expect(dailyPuzzleActivityCoins([ids.first,ids.last],day),20);
  });
  test('seven day reward cycle and missed day', () {
    expect(List.generate(9, (i) => dailyPuzzleRewardCoins(i + 1)), [
      10,
      15,
      20,
      25,
      30,
      35,
      40,
      10,
      15,
    ]);
    final day = DateTime.utc(2026, 10, 29);
    final ids = [
      '2026-10-27-v8-medium-001',
      '2026-10-29-v8-medium-002',
      '2026-10-29-v8-hard-001',
    ];
    expect(dailyPuzzleStreakFromIds(ids, day), 1);
    expect(dailyPuzzleStreakFromIds(ids, day.add(const Duration(days: 1))), 1);
    expect(dailyPuzzleStreakFromIds(ids, day.add(const Duration(days: 2))), 0);
  });
  test('daily resets at midnight instead of waiting 24 hours', () async {
    FlutterSecureStorage.setMockInitialValues({
      'chessverse_last_daily_completion_utc': '2026-10-28T23:59:00Z',
    });
    await LocalGameArchive.init();
    expect(
      LocalGameArchive.isDailyChallengeLockedAt(
        DateTime.utc(2026, 10, 28, 23, 59, 30),
      ),
      true,
    );
    expect(
      LocalGameArchive.isDailyChallengeLockedAt(DateTime.utc(2026, 10, 29)),
      false,
    );
  });
  test('daily selection is stable, moderate or hard, and rotates', () {
    final day = DateTime.utc(2026, 10, 29);
    final puzzle = dailyPuzzleForDate(day);
    expect(puzzle.difficulty, PuzzleDifficulty.medium);
    expect(puzzle.playerMoveGoal, greaterThanOrEqualTo(3));
    expect(
      dailyPuzzleForDate(day.add(const Duration(hours: 12))).id,
      puzzle.id,
    );
    expect(
      dailyPuzzleForDate(day.add(const Duration(days: 1))).id,
      isNot(puzzle.id),
    );
    expect(
      dailyPuzzleForDate(day, hard: true).difficulty,
      PuzzleDifficulty.hard,
    );
  });
}
