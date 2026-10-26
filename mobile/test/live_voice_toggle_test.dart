import 'dart:io';

import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/core/widgets/live_voice_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('34 languages: 320px, large text, RTL and working mute', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final codes = Directory('assets/i18n/ui')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''));
    for (final code in codes) {
      await tester.runAsync(() => UiCopy.load(code));
      bool? toggled;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Directionality(
                textDirection: ['ar', 'fa', 'he', 'ur'].contains(code)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: SingleChildScrollView(
                  child: LiveVoiceToggle(
                    enabled: true,
                    onChanged: (v) => toggled = v,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: code);
      await tester.tap(find.byType(Switch));
      expect(toggled, false, reason: code);
    }
    await tester.runAsync(() => UiCopy.load('en'));
  });
}
