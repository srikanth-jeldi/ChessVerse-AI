import 'package:chessverse_ai/core/app_language.dart';
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
        () => AppLanguageController.effectiveLanguageChanges.value = null);
    final report =
        AiReviewReport.fromMoves(['e2e4', 'e7e5', 'Ng1f3'], newestFirst: false);
    for (final size in [const Size(360, 800), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      for (final language
          in AppLanguageController.supported.where((l) => l.code != 'system')) {
        FlutterSecureStorage.setMockInitialValues(
            {'settings.language': language.code});
        AppLanguageController.effectiveLanguageChanges.value = null;
        await tester.pumpWidget(MaterialApp(
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () =>
                            showAdaptiveAiReview(context, report: report),
                        child: const Text('Open'))))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text(CoachLocalizations(language.code).text('title')),
            findsOneWidget,
            reason: '${language.code} $size');
        expect(tester.takeException(), isNull,
            reason: '${language.code} $size');
        if (size.width > 900) {
          final copy = CoachLocalizations(language.code);
          await tester.tap(find.text(copy.text('showThreat')).first);
          await tester.pumpAndSettle();
          expect(find.text(copy.text('threatTitle')), findsOneWidget);
          expect(tester.takeException(), isNull,
              reason: 'threat ${language.code}');
          await tester.tap(find.text(copy.text('gotIt')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(copy.text('explain')).first);
          await tester.pumpAndSettle();
          expect(find.text(personalCoachText('title', language.code)),
              findsOneWidget);
          expect(tester.takeException(), isNull,
              reason: 'personal ${language.code}');
          await tester.tap(find.text(copy.text('back')));
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    }
  });
}
