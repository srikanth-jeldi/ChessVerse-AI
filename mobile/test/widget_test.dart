import 'package:chessverse_ai/main.dart';
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
}
