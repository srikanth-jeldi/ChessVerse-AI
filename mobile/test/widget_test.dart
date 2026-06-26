import 'package:chessverse_ai/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders game board shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessVerseApp());

    expect(find.text('ChessVerse AI'), findsOneWidget);
    expect(find.text('AI Arena'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
  });
}

