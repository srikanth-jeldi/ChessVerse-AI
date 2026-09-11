import 'package:chessverse_ai/features/tutorial/presentation/master_games_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'master game opens a real position and reveals its continuation',
    (WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'settings.language': 'en',
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: MasterGamesScreen()));
      await tester.pump();
      expect(find.text('ENTER THE MASTER’S MIND'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('master-game-kasparov-topalov-1999')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Position before move 24'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('master-narration')),
        findsOneWidget,
      );

      final Finder answer = find.byKey(
        const ValueKey<String>('master-choice-24. Rxd4!!'),
      );
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pumpAndSettle();
      expect(find.text('MASTER MOVE FOUND'), findsOneWidget);
      expect(find.text('25.Re7+'), findsOneWidget);

      final Finder complete = find.text('COMPLETE MASTERCLASS');
      await tester.ensureVisible(complete);
      await tester.tap(complete);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('master-completion-close')),
        findsOneWidget,
      );
      expect(find.text('1 / 1'), findsOneWidget);
    },
  );
}
