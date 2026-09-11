import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/features/play/presentation/position_creator_screen.dart';

void main() {
  testWidgets('returns a valid custom setup and selected player side', (
    WidgetTester tester,
  ) async {
    PositionSetup? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return FilledButton(
              onPressed: () async {
                result = await Navigator.push<PositionSetup>(
                  context,
                  MaterialPageRoute<PositionSetup>(
                    builder: (_) => const PositionCreatorScreen(),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('POSITION CREATOR'), findsOneWidget);

    await tester.tap(find.text('PLAY BLACK'));
    final Finder start = find.byKey(
      const ValueKey<String>('position-start-ai'),
    );
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.pieces, <String, String>{'e1': 'wK', 'e8': 'bK'});
    expect(result!.humanWhite, isFalse);
  });
}
