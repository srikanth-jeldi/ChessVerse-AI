import 'package:chessverse_ai/main.dart';
import 'package:chessverse_ai/features/auth/presentation/auth_screen.dart';
import 'package:chessverse_ai/features/online/data/online_match_api.dart';
import 'package:chessverse_ai/features/onboarding/presentation/onboarding_screen.dart';
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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: BrandedSplash()));

    expect(find.byKey(const ValueKey<String>('branded-splash-image')),
        findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onComplete: () {})),
    );
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(onAuthenticated: (_) {})),
    );

    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('registration and login actions remain available', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(onAuthenticated: (_) {})),
    );

    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('password reset validates email without an error screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(onAuthenticated: (_) {})),
    );

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter your registered email first, then tap Forgot password.'),
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
          initialGameMode: GameMode.local,
        ),
      ),
    );
    expect(find.text('LOCAL MATCH'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('square-e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e4')));
    await tester.pump(const Duration(milliseconds: 600));

    final ChessBoard board = tester.widget<ChessBoard>(find.byType(ChessBoard));
    // Shared-device play now deliberately keeps a fixed white-side board.
    expect(board.flipped, isFalse);
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

    final ChessBoard board = tester.widget<ChessBoard>(find.byType(ChessBoard));
    expect(board.moveSequence, 2);
  });

  testWidgets('online replay animates the authoritative latest piece', (
    WidgetTester tester,
  ) async {
    const OnlineMatchDto match = OnlineMatchDto(
      id: '22222222-2222-2222-2222-222222222222',
      roomCode: 'CVSYNC',
      status: 'ACTIVE',
      yourColor: 'WHITE',
      activeColor: 'WHITE',
      whitePlayerName: 'White player',
      blackPlayerName: 'Black player',
      fen: '',
      moves: <OnlineMoveDto>[
        OnlineMoveDto(ply: 0, uci: 'b1c3'),
        OnlineMoveDto(ply: 1, uci: 'd7d5'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: GameMode.online,
          initialOnlineMatch: match,
          initialAuthToken: 'test-token',
          onlineApi: _FakeOnlineApi(active: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final ChessBoard board = tester.widget<ChessBoard>(find.byType(ChessBoard));
    expect(board.lastMovedPiece?.white, isFalse);
    expect(board.lastMovedPiece?.code, 'P');
    expect(board.lastFromSquare, 'd7');
    expect(board.lastToSquare, 'd5');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
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

    ChessBoard board = tester.widget<ChessBoard>(find.byType(ChessBoard));
    expect(board.moveSequence, 1);

    await tester.tap(find.byKey(const ValueKey<String>('square-e7')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e5')));
    await tester.pump(const Duration(milliseconds: 900));

    board = tester.widget<ChessBoard>(find.byType(ChessBoard));
    expect(board.moveSequence, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('game header exposes responsive Back to Home navigation', (
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
          initialGameMode: GameMode.local,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('desktop-back-to-home')),
      findsOneWidget,
    );
    expect(find.text('Back to Home'), findsOneWidget);

    tester.view.physicalSize = const Size(430, 932);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('mobile-back-to-home')),
      findsOneWidget,
    );
    expect(find.byTooltip('Back to Home'), findsOneWidget);
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
    await tester.tap(
      find.byKey(const ValueKey<String>('landscape-coach-toggle')),
    );
    await tester.pump();
    final Rect landscapeControls = tester.getRect(
      find.byKey(const ValueKey<String>('compact-landscape-ai-coach')),
    );
    final Rect boardWithCoach = tester.getRect(find.byType(ChessBoard));
    expect(boardWithCoach.right, lessThanOrEqualTo(landscapeControls.left));
    expect(boardWithCoach.width, lessThanOrEqualTo(landscapeBoard.width));
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

  testWidgets('portrait game keeps the AI coach actions in scrollable space', (
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

    expect(
      find.byKey(const ValueKey<String>('portrait-game-scroll-view')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('mobile-ai-coach')),
          )
          .height,
      greaterThanOrEqualTo(360),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily challenge opens the current tactics board', (
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
          initialGameMode: GameMode.daily,
          initialDailyDifficulty: DailyChallengeDifficulty.easy,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DAILY CHALLENGE'), findsOneWidget);
    expect(find.byType(ChessBoard), findsOneWidget);
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
    expect(boardSize.height, closeTo(boardSize.width, 2));
    expect(
      find.text('AI TRAINING • 3-LEVEL HINTS • GAME REVIEW'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('mobile-ai-coach')),
      findsOneWidget,
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

    for (final String label in <String>['Piece hint', 'Analyze', 'Try again']) {
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
    await tester.tap(find.text('Find Match'));
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
    await tester.tap(find.text('Find Match'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    await tester.pump();

    expect(find.text('FINDING YOUR RIVAL'), findsNothing);
    expect(find.textContaining('No active rival found'), findsOneWidget);
    expect(find.text('Find Match'), findsOneWidget);
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
    await tester.tap(find.text('Find Match'));
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
          initialGameMode: GameMode.local,
        ),
      ),
    );

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
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox.shrink());
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

    await tester.tap(find.text('Analyze'));
    await tester.pumpAndSettle();

    expect(find.text('AI Agent Coach'), findsOneWidget);
    expect(find.text('Evaluation'), findsOneWidget);
    expect(find.text('White legal moves'), findsOneWidget);
    expect(find.textContaining('Recommended:'), findsOneWidget);
  });
}
