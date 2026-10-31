import 'package:chessverse_ai/core/computer_game_store.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final action in ['dismiss', 'new game', 'direct new game', 'analysis']) {
    testWidgets('checkmate -> $action respects store review eligibility', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      FlutterSecureStorage.setMockInitialValues({
        'settings.coachLanguage': 'en',
        'auth.token': 'fixture-token',
        'auth.displayName': 'Fixture player',
        'auth.expiresAt': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
        'auth.isGuest': 'false',
      });
      ComputerGameStore.resetForTesting();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const review = MethodChannel('dev.britannio.in_app_review');
      const environment = MethodChannel(
        'com.epitomehub.chessverse/ad_environment',
      );
      var requests = 0;
      messenger.setMockMethodCallHandler(environment, (_) async => true);
      messenger.setMockMethodCallHandler(review, (call) async {
        if (call.method == 'isAvailable') return true;
        if (call.method == 'requestReview') requests++;
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(review, null);
        messenger.setMockMethodCallHandler(environment, null);
      });
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            initiallySignedIn: true,
            useRemoteEngine: false,
            resumeDraft: ComputerGameDraft(
              id: 'review-$action',
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
      expect(requests, 0);
      tester.widget<ChessBoard>(find.byType(ChessBoard)).onSquareTap('f7');
      await tester.pump();
      tester.widget<ChessBoard>(find.byType(ChessBoard)).onSquareTap('g7');
      await tester.pump();
      expect(find.byType(GameResultOverlay), findsNothing);
      expect(requests, 0);
      await tester.pump(const Duration(seconds: 31));
      expect(find.byType(GameResultOverlay), findsNothing);
      expect(requests, 0);
      if (action == 'analysis') {
        await tester.tap(find.byKey(const ValueKey('review-completed-game')));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.close_rounded), findsWidgets);
        expect(requests, 0);
        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(requests, 0);
        expect(find.byType(GameResultOverlay), findsNothing);
        expect(
          find.byKey(const ValueKey('completed-game-actions')),
          findsOneWidget,
        );
      } else if (action == 'direct new game') {
        await tester.tap(find.byKey(const ValueKey('new-game-after-result')));
      } else {
        await tester.tap(find.byKey(const ValueKey('view-game-result')));
        await tester.pump();
        final result = tester.widget<GameResultOverlay>(
          find.byType(GameResultOverlay),
        );
        expect(result.detail, 'Checkmate');
        if (action == 'dismiss') {
          result.onDismiss();
        } else {
          result.onNewGame();
        }
      }
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(requests, action == 'analysis' ? 0 : 1);
      expect(find.byType(GameResultOverlay), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
