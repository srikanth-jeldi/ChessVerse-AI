import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes Indian and international phone numbers', () {
    expect(normalizePhone('7569898494'), '+917569898494');
    expect(normalizePhone('+1 415 555 2671'), '+14155552671');
    expect(normalizePhone('12345'), isNull);
  });

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
    expect(find.text('User ID, email or phone'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text(
        'Google login needs GOOGLE_WEB_CLIENT_ID and GOOGLE_SERVER_CLIENT_ID.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('phone registration explains automatic India country code', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChessVerseApp());

    await tester.tap(find.text('Phone'));
    await tester.pump();

    expect(find.text('India +91 is added automatically'), findsOneWidget);
  });

  testWidgets('switches between computer and local players', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('game-mode-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Local 2P').last);
    await tester.pumpAndSettle();

    expect(find.text('Local Match'), findsOneWidget);
    expect(find.text('Player 2'), findsWidgets);
  });

  testWidgets('computer replies after a legal white move', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
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
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('game-mode-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Local 2P').last);
    await tester.pumpAndSettle();

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

  testWidgets('analysis opens a useful position report', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
    );

    await tester.tap(find.text('Analyze'));
    await tester.pumpAndSettle();

    expect(find.text('Position analysis'), findsOneWidget);
    expect(find.text('Evaluation'), findsOneWidget);
    expect(find.text('White legal moves'), findsOneWidget);
    expect(find.textContaining('Recommended:'), findsOneWidget);
  });
}
