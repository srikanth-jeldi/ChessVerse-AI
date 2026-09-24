import 'package:chessverse_ai/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop rankings keeps the complete primary navigation', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: LeaderboardScreen(
          onHome: () {},
          onPlay: () {},
          onMyGames: () {},
          onPuzzles: () {},
          onLearn: () {},
          onProfile: () {},
          onCommunity: () {},
          onCollection: () {},
        ),
      ),
    );
    // Rankings uses animated skeletons while its preview data resolves, so a
    // fixed pump is deterministic whereas pumpAndSettle can never become idle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    for (final String label in <String>[
      'Home',
      'Play',
      'My Games',
      'Puzzles',
      'Learn',
      'Profile',
      'Community',
      'Collection',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label is missing');
    }

    // Dispose the screen so its decorative animations cannot keep the test
    // binding alive after the assertions have completed.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
