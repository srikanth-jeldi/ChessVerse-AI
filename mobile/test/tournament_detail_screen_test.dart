import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/presentation/tournament_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final detail = TournamentDetailDto(
    id: 'hyd',
    name: 'Hyderabad Royal Cup',
    description: 'Seven-round rated rapid beneath the royal city lights.',
    minutes: 10,
    players: 64,
    capacity: 128,
    status: 'ACTIVE',
    joined: true,
    currentRound: 2,
    startsAt: DateTime.now().subtract(const Duration(minutes: 5)),
    rounds: const <TournamentRoundDto>[
      TournamentRoundDto(1, 'FINISHED', <TournamentPairingDto>[
        TournamentPairingDto(
          1,
          TournamentPlayerDto('p1', 'Arjun', null),
          TournamentPlayerDto('p2', 'Kenji', null),
          'match-1',
          TournamentPlayerDto('p1', 'Arjun', null),
          'FINISHED',
        ),
      ]),
      TournamentRoundDto(2, 'ACTIVE', <TournamentPairingDto>[
        TournamentPairingDto(
          1,
          TournamentPlayerDto('p1', 'Arjun', null),
          TournamentPlayerDto('p3', 'Maya', null),
          'match-2',
          null,
          'ACTIVE',
        ),
      ]),
    ],
  );

  for (final size in <Size>[const Size(390, 844), const Size(1100, 900)]) {
    testWidgets('tournament detail adapts at ${size.width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var toggles = 0;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TournamentDetailContent(
            detail: detail,
            busy: false,
            onToggle: () async => toggles++,
            onRefresh: () async {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('HYDERABAD'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('HOW TO PLAY'), 250,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('HOW TO PLAY'), findsOneWidget);
      expect(find.text('OFFICIAL TOURNAMENT RULES'), findsOneWidget);
      expect(find.text('+100 CP'), findsOneWidget);
      expect(find.text('+250 CP'), findsOneWidget);
      expect(find.text('+1000 CP'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('TOURNAMENT BRACKET'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('TOURNAMENT BRACKET'), findsOneWidget);
      expect(find.text('OPENING ROUND'), findsOneWidget);
      expect(find.text('QUARTERFINAL'), findsOneWidget);
      expect(find.text('Arjun'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      expect(toggles, 0);
    });
  }
}
