import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/presentation/tournament_circuit_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'custom tournaments keep their names instead of index-based city names',
    () {
      for (var index = 0; index < 10; index++) {
        expect(
          CircuitTheme.forName('Blitz Warriors Members Cup', index).city,
          'Blitz Warriors Members Cup',
        );
        expect(
          CircuitTheme.forName('Blitz Warriors Members Cup', index).subtitle,
          isEmpty,
        );
      }
      expect(CircuitTheme.forName('Dubai Gold Open', 0).city, 'DUBAI');
    },
  );
  final tournaments = <TournamentDto>[
    const TournamentDto(
      id: 'cancelled-club',
      name: 'Cancelled club challenge',
      description: 'This must not appear as an upcoming city tournament.',
      minutes: 5,
      players: 0,
      capacity: 32,
      status: 'CANCELLED',
      joined: true,
      clubId: 'club-1',
    ),
    TournamentDto(
      id: 'hyd-finished',
      name: 'Hyderabad Royal Cup',
      description: 'Previous weekly cup.',
      minutes: 10,
      players: 64,
      capacity: 128,
      status: 'FINISHED',
      joined: true,
      startsAt: DateTime.now().subtract(const Duration(days: 2)),
      endsAt: DateTime.now().subtract(const Duration(days: 1)),
      champion: const TournamentPlayerDto('champion-1', 'Srikanth', null),
    ),
    TournamentDto(
      id: 'hyd-older',
      name: ' Hyderabad  Royal Cup ',
      description: 'Older edition with a previous winner.',
      minutes: 10,
      players: 12,
      capacity: 128,
      status: 'FINISHED',
      joined: true,
      startsAt: DateTime.now().subtract(const Duration(days: 6)),
      endsAt: DateTime.now().subtract(const Duration(days: 5)),
      champion: const TournamentPlayerDto('older', 'Older winner', null),
    ),
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
    testWidgets('world circuit adapts at ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TournamentDto? opened;
      await tester.pumpWidget(
        MaterialApp(
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
        ),
      );
      await tester.pump();

      expect(find.text('WORLD CHESS CIRCUIT'), findsOneWidget);
      expect(find.text('SEASON PROGRESSION'), findsOneWidget);
      expect(find.text("THIS WEEK'S CHAMPIONS"), findsOneWidget);
      expect(find.text('Srikanth'), findsOneWidget);
      expect(find.text('Older winner'), findsNothing);
      expect(find.text('Cancelled club challenge'), findsNothing);
      expect(find.text('1250 / 5000 CP'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('HYDERABAD'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('REGISTERED'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('HYDERABAD'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HYDERABAD'));
      expect(opened?.id, 'hyd');
      await tester.scrollUntilVisible(
        find.text('TOKYO'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('TOKYO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
