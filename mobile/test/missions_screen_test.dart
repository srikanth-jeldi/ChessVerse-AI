import 'package:chessverse_ai/features/missions/data/mission_api.dart';
import 'package:chessverse_ai/features/missions/presentation/missions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMissionApi extends MissionApi {
  _FakeMissionApi(this.board);
  MissionBoard board;
  int claims = 0;

  @override
  Future<MissionBoard> load(String token) async => board;

  @override
  Future<MissionBoard> claim(String token, String code) async {
    claims++;
    board = MissionBoard(
      daily: <PlayerMission>[
        PlayerMission(
          code: 'DAILY_PLAY',
          cadence: 'DAILY',
          title: 'server title',
          description: 'server description',
          progress: 1,
          target: 1,
          rewardCoins: 25,
          completed: true,
          claimed: true,
          resetsAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      ],
      weekly: const <PlayerMission>[],
    );
    return board;
  }
}

void main() {
  testWidgets('mission board localizes server codes and claims once', (
    WidgetTester tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'settings.language': 'en',
    });
    final _FakeMissionApi api = _FakeMissionApi(
      MissionBoard(
        daily: <PlayerMission>[
          PlayerMission(
            code: 'DAILY_PLAY',
            cadence: 'DAILY',
            title: 'server title',
            description: 'server description',
            progress: 1,
            target: 1,
            rewardCoins: 25,
            completed: true,
            claimed: false,
            resetsAt: DateTime.now().add(const Duration(hours: 2)),
          ),
        ],
        weekly: const <PlayerMission>[],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MissionsScreen(token: 'token', api: api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make your move'), findsOneWidget);
    expect(find.text('server title'), findsNothing);
    expect(find.textContaining('Resets in'), findsOneWidget);
    await tester.tap(find.text('CLAIM REWARD'));
    await tester.pumpAndSettle();
    expect(api.claims, 1);
    expect(find.text('CLAIMED'), findsOneWidget);
    expect(find.text('25 coins added to your wallet.'), findsOneWidget);
  });
}
