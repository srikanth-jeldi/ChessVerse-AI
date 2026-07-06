import 'package:chessverse_ai/app/chessverse_app.dart';
import 'package:chessverse_ai/features/game/application/game_controller.dart';
import 'package:chessverse_ai/features/game/presentation/screens/chess_board_screen.dart';
import 'package:chessverse_ai/features/game/presentation/widgets/chess_board_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app opens splash and navigates to home', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessVerseApp());

    expect(find.text('ChessVerse AI'), findsOneWidget);
    expect(find.text('Play. Learn. Improve.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Guest'), findsOneWidget);
    expect(find.text('Milestone 1'), findsOneWidget);
    expect(find.text('Play Chess'), findsOneWidget);
  });

  testWidgets('game mode opens playable board', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessVerseApp());
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play Chess'));
    await tester.pumpAndSettle();
    expect(find.text('Select Game Mode'), findsOneWidget);

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(find.byType(ChessBoardView), findsOneWidget);
    expect(find.textContaining('Turn: White'), findsOneWidget);
  });

  testWidgets('local game detects fool mate checkmate', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChessBoardScreen(
          mode: ChessGameMode.local,
          difficulty: AiDifficulty.medium,
        ),
      ),
    );

    for (final (String from, String to) in <(String, String)>[
      ('f2', 'f3'),
      ('e7', 'e5'),
      ('g2', 'g4'),
      ('d8', 'h4'),
    ]) {
      await tester.tap(find.text(from));
      await tester.pump();
      await tester.tap(find.text(to));
      await tester.pump();
    }

    expect(find.text('CHECKMATE'), findsOneWidget);
    expect(find.textContaining('Black wins'), findsOneWidget);
  });

  testWidgets('AI game replies after a legal white move', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChessBoardScreen(
          mode: ChessGameMode.ai,
          difficulty: AiDifficulty.easy,
        ),
      ),
    );

    await tester.tap(find.text('e2'));
    await tester.pump();
    await tester.tap(find.text('e4'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Moves: 2'), findsOneWidget);
    expect(find.textContaining('Turn: White'), findsOneWidget);
  });
}
