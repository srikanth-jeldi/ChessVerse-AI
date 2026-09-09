import 'package:chessverse_ai/core/widgets/desktop_app_sidebar.dart';
import 'package:chessverse_ai/features/online/data/online_match_api.dart';
import 'package:chessverse_ai/features/online/presentation/match_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('zero-move game keeps replay slider disabled', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const match = OnlineMatchDto(
      id: 'empty-game',
      roomCode: 'EMPTY1',
      status: 'FINISHED',
      yourColor: 'WHITE',
      activeColor: 'WHITE',
      whitePlayerName: 'Guest',
      blackPlayerName: 'ChessVerseAI',
      fen: '',
      moves: <OnlineMoveDto>[],
    );

    await tester.pumpWidget(
      const MaterialApp(home: OnlineMatchReplayScreen(match: match)),
    );
    await tester.pump();

    final Slider slider = tester.widget<Slider>(
      find.byKey(const ValueKey<String>('game-replay-slider')),
    );
    expect(slider.onChanged, isNull);
    expect(find.text('Starting position'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Games retains the shared desktop navigation and active item', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(1910, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final destinations = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MatchHistoryScreen(onDestinationSelected: destinations.add),
      ),
    );
    await tester.pump();
    final sidebar = find.byType(DesktopAppSidebar);
    expect(tester.widget<DesktopAppSidebar>(sidebar).selected, 'My Games');
    for (final label in [
      'Home',
      'Play',
      'Puzzles',
      'Learn',
      'Profile',
      'Community',
    ]) {
      await tester.tap(
        find.descendant(of: sidebar, matching: find.text(label)),
      );
    }
    expect(destinations, [0, 1, 2, 3, 4, 5]);
    await tester.tap(
      find.descendant(of: sidebar, matching: find.text('My Games')),
    );
    expect(destinations, hasLength(6));
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
      isFalse,
    );
    expect(tester.takeException(), isNull);

    // A phone keeps its normal standalone page instead of squeezing a sidebar.
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    expect(find.byType(DesktopAppSidebar), findsNothing);
    expect(find.text('MY GAMES'), findsOneWidget);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
