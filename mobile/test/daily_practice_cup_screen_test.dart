import 'dart:async';

import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/cup_turn_voice.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/core/live_coach_localizations.dart';
import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/data/social_api.dart';
import 'package:chessverse_ai/features/social/presentation/daily_practice_cup_screen.dart';
import 'package:chessverse_ai/main.dart'
    show ChessBoard, MoveHistorySheet, PracticeMatchStudio;
import 'package:chessverse_ai/core/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _PracticeApi extends CommunityApi {
  Completer<void>? holdMove;
  SocialException? joinFailure;
  final state = {
    'id': 'cup',
    'mySeat': 0,
    'seats': List.generate(6, (i) => {'name': 'Player $i', 'bot': i != 0}),
    'games': [
      {'number': 1, 'round': 1, 'white': 0, 'black': 5, 'result': '*'},
    ],
  };
  String? played;
  int? expectedPly;
  @override
  Future<Map<String, dynamic>> joinDailyPractice(String token) async {
    if (joinFailure != null) throw joinFailure!;
    return state;
  }

  @override
  Future<Map<String, dynamic>> dailyPracticeStandings(
    String token,
    String cup,
  ) async => state;
  @override
  Future<Map<String, dynamic>> practiceBoard(
    String token,
    String cup,
    int board, {
    String? move,
    int? ply,
  }) async {
    played = move;
    expectedPly = ply;
    if (move != null && holdMove != null) await holdMove!.future;
    if (move != null) {
      ((state['games'] as List).first as Map)['moves'] = 'e2e4 e8e7';
    }
    return {
      'cup': state,
      'board': 1,
      'ply': move == null ? 0 : 2,
      'legal': ['e2e4'],
      'fen': move == null
          ? '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1'
          : '8/4k3/8/8/4P3/8/8/4K3 w - - 0 2',
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('turn voice addresses the player or names the opponent in each coach language', () {
    for (final locale in AppLanguageController.supported.where(
      (l) => l.code != 'system',
    )) {
      for (final mine in [true, false]) {
        final line = cupTurnAnnouncement(locale.code, 'Leo', mine: mine);
        expect(line, contains('Leo'));
        if (locale.code != 'en') {
          expect(line, isNot(cupTurnAnnouncement('en', 'Leo', mine: mine)));
        }
      }
    }
    expect(
      cupTurnAnnouncement('te', 'లియో', mine: false),
      'ఇప్పుడు లియో వంతు.',
    );
  });
  testWidgets(
    'turn banner repeats above the idle board until touched or the turn changes',
    (tester) async {
      final banner = find.byKey(const ValueKey('prominent-turn-banner'));
      Widget page(bool whiteTurn) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PracticeMatchStudio(
              board: const SizedBox(
                key: ValueKey('test-board'),
                height: 160,
                width: 320,
                child: ColoredBox(color: Colors.black),
              ),
              whiteName: 'White',
              blackName: 'Black',
              flipped: false,
              whiteTurn: whiteTurn,
              result: '*',
              inCheck: false,
              moves: const [],
              onStandings: null,
              onRefresh: null,
            ),
          ),
        ),
      );
      await tester.pumpWidget(page(true));
      expect(banner, findsOneWidget);
      expect(tester.getBottomLeft(find.byKey(const ValueKey('board-top-turn-slot'))).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.byKey(const ValueKey('test-board'))).dy));

      await tester.pump(const Duration(milliseconds: 1801));
      expect(banner, findsNothing);
      await tester.pumpWidget(page(true));
      expect(banner, findsNothing);
      await tester.pump(const Duration(seconds: 5));
      expect(banner, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1800));
      expect(banner, findsNothing);
      await tester.tap(find.byKey(const ValueKey('test-board')));
      await tester.pump(const Duration(seconds: 6));
      expect(banner, findsNothing);
      await tester.pumpWidget(page(false));
      expect(banner, findsNothing);
      await tester.pumpWidget(page(true));
      expect(banner, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('test-board')));
      await tester.pump();
      expect(banner, findsNothing);
      await tester.pump(const Duration(seconds: 6));
      expect(banner, findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final locale in AppLanguageController.supported.where(
    (l) => l.code != 'system',
  )) {
    testWidgets(
      'Cup error, retry and playable board fit at large text in ${locale.code}',
      (tester) async {
        await tester.runAsync(() => UiCopy.load(locale.code));
        AppLanguageController.effectiveLanguageChanges.value = locale.code;
        addTearDown(() async {
          AppLanguageController.effectiveLanguageChanges.value = 'en';
          await tester.runAsync(() => UiCopy.load('en'));
          tester.view.reset();
        });
        for (final size in [const Size(320, 740), const Size(1000, 650)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          final api = _PracticeApi()
            ..joinFailure = const SocialException('missing', statusCode: 404);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.6)),
                child: Directionality(
                  textDirection: ['ar', 'he', 'fa', 'ur'].contains(locale.code)
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: child!,
                ),
              ),
              home: DailyPracticeCupScreen(
                key: UniqueKey(),
                api: api,
                token: 'test',
              ),
            ),
          );
          await tester.pumpAndSettle();
          final title = find.text(UiCopy.text('Daily Practice Cup'));
          final heading = tester.renderObject<RenderParagraph>(title);
          expect(
            heading.didExceedMaxLines,
            isFalse,
            reason: 'Title clipped at ${size.width}',
          );
          expect(
            find.text(
              UiCopy.text('Daily Practice Cup is temporarily unavailable.'),
            ),
            findsOneWidget,
          );
          api.joinFailure = null;
          await tester.tap(find.text(UiCopy.text('Retry')));
          await tester.pumpAndSettle();
          final pair = find.text('Player 0  •  Player 5');
          await tester.ensureVisible(pair);
          await tester.tap(pair);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('square-a1')), findsOneWidget);
          expect(
            tester.getCenter(find.byKey(const ValueKey('square-a1'))).dx,
            lessThan(
              tester.getCenter(find.byKey(const ValueKey('square-h1'))).dx,
            ),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }
  testWidgets(
    'missing cup service shows a readable retry that opens the lobby after recovery',
    (tester) async {
      final api = _PracticeApi()
        ..joinFailure = const SocialException(
          'Community request failed.',
          statusCode: 404,
        );
      await tester.pumpWidget(
        MaterialApp(
          home: DailyPracticeCupScreen(api: api, token: 'test'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Daily Practice Cup is temporarily unavailable.'),
        findsOneWidget,
      );
      expect(find.textContaining('SocialException'), findsNothing);
      api.joinFailure = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Player 0'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    },
  );
  testWidgets('registration shows only real entrants until the roster locks', (
    tester,
  ) async {
    final api = _PracticeApi();
    final full = {...api.state};
    api.state.addAll({
      'lobbySeconds': 5,
      'games': [],
      'seats': [
        {'name': 'Player 0', 'bot': false},
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: DailyPracticeCupScreen(api: api, token: 'test'),
      ),
    );
    await tester.pump();
    expect(find.textContaining('1/6'), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    api.state.remove('lobbySeconds');
    api.state.addAll(full);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byIcon(Icons.smart_toy), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });
  test(
    'all coach languages include the actual reply and stronger alternative',
    () {
      for (final locale in AppLanguageController.supported) {
        final text = liveReplyAdvice(locale.code, 'c5f2', 'f2g2', {
          'attacker': 'BISHOP',
          'captured': 'ROOK',
          'check': true,
          'mate': false,
        });
        expect(text, contains('c5 → f2+'));
        expect(text, contains('f2 → g2'));
        expect(text, isNot(contains('{p}')));
        if (locale.code == 'te') expect(text, contains('తీసుకోగలడు'));
      }
    },
  );
  testWidgets('roster uses player avatars and names stay clean on the board', (
    tester,
  ) async {
    final api = _PracticeApi();
    await tester.pumpWidget(
      MaterialApp(
        home: DailyPracticeCupScreen(api: api, token: 'test'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Player 5'), findsOneWidget);
    expect(find.byType(PlayerAvatar), findsNWidgets(6));
    expect(find.byIcon(Icons.smart_toy), findsNothing);
    expect(find.textContaining('· AI'), findsNothing);
    final pairing = find.text('Player 0  •  Player 5');
    await tester.ensureVisible(pairing);
    await tester.tap(pairing);
    await tester.pumpAndSettle();
    expect(find.text('Automatic voice coach'), findsOneWidget);
    // Muting audio must not hide written coaching or its language selector.
    expect(find.byKey(const ValueKey('live-coach-language')), findsOneWidget);
    expect(find.textContaining('· AI'), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('square-e2')));
    await tester.tap(find.byKey(const ValueKey('square-e2')));
    api.holdMove = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('square-e4')));
    await tester.pump();
    expect(
      tester.widget<ChessBoard>(find.byType(ChessBoard)).lastToSquare,
      'e4',
    );
    expect(find.byKey(const ValueKey('moving-piece-true-P')), findsOneWidget);
    api.holdMove!.complete();
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pumpAndSettle();
    final board = tester.widget<ChessBoard>(find.byType(ChessBoard));
    expect(board.lastFromSquare, 'e8');
    expect(board.lastToSquare, 'e7');
    expect(board.pieces.containsKey('e4'), isTrue);
    expect(api.played, 'e2e4');
    expect(api.expectedPly, 0);
    final history = find.widgetWithText(OutlinedButton, 'Move History');
    await tester.ensureVisible(history);
    await tester.tap(history);
    await tester.pumpAndSettle();
    expect(find.byType(MoveHistorySheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MoveHistorySheet),
        matching: find.text('e2e4'),
      ),
      findsOneWidget,
    );
  });
}
