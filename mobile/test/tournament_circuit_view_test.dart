import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/presentation/tournament_circuit_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tournaments = <TournamentDto>[
    TournamentDto(
      id: 'hyd',
      name: 'Hyderabad Royal Cup',
      description: 'Seven-round rated rapid beneath the city lights.',
      minutes: 10,
      players: 42,
      capacity: 128,
      status: 'OPEN',
      joined: true,
      startsAt: DateTime.now().add(const Duration(days: 1)),
    ),
    const TournamentDto(
      id: 'tokyo',
      name: 'Tokyo Neon Masters',
      description: 'Fast knockout chess in the neon arena.',
      minutes: 5,
      players: 64,
      capacity: 128,
      status: 'ACTIVE',
      joined: false,
    ),
  ];

  for (final size in <Size>[const Size(390, 844), const Size(1100, 800)]) {
    testWidgets('world circuit adapts at ${size.width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TournamentDto? opened;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TournamentCircuitView(
            tournaments: tournaments,
            fairPlayScore: 100,
            circuitPoints: 1250,
            onOpen: (event) => opened = event,
            onRefresh: () async {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('WORLD CHESS CIRCUIT'), findsOneWidget);
      expect(find.text('HYDERABAD'), findsOneWidget);
      expect(find.text('REGISTERED'), findsOneWidget);
      expect(find.text('SEASON PROGRESSION'), findsOneWidget);
      expect(find.text('1250 / 5000 CP'), findsOneWidget);
      if (size.width < 600) {
        await tester.drag(
            find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pump();
      }
      await tester.tap(find.ancestor(
          of: find.text('HYDERABAD'), matching: find.byType(InkWell)));
      expect(opened?.id, 'hyd');
      await tester.scrollUntilVisible(find.text('TOKYO'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('TOKYO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
