import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh guest cannot inherit another identity progress', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    await LocalGameArchive.activateIdentity('account:player@example.com');
    LocalGameArchive.markPuzzleSolved('easy-001');
    LocalGameArchive.markDailyChallengeComplete('daily-001');
    LocalGameArchive.addGame(
      SavedGameRecord(
        mode: 'Computer',
        result: 'You win',
        detail: 'Checkmate',
        moves: const <String>[],
        playedAt: DateTime.utc(2026, 8, 21),
        whitePlayer: 'Player',
        blackPlayer: 'Computer',
      ),
    );
    expect(LocalGameArchive.rewards().xp, greaterThan(0));

    await LocalGameArchive.activateIdentity('guest:fresh-installation');

    expect(LocalGameArchive.stats().gamesPlayed, 0);
    expect(LocalGameArchive.stats().puzzlesSolved, 0);
    expect(LocalGameArchive.stats().dailySolved, 0);
    expect(LocalGameArchive.rewards().xp, 0);
    expect(LocalGameArchive.rewards().level, 1);
    expect(LocalGameArchive.rewards().unlockedBadges, 0);
    expect(LocalGameArchive.completedAcademyLessonIds, isEmpty);
  });

  test('logout wipe removes cached player progress immediately', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    await LocalGameArchive.activateIdentity('account:logout@example.com');
    LocalGameArchive.markPuzzleSolved('medium-001');
    LocalGameArchive.addGame(
      SavedGameRecord(
        mode: 'Online',
        result: 'You win',
        detail: 'Checkmate',
        moves: const <String>['e4'],
        playedAt: DateTime.utc(2026, 8, 21),
        whitePlayer: 'Player',
        blackPlayer: 'Opponent',
      ),
    );

    await LocalGameArchive.clearDeviceUserData();
    await LocalGameArchive.init();

    expect(LocalGameArchive.stats().gamesPlayed, 0);
    expect(LocalGameArchive.stats().puzzlesSolved, 0);
    expect(LocalGameArchive.rewards().xp, 0);
    expect(LocalGameArchive.rewards().level, 1);
  });
}
