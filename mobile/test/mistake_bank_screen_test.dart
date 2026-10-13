import 'dart:async';

import 'package:chessverse_ai/core/mistake_practice_localizations.dart';
import 'package:chessverse_ai/features/analysis/data/engine_candidates_api.dart';
import 'package:chessverse_ai/features/tutorial/data/academy_progress_store.dart';

import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/desktop_navigation_bridge.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/core/mistake_bank_localizations.dart';
import 'package:chessverse_ai/core/mistake_lesson_localizations.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_challenge.dart';
import 'package:chessverse_ai/features/analysis/domain/pgn_position_reconstructor.dart';
import 'package:chessverse_ai/features/analysis/presentation/mistake_bank_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

SavedMoveReview review({
  String best = 'e2e4',
  List<String> pv = const ['e2e4', 'e7e5', 'g1f3'],
  bool black = false,
}) => SavedMoveReview(
  ply: 1,
  fenBefore:
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR ${black ? 'b' : 'w'} KQkq - 0 1',
  playedMove: black ? 'e7e6' : 'e2e3',
  bestMove: best,
  classification: 'Blunder',
  centipawnLoss: 180,
  opponentThreat: '',
  explanation: 'Control the centre.',
  principalVariation: pv,
);

void main() {
  test('34 languages cover guided and independent practice messages', () {
    final codes = AppLanguageController.supported
        .where((l) => l.code != 'system')
        .map((l) => l.code)
        .toSet();
    expect(mistakePracticeTranslations.keys.toSet(), codes);
    for (final code in codes) {
      expect(
        mistakePracticeTranslations[code],
        hasLength(mistakePracticeKeys.length),
      );
      for (final key in mistakePracticeKeys) {
        final value = mistakePracticeText(key, code, {
          'move': 'e7e5',
          'loss': '1.00',
        });
        expect(value, isNotEmpty);
        expect(value, isNot(contains(RegExp(r'[{}]'))));
      }
    }
  });
  test('all 34 languages explain the lesson, completion and review date', () {
    final codes = AppLanguageController.supported
        .where((l) => l.code != 'system')
        .map((l) => l.code)
        .toSet();
    expect(mistakeLessonTranslations.keys.toSet(), codes);
    for (final code in codes) {
      expect(
        mistakeLessonTranslations[code],
        hasLength(mistakeLessonKeys.length),
      );
      for (final key in mistakeLessonKeys) {
        final text = mistakeLessonText(key, code, {
          'move': 'e2 → e4',
          'focus': 'test',
          'date': '2026-10-14',
        });
        expect(text.trim(), isNotEmpty);
        expect(text, isNot(contains(RegExp(r'[{}]'))), reason: '$code $key');
      }
    }
  });
  test(
    'all 34 supported languages have every training message and piece name',
    () {
      final codes = AppLanguageController.supported
          .where((l) => l.code != 'system')
          .map((l) => l.code)
          .toSet();
      expect(codes, hasLength(34));
      expect(mistakeBankTranslations.keys.toSet(), codes);
      for (final code in codes) {
        expect(
          mistakeBankTranslations[code],
          hasLength(mistakeBankKeys.length),
          reason: code,
        );
        for (final key in mistakeBankKeys) {
          final text = mistakeBankText(key, code, {
            'square': 'g1',
            'piece': mistakeBankText('N', code),
          });
          expect(text.trim(), isNotEmpty, reason: '$code $key');
          expect(text, isNot(contains(RegExp(r'[{}]'))), reason: '$code $key');
        }
        if (code != 'en') {
          expect(
            mistakeBankText('instructions', code),
            isNot(mistakeBankText('instructions', 'en')),
            reason: code,
          );
        }
      }
    },
  );
  test('solution validation handles special moves and king safety', () {
    List<String> replay(String fen, String move) =>
        replayUciLine(fen, [move], requireLegalMoves: true);
    expect(replay('4k3/8/8/8/8/8/8/4K2R w K - 0 1', 'e1g1'), hasLength(2));
    expect(replay('4kr2/8/8/8/8/8/8/4K2R w K - 0 1', 'e1g1'), hasLength(1));
    expect(replay('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1', 'e5d6'), hasLength(2));
    expect(replay('4k3/P7/8/8/8/8/8/4K3 w - - 0 1', 'a7a8n'), hasLength(2));
    expect(replay('4k3/P7/8/8/8/8/8/4K3 w - - 0 1', 'a7a8'), hasLength(1));
    expect(replay('4r1k1/8/8/8/8/8/4R3/4K3 w - - 0 1', 'e2d2'), hasLength(1));
  });
  test('solution ends at the first invalid reply instead of skipping it', () {
    expect(mistakeChallengeLine(review(pv: ['e2e4', 'broken', 'g1f3'])), [
      'e2e4',
    ]);
    expect(mistakeChallengeLine(review(pv: ['e2e4', 'a1a8', 'g1f3'])), [
      'e2e4',
    ]);
    expect(mistakeChallengeLine(review(best: 'a1a8')), isEmpty);
  });

  Future<void> open(
    WidgetTester tester,
    SavedMoveReview move, {
    String language = 'en',
    Size size = const Size(390, 844),
    double scale = 1,
    Future<List<EngineCandidateLine>> Function(String fen)? analyze,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    LocalGameArchive.clearAccountScopedCloudState();
    await AppLanguageController.select(language);
    DesktopNavigationBridge.coinBalance.value = 1125;
    LocalGameArchive.addGame(
      SavedGameRecord(
        mode: 'Computer',
        result: 'White wins',
        detail: 'Checkmate',
        moves: const ['e2e3'],
        playedAt: DateTime.now(),
        whitePlayer: 'Player',
        blackPlayer: 'ChessVerseAI',
        moveReviews: [move],
      ),
    );
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        initialRoute: '/mistakes',
        routes: {
          '/': (_) => const Scaffold(),
          '/mistakes': (_) => MistakeBankScreen(analyzePosition: analyze),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('in-screen picker changes language and persists the choice', (
    tester,
  ) async {
    await open(tester, review());
    await tester.tap(find.byKey(const ValueKey('mistake-language-picker')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('తెలుగు'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('తెలుగు'));
    await tester.pumpAndSettle();
    expect(await AppLanguageController.selectedCode(), 'te');
    expect(find.text(mistakeBankText('title', 'te')), findsOneWidget);
    expect(find.text(mistakePracticeText('learn', 'te')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mistake-language-picker')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  Future<void> tap(WidgetTester tester, String square) async {
    await tester.ensureVisible(find.byKey(ValueKey('mistake-square-$square')));
    await tester.tap(find.byKey(ValueKey('mistake-square-$square')));
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('guided success remains due; clean self-test advances mastery', (
    tester,
  ) async {
    await open(tester, review(pv: ['e2e4']));
    await tap(tester, 'e2');
    await tap(tester, 'e4');
    await tester.pumpAndSettle();
    var progress =
        (await const AcademyProgressStore().readMistakeReviews()).values.single;
    expect(progress.assistedCompletions, 1);
    expect(progress.successes, 0);
    expect(progress.stage, 0);
    expect(progress.due(DateTime.now().toUtc()), isTrue);
    await press(tester, 'mistake-self-test');
    expect(find.byKey(const ValueKey('mistake-piece-prompt')), findsNothing);
    expect(find.byKey(const ValueKey('mistake-hint-move')), findsNothing);
    expect(find.byKey(const ValueKey('mistake-reason')), findsNothing);
    await tap(tester, 'e2');
    await tap(tester, 'e4');
    await tester.pumpAndSettle();
    expect(find.text('Solved without hints or retries.'), findsOneWidget);
    progress =
        (await const AcademyProgressStore().readMistakeReviews()).values.single;
    expect(progress.assistedCompletions, 1);
    expect(progress.successes, 1);
    expect(progress.stage, 1);
    expect(find.byKey(const ValueKey('mistake-next-review')), findsOneWidget);
  });

  testWidgets('a hint in self-test cannot count as independent mastery', (
    tester,
  ) async {
    await open(tester, review(pv: ['e2e4']));
    await press(tester, 'mistake-try-own');
    await press(tester, 'mistake-hint');
    await tap(tester, 'e2');
    await tap(tester, 'e4');
    await tester.pumpAndSettle();
    final progress =
        (await const AcademyProgressStore().readMistakeReviews()).values.single;
    expect(progress.successes, 0);
    expect(progress.assistedCompletions, 1);
    expect(find.textContaining('Completed with help'), findsOneWidget);
  });

  testWidgets(
    'verified equally good alternative is accepted with its own line',
    (tester) async {
      await open(
        tester,
        review(pv: ['e2e4']),
        analyze: (_) async => [
          const EngineCandidateLine(
            move: 'e2e4',
            evaluationCp: 30,
            principalVariation: ['e2e4'],
          ),
          const EngineCandidateLine(
            move: 'd2d4',
            evaluationCp: 25,
            principalVariation: ['d2d4'],
          ),
        ],
      );
      await press(tester, 'mistake-try-own');
      await tap(tester, 'd2');
      await tap(tester, 'd4');
      await tester.pumpAndSettle();
      expect(find.text('Stronger move: d2 → d4'), findsOneWidget);
      expect(find.text('Solved without hints or retries.'), findsOneWidget);
    },
  );

  testWidgets(
    'comparison plays a verified reply and returns to unchanged exercise',
    (tester) async {
      await open(
        tester,
        review(pv: ['e2e4']),
        analyze: (_) async => [
          const EngineCandidateLine(
            move: 'e7e5',
            evaluationCp: 10,
            principalVariation: ['e7e5'],
          ),
        ],
      );
      await press(tester, 'mistake-show-played');
      expect(find.text('Engine reply: e7 → e5'), findsWidgets);
      await press(tester, 'mistake-preview-next');
      await press(tester, 'mistake-preview-close');
      await tap(tester, 'e2');
      await tap(tester, 'e4');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mistake-next')), findsOneWidget);
    },
  );

  testWidgets('late engine result cannot update a disposed lesson', (
    tester,
  ) async {
    final pending = Completer<List<EngineCandidateLine>>();
    await open(tester, review(), analyze: (_) => pending.future);
    await tap(tester, 'd2');
    await tap(tester, 'd4');
    await tester.pumpWidget(const SizedBox());
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tap play, reselect, wrong move, hints and automatic reply work',
    (tester) async {
      await open(tester, review());

      expect(find.text('You played: e2 → e3'), findsWidgets);
      expect(find.byKey(const ValueKey('mistake-goal')), findsOneWidget);

      expect(
        tester.getTopLeft(find.byKey(const ValueKey('mistake-goal'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('mistake-square-a8'))).dy,
        ),
      );
      expect(
        find.text('e2: Pawn. Tap this piece, then choose its destination.'),
        findsOneWidget,
      );
      await tap(tester, 'e4'); // Empty square is not a move attempt.
      await tap(tester, 'd2');
      await tap(tester, 'e2'); // Reselect an own piece.
      await tap(tester, 'e3');
      await tester.pumpAndSettle();
      expect(find.textContaining('not in the saved line'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('mistake-hint')));
      await tester.tap(find.byKey(const ValueKey('mistake-hint')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('mistake-hint')));
      await tester.tap(find.byKey(const ValueKey('mistake-hint')));
      await tester.pump();
      expect(find.text('e2 → e4'), findsOneWidget);
      await tap(tester, 'e2');
      await tap(tester, 'e4');
      expect(find.text('Checking this move…'), findsOneWidget);
      await tap(tester, 'e7'); // Cannot interfere during the reply delay.
      await tap(tester, 'e5');
      await tester.pumpAndSettle();
      await tap(tester, 'g1');
      expect(
        find.text('g1: Knight. Tap this piece, then choose its destination.'),
        findsOneWidget,
      );
      await tap(tester, 'f3');
      await tester.pumpAndSettle();
      expect(
        find.text('Guided practice complete. Now try without help.'),
        findsOneWidget,
      );
      expect(find.text('Stronger move: e2 → e4'), findsOneWidget);
      expect(find.byKey(const ValueKey('mistake-turn')), findsNothing);
      expect(find.byKey(const ValueKey('mistake-skip')), findsNothing);
      expect(
        find.textContaining('this does not mean the game is won'),
        findsOneWidget,
      );
      expect(find.textContaining('Practise again on'), findsNothing);
      expect(find.byKey(const ValueKey('mistake-next')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'black plays from the near side and a broken reply cannot freeze the puzzle',
    (tester) async {
      await open(
        tester,
        review(black: true, best: 'e7e5', pv: ['e7e5', 'bad']),
      );
      expect(
        tester.getCenter(find.byKey(const ValueKey('mistake-square-e7'))).dy,
        greaterThan(
          tester.getCenter(find.byKey(const ValueKey('mistake-square-e2'))).dy,
        ),
      );
      await tap(tester, 'e7');
      await tap(tester, 'e5');
      await tester.pumpAndSettle();
      expect(
        find.text('Guided practice complete. Now try without help.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('invalid saved best move offers an explanation and skip', (
    tester,
  ) async {
    await open(tester, review(best: 'a1a8'));
    expect(find.textContaining('no playable solution'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('mistake-hint')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('mistake-skip')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  for (final language in AppLanguageController.supported.where(
    (l) => l.code != 'system',
  )) {
    testWidgets(
      '${language.code}: localized screen, piece prompt and board work on a narrow phone',
      (tester) async {
        await open(
          tester,
          review(pv: ['e2e4']),
          language: language.code,
          size: const Size(320, 740),
          scale: 1.5,
        );
        final code = language.code;
        expect(find.text(mistakeBankText('title', code)), findsOneWidget);
        expect(find.byKey(const ValueKey('mistake-goal')), findsOneWidget);
        expect(find.text(mistakeBankText('hint', code)), findsOneWidget);
        expect(find.text(mistakeBankText('skip', code)), findsOneWidget);
        expect(
          find.text(
            mistakeBankText('piecePrompt', code, {
              'square': 'e2',
              'piece': mistakeBankText('P', code),
            }),
          ),
          findsOneWidget,
        );
        final rtl = const {'ar', 'ur', 'fa', 'he'}.contains(code);
        expect(
          Directionality.of(
            tester.element(find.byKey(const ValueKey('mistake-piece-prompt'))),
          ),
          rtl ? TextDirection.rtl : TextDirection.ltr,
        );
        final a1 = find.byKey(const ValueKey('mistake-square-a1'));
        final h1 = find.byKey(const ValueKey('mistake-square-h1'));
        expect(tester.getCenter(a1).dx, lessThan(tester.getCenter(h1).dx));
        await tester.ensureVisible(
          find.byKey(const ValueKey('mistake-square-e2')),
        );
        await tap(tester, 'e2');
        await tester.ensureVisible(
          find.byKey(const ValueKey('mistake-square-e4')),
        );
        await tap(tester, 'e4');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('mistake-next')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: code);
      },
    );
  }

  for (final scale in [1.0, 1.5]) {
    testWidgets('Telugu title and instructions fit 320px at scale $scale', (
      tester,
    ) async {
      await open(
        tester,
        review(),
        language: 'te',
        size: const Size(320, 740),
        scale: scale,
      );
      expect(find.text('తప్పుల సాధన'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mistake-piece-prompt')),
        findsOneWidget,
      );
      expect(find.text('సూచన'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
