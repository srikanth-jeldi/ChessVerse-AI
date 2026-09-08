import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/live_coach_localizations.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
 testWidgets('position analysis localizes labels without mobile overflow', (tester) async {
   tester.view.devicePixelRatio = 1;
   tester.view.physicalSize = const Size(360, 800);
   addTearDown(tester.view.resetDevicePixelRatio);
   addTearDown(tester.view.resetPhysicalSize);
   for (final language in AppLanguageController.supported.where((l) => l.code != 'system')) {
     await tester.pumpWidget(MaterialApp(home: Scaffold(body: PositionAnalysisSheet(
       languageCode: language.code,
       analysis: const PositionAnalysis(side: 'White', evaluation: 0, material: 0,
         legalMoves: 20, captures: 0, bestMove: 'e2e4', quality: 'Playable',
         coachLine: 'No legal move is available in this position.', inCheck: false),
     ))));
     await tester.pumpAndSettle();
     expect(find.text(localizeLiveCoach('White legal moves', language.code)), findsOneWidget);
     expect(find.text(localizeLiveCoach('Equal', language.code)), findsOneWidget);
     expect(tester.takeException(), isNull, reason: language.code);
   }
   await tester.pumpWidget(const SizedBox());
 });
}
