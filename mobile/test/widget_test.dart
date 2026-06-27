import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders game board shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessVerseApp());

    expect(find.text('ChessVerse AI'), findsOneWidget);
    expect(find.text('AI Arena'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
  });

  testWidgets('login and provider actions keep the auth form visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChessVerseApp());

    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('User ID or email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.text('Google'));
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text(
        'Google sign-in needs OAuth app credentials. Email login is ready now.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('switches between computer and local players', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(initiallySignedIn: true)),
    );

    await tester.tap(find.text('2 Players'));
    await tester.pump();

    expect(find.text('Local Match'), findsOneWidget);
    expect(find.text('Player 2'), findsWidgets);
  });

  testWidgets('computer replies after a legal white move', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(initiallySignedIn: true)),
    );

    await tester.tap(find.byKey(const ValueKey<String>('square-e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e4')));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('2 moves'), findsOneWidget);
  });

  testWidgets('checkmate marks the checked king square and shows the winner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(initiallySignedIn: true)),
    );
    await tester.tap(find.text('2 Players'));
    await tester.pump();

    for (final (String from, String to) in <(String, String)>[
      ('f2', 'f3'),
      ('e7', 'e5'),
      ('g2', 'g4'),
      ('d8', 'h4'),
    ]) {
      await tester.tap(find.byKey(ValueKey<String>('square-$from')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey<String>('square-$to')));
      await tester.pump();
    }

    final BoardSquare checkedKing = tester.widget<BoardSquare>(
      find.byKey(const ValueKey<String>('square-e1')),
    );
    expect(checkedKing.checkedKing, isTrue);
    expect(find.text('Black wins'), findsOneWidget);
    expect(find.text('Checkmate'), findsOneWidget);
  });
}
