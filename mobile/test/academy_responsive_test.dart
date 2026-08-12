import 'package:chessverse_ai/features/tutorial/domain/academy_lesson.dart';
import 'package:chessverse_ai/features/tutorial/presentation/interactive_academy_lesson_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/learn_chess_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile academy exposes animated practice flow',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: InteractiveAcademyLessonScreen(
        lesson: AcademyCatalog.forChapter('The knight jump'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('The knight jump'), findsOneWidget);
    expect(find.text('AI COACH'), findsOneWidget);
    expect(find.text('REPLAY'), findsOneWidget);
    expect(find.text('LESSON FLOW'), findsNothing);
  });

  testWidgets('desktop academy uses the instructor workspace',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: InteractiveAcademyLessonScreen(
        lesson: AcademyCatalog.forChapter('How pawns move'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('LESSON FLOW'), findsOneWidget);
    expect(find.text('Watch'), findsOneWidget);
    expect(find.text('Understand'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('AI COACH'), findsOneWidget);
  });

  testWidgets('learn landing exposes a personalized AI path',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LearnChessScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('YOUR AI LEARNING PATH'), findsOneWidget);
    expect(find.textContaining('Next:'), findsOneWidget);
    expect(find.byTooltip('Start recommended lesson'), findsOneWidget);
    expect(find.text('1. WATCH'), findsOneWidget);
    expect(find.text('2. PRACTICE'), findsOneWidget);
    expect(find.text('3. MASTER'), findsOneWidget);
  });

  testWidgets('landscape phone keeps the academy board and coach side by side',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: InteractiveAcademyLessonScreen(
        lesson: AcademyCatalog.forChapter('How pawns move'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('AI COACH'), findsOneWidget);
    expect(find.text('1  AI DEMO'), findsOneWidget);
    expect(find.text('LESSON FLOW'), findsNothing);
  });
}
