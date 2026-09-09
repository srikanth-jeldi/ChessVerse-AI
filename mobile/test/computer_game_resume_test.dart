import 'package:chessverse_ai/core/computer_game_store.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('resume restores saved board instead of the starting position',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final draft =
        ComputerGameDraft(id: 'resume', updatedAt: DateTime.utc(2026), state: {
      'version': 1,
      'pieces': {'e1': 'wK', 'e8': 'bK', 'd4': 'wP'},
      'moves': ['e7e5', 'd2d4'],
      'humanWhite': true,
      'level': 3,
      'whiteSeconds': 421,
      'blackSeconds': 399,
      'whiteName': 'Saved player',
      'blackName': 'Saved computer',
    });
    await tester.pumpWidget(MaterialApp(
        home: GameScreen(
      initiallySignedIn: true,
      useRemoteEngine: false,
      initialGameMode: GameMode.computer,
      resumeDraft: draft,
    )));
    await tester.pump();
    final board = tester.widget<ChessBoard>(find.byType(ChessBoard));
    expect(board.pieces.length, 3);
    expect(board.pieces['d4']?.code, 'P');
    expect(board.pieces['d2'], isNull);
    expect(board.pieces['e1']?.white, true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
