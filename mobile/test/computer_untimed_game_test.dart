import 'dart:convert';

import 'package:chessverse_ai/core/computer_game_store.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'computer checkmate explains the result immediately and dismisses cleanly',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'settings.coachLanguage': 'en',
      });
      ComputerGameStore.resetForTesting();
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            initiallySignedIn: true,
            useRemoteEngine: false,
            resumeDraft: ComputerGameDraft(
              id: 'mate',
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
      final result = tester.widget<GameResultOverlay>(
        find.byType(GameResultOverlay),
      );
      expect(result.title, 'You win');
      expect(result.detail, 'Checkmate');
      result.onDismiss();
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(GameResultOverlay), findsNothing);
      expect(find.byType(OnlineVictoryCelebration), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  for (final seconds in [0, 2]) {
    testWidgets(
      'untimed computer draft with $seconds seconds saves and resumes',
      (tester) async {
        ComputerGameStore.resetForTesting();
        FlutterSecureStorage.setMockInitialValues({
          'auth.token': 'untimed-guest',
          'auth.displayName': 'Guest Player',
          'auth.isGuest': 'true',
          'auth.expiresAt': DateTime.now()
              .add(const Duration(days: 1))
              .toIso8601String(),
          'settings.coachLanguage': 'en',
        });
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final previousClient = ComputerGameStore.client;
        addTearDown(() => ComputerGameStore.client = previousClient);
        var revision = 0;
        Map<String, dynamic>? saved;
        ComputerGameStore.client = MockClient((request) async {
          if (request.method == 'PUT') {
            final body = jsonDecode(request.body) as Map;
            revision++;
            saved = body['draft'] == null
                ? null
                : Map<String, dynamic>.from(body['draft']);
          }
          return http.Response(
            jsonEncode({'revision': revision, 'draft': saved}),
            200,
          );
        });
        await ComputerGameStore.prepare('untimed-guest', null);
        var draft = ComputerGameDraft(
          id: 'legacy-clock',
          updatedAt: DateTime.utc(2026),
          state: {
            'version': 1,
            'pieces': {'e1': 'wK', 'e8': 'bK', 'e2': 'wP', 'e7': 'bP'},
            'moves': ['a2a3', 'a7a6'],
            'humanWhite': true,
            'level': 3,
            'whiteSeconds': seconds,
            'blackSeconds': seconds,
            'whiteName': 'Guest Player',
            'blackName': 'Computer',
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GameScreen(
                        initiallySignedIn: true,
                        initiallyGuest: true,
                        useRemoteEngine: false,
                        resumeDraft: draft,
                      ),
                    ),
                  ),
                  child: const Text('Continue game'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Continue game'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(minutes: 20));
        expect(find.byType(GameResultOverlay), findsNothing);
        expect(find.byType(OnlineVictoryCelebration), findsNothing);
        expect(find.text('10:00'), findsNothing);
        expect(
          tester.widget<ChessBoard>(find.byType(ChessBoard)).moveSequence,
          2,
        );

        await tester.tap(find.byKey(const ValueKey('pause-computer-game')));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(GameScreen), findsNothing);
        expect(saved, isNotNull);
        expect(saved!['state']['whiteSeconds'], seconds);
        expect(saved!['state']['blackSeconds'], seconds);
        expect(saved!['state']['pieces'], draft.state['pieces']);
        expect(saved!['state']['moves'], draft.state['moves']);
        draft = ComputerGameDraft.fromJson(saved!);

        await tester.tap(find.text('Continue game'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        var board = tester.widget<ChessBoard>(find.byType(ChessBoard));
        expect(board.pieces['e2']?.code, 'P');
        expect(board.moveSequence, 2);
        board.onSquareTap('e2');
        await tester.pump();
        board = tester.widget<ChessBoard>(find.byType(ChessBoard));
        board.onSquareTap('e4');
        await tester.pump();
        expect(
          tester
              .widget<ChessBoard>(find.byType(ChessBoard))
              .pieces['e4']
              ?.white,
          true,
        );
        expect(find.byType(GameResultOverlay), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      },
    );
  }
}
