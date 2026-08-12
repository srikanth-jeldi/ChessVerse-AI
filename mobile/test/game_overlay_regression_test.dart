import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GameSnapshot snapshotWithPly(int ply) => GameSnapshot(
        pieces: const <String, ChessPiece>{},
        moves: List<String>.filled(ply, 'move'),
        capturedWhite: const <ChessPiece>[],
        capturedBlack: const <ChessPiece>[],
        coachNote: 'test',
        lastFromSquare: null,
        lastToSquare: null,
        lastCaptureSquare: null,
        whiteSeconds: 600,
        blackSeconds: 600,
      );

  test('computer undo always restores the latest human-turn snapshot', () {
    final List<GameSnapshot> aiThinkingHistory = <GameSnapshot>[
      snapshotWithPly(0),
      snapshotWithPly(1),
      snapshotWithPly(2),
    ];
    expect(
      computerUndoSnapshotIndex(
        aiThinkingHistory,
        humanPlaysWhite: true,
      ),
      2,
    );

    final List<GameSnapshot> afterAiReplyHistory = <GameSnapshot>[
      ...aiThinkingHistory,
      snapshotWithPly(3),
    ];
    expect(
      computerUndoSnapshotIndex(
        afterAiReplyHistory,
        humanPlaysWhite: true,
      ),
      2,
    );
    expect(
      computerUndoSnapshotIndex(
        <GameSnapshot>[
          snapshotWithPly(0),
          snapshotWithPly(1),
          snapshotWithPly(2),
        ],
        humanPlaysWhite: false,
      ),
      1,
    );
    expect(
      computerUndoSnapshotIndex(
        <GameSnapshot>[snapshotWithPly(0)],
        humanPlaysWhite: false,
      ),
      -1,
    );
  });

  testWidgets('turn reminder is text-only and has no popup subtitle',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(initiallySignedIn: true, useRemoteEngine: false),
      ),
    );
    await tester.pump();

    expect(find.text('YOUR TURN'), findsOneWidget);
    expect(find.textContaining('You play'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('prominent-turn-banner')),
      findsOneWidget,
    );
  });

  testWidgets('coach recommendation suppresses the previous-move arrow',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChessBoard(
            pieces: const <String, ChessPiece>{
              'e4': ChessPiece('P', true),
              'f6': ChessPiece('N', false),
            },
            selectedSquare: null,
            legalTargets: const <String>{},
            lastFromSquare: 'e2',
            lastToSquare: 'e4',
            lastCaptureSquare: null,
            moveSequence: 2,
            checkedKingSquare: null,
            decisiveSquare: null,
            coachArrowFrom: 'g8',
            coachArrowTo: 'f6',
            flipped: false,
            showCoordinates: true,
            palette: boardPalettes[BoardSkin.royalWalnut]!,
            onSquareTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final Iterable<CustomPaint> arrowPaints = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((CustomPaint paint) => paint.painter is LastMoveTrailPainter);
    expect(arrowPaints, hasLength(1));
    final LastMoveTrailPainter painter =
        arrowPaints.single.painter! as LastMoveTrailPainter;
    expect(painter.from, 'g8');
    expect(painter.to, 'f6');
  });

  testWidgets('latest move arrow remains visible after its entrance animation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChessBoard(
            pieces: const <String, ChessPiece>{
              'e4': ChessPiece('P', true),
            },
            selectedSquare: null,
            legalTargets: const <String>{},
            lastFromSquare: 'e2',
            lastToSquare: 'e4',
            lastCaptureSquare: null,
            moveSequence: 1,
            checkedKingSquare: null,
            decisiveSquare: null,
            coachArrowFrom: null,
            coachArrowTo: null,
            flipped: false,
            showCoordinates: true,
            palette: boardPalettes[BoardSkin.royalWalnut]!,
            onSquareTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    final LastMoveTrailPainter painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((CustomPaint paint) => paint.painter)
        .whereType<LastMoveTrailPainter>()
        .single;
    expect(painter.from, 'e2');
    expect(painter.to, 'e4');
    expect(painter.progress, 1);
    expect(painter.fadeOut, isFalse);
  });

  testWidgets('losing king falls and victory title zooms over fireworks',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: <Widget>[
            ChessBoard(
              pieces: const <String, ChessPiece>{
                'e1': ChessPiece('K', true),
                'e8': ChessPiece('K', false),
              },
              selectedSquare: null,
              legalTargets: const <String>{},
              lastFromSquare: 'h5',
              lastToSquare: 'e8',
              lastCaptureSquare: null,
              moveSequence: 12,
              checkedKingSquare: 'e8',
              decisiveSquare: 'e8',
              fallenKingSquare: 'e8',
              coachArrowFrom: null,
              coachArrowTo: null,
              flipped: false,
              showCoordinates: true,
              palette: boardPalettes[BoardSkin.royalWalnut]!,
              onSquareTap: (_) {},
            ),
            const OnlineVictoryCelebration(
              winnerAtTop: true,
              title: 'You win',
            ),
          ]),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey<String>('king-fall-e8-true')),
        findsOneWidget);
    expect(find.text('YOU WIN'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
