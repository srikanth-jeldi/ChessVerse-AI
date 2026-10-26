import 'package:chessverse_ai/core/theme/app_theme.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('retained profile refreshes after guest signs in and signs out', (
    tester,
  ) async {
    Widget profile(String name, String username, bool guest) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: ProfileScreen(playerName: name, username: username, isGuest: guest),
    );
    await tester.pumpWidget(profile('Guest 826237', 'guest_826237', true));
    final originalState = tester.state(find.byType(ProfileScreen));
    expect(find.text('Guest 826237'), findsOneWidget);
    await tester.pumpWidget(profile('hello buddy', 'hello_buddy', false));
    expect(tester.state(find.byType(ProfileScreen)), same(originalState));
    expect(find.text('hello buddy'), findsOneWidget);
    expect(find.text('@hello_buddy'), findsOneWidget);
    expect(find.text('Guest 826237'), findsNothing);
    await tester.pumpWidget(profile('Renamed player', 'hello_buddy', false));
    expect(find.text('Renamed player'), findsOneWidget);
    await tester.pumpWidget(profile('Guest 999', 'guest_999', true));
    expect(find.text('Guest 999'), findsOneWidget);
    expect(find.text('hello buddy'), findsNothing);
    expect(find.text('Renamed player'), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('academy access lives inside the player profile', (
    WidgetTester tester,
  ) async {
    bool opened = false;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: ProfileScreen(
          playerName: 'Student',
          isGuest: false,
          onAcademy: () => opened = true,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('profile-actions-menu')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Academy'));

    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rich player profile opens and saves editor', (
    WidgetTester tester,
  ) async {
    String? savedDisplayName;
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
          onDisplayNameChanged: (String value) async =>
              savedDisplayName = value,
        ),
      ),
    );

    expect(find.text('PLAYER PROFILE'), findsOneWidget);
    expect(find.text('Srikant'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('edit-player-profile')));
    await tester.pumpAndSettle();
    expect(find.text('CUSTOMIZE YOUR PLAYER'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('profile-display-name-field')),
      'Sri King',
    );
    await tester.tap(find.byKey(const ValueKey<String>('profile-avatar-2')));
    await tester.tap(find.byKey(const ValueKey<String>('save-player-profile')));
    await tester.pumpAndSettle();

    expect(savedDisplayName, 'Sri King');
    expect(find.text('Sri King'), findsOneWidget);
    expect(find.text('@srikant'), findsOneWidget);
    expect(find.text('Player profile saved'), findsOneWidget);
    expect(LocalGameArchive.profileAvatar, 2);
    expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
