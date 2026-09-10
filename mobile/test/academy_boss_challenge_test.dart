import 'package:chessverse_ai/features/tutorial/domain/academy_lesson.dart';
import 'package:chessverse_ai/features/tutorial/presentation/academy_boss_challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('three correct no-hint positions award a mastery certificate',
      (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final List<AcademyLesson> lessons = <AcademyLesson>[
      AcademyCatalog.forChapter('Check and checkmate'),
      AcademyCatalog.forChapter('Pins'),
      AcademyCatalog.forChapter('The opposition'),
    ];
    await tester.pumpWidget(MaterialApp(
      home: AcademyBossChallengeScreen(
        courseId: 'master-test',
        courseTitle: 'Master Test',
        lessons: lessons,
        accent: const Color(0xFF59E4C8),
      ),
    ));

    for (final AcademyLesson lesson in lessons) {
      await tester.tap(find.text('${lesson.from} → ${lesson.to}'));
      await tester.pump();
      await tester.tap(find.text(
        lesson == lessons.last ? 'SEE RESULT' : 'NEXT POSITION',
      ));
      await tester.pumpAndSettle();
    }

    expect(find.text('MASTERY CERTIFICATE'), findsOneWidget);
    expect(find.text('COPY SHARE MESSAGE'), findsOneWidget);
  });
}

