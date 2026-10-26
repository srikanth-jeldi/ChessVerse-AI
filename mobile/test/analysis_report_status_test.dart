import 'package:chessverse_ai/core/analysis_dashboard_localizations.dart';
import 'package:chessverse_ai/features/analysis/presentation/analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('report status remains readable in 34 languages and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    expect(analysisDashboardTranslations.length, 34);
    for (final code in analysisDashboardTranslations.keys) {
      for (final label in ['latestEmpty', 'latestReport']) {
        final text = analysisDashboardText(label, code);
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: {'ar', 'fa', 'he', 'ur'}.contains(code)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(32),
                    child: AnalysisReportStatus(text),
                  ),
                ),
              ),
            ),
          ),
        );
        final rendered = tester.widget<Text>(find.text(text));
        expect(rendered.style!.fontSize, greaterThanOrEqualTo(16));
        expect(rendered.maxLines, isNull);
        expect(tester.takeException(), isNull, reason: '$code/$label');
      }
    }
  });
}
