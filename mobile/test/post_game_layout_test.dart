import 'package:chessverse_ai/core/computer_game_store.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scenario in [
    (const Size(390, 844), 'te', 1.0),
    (const Size(320, 640), 'en', 1.5),
    (const Size(740, 360), 'he', 1.0),
  ]) {
    testWidgets('completed board/actions fit $scenario', (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'settings.coachLanguage': scenario.$2,
      });
      ComputerGameStore.resetForTesting();
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scenario.$3)),
            child: child!,
          ),
          home: GameScreen(
            initiallySignedIn: true,
            useRemoteEngine: false,
            resumeDraft: ComputerGameDraft(
              id: 'layout-${scenario.$2}',
              updatedAt: DateTime.utc(2026),
              state: {
                'version': 1,
                'pieces': {'g6': 'wK', 'f7': 'wQ', 'h8': 'bK'},
                'moves': ['move', 'move'],
                'humanWhite': true,
                'level': 3,
                'whiteSeconds': 600,
                'blackSeconds': 600,
                'whiteName': 'Guest Player',
                'blackName': 'Computer',
              },
            ),
          ),
        ),
      );
      await tester.pump();
      tester.widget<ChessBoard>(find.byType(ChessBoard)).onSquareTap('f7');
      await tester.pump();
      tester.widget<ChessBoard>(find.byType(ChessBoard)).onSquareTap('g7');
      await tester.pump();
      expect(find.byType(GameResultOverlay), findsNothing);
      final boardRect = tester.getRect(find.byType(ChessBoard));
      final actionsRect = tester.getRect(
        find.byKey(const ValueKey('completed-game-actions')),
      );
      expect(actionsRect.overlaps(boardRect), isFalse);
      expect(
        find.byKey(const ValueKey('view-game-result')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('review-completed-game')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('new-game-after-result')).hitTestable(),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 31));
      expect(find.byType(GameResultOverlay), findsNothing);
      await tester.tap(find.byKey(const ValueKey('view-game-result')));
      await tester.pump();
      expect(find.byType(GameResultOverlay), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
