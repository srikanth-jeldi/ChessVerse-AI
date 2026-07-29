import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('shared rules distinguish stalemate from checkmate', () {
    final Map<String, ChessPiece> pieces = <String, ChessPiece>{
      'c6': const ChessPiece('K', true),
      'b6': const ChessPiece('Q', true),
      'a8': const ChessPiece('K', false),
    };

    expect(ChessRules.isKingInCheck(false, pieces), isFalse);
    expect(ChessRules.hasAnySafeMove(false, pieces), isFalse);
    expect(ChessRules.isStalemate(false, pieces), isTrue);
    expect(ChessRules.isCheckmate(false, pieces), isFalse);
  });

  testWidgets(
    'capture overlay owns both pieces until victim exits, then commits board',
    (WidgetTester tester) async {
      const ChessPiece attacker = ChessPiece('Q', true);
      const ChessPiece victim = ChessPiece('R', false);
      const BoardPalette palette = BoardPalette(
        label: 'Test',
        light: Color(0xFFE9D5B7),
        dark: Color(0xFF7A5035),
        frame: Color(0xFF4A2F20),
        accent: Color(0xFFFFD166),
      );

      Widget board({
        required Map<String, ChessPiece> pieces,
        required int sequence,
        String? from,
        String? to,
        ChessPiece? moved,
        ChessPiece? captured,
      }) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 400,
                child: ChessBoard(
                  pieces: pieces,
                  selectedSquare: null,
                  legalTargets: const <String>{},
                  lastFromSquare: from,
                  lastToSquare: to,
                  lastCaptureSquare: captured == null ? null : to,
                  lastMovedPiece: moved,
                  lastCapturedPiece: captured,
                  moveSequence: sequence,
                  checkedKingSquare: null,
                  decisiveSquare: null,
                  flipped: false,
                  showCoordinates: true,
                  palette: palette,
                  onSquareTap: (_) {},
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(
        board(
          pieces: const <String, ChessPiece>{
            'a1': attacker,
            'd5': victim,
          },
          sequence: 0,
        ),
      );

      await tester.pumpWidget(
        board(
          pieces: const <String, ChessPiece>{'d5': attacker},
          sequence: 1,
          from: 'a1',
          to: 'd5',
          moved: attacker,
          captured: victim,
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey<String>('d5-true-Q')), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('moving-piece-true-Q')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('captured-piece-false-R')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 560));

      expect(find.byKey(const ValueKey<String>('d5-true-Q')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('moving-piece-true-Q')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('captured-piece-false-R')),
        findsNothing,
      );
    },
  );

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
    expect(find.textContaining('Guest Player is local-only'), findsOneWidget);
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
      find.byKey(const ValueKey<String>('open-full-controls')),
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

  test('daily challenge rotates deterministically across seven days', () {
    final DateTime firstDay = DateTime(2026, 7, 28);
    final List<int> patterns = List<int>.generate(
      7,
      (int offset) =>
          dailyChallengePatternForDate(firstDay.add(Duration(days: offset))),
    );

    expect(patterns.toSet(), hasLength(7));
    expect(
      dailyChallengePatternForDate(firstDay.add(const Duration(days: 7))),
      patterns.first,
    );
    expect(dailyChallengeDateKey(firstDay), '2026-07-28');
  });

  testWidgets('daily challenge follows its forced line and starts 24h lock', (
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
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(find.text('0/4'), findsOneWidget);

    final List<(String, String)> playerMoves = <(String, String)>[
      ('a1', 'a2'),
      ('a2', 'a3'),
      ('a3', 'h3'),
      ('h3', 'h7'),
    ];
    for (int index = 0; index < playerMoves.length; index++) {
      final (String from, String to) = playerMoves[index];
      await tester.tap(find.byKey(ValueKey<String>('square-$from')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey<String>('square-$to')));
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        find.text('${index + 1}/4'),
        findsOneWidget,
        reason: 'Daily move $from$to should advance the forced line.',
      );
    }

    expect(find.text('Challenge complete'), findsOneWidget);
    expect(find.text('1 - 0'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(
      find.textContaining('Next challenge unlocks in 23 hours 59 minutes'),
      findsWidgets,
    );
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

  testWidgets('phone and web layouts agree on exact checkmate result', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final Size viewport in <Size>[
      const Size(430, 932),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            key: ValueKey<String>('game-${viewport.width}'),
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
      expect(find.text('Black wins'), findsOneWidget);
      expect(find.text('Checkmate'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
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
