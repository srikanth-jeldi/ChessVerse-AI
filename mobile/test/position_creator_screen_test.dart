import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/features/play/presentation/position_creator_screen.dart';

void main() {
  testWidgets(
    'learner inventory enforces each colour and piece limit, and restores erased stock',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: PositionCreatorScreen()));
      Future<void> tap(String key) async {
        final target = find.byKey(ValueKey(key));
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      for (final colour in ['w', 'b']) {
        for (final entry in {'Q': 1, 'R': 2, 'B': 2, 'N': 2, 'P': 8}.entries) {
          await tester.tap(find.text('CLEAR'));
          await tester.pumpAndSettle();
          final piece = '$colour${entry.key}';
          await tap('palette-$piece');
          final squares = [
            'a3',
            'b3',
            'c3',
            'd3',
            'e3',
            'f3',
            'g3',
            'h3',
            'a4',
          ];
          for (final square in squares.take(entry.value)) {
            await tap('setup-square-$square');
          }
          expect(
            tester.widget<Text>(find.byKey(ValueKey('remaining-$piece'))).data,
            '0 / ${entry.value}',
          );
          expect(
            tester
                .widget<InkWell>(find.byKey(ValueKey('palette-$piece')))
                .onTap,
            isNull,
          );
          // The already-selected brush must not bypass the disabled palette.
          await tap('setup-square-a4');
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('setup-square-a4')),
              matching: find.byType(Image),
            ),
            findsNothing,
          );
          await tap('palette-erase');
          await tap('setup-square-a3');
          expect(
            tester.widget<Text>(find.byKey(ValueKey('remaining-$piece'))).data,
            '1 / ${entry.value}',
          );
          await tap('palette-$piece');
          await tap('setup-square-a4');
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('setup-square-a4')),
              matching: find.byType(Image),
            ),
            findsOneWidget,
          );
        }
      }
      expect(
        tester.widget<InkWell>(find.byKey(const ValueKey('palette-wK'))).onTap,
        isNull,
      );
      expect(
        tester.widget<InkWell>(find.byKey(const ValueKey('palette-bK'))).onTap,
        isNull,
      );
      await tap('palette-erase');
      await tap('setup-square-e8');
      await tap('palette-bK');
      await tap('setup-square-d8');
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('remaining-bK'))).data,
        '0 / 1',
      );
      expect(tester.takeException(), isNull);
    },
  );

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
    expect(find.text('Set Up Board'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('setup-black-turn')));
    await tester.tap(find.byKey(const ValueKey('setup-black-turn')));
    await tester.ensureVisible(find.text('PLAY BLACK'));
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
    expect(result!.whiteToMove, isFalse);
    expect(result!.initialFen.split(' ')[1], 'b');
  });
}
