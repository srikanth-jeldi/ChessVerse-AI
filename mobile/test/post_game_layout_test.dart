import 'package:chessverse_ai/core/audio/chess_sound_service.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/computer_game_store.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final channel in [
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (_) async => null);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers'),
          (call) async {
            if (call.method == 'create') {
              final id = (call.arguments as Map)['playerId'];
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                  .setMockMethodCallHandler(
                    MethodChannel('xyz.luan/audioplayers/events/$id'),
                    (_) async => null,
                  );
            }
            return null;
          },
        );
    ChessSoundService.instance.enabled = false;
    if (Platform.environment['UI_VISUAL_FONTS'] != '1') return;
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            await File('C:/Windows/Fonts/Nirmala.ttc').readAsBytes(),
          ),
        ),
      );
    await font.load();
    final serif = FontLoader('serif')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            await File('C:/Windows/Fonts/Nirmala.ttc').readAsBytes(),
          ),
        ),
      );
    await serif.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final scenario in [
    for (final language in AppLanguageController.supported.where(
      (l) => l.code != 'system',
    ))
      (const Size(390, 844), language.code, 1.0),
    (const Size(320, 640), 'en', 1.5),
    (const Size(740, 360), 'he', 1.0),
  ]) {
    testWidgets('completed board/actions fit $scenario', (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'settings.coachLanguage': scenario.$2,
        'settings.language': scenario.$2,
      });
      ComputerGameStore.resetForTesting();
      tester.view.physicalSize = scenario.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ChessVerseTheme.dark(),
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
      final buttons = [
        'view-game-result',
        'review-completed-game',
        'new-game-after-result',
      ].map((key) => tester.getRect(find.byKey(ValueKey(key)))).toList();
      expect(buttons[0].top, closeTo(buttons[1].top, 1));
      expect(buttons[1].top, closeTo(buttons[2].top, 1));
      expect(tester.takeException(), isNull);
      if (Platform.environment['UI_VISUAL_FONTS'] == '1' &&
          ['en', 'te'].contains(scenario.$2) &&
          scenario.$1.width == 390) {
        await expectLater(
          find.byType(GameScreen),
          matchesGoldenFile('goldens/post_game_fixed_${scenario.$2}.png'),
        );
      }
      await tester.pump(const Duration(seconds: 31));
      expect(find.byType(GameResultOverlay), findsNothing);
      await tester.tap(find.byKey(const ValueKey('view-game-result')));
      await tester.pump();
      expect(find.byType(GameResultOverlay), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
