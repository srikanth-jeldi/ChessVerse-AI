import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('promotion choices show piece artwork and readable names', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: <String>['Q', 'R', 'B', 'N']
                .map(
                  (String code) => PromotionChoice(
                    piece: ChessPiece(code, true),
                    onSelected: () {},
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChessCoin), findsNWidgets(4));
    for (final String name in <String>['Queen', 'Rook', 'Bishop', 'Knight']) {
      expect(find.text(name), findsOneWidget);
    }
    for (final String code in <String>['Q', 'R', 'B', 'N']) {
      expect(find.text(code), findsNothing);
    }
  });
}
