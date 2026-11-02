import 'dart:convert';

import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repeat saves collapse and rematches remain separate', () async {
    SavedGameRecord match(String? id, int minute) => SavedGameRecord(
      onlineMatchId: id,
      mode: 'Online',
      result: 'White wins',
      detail: 'Checkmate',
      moves: const ['e2e4'],
      playedAt: DateTime.utc(2026, 10, 30, 8, minute),
      whitePlayer: 'White player',
      blackPlayer: 'Black player',
    );
    final legacy = match(null, 1).toJson();
    FlutterSecureStorage.setMockInitialValues({
      'chessverse_saved_games_v1': jsonEncode([legacy, legacy, match(null, 2).toJson()]),
    });
    await LocalGameArchive.init();
    expect(LocalGameArchive.games.length, 2);
    expect(LocalGameArchive.addGame(match('first', 3)), isTrue);
    expect(LocalGameArchive.addGame(match('first', 4)), isFalse);
    expect(LocalGameArchive.addGame(match('rematch', 4)), isTrue);
    expect(SavedGameRecord.fromJson(LocalGameArchive.games.first.toJson()).onlineMatchId, 'rematch');
    expect(LocalGameArchive.games.length, 4);
  });
}
