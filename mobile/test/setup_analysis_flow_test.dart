import 'dart:async';

import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/features/analysis/data/engine_candidates_api.dart';
import 'package:chessverse_ai/features/analysis/presentation/setup_analysis_screen.dart';
import 'package:chessverse_ai/features/play/presentation/position_creator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const fen = '4k3/p7/8/8/8/8/8/4K3 b - - 0 1';
const lines = [
  EngineCandidateLine(
    move: 'a7a6',
    evaluationCp: 125,
    principalVariation: ['a7a6', 'e1d1'],
  ),
  EngineCandidateLine(
    move: 'a7a5',
    evaluationCp: 80,
    principalVariation: ['a7a5', 'e1d1'],
  ),
];

void main() {
  testWidgets(
    'editor blocks illegal side, then opens exact Black-to-move analysis',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await tester.runAsync(() => UiCopy.load('en'));
      await tester.pumpWidget(const MaterialApp(home: PositionCreatorScreen()));
      await tester.tap(find.byKey(const ValueKey('setup-square-e7')));
      await tester.ensureVisible(
        find.byKey(const ValueKey('position-analyse')),
      );
      await tester.tap(find.byKey(const ValueKey('position-analyse')));
      await tester.pump();
      expect(find.byType(SetupAnalysisScreen), findsNothing);
      expect(
        find.text(
          'The side not moving cannot already be in check. Change the board or side to move.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('setup-black-turn')),
      );
      await tester.tap(find.byKey(const ValueKey('setup-black-turn')));
      await tester.ensureVisible(
        find.byKey(const ValueKey('position-analyse')),
      );
      await tester.tap(find.byKey(const ValueKey('position-analyse')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SetupAnalysisScreen>(find.byType(SetupAnalysisScreen))
            .fen,
        '4k3/4Q3/8/8/8/8/8/4K3 b - - 0 1',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PositionCreatorScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final lang in AppLanguageController.supported.where(
    (l) => l.code != 'system',
  )) {
    for (final state in [
      'editor',
      'loaded',
      'error',
      'empty',
      'loading',
      'signed-out',
    ]) {
      testWidgets('setup $state ${lang.code} narrow enlarged', (tester) async {
        FlutterSecureStorage.setMockInitialValues(
          state == 'signed-out'
              ? {}
              : {
                  'auth.token': 'layout-test-token',
                  'auth.expiresAt': '2099-01-01T00:00:00Z',
                  'auth.displayName': 'Layout player',
                  'auth.isGuest': 'false',
                },
        );
        await tester.runAsync(() => UiCopy.load(lang.code));
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final pending = Completer<List<EngineCandidateLine>>();
        final Widget page = state == 'editor'
            ? const PositionCreatorScreen()
            : SetupAnalysisScreen(
                fen: fen,
                analyze: state == 'signed-out'
                    ? null
                    : (_) async {
                        if (state == 'error') {
                          throw const EngineCandidatesApiException(503);
                        }
                        if (state == 'loading') return pending.future;
                        return state == 'empty' ? [] : lines;
                      },
              );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang.code),
            supportedLocales: AppLanguageController.supported
                .where((l) => l.code != 'system')
                .map((l) => Locale(l.code)),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: page,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        if (state == 'editor') {
          await tester.ensureVisible(
            find.byKey(const ValueKey('position-start-ai')),
          );
          await tester.pump();
          expect(find.text(UiCopy.text('Analyse Position')), findsOneWidget);
          expect(find.text(UiCopy.text('Play against AI')), findsOneWidget);
        } else if (state == 'loaded') {
          await tester.ensureVisible(find.text('a7a6   -1.25'));
          await tester.pump();
          expect(find.text('a7a6   -1.25'), findsOneWidget);
          await tester.ensureVisible(find.byKey(const ValueKey('line-next')));
          await tester.tap(find.byKey(const ValueKey('line-next')));
          await tester.pump();
          expect(
            tester
                .widget<SetupPositionBoard>(find.byType(SetupPositionBoard))
                .fen
                .split(' ')[1],
            'w',
          );
        } else if (state == 'error' || state == 'signed-out') {
          await tester.ensureVisible(find.text(UiCopy.text('Retry')));
          await tester.pump();
        }
        expect(tester.takeException(), isNull, reason: '${lang.code}/$state');
        await tester.pumpWidget(const SizedBox());
        if (!pending.isCompleted) pending.complete([]);
        await tester.pump();
      });
    }
  }

  testWidgets('analysis retry succeeds and preserves chosen black position', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'auth.token': 'layout-test-token',
      'auth.expiresAt': '2099-01-01T00:00:00Z',
      'auth.displayName': 'Layout player',
      'auth.isGuest': 'false',
    });
    await tester.runAsync(() => UiCopy.load('en'));
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SetupAnalysisScreen(
          fen: fen,
          analyze: (input) async {
            expect(input, fen);
            if (++attempts == 1) throw TimeoutException('test');
            return lines;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('a7a6   -1.25'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
