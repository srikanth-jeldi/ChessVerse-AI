import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
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
