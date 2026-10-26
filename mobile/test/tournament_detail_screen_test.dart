import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
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
          true,
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
          true,
        ),
        TournamentPairingDto(
          2,
          TournamentPlayerDto('p4', 'Srikanth', null),
          null,
          null,
          TournamentPlayerDto('p4', 'Srikanth', null),
          'BYE',
          true,
        ),
      ]),
    ],
  );

  testWidgets(
    'refresh never auto-opens and a pairing can be resumed repeatedly',
    (tester) async {
      var opens = 0;
      var routeClosed = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: TournamentDetailScreen(
            id: 'hyd',
            token: 'test',
            api: _TournamentApi(detail),
            onOpenMatch: (_) async {
              opens++;
              await routeClosed.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 16));
      expect(opens, 0);
      await tester.tap(find.text('Enter / Resume game').first);
      await tester.pump();
      expect(opens, 1);
      await tester.tap(find.text('Enter / Resume game').first);
      await tester.pump();
      expect(opens, 1);
      routeClosed.complete();
      await tester.pumpAndSettle();
      routeClosed = Completer<void>();
      await tester.tap(find.text('Enter / Resume game').first);
      await tester.pump();
      expect(opens, 2);
      routeClosed.complete();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('entry and resume cards fit all 34 languages with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manifest = (await tester.runAsync(
      () => AssetManifest.loadFromAssetBundle(rootBundle),
    ))!;
    final paths = manifest.listAssets().where(
      (p) => p.startsWith('assets/i18n/ui/') && p.endsWith('.json'),
    );
    expect(paths.length, 34);
    for (final path in paths) {
      final code = path.split('/').last.split('.').first;
      await tester.runAsync(() => UiCopy.load(code));
      final copy = jsonDecode(
        (await tester.runAsync(() => rootBundle.loadString(path)))!,
      ) as Map;
      expect(copy['Starts at {0} (your local time)'], contains('{0}'));
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: {'ar', 'fa', 'ur', 'he'}.contains(code)
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
              child: Scaffold(
                body: TournamentDetailContent(
                  detail: detail,
                  busy: false,
                  onToggle: () async {},
                  onRefresh: () async {},
                  onOpenMatch: (_) async {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: code);
    }
    await tester.runAsync(() => UiCopy.load('en'));
  });

  for (final size in <Size>[const Size(390, 844), const Size(1100, 900)]) {
    testWidgets('tournament detail adapts at ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var toggles = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TournamentDetailContent(
              detail: detail,
              busy: false,
              onToggle: () async => toggles++,
              onRefresh: () async {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('HYDERABAD'), findsOneWidget);
      expect(
        find.bySemanticsLabel('HYDERABAD championship trophy'),
        findsWidgets,
      );
      await tester.scrollUntilVisible(
        find.text('HOW TO PLAY'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('HOW TO PLAY'), findsOneWidget);
      expect(find.text('OFFICIAL TOURNAMENT RULES'), findsOneWidget);
      expect(find.text('+100 CP'), findsOneWidget);
      expect(find.text('+250 CP'), findsOneWidget);
      expect(find.text('+1000 CP'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('TOURNAMENT BRACKET'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('TOURNAMENT BRACKET'), findsOneWidget);
      expect(find.text('OPENING ROUND'), findsOneWidget);
      expect(find.text('QUARTERFINAL'), findsOneWidget);
      expect(find.text('Arjun'), findsNWidgets(3));
      expect(find.text('BYE · Advances automatically'), findsOneWidget);
      expect(find.text('TBD'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(toggles, 0);
    });
  }
}

class _TournamentApi extends CommunityApi {
  const _TournamentApi(this.detail);
  final TournamentDetailDto detail;
  @override
  Future<TournamentDetailDto> tournamentDetail(String token, String id) async =>
      detail;
}
