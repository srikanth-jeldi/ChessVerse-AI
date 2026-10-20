import 'package:chessverse_ai/core/computer_game_store.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final humanWhite in [true, false]) {
    testWidgets(
      'custom Black-to-move game assigns correct turn: humanWhite=$humanWhite',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        tester.view.physicalSize = const Size(1400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final draft = ComputerGameDraft(
          id: 'black-setup',
          updatedAt: DateTime.now(),
          state: {
            'version': 1,
            'initialFen': '4k3/p7/8/8/8/8/8/4K3 b - - 0 1',
            'pieces': {'e1': 'wK', 'e8': 'bK', 'a7': 'bP'},
            'moves': <String>[],
            'humanWhite': humanWhite,
            'whiteName': 'White',
            'blackName': 'Black',
            'level': 1,
            'whiteSeconds': 600,
            'blackSeconds': 600,
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              initiallySignedIn: true,
              useRemoteEngine: false,
              initialGameMode: GameMode.computer,
              resumeDraft: draft,
            ),
          ),
        );
        await tester.pump();
        if (!humanWhite) {
          // Black is the human. The pawn must be selectable immediately.
          final board = tester.widget<ChessBoard>(find.byType(ChessBoard));
          board.onSquareTap('a7');
          await tester.pump();
          board.onSquareTap('a6');
          await tester.pump();
          expect(
            tester
                .widget<ChessBoard>(find.byType(ChessBoard))
                .pieces['a6']
                ?.code,
            'P',
          );
        } else {
          // Black is the AI; it must move without waiting for a fictitious White ply.
          await tester.pump(const Duration(seconds: 2));
          await tester.pump(const Duration(seconds: 2));
          final board = tester.widget<ChessBoard>(find.byType(ChessBoard));
          expect(
            board.pieces['a7'] == null || board.pieces['e8'] == null,
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      },
    );
  }
  for (final removeGame in [false, true]) {
    testWidgets(
      'save conflict dialog closes safely (removed game: $removeGame)',
      (tester) async {
        ComputerGameStore.resetForTesting();
        FlutterSecureStorage.setMockInitialValues({
          'auth.token': 'conflict-player',
          'auth.displayName': 'Player',
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
        final oldClient = ComputerGameStore.client;
        addTearDown(() => ComputerGameStore.client = oldClient);
        ComputerGameStore.client = MockClient((request) async {
          if (request.method == 'PUT' &&
              jsonDecode(request.body)['draft'] != null) {
            return http.Response('{}', 409);
          }
          return http.Response(jsonEncode({'revision': 1, 'draft': null}), 200);
        });
        await ComputerGameStore.prepare('conflict-player', null);
        final navigator = GlobalKey<NavigatorState>();
        final gameRoute = MaterialPageRoute<void>(
          builder: (_) => const GameScreen(
            initiallySignedIn: true,
            initiallyGuest: true,
            useRemoteEngine: false,
            initialGameMode: GameMode.computer,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('My Games')),
          ),
        );
        navigator.currentState!.push(gameRoute);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Game changed on another device'), findsOneWidget);
        if (removeGame) {
          navigator.currentState!.removeRoute(gameRoute);
          await tester.pump();
        }
        await tester.tap(find.text('Back to My Games'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.text('My Games'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final width in [390.0, 1400.0]) {
    testWidgets('guest account saves before Home exit at $width', (
      tester,
    ) async {
      ComputerGameStore.resetForTesting();
      FlutterSecureStorage.setMockInitialValues({
        'auth.token': 'guest-save-$width',
        'auth.displayName': 'Guest player',
        'auth.isGuest': 'true',
        'auth.expiresAt': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
        'settings.coachLanguage': 'en',
      });
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final oldClient = ComputerGameStore.client;
      addTearDown(() => ComputerGameStore.client = oldClient);
      var revision = 0;
      Map<String, dynamic>? saved;
      ComputerGameStore.client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer guest-save-$width');
        if (request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map;
          expect(body['revision'], revision);
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
      await ComputerGameStore.prepare('guest-save-$width', null);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const GameScreen(
                      initiallySignedIn: true,
                      initiallyGuest: true,
                      useRemoteEngine: false,
                      initialGameMode: GameMode.computer,
                    ),
                  ),
                ),
                child: const Text('Open game'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open game'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('pause-computer-game')), findsOneWidget);
      await tester.tap(
        find.byKey(
          ValueKey(
            width > 1000 ? 'desktop-back-to-home' : 'pause-computer-game',
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Open game'), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
      expect(saved?['state']['pieces'], hasLength(32));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
  testWidgets('resume restores saved board instead of the starting position', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final draft = ComputerGameDraft(
      id: 'resume',
      updatedAt: DateTime.utc(2026),
      state: {
        'version': 1,
        'pieces': {'e1': 'wK', 'e8': 'bK', 'd4': 'wP'},
        'moves': ['e7e5', 'd2d4'],
        'humanWhite': true,
        'level': 3,
        'whiteSeconds': 421,
        'blackSeconds': 399,
        'whiteName': 'Saved player',
        'blackName': 'Saved computer',
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: GameMode.computer,
          resumeDraft: draft,
        ),
      ),
    );
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
