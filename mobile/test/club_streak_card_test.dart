import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/features/social/presentation/club_streak_card.dart';

void main() {
  setUpAll(() async {
    if (Platform.environment['CLUB_VISUAL_FONTS'] != '1') return;
    final font = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            await File('C:/Windows/Fonts/Nirmala.ttc').readAsBytes(),
          ),
        ),
      );
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 480.0]) {
    testWidgets('streak reference layout $width', (tester) async {
      tester.view.physicalSize = Size(width, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF071D2A),
            body: Align(
              alignment: Alignment.topCenter,
              child: ClubStreakCard(
                language: 'te',
                reward: const {
                  'streak': 1,
                  'earnedToday': true,
                  'awardedCoins': 0,
                  'nextCoins': 10,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('club-coins-awarded')), findsOneWidget);
      expect(find.text('+5 కాయిన్లు'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('streak-day-4'))).dy,
        tester.getTopLeft(find.byKey(const ValueKey('streak-day-1'))).dy,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('streak-day-5'))).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(const ValueKey('streak-day-1'))).dy,
        ),
      );
      expect(tester.takeException(), isNull);
      if (Platform.environment['CLUB_VISUAL_FONTS'] == '1' && width == 480) {
        await expectLater(
          find.byType(ClubStreakCard),
          matchesGoldenFile('goldens/streak_reference.png'),
        );
      }
    });
  }
  testWidgets('no reward confirmation before completion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClubStreakCard(
            language: 'en',
            reward: {'streak': 0, 'earnedToday': false, 'nextCoins': 5},
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('club-coins-awarded')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('historical completion does not invent a coin award', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClubStreakCard(
            language: 'en',
            reward: {
              'streak': 2,
              'earnedToday': true,
              'awardedCoins': 0,
              'creditedCoins': 0,
              'nextCoins': 15,
            },
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('club-coins-awarded')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
