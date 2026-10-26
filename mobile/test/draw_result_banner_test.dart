import 'dart:convert';

import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('draw stays visible and opens result in all 34 locales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manifest = (await tester.runAsync(
      () => AssetManifest.loadFromAssetBundle(rootBundle),
    ))!;
    final paths = manifest.listAssets().where(
      (p) => p.startsWith('assets/i18n/ui/') && p.endsWith('.json'),
    );
    expect(paths.length, 34);
    for (final path in paths) {
      final code = path.split('/').last.split('.').first;
      await tester.runAsync(() => UiCopy.load(code));
      final copy = jsonDecode(
        (await tester.runAsync(() => rootBundle.loadString(path)))!,
      ) as Map;
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: {'ar', 'fa', 'he', 'ur'}.contains(code)
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: DrawResultBanner(
                    reason: 'Stalemate',
                    onViewResult: () => opened++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 35));
      expect(find.text('½ – ½'), findsOneWidget, reason: code);
      expect(
        find.text(copy['Draw'] as String? ?? 'Draw'),
        findsOneWidget,
        reason: code,
      );
      await tester.tap(find.text('½ – ½'));
      expect(opened, 1, reason: code);
      expect(tester.takeException(), isNull, reason: code);
    }
    await tester.runAsync(() => UiCopy.load('en'));
  });
}
