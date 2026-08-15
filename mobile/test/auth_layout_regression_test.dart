import 'package:chessverse_ai/features/auth/presentation/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('portrait login is scroll-safe and anchors the king',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(onAuthenticated: (_) {})),
    );
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final Rect selector = tester.getRect(
      find.byKey(const ValueKey<String>('auth-mode-selector')),
    );
    final Rect king = tester.getRect(
      find.byKey(const ValueKey<String>('auth-king-anchor')),
    );
    expect((king.bottom - selector.top).abs(), lessThan(1));
    expect(king.center.dx, greaterThan(selector.center.dx + 100));
    expect(king.height, greaterThan(220));
  });

  testWidgets('opening the keyboard keeps the login field focused',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(onAuthenticated: (_) {})),
    );

    final Finder identityField = find.byType(TextField).first;
    await tester.tap(identityField);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    final EditableText editable = tester.widget<EditableText>(
      find.descendant(
        of: identityField,
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(identityField, 'player@example.com');
    expect(find.text('player@example.com'), findsOneWidget);
  });

  testWidgets('landscape phone uses the dedicated mobile split',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(onAuthenticated: (_) {})),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('auth-landscape-split')),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
