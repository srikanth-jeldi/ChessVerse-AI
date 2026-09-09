import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final mode in [GameMode.daily, GameMode.puzzle]) {
    for (final difficulty in DailyChallengeDifficulty.values) {
      testWidgets('${mode.name} ${difficulty.name} never reveals an idle move',
          (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: mode,
          initialDailyDifficulty: difficulty,
          initialPuzzleId:
              mode == GameMode.puzzle ? '${difficulty.name}-001' : null,
        )));
        await tester.pump();
        await tester.pump(const Duration(seconds: 31));
        expect(find.byKey(const ValueKey<String>('idle-hint-source')),
            findsNothing);
        expect(find.byKey(const ValueKey<String>('idle-hint-target')),
            findsNothing);
        expect(find.textContaining('Blue lights suggest'), findsNothing);
        // Selecting a piece must not re-arm the automatic hint timer either.
        final board = tester.widget<ChessBoard>(find.byType(ChessBoard));
        final ownSquare =
            board.pieces.entries.firstWhere((e) => e.value.white).key;
        await tester.tap(find.byKey(ValueKey<String>('square-$ownSquare')));
        await tester.pump();
        await tester.pump(const Duration(seconds: 31));
        expect(find.byKey(const ValueKey<String>('idle-hint-source')),
            findsNothing);
        expect(find.byKey(const ValueKey<String>('idle-hint-target')),
            findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }
}
