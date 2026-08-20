import 'package:chessverse_ai/features/social/data/social_api.dart';
import 'package:chessverse_ai/features/social/presentation/social_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const SocialHubDto preview = SocialHubDto(
    friends: <SocialPlayerDto>[
      SocialPlayerDto(connectionId: 'c1', playerId: 'p1', username: 'rival',
        displayName: 'Knight Rival', country: 'India', rating: 1542,
        online: true, relationship: 'FRIEND'),
    ],
    incoming: <SocialPlayerDto>[], outgoing: <SocialPlayerDto>[],
    challenges: <SocialChallengeDto>[
      SocialChallengeDto(id: 'ch1', opponentName: 'Knight Rival', minutes: 10,
        roomCode: 'CV1234', matchId: 'm1', status: 'PENDING', incoming: true,
        expiresAt: null),
    ],
  );

  for (final Size size in <Size>[const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('community is usable at ${size.width.toInt()}px', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(
        themeMode: ThemeMode.dark,
        home: SocialHubScreen(previewHub: preview),
      ));
      await tester.pump();
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('Knight Rival'), findsWidgets);
      expect(find.text('Challenge'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
