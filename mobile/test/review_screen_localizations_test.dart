import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/analysis_dashboard_localizations.dart';
import 'package:chessverse_ai/core/coach_localizations.dart';
import 'package:chessverse_ai/core/personal_coach_localizations.dart';
import 'package:chessverse_ai/features/analysis/domain/ai_review_report.dart';
import 'package:chessverse_ai/features/analysis/presentation/adaptive_ai_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'full review opens in every selected language at mobile and desktop widths',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        () => AppLanguageController.effectiveLanguageChanges.value = null,
      );
      final report = AiReviewReport.fromMoves([
        'e2e4',
        'e7e5',
        'Ng1f3',
      ], newestFirst: false, knownAccuracy: 82);
      for (final size in [const Size(360, 800), const Size(1280, 900)]) {
        tester.view.physicalSize = size;
        for (final language in AppLanguageController.supported.where(
          (l) => l.code != 'system',
        )) {
          FlutterSecureStorage.setMockInitialValues({
            'settings.language': language.code,
          });
          AppLanguageController.effectiveLanguageChanges.value = null;
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () =>
                        showAdaptiveAiReview(context, report: report),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(
            find.text(CoachLocalizations(language.code).text('title')),
            findsOneWidget,
            reason: '${language.code} $size',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${language.code} $size',
          );
          if (size.width == 360) {
            expect(
              find.text(analysisDashboardText('openReview', language.code)),
              findsOneWidget,
              reason: 'summary action ${language.code}',
            );
          }
          if (size.width == 360 && language.code == 'en') {
            expect(
              find.byKey(const ValueKey<String>('ai-review-score-badge')),
              findsOneWidget,
            );
            expect(find.text('${report.accuracy} / 100'), findsOneWidget);
            final reviewButton = find.text(
              analysisDashboardText('openReview', language.code),
            );
            await tester.ensureVisible(reviewButton);
            await tester.tap(reviewButton);
            await tester.pumpAndSettle();
            expect(find.text('Move 1 · e2e4'), findsOneWidget);
            expect(
              find.text(personalCoachText('askPosition', language.code)),
              findsNothing,
            );
            expect(find.bySemanticsLabel('White king'), findsOneWidget);
            expect(find.bySemanticsLabel('Black king'), findsOneWidget);
            expect(
              find.byKey(const ValueKey<String>('vertical-evaluation-bar')),
              findsOneWidget,
            );
            expect(find.text('5 possible moves to compare'), findsNothing);
            await tester.tap(find.text('Advanced'));
            await tester.pumpAndSettle();
            expect(
              find.text(personalCoachText('askPosition', language.code)),
              findsOneWidget,
            );
            await tester.scrollUntilVisible(
              find.text('5 possible moves to compare'),
              300,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text('5 possible moves to compare'), findsOneWidget);
            expect(
              find.textContaining('A legal candidate from this position.'),
              findsNWidgets(4),
            );
          }
          if (size.width > 900) {
            final copy = CoachLocalizations(language.code);
            await tester.tap(find.text(copy.text('showThreat')).first);
            await tester.pumpAndSettle();
            expect(find.text(copy.text('threatTitle')), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason: 'threat ${language.code}',
            );
            await tester.tap(find.text(copy.text('gotIt')));
            await tester.pumpAndSettle();
            await tester.tap(find.text(copy.text('explain')).first);
            await tester.pumpAndSettle();
            expect(
              find.text(personalCoachText('title', language.code)),
              findsOneWidget,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: 'personal ${language.code}',
            );
            await tester.tap(find.text(copy.text('back')));
            await tester.pumpAndSettle();
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        }
      }
    },
  );

  testWidgets('mobile review hides fallback score and empty quality cards', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final report = AiReviewReport.fromMoves(
      const <String>[],
      newestFirst: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAdaptiveAiReview(context, report: report),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('62 / 100'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('ai-review-score-badge')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('ai-review-accuracy-unavailable')),
      findsOneWidget,
    );
    expect(find.text('0%'), findsNothing);
  });
}
