import 'package:chessverse_ai/core/theme/app_theme.dart';
import 'package:chessverse_ai/features/library/presentation/reference_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saved games content starts near the top on a phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const SavedGamesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('All')).dy, lessThan(180));
    expect(tester.takeException(), isNull);
  });
}
