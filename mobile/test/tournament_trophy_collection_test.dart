import 'package:chessverse_ai/features/profile/presentation/profile_screen.dart';
import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'champion artwork and placements stay distinct on narrow screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: TournamentTrophies(
                  achievements: [
                    for (final placement in [
                      'CHAMPION',
                      'RUNNER_UP',
                      'PARTICIPANT',
                    ])
                      TournamentAchievementDto(
                        tournamentId: placement,
                        tournamentName: 'Hyderabad Royal Championship',
                        badgeCode: 'HYDERABAD_ROYAL',
                        placement: placement,
                        awardedAt: DateTime(2026, 10, 26),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Champion'), findsOneWidget);
      expect(find.text('Runner-up'), findsOneWidget);
      expect(find.text('Participant'), findsOneWidget);
      expect(find.text('HYDERABAD ROYAL'), findsNothing);
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(
        images.any(
          (image) =>
              image.image is AssetImage &&
              (image.image as AssetImage).assetName ==
                  'assets/branding/trophy-hyderabad-royal-v1.webp',
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
