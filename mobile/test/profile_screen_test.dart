import 'package:chessverse_ai/core/theme/app_theme.dart';
import 'package:chessverse_ai/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rich player profile opens and saves editor', (
    WidgetTester tester,
  ) async {
    String? savedUsername;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: ProfileScreen(
          playerName: 'Srikant',
          username: 'srikant',
          isGuest: false,
          onUsernameChanged: (String value) => savedUsername = value,
        ),
      ),
    );

    expect(find.text('PLAYER PROFILE'), findsOneWidget);
    expect(find.textContaining('ELO'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('edit-player-profile')));
    await tester.pumpAndSettle();
    expect(find.text('CUSTOMIZE YOUR PLAYER'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('profile-username-field')),
      'srikantjheldi',
    );
    await tester.tap(find.byKey(const ValueKey<String>('profile-avatar-2')));
    await tester.tap(find.byKey(const ValueKey<String>('save-player-profile')));
    await tester.pumpAndSettle();

    expect(savedUsername, 'srikantjheldi');
    expect(find.text('@srikantjheldi'), findsOneWidget);
    expect(find.text('Player profile saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
