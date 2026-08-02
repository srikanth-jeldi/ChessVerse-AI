import 'package:chessverse_ai/features/online/data/online_match_api.dart';
import 'package:chessverse_ai/features/online/presentation/match_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('online replay navigates through every authoritative move', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const OnlineMatchDto match = OnlineMatchDto(
      id: 'history-1',
      roomCode: 'CVTEST',
      status: 'FINISHED',
      yourColor: 'WHITE',
      activeColor: 'WHITE',
      whitePlayerName: 'You',
      blackPlayerName: 'Opponent',
      fen: '',
      result: '1-0',
      resultReason: 'CHECKMATE',
      durationSeconds: 95,
      moves: <OnlineMoveDto>[
        OnlineMoveDto(ply: 0, uci: 'e2e4'),
        OnlineMoveDto(ply: 1, uci: 'e7e5'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: OnlineMatchReplayScreen(match: match)),
    );
    await tester.pump();

    expect(find.text('Starting position'), findsOneWidget);
    expect(find.textContaining('1m 35s'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pump();
    expect(find.textContaining('Move 1 of 2: e2e4'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pump();
    expect(find.textContaining('Move 2 of 2: e7e5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
