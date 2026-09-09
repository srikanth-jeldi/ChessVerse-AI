import 'package:chessverse_ai/core/widgets/desktop_app_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop sidebar exposes a working My Games menu',
      (tester) async {
    bool opened = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DesktopAppSidebar(
      selected: 'Home',
      onMyGames: () => opened = true,
    ))));
    expect(find.text('My Games'), findsOneWidget);
    await tester.tap(find.text('My Games'));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
