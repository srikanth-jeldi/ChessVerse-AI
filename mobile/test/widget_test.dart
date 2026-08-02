import 'package:chessverse_ai/main.dart';
import 'package:chessverse_ai/features/online/data/online_match_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeOnlineApi extends OnlineMatchApi {
  const _FakeOnlineApi({required this.active});

  final bool active;

  @override
  Future<OnlineMatchDto> randomMatch(String token) async => OnlineMatchDto(
        id: '11111111-1111-1111-1111-111111111111',
        roomCode: 'CVTEST',
        status: active ? 'ACTIVE' : 'WAITING',
        yourColor: 'WHITE',
        activeColor: 'WHITE',
        whitePlayerName: 'Srika',
        blackPlayerName: active ? 'Online Rival' : null,
        fen: '',
        moves: const <OnlineMoveDto>[],
      );

  @override
  Future<OnlineMatchDto> cancelWaiting(String token, String matchId) =>
      randomMatch(token);

  @override
  Future<OnlineMatchDto> getMatch(String token, String matchId) =>
      randomMatch(token);

  @override
  WebSocketChannel openMatchChannel(String token, String matchId) {
    throw StateError('Socket intentionally unavailable in widget test');
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('king squares are attacked but can never be captured', () {
    final Map<String, ChessPiece> pieces = <String, ChessPiece>{
      'a1': const ChessPiece('K', true),
      'e7': const ChessPiece('R', true),
      'e8': const ChessPiece('K', false),
    };

    expect(ChessRules.attacksSquare('e7', 'e8', pieces), isTrue);
    expect(ChessRules.safeLegalTargets('e7', pieces), isNot(contains('e8')));
  });

  test('a checked king with an escape is not checkmate', () {
    final Map<String, ChessPiece> pieces = <String, ChessPiece>{
      'e1': const ChessPiece('K', true),
      'e8': const ChessPiece('R', false),
      'a8': const ChessPiece('K', false),
    };

    expect(ChessRules.isKingInCheck(true, pieces), isTrue);
    expect(ChessRules.hasAnySafeMove(true, pieces), isTrue);
    expect(ChessRules.isCheckmate(true, pieces), isFalse);
  });

  test('shared rules identify a boxed back-rank checkmate', () {
    final Map<String, ChessPiece> pieces = <String, ChessPiece>{
      'f4': const ChessPiece('K', true),
      'a8': const ChessPiece('Q', true),
      'd3': const ChessPiece('B', true),
      'h8': const ChessPiece('K', false),
      'h7': const ChessPiece('P', false),
      'g7': const ChessPiece('P', false),
    };

    expect(ChessRules.isKingInCheck(false, pieces), isTrue);
    expect(ChessRules.hasAnySafeMove(false, pieces), isFalse);
    expect(ChessRules.isCheckmate(false, pieces), isTrue);
  });

  testWidgets('shows branded splash before onboarding and account access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChessVerseApp());

    expect(find.byKey(const ValueKey<String>('branded-splash-image')),
        findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Welcome to ChessVerse AI'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue as Guest Player'), findsOneWidget);
    expect(find.textContaining('secure numbered identity'), findsOneWidget);
  });

  testWidgets('registration and login actions remain available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChessVerseApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('User ID or email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Create ChessVerse ID'), findsOneWidget);
  });

  testWidgets('password reset validates email without an error screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChessVerseApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter your email first, then tap Forgot password.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches between computer and local players', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('game-controls-handle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 Players').last);
    await tester.pumpAndSettle();

    expect(find.text('Pass & Play'), findsOneWidget);
    expect(find.text('Player 2'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('rename-player-two')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('rename-player-two')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Anu');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Player 2: Anu'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('square-e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e4')));
    await tester.pump(const Duration(milliseconds: 600));

    final ChessBoard board = tester.widget<ChessBoard>(find.byType(ChessBoard));
    expect(board.flipped, isTrue);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is CustomPaint && widget.painter is LastMoveTrailPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('computer replies after a legal white move', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('square-e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e4')));
    await tester.pump(const Duration(milliseconds: 900));

    final GamePanel panel = tester.widget<GamePanel>(find.byType(GamePanel));
    expect(panel.moves, hasLength(2));
  });

  testWidgets('black player can move after starting a new game', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialSideChoice: PlayerSideChoice.black,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    GamePanel panel = tester.widget<GamePanel>(find.byType(GamePanel));
    expect(panel.moves, hasLength(1));

    final Finder newGameButton = find.byTooltip('New game');
    expect(newGameButton, findsOneWidget);
    await tester.tap(newGameButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    panel = tester.widget<GamePanel>(find.byType(GamePanel));
    expect(panel.moves, hasLength(1));

    await tester.tap(find.byKey(const ValueKey<String>('square-e7')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e5')));
    await tester.pump(const Duration(milliseconds: 900));

    panel = tester.widget<GamePanel>(find.byType(GamePanel));
    expect(panel.moves, hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone board remains layout-stable across consecutive moves', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: GameMode.local,
        ),
      ),
    );

    for (final (String from, String to) in <(String, String)>[
      ('e2', 'e4'),
      ('d7', 'd5'),
      ('e4', 'd5'),
      ('g8', 'f6'),
    ]) {
      await tester.tap(find.byKey(ValueKey<String>('square-$from')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey<String>('square-$to')));
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.takeException(), isNull);
    }

    tester.view.physicalSize = const Size(932, 430);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('landscape-game-layout')),
      findsOneWidget,
    );
    final Rect landscapeBoard = tester.getRect(find.byType(ChessBoard));
    final Rect landscapeControls = tester.getRect(
      find.byKey(const ValueKey<String>('landscape-game-controls')),
    );
    expect(landscapeBoard.right, lessThanOrEqualTo(landscapeControls.left));
    await tester.tap(
      find.byKey(const ValueKey<String>('game-controls-handle')),
    );
    await tester.pump();
    final Rect boardAfterControlsExpand =
        tester.getRect(find.byType(ChessBoard));
    expect(boardAfterControlsExpand, landscapeBoard);
    for (final (String from, String to) in <(String, String)>[
      ('g1', 'f3'),
      ('b8', 'c6'),
    ]) {
      await tester.tap(find.byKey(ValueKey<String>('square-$from')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey<String>('square-$to')));
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.takeException(), isNull);
    }

    tester.view.physicalSize = const Size(430, 932);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('portrait-game-layout')),
      findsOneWidget,
    );
    final Rect portraitBoard = tester.getRect(find.byType(ChessBoard));
    expect(portraitBoard.center.dx, closeTo(215, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily challenge follows the forced line and ends in checkmate', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('game-controls-handle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Checkmate').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Easy - 3-step finish').last);
    await tester.pumpAndSettle();

    expect(find.text('Daily Checkmate'), findsWidgets);
    expect(find.text('0/3 solved'), findsOneWidget);

    for (final (String from, String to) in <(String, String)>[
      ('f1', 'c4'),
      ('d1', 'h5'),
      ('h5', 'f7'),
    ]) {
      await tester.tap(find.byKey(ValueKey<String>('square-$from')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey<String>('square-$to')));
      await tester.pump(const Duration(milliseconds: 650));
    }

    expect(find.text('Challenge complete'), findsOneWidget);
    expect(find.text('3-move checkmate'), findsOneWidget);
  });

  testWidgets('phone layout prioritizes the playable board', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
    );

    final Size boardSize = tester.getSize(find.byType(ChessBoard));
    expect(boardSize.width, greaterThan(405));
    expect(boardSize.height, boardSize.width);
    expect(find.text('Solo Challenge'), findsOneWidget);

    final Finder panelFinder =
        find.byKey(const ValueKey<String>('game-controls-panel'));
    final double collapsedHeight = tester.getSize(panelFinder).height;
    await tester.tap(
      find.byKey(const ValueKey<String>('game-controls-handle')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final GamePanel expandedPanel =
        tester.widget<GamePanel>(find.byType(GamePanel));
    expect(expandedPanel.expanded, isTrue);
    final double expandedHeight = tester.getSize(panelFinder).height;
    expect(expandedHeight, collapsedHeight);
    expect(
      tester.getBottomRight(panelFinder).dy,
      closeTo(tester.view.physicalSize.height, 1),
    );
  });

  testWidgets('compact phone keeps coach actions visible without overlap', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: GameMode.local,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('square-b1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-c3')));
    await tester.pump(const Duration(milliseconds: 500));

    for (final String label in <String>['Hint', 'Threat', 'Try again']) {
      final Finder action = find.text(label);
      expect(action, findsOneWidget);
      expect(
        tester.getBottomRight(action).dy,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('online lobby shows animated searching state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnlineMatchmakingSheet(
            api: _FakeOnlineApi(active: false),
            token: 'test-token',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Find random player'));
    await tester.pump();

    expect(find.text('FINDING YOUR RIVAL'), findsOneWidget);
    expect(find.text('Searching worldwide players...'), findsOneWidget);
    expect(find.text('Cancel search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('random search stops after twenty seconds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnlineMatchmakingSheet(
            api: _FakeOnlineApi(active: false),
            token: 'test-token',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Find random player'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    await tester.pump();

    expect(find.text('FINDING YOUR RIVAL'), findsNothing);
    expect(find.textContaining('No active rival found'), findsOneWidget);
    expect(find.text('Find random player'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('online lobby reveals versus cards before opening board', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnlineMatchmakingSheet(
            api: _FakeOnlineApi(active: true),
            token: 'test-token',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Find random player'));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('OPPONENT FOUND'), findsOneWidget);
    expect(find.text('VS'), findsOneWidget);
    expect(find.text('Srika'), findsOneWidget);
    expect(find.text('Online Rival'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkmate marks the checked king square and shows the winner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('game-controls-handle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 Players').last);
    await tester.pumpAndSettle();

    for (final (String from, String to) in <(String, String)>[
      ('f2', 'f3'),
      ('e7', 'e5'),
      ('g2', 'g4'),
      ('d8', 'h4'),
    ]) {
      await tester.tap(find.byKey(ValueKey<String>('square-$from')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey<String>('square-$to')));
      await tester.pump();
    }

    final BoardSquare checkedKing = tester.widget<BoardSquare>(
      find.byKey(const ValueKey<String>('square-e1')),
    );
    expect(checkedKing.checkedKing, isTrue);
    expect(find.text('Black wins'), findsOneWidget);
    expect(find.text('Checkmate'), findsOneWidget);
  });

  testWidgets('analysis opens a useful position report', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('game-controls-handle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analyze'));
    await tester.pumpAndSettle();

    expect(find.text('Position analysis'), findsOneWidget);
    expect(find.text('Evaluation'), findsOneWidget);
    expect(find.text('White legal moves'), findsOneWidget);
    expect(find.textContaining('Recommended:'), findsOneWidget);
  });
}
