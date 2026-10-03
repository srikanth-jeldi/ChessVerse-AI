import 'package:chessverse_ai/core/analysis_dashboard_localizations.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/coach_localizations.dart';
import 'package:chessverse_ai/features/analysis/domain/ai_review_report.dart';
import 'package:chessverse_ai/features/analysis/presentation/adaptive_ai_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in ['en', 'te']) {
    for (final size in [
      const Size(390, 844),
      const Size(360, 640),
      const Size(844, 390),
    ]) {
      testWidgets(
        'review actions scroll into the safe viewport: $language $size',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          final padding = FakeViewPadding(
            top: 32,
            bottom: 48,
            left: size.width > size.height ? 44 : 0,
          );
          tester.view.padding = padding;
          tester.view.viewPadding = padding;
          addTearDown(tester.view.reset);
          FlutterSecureStorage.setMockInitialValues({
            'settings.language': language,
          });
          AppLanguageController.effectiveLanguageChanges.value = null;
          addTearDown(
            () => AppLanguageController.effectiveLanguageChanges.value = null,
          );
          final report = AiReviewReport.fromMoves(
            ['e2e4', 'e7e5', 'Ng1f3'],
            newestFirst: false,
            knownAccuracy: 82,
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showAdaptiveAiReview(
                      context,
                      report: report,
                      onGeneratePuzzles: () {},
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();

          Future<void> revealAndCheck(Finder action) async {
            for (var swipe = 0; swipe < 40; swipe++) {
              if (tester.getRect(action).bottom <=
                      size.height - padding.bottom &&
                  action.hitTestable().evaluate().isNotEmpty) {
                break;
              }
              await tester.drag(
                find.byType(SingleChildScrollView).first,
                const Offset(0, -180),
              );
              await tester.pumpAndSettle();
            }
            await tester.pumpAndSettle();
            final rect = tester.getRect(action);
            expect(
              rect.bottom,
              lessThanOrEqualTo(size.height - padding.bottom),
            );
            expect(rect.top, greaterThanOrEqualTo(padding.top));
            expect(rect.left, greaterThanOrEqualTo(padding.left));
            expect(action.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          }

          final start = find.widgetWithText(
            FilledButton,
            analysisDashboardText('openReview', language),
          );
          await revealAndCheck(start);
          await tester.tap(start);
          await tester.pumpAndSettle();
          final next = find.widgetWithIcon(
            FilledButton,
            Icons.arrow_forward_rounded,
          );
          final previous = find.widgetWithIcon(
            OutlinedButton,
            Icons.arrow_back_rounded,
          );
          await revealAndCheck(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(find.text('2 / 3'), findsOneWidget);
          await revealAndCheck(previous);
          await tester.tap(previous);
          await tester.pumpAndSettle();
          expect(find.text('1 / 3'), findsOneWidget);
          await tester.tap(
            find.descendant(
              of: find.byKey(
                const ValueKey<String>('review-mode-toggle'),
              ),
              matching: find.text(
                CoachLocalizations(language).text('moveByMove'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await revealAndCheck(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(find.text('2 / 3'), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
