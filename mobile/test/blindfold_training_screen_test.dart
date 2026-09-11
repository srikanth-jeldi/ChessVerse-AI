import 'package:chessverse_ai/features/tutorial/presentation/blindfold_training_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/learn_chess_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'settings.language': 'en',
    });
  });

  testWidgets('compact blindfold lab answers and advances without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: BlindfoldTrainingScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('BLINDFOLD LAB'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('blindfold-answer-Light')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('blindfold-answer-Light')),
    );
    await tester.pump();
    expect(find.text('VISUALIZED!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('memory mission hides pieces before accepting an answer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BlindfoldTrainingScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(
      find.byKey(const ValueKey<String>('blindfold-answer-Light')),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('blindfold-next')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('blindfold-next')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('blindfold-answer-e5')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('blindfold-answer-e5')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('blindfold-next')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('blindfold-next')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('hide-blindfold-pieces')),
      findsOneWidget,
    );
    expect(find.text('♘'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('hide-blindfold-pieces')),
    );
    await tester.pump();
    expect(find.text('♘'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('blindfold-answer-f3')),
      findsOneWidget,
    );
  });

  testWidgets('learn page exposes and opens the blindfold lab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LearnChessScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    final Finder card = find.byKey(
      const ValueKey<String>('blindfold-lab-card'),
    );
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(BlindfoldTrainingScreen), findsOneWidget);
  });
}
