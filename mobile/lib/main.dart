import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/app_config.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_session_store.dart';
import 'features/engine/data/engine_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );
  AppConfig.validate();
  runApp(const ChessVerseApp());
}

class ChessVerseApp extends StatelessWidget {
  const ChessVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessVerse AI',
      debugShowCheckedModeBanner: false,
      theme: ChessVerseTheme.dark(),
      home: const SplashGate(),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  Timer? _timer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showSplash
          ? const BrandedSplash(key: ValueKey<String>('splash'))
          : const GameScreen(
              key: ValueKey<String>('game'),
              initiallySignedIn: AppConfig.arenaPreview,
            ),
    );
  }
}

class BrandedSplash extends StatelessWidget {
  const BrandedSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02070D),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth > constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image(
                key: const ValueKey<String>('branded-splash-image'),
                image: AssetImage(
                  wide
                      ? 'assets/branding/splash_screen_wide.png'
                      : 'assets/branding/splash_screen_mobile.png',
                ),
                fit: BoxFit.contain,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0x12000000),
                      Color(0x00000000),
                      Color(0x66000000),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChessVerseTheme {
  static ThemeData dark() {
    const ink = Color(0xFF101014);
    const brass = Color(0xFFD6A84F);
    const mint = Color(0xFF63D2B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: brass,
        secondary: mint,
        surface: Color(0xFF1A1B20),
        onSurface: Color(0xFFF6F1E8),
      ),
      scaffoldBackgroundColor: ink,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Color(0xFFF6F1E8),
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFF6F1E8),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFE6D8BC),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFC8C1B6),
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brass,
          foregroundColor: ink,
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF6F1E8),
          side: const BorderSide(color: Color(0xFF61553F)),
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFF6F1E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

enum BoardSkin { royalWalnut, jadeGlass, tournament, marble, sapphire }

enum GameMode { computer, daily, local, online }

enum DailyChallengeDifficulty { easy, medium, hard }

extension DailyChallengeDifficultyDetails on DailyChallengeDifficulty {
  String get label => switch (this) {
        DailyChallengeDifficulty.easy => 'Easy · 3 moves',
        DailyChallengeDifficulty.medium => 'Medium · 4 moves',
        DailyChallengeDifficulty.hard => 'Hard · 5 moves',
      };

  int get prefixPlyCount => switch (this) {
        DailyChallengeDifficulty.easy => 4,
        DailyChallengeDifficulty.medium => 2,
        DailyChallengeDifficulty.hard => 0,
      };
}

class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.setupMoves,
    required this.solution,
  });

  final String id;
  final String title;
  final DailyChallengeDifficulty difficulty;
  final List<String> setupMoves;
  final List<String> solution;

  int get playerMoveGoal => (solution.length + 1) ~/ 2;
}

class AiProfile {
  const AiProfile(this.name, this.elo, this.description);

  final String name;
  final int elo;
  final String description;
}

AiProfile aiProfileFor(int level) {
  return switch (level.clamp(1, 10)) {
    1 => const AiProfile('Beginner', 1320, 'Beatable, short calculation'),
    2 => const AiProfile('Learner', 1400, 'Basic tactics and development'),
    3 => const AiProfile('Casual', 1500, 'Punishes simple mistakes'),
    4 => const AiProfile('Intermediate', 1600, 'Plans two ideas ahead'),
    5 => const AiProfile('Club', 1750, 'Solid positional play'),
    6 => const AiProfile('Advanced', 1900, 'Finds tactical combinations'),
    7 => const AiProfile('Expert', 2100, 'Deep calculation and defense'),
    8 => const AiProfile('Candidate Master', 2300, 'Tournament strength'),
    9 => const AiProfile('Master', 2600, 'Elite engine pressure'),
    _ => const AiProfile('Grandmaster', 3000, 'Maximum challenge'),
  };
}

class AiCandidate {
  const AiCandidate(this.from, this.to, this.score);

  final String from;
  final String to;
  final double score;
}

class PositionAnalysis {
  const PositionAnalysis({
    required this.side,
    required this.evaluation,
    required this.material,
    required this.legalMoves,
    required this.captures,
    required this.bestMove,
    required this.inCheck,
  });

  final String side;
  final double evaluation;
  final int material;
  final int legalMoves;
  final int captures;
  final String? bestMove;
  final bool inCheck;
}

class BoardPalette {
  const BoardPalette({
    required this.label,
    required this.light,
    required this.dark,
    required this.frame,
    required this.accent,
  });

  final String label;
  final Color light;
  final Color dark;
  final Color frame;
  final Color accent;
}

const Map<BoardSkin, BoardPalette> boardPalettes = <BoardSkin, BoardPalette>{
  BoardSkin.royalWalnut: BoardPalette(
    label: 'Walnut',
    light: Color(0xFFE9D5B7),
    dark: Color(0xFF7A4F2A),
    frame: Color(0xFF342113),
    accent: Color(0xFFD6A84F),
  ),
  BoardSkin.jadeGlass: BoardPalette(
    label: 'Jade',
    light: Color(0xFFD8EEE1),
    dark: Color(0xFF2F7D66),
    frame: Color(0xFF12372E),
    accent: Color(0xFF63D2B8),
  ),
  BoardSkin.tournament: BoardPalette(
    label: 'Classic',
    light: Color(0xFFF0D9B5),
    dark: Color(0xFFB58863),
    frame: Color(0xFF30251E),
    accent: Color(0xFFE2B458),
  ),
  BoardSkin.marble: BoardPalette(
    label: 'Marble',
    light: Color(0xFFF2F0EA),
    dark: Color(0xFF667078),
    frame: Color(0xFF252A2D),
    accent: Color(0xFFB9E4EE),
  ),
  BoardSkin.sapphire: BoardPalette(
    label: 'Sapphire',
    light: Color(0xFFDCE7EA),
    dark: Color(0xFF28546A),
    frame: Color(0xFF142B35),
    accent: Color(0xFF60D6D0),
  ),
};

class ChessPiece {
  const ChessPiece(this.code, this.white);

  final String code;
  final bool white;
}

class GameSnapshot {
  const GameSnapshot({
    required this.pieces,
    required this.moves,
    required this.capturedWhite,
    required this.capturedBlack,
    required this.coachNote,
    required this.lastFromSquare,
    required this.lastToSquare,
    required this.lastCaptureSquare,
    required this.whiteSeconds,
    required this.blackSeconds,
  });

  final Map<String, ChessPiece> pieces;
  final List<String> moves;
  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;
  final String coachNote;
  final String? lastFromSquare;
  final String? lastToSquare;
  final String? lastCaptureSquare;
  final int whiteSeconds;
  final int blackSeconds;
}

class ParsedMove {
  const ParsedMove(this.from, this.to);

  final String from;
  final String to;
}

class SquarePosition {
  const SquarePosition(this.file, this.rank);

  final int file;
  final int rank;
}

class ChessRules {
  static SquarePosition positionOf(String square) {
    return SquarePosition(square.codeUnitAt(0) - 97, int.parse(square[1]));
  }

  static String squareOf(int file, int rank) {
    return '${String.fromCharCode(97 + file)}$rank';
  }

  static bool isInside(int file, int rank) {
    return file >= 0 && file < 8 && rank >= 1 && rank <= 8;
  }

  static List<String> legalTargets(
    String from,
    Map<String, ChessPiece> pieces,
  ) {
    return pseudoLegalTargets(from, pieces);
  }

  static List<String> safeLegalTargets(
    String from,
    Map<String, ChessPiece> pieces,
  ) {
    final ChessPiece? piece = pieces[from];
    if (piece == null) {
      return <String>[];
    }

    return pseudoLegalTargets(from, pieces).where((String target) {
      final Map<String, ChessPiece> next = applyMove(from, target, pieces);
      return !isKingInCheck(piece.white, next);
    }).toList();
  }

  static List<String> pseudoLegalTargets(
    String from,
    Map<String, ChessPiece> pieces,
  ) {
    final ChessPiece? piece = pieces[from];
    if (piece == null) {
      return <String>[];
    }

    return switch (piece.code) {
      'P' => _pawnTargets(from, piece, pieces),
      'N' => _jumpTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 2),
          SquarePosition(2, 1),
          SquarePosition(2, -1),
          SquarePosition(1, -2),
          SquarePosition(-1, -2),
          SquarePosition(-2, -1),
          SquarePosition(-2, 1),
          SquarePosition(-1, 2),
        ]),
      'B' => _rayTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 1),
          SquarePosition(1, -1),
          SquarePosition(-1, 1),
          SquarePosition(-1, -1),
        ]),
      'R' => _rayTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 0),
          SquarePosition(-1, 0),
          SquarePosition(0, 1),
          SquarePosition(0, -1),
        ]),
      'Q' => _rayTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 0),
          SquarePosition(-1, 0),
          SquarePosition(0, 1),
          SquarePosition(0, -1),
          SquarePosition(1, 1),
          SquarePosition(1, -1),
          SquarePosition(-1, 1),
          SquarePosition(-1, -1),
        ]),
      'K' => _jumpTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 0),
          SquarePosition(-1, 0),
          SquarePosition(0, 1),
          SquarePosition(0, -1),
          SquarePosition(1, 1),
          SquarePosition(1, -1),
          SquarePosition(-1, 1),
          SquarePosition(-1, -1),
        ]),
      _ => <String>[],
    };
  }

  static bool hasAnySafeMove(bool white, Map<String, ChessPiece> pieces) {
    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white == white &&
          safeLegalTargets(entry.key, pieces).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static bool isKingInCheck(bool white, Map<String, ChessPiece> pieces) {
    String? kingSquare;
    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white == white && entry.value.code == 'K') {
        kingSquare = entry.key;
        break;
      }
    }
    if (kingSquare == null) {
      return false;
    }

    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white != white &&
          attacksSquare(entry.key, kingSquare, pieces)) {
        return true;
      }
    }
    return false;
  }

  static bool attacksSquare(
    String from,
    String target,
    Map<String, ChessPiece> pieces,
  ) {
    final ChessPiece? piece = pieces[from];
    if (piece == null) {
      return false;
    }

    if (piece.code == 'P') {
      final SquarePosition origin = positionOf(from);
      final SquarePosition attacked = positionOf(target);
      final int direction = piece.white ? 1 : -1;
      return attacked.rank == origin.rank + direction &&
          (attacked.file - origin.file).abs() == 1;
    }

    return pseudoLegalTargets(from, pieces).contains(target);
  }

  static Map<String, ChessPiece> applyMove(
    String from,
    String target,
    Map<String, ChessPiece> pieces,
  ) {
    final Map<String, ChessPiece> next = Map<String, ChessPiece>.from(pieces);
    final ChessPiece? piece = next.remove(from);
    if (piece != null) {
      next[target] = piece;
    }
    return next;
  }

  static List<String> _pawnTargets(
    String from,
    ChessPiece piece,
    Map<String, ChessPiece> pieces,
  ) {
    final SquarePosition origin = positionOf(from);
    final int direction = piece.white ? 1 : -1;
    final int startRank = piece.white ? 2 : 7;
    final List<String> targets = <String>[];
    final int oneRank = origin.rank + direction;

    if (isInside(origin.file, oneRank)) {
      final String oneStep = squareOf(origin.file, oneRank);
      if (!pieces.containsKey(oneStep)) {
        targets.add(oneStep);

        final int twoRank = origin.rank + direction * 2;
        final String twoStep = squareOf(origin.file, twoRank);
        if (origin.rank == startRank &&
            isInside(origin.file, twoRank) &&
            !pieces.containsKey(twoStep)) {
          targets.add(twoStep);
        }
      }
    }

    for (final int fileDelta in <int>[-1, 1]) {
      final int targetFile = origin.file + fileDelta;
      final int targetRank = origin.rank + direction;
      if (!isInside(targetFile, targetRank)) {
        continue;
      }
      final String target = squareOf(targetFile, targetRank);
      final ChessPiece? occupant = pieces[target];
      if (occupant != null && occupant.white != piece.white) {
        targets.add(target);
      }
    }

    return targets;
  }

  static List<String> _jumpTargets(
    String from,
    ChessPiece piece,
    Map<String, ChessPiece> pieces,
    List<SquarePosition> deltas,
  ) {
    final SquarePosition origin = positionOf(from);
    final List<String> targets = <String>[];

    for (final SquarePosition delta in deltas) {
      final int file = origin.file + delta.file;
      final int rank = origin.rank + delta.rank;
      if (!isInside(file, rank)) {
        continue;
      }
      final String target = squareOf(file, rank);
      final ChessPiece? occupant = pieces[target];
      if (occupant == null || occupant.white != piece.white) {
        targets.add(target);
      }
    }

    return targets;
  }

  static List<String> _rayTargets(
    String from,
    ChessPiece piece,
    Map<String, ChessPiece> pieces,
    List<SquarePosition> directions,
  ) {
    final SquarePosition origin = positionOf(from);
    final List<String> targets = <String>[];

    for (final SquarePosition direction in directions) {
      int file = origin.file + direction.file;
      int rank = origin.rank + direction.rank;

      while (isInside(file, rank)) {
        final String target = squareOf(file, rank);
        final ChessPiece? occupant = pieces[target];
        if (occupant == null) {
          targets.add(target);
        } else {
          if (occupant.white != piece.white) {
            targets.add(target);
          }
          break;
        }
        file += direction.file;
        rank += direction.rank;
      }
    }

    return targets;
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    this.initiallySignedIn = false,
    this.useRemoteEngine = true,
    super.key,
  });

  final bool initiallySignedIn;
  final bool useRemoteEngine;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const AuthApi _authApi = AuthApi();
  static const AuthSessionStore _sessionStore = AuthSessionStore();
  static const EngineApi _engineApi = EngineApi();
  final math.Random _random = math.Random();
  AudioPlayer? _warningPlayer;
  final List<String> _moves = <String>[];
  final List<ChessPiece> _capturedWhite = <ChessPiece>[];
  final List<ChessPiece> _capturedBlack = <ChessPiece>[];
  final List<GameSnapshot> _history = <GameSnapshot>[];
  Timer? _clockTimer;
  String? _selectedSquare;
  String? _lastFromSquare;
  String? _lastToSquare;
  String? _lastCaptureSquare;
  String _coachNote = 'Select a coin to see legal moves.';
  BoardSkin _skin = BoardSkin.royalWalnut;
  GameMode _gameMode = GameMode.computer;
  double _aiLevel = 4;
  bool _aiThinking = false;
  bool _coachEnabled = true;
  int _whiteSeconds = 10 * 60;
  int _blackSeconds = 10 * 60;
  bool _signedIn = false;
  String? _authToken;
  bool _awaitingCode = false;
  bool _authLoading = false;
  bool _authHasError = false;
  bool _registerMode = true;
  String _authUsername = '';
  String _authDisplayName = '';
  String _authIdentity = '';
  String _authPassword = '';
  String _authCode = '';
  String _authMessage =
      'Create an account to save games, ratings and coach history.';
  String _whitePlayerName = 'Guest Player';
  String _blackPlayerName = 'ChessVerse AI';
  String? _gameResultTitle;
  String? _gameResultDetail;
  bool _resultVisible = true;
  bool _checkWarningActive = false;
  bool _controlsExpanded = false;
  DailyChallengeDifficulty _dailyDifficulty = DailyChallengeDifficulty.medium;
  late DailyChallenge _dailyChallenge;
  int _dailyPlyIndex = 0;
  int _dailyMistakes = 0;

  static const Map<String, ChessPiece> _initialPieces = <String, ChessPiece>{
    'a8': ChessPiece('R', false),
    'b8': ChessPiece('N', false),
    'c8': ChessPiece('B', false),
    'd8': ChessPiece('Q', false),
    'e8': ChessPiece('K', false),
    'f8': ChessPiece('B', false),
    'g8': ChessPiece('N', false),
    'h8': ChessPiece('R', false),
    'a7': ChessPiece('P', false),
    'b7': ChessPiece('P', false),
    'c7': ChessPiece('P', false),
    'd7': ChessPiece('P', false),
    'e7': ChessPiece('P', false),
    'f7': ChessPiece('P', false),
    'g7': ChessPiece('P', false),
    'h7': ChessPiece('P', false),
    'a2': ChessPiece('P', true),
    'b2': ChessPiece('P', true),
    'c2': ChessPiece('P', true),
    'd2': ChessPiece('P', true),
    'e2': ChessPiece('P', true),
    'f2': ChessPiece('P', true),
    'g2': ChessPiece('P', true),
    'h2': ChessPiece('P', true),
    'a1': ChessPiece('R', true),
    'b1': ChessPiece('N', true),
    'c1': ChessPiece('B', true),
    'd1': ChessPiece('Q', true),
    'e1': ChessPiece('K', true),
    'f1': ChessPiece('B', true),
    'g1': ChessPiece('N', true),
    'h1': ChessPiece('R', true),
  };

  late Map<String, ChessPiece> _pieces =
      Map<String, ChessPiece>.from(_initialPieces);

  @override
  void initState() {
    super.initState();
    _dailyChallenge = _challengeForToday(_dailyDifficulty);
    _signedIn = widget.initiallySignedIn;
    if (widget.initiallySignedIn) {
      _whitePlayerName = 'Preview Player';
    }
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _moves.isEmpty || _gameResultTitle != null) {
        return;
      }
      setState(() {
        if (_moves.length.isEven) {
          _whiteSeconds = math.max(0, _whiteSeconds - 1);
        } else {
          _blackSeconds = math.max(0, _blackSeconds - 1);
        }
        if (_whiteSeconds == 0 || _blackSeconds == 0) {
          _gameResultTitle = _whiteSeconds == 0 ? 'Black wins' : 'White wins';
          _gameResultDetail = 'Victory on time';
          _resultVisible = true;
          _coachNote = '$_gameResultTitle. $_gameResultDetail.';
        }
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    final AudioPlayer? warningPlayer = _warningPlayer;
    if (warningPlayer != null) {
      unawaited(warningPlayer.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BoardPalette palette = boardPalettes[_skin]!;
    final bool sideToMoveWhite = _moves.length.isEven;
    final bool sideInCheck = ChessRules.isKingInCheck(sideToMoveWhite, _pieces);
    final String? checkedKingSquare =
        sideInCheck ? _kingSquare(sideToMoveWhite) : null;
    final Set<String> legalTargets = _selectedSquare == null
        ? <String>{}
        : _legalTargetsFor(_selectedSquare!).toSet();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF193128),
          image: DecorationImage(
            image: const AssetImage(
              'assets/backgrounds/grandmaster-table-v1.webp',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              const Color(0xFF10251E).withValues(alpha: 0.28),
              BlendMode.multiply,
            ),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool landscape =
                  constraints.maxWidth > constraints.maxHeight;
              final bool wide = constraints.maxWidth >= 980 ||
                  (landscape && constraints.maxWidth >= 700);
              const EdgeInsets pagePadding = EdgeInsets.zero;
              final double availableHeight =
                  constraints.maxHeight - pagePadding.vertical;
              final double mobileHeaderHeight = wide ? 0 : 58;
              final double widePanelWidth = _controlsExpanded
                  ? math.min(
                      340,
                      math.max(320, constraints.maxWidth * 0.26),
                    )
                  : 84;
              const double portraitPanelMinimum = 190;
              final double boardDimension = math.min(
                wide
                    ? constraints.maxWidth -
                        pagePadding.horizontal -
                        widePanelWidth -
                        10
                    : constraints.maxWidth - pagePadding.horizontal,
                math.max(
                  260,
                  wide
                      ? availableHeight
                      : availableHeight -
                          mobileHeaderHeight -
                          portraitPanelMinimum -
                          18,
                ),
              );

              final Widget board = ChessBoard(
                pieces: _pieces,
                selectedSquare: _selectedSquare,
                legalTargets: legalTargets,
                lastFromSquare: _lastFromSquare,
                lastToSquare: _lastToSquare,
                lastCaptureSquare: _lastCaptureSquare,
                checkedKingSquare: checkedKingSquare,
                decisiveSquare:
                    _gameResultDetail == 'Checkmate' ? _lastToSquare : null,
                flipped: _gameMode == GameMode.local && !sideToMoveWhite,
                palette: palette,
                onSquareTap: _handleSquareTap,
              );

              final Widget panel = GamePanel(
                compact: !wide ||
                    constraints.maxHeight < 620 ||
                    widePanelWidth < 340,
                collapsible: true,
                expanded: _controlsExpanded,
                whitePlayerName: _whitePlayerName,
                blackPlayerName: _blackPlayerName,
                activeColor: _moves.length.isEven ? 'White' : 'Black',
                gameMode: _gameMode,
                aiLevel: _aiLevel.round(),
                aiThinking: _aiThinking,
                coachEnabled: _coachEnabled,
                moves: _moves,
                capturedWhite: _capturedWhite,
                capturedBlack: _capturedBlack,
                coachNote: _coachNote,
                whiteClock: _formatClock(_whiteSeconds),
                blackClock: _formatClock(_blackSeconds),
                skin: _skin,
                onSkinChanged: (BoardSkin skin) => setState(() => _skin = skin),
                onGameModeChanged: _changeGameMode,
                dailyDifficulty: _dailyDifficulty,
                dailyProgress: _dailyPlayerMovesCompleted,
                dailyGoal: _dailyChallenge.playerMoveGoal,
                dailyMistakes: _dailyMistakes,
                onDailyDifficultyChanged: _changeDailyDifficulty,
                onAiLevelChanged: (double level) {
                  setState(() => _aiLevel = level);
                },
                onCoachChanged: (bool value) {
                  setState(() => _coachEnabled = value);
                },
                onReset: _reset,
                onUndo: _undo,
                onHint: _showHint,
                onAnalyze: _showAnalysis,
                onEditBlackPlayer: _editBlackPlayerName,
                onToggleExpanded: () {
                  setState(() => _controlsExpanded = !_controlsExpanded);
                },
                onLogout: _logout,
                canUndo: _history.isNotEmpty,
              );

              return Padding(
                padding: pagePadding,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (wide)
                      Center(
                        child: SizedBox(
                          width: boardDimension + widePanelWidth + 10,
                          height: boardDimension,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              SizedBox(
                                width: boardDimension,
                                height: boardDimension,
                                child: BoardStage(
                                  palette: palette,
                                  child: board,
                                ),
                              ),
                              const SizedBox(width: 10),
                              AnimatedContainer(
                                key: const ValueKey<String>(
                                  'landscape-game-controls',
                                ),
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                                width: widePanelWidth,
                                child: panel,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: <Widget>[
                          CompactHeader(
                            playerName: _whitePlayerName,
                            onReset: _reset,
                            onLogout: _logout,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: boardDimension,
                            height: boardDimension,
                            child: BoardStage(
                              palette: palette,
                              child: board,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            key: const ValueKey<String>('game-controls-panel'),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: SizedBox.expand(
                                key: ValueKey<bool>(_controlsExpanded),
                                child: panel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (!_signedIn)
                      Positioned.fill(
                        child: AuthOverlay(
                          registerMode: _registerMode,
                          awaitingCode: _awaitingCode,
                          message: _authMessage,
                          hasError: _authHasError,
                          onModeChanged: _setAuthMode,
                          onUsernameChanged: (String value) {
                            _authUsername = value.trim();
                          },
                          onDisplayNameChanged: (String value) {
                            _authDisplayName = value.trim();
                          },
                          onIdentityChanged: (String value) {
                            _authIdentity = value.trim();
                          },
                          onPasswordChanged: (String value) {
                            _authPassword = value;
                          },
                          onCodeChanged: (String value) {
                            _authCode = value.trim();
                          },
                          onSubmit: _submitAuth,
                          onContinueDefault: _continueAsDefaultPlayer,
                          onFacebookLogin: _showFacebookSetupMessage,
                          onForgotPassword: _showPasswordResetDialog,
                          onResendCode: _resendVerificationCode,
                          onBackFromCode: () => setState(() {
                            _awaitingCode = false;
                            _authCode = '';
                            _authMessage =
                                'Update your details or request a new code.';
                          }),
                          loading: _authLoading,
                        ),
                      ),
                    if (_signedIn && _gameResultTitle != null && _resultVisible)
                      Positioned.fill(
                        child: GameResultOverlay(
                          title: _gameResultTitle!,
                          detail: _gameResultDetail ?? 'Game complete',
                          onNewGame: _reset,
                          onReview: () => setState(() {
                            _resultVisible = false;
                          }),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _setAuthMode(bool registerMode) {
    setState(() {
      _registerMode = registerMode;
      _awaitingCode = false;
      _authHasError = false;
      _authMessage = registerMode
          ? 'Create an account to save games, ratings and coach history.'
          : 'Welcome back. Sign in with your user id and password.';
    });
  }

  void _continueAsDefaultPlayer() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _authToken = null;
      _whitePlayerName = 'Guest Player';
      _signedIn = true;
      _authLoading = false;
      _authHasError = false;
      _awaitingCode = false;
      _coachNote =
          'Guest Player mode is ready. Create an account later to save progress.';
    });
  }

  void _showFacebookSetupMessage() {
    setState(() {
      _authHasError = false;
      _authMessage =
          'Facebook login needs Meta app credentials, package SHA setup, iOS bundle setup, privacy policy, and data deletion URL before store release. ChessVerse login and Guest Player work now.';
    });
  }

  Future<void> _resendVerificationCode() async {
    if (_authLoading || _authIdentity.isEmpty) {
      return;
    }
    setState(() {
      _authLoading = true;
      _authHasError = false;
      _authMessage = 'Requesting a new verification code...';
    });
    try {
      final Map<String, dynamic> response = await _authApi.post(
        'resend-verification',
        <String, String>{'email': _authIdentity},
      );
      if (!mounted) return;
      final String baseMessage =
          response['message'] as String? ?? 'A new code has been sent.';
      final String? developmentCode = response['developmentCode'] as String?;
      setState(() {
        _authMessage = developmentCode == null
            ? baseMessage
            : '$baseMessage Local test code: $developmentCode';
      });
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _authHasError = true;
          _authMessage = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _authLoading = false);
      }
    }
  }

  Future<void> _showPasswordResetDialog() async {
    final TextEditingController emailController = TextEditingController(
        text: _authIdentity.contains('@') ? _authIdentity : '');
    final TextEditingController codeController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool codeSent = false;
        bool loading = false;
        bool hasError = false;
        String message =
            'Enter your verified email to receive a password reset code.';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> submit() async {
              final String email = emailController.text.trim();
              final String code = codeController.text.trim();
              final String password = passwordController.text;
              if (email.isEmpty ||
                  (codeSent &&
                      (!RegExp(r'^\d{6}$').hasMatch(code) ||
                          password.length < 8))) {
                setDialogState(() {
                  hasError = true;
                  message = codeSent
                      ? 'Enter the six-digit code and an 8+ character password.'
                      : 'Enter your verified email address.';
                });
                return;
              }

              setDialogState(() {
                loading = true;
                hasError = false;
                message = codeSent
                    ? 'Updating your password...'
                    : 'Sending a secure reset code...';
              });
              try {
                final Map<String, dynamic> response = await _authApi.post(
                  codeSent ? 'password/reset' : 'password/forgot',
                  codeSent
                      ? <String, String>{
                          'email': email,
                          'code': code,
                          'newPassword': password,
                        }
                      : <String, String>{'email': email},
                );
                if (!dialogContext.mounted) return;
                if (codeSent) {
                  Navigator.of(dialogContext).pop();
                  if (!mounted) return;
                  setState(() {
                    _registerMode = false;
                    _awaitingCode = false;
                    _authIdentity = email;
                    _authHasError = false;
                    _authMessage =
                        'Password updated. Sign in with your new password.';
                  });
                } else {
                  final String baseMessage = response['message'] as String? ??
                      'If the account exists, a reset code was sent.';
                  final String? developmentCode =
                      response['developmentCode'] as String?;
                  setDialogState(() {
                    codeSent = true;
                    message = developmentCode == null
                        ? baseMessage
                        : '$baseMessage Local test code: $developmentCode';
                  });
                }
              } on AuthApiException catch (error) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    hasError = true;
                    message = error.message;
                  });
                }
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => loading = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Reset password'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(message),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        enabled: !codeSent && !loading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Verified email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (codeSent) ...<Widget>[
                        const SizedBox(height: 12),
                        TextField(
                          controller: codeController,
                          enabled: !loading,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Six-digit reset code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: passwordController,
                          enabled: !loading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'New password',
                            helperText: 'At least 8 characters',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (hasError) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          message,
                          style: const TextStyle(color: Color(0xFFFF7774)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: Text(codeSent ? 'Update password' : 'Send reset code'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitAuth() async {
    if (_authLoading) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (_registerMode &&
        !_awaitingCode &&
        (_authUsername.isEmpty ||
            _authDisplayName.isEmpty ||
            _authIdentity.isEmpty ||
            _authPassword.length < 8)) {
      setState(() {
        _authHasError = true;
        _authMessage =
            'Enter a user id, display name, valid email and an 8+ character password.';
      });
      return;
    }
    if (_awaitingCode && !RegExp(r'^\d{6}$').hasMatch(_authCode)) {
      setState(() {
        _authHasError = true;
        _authMessage = 'Enter the six-digit code sent to your email.';
      });
      return;
    }
    if (!_registerMode && (_authIdentity.isEmpty || _authPassword.isEmpty)) {
      setState(() {
        _authHasError = true;
        _authMessage = 'Enter your user id and password.';
      });
      return;
    }

    setState(() {
      _authLoading = true;
      _authHasError = false;
      _authMessage = _awaitingCode
          ? 'Verifying your code...'
          : _registerMode
              ? 'Sending a secure verification code...'
              : 'Signing you in...';
    });

    try {
      if (_registerMode && !_awaitingCode) {
        final Map<String, dynamic> response = await _authApi.post(
          'register',
          <String, String>{
            'username': _authUsername,
            'displayName': _authDisplayName,
            'email': _authIdentity,
            'password': _authPassword,
          },
        );
        if (!mounted) return;
        setState(() {
          _awaitingCode = true;
          _authHasError = false;
          final String baseMessage = response['message'] as String? ??
              'Verification code sent. Check your inbox.';
          final String? developmentCode =
              response['developmentCode'] as String?;
          _authMessage = developmentCode == null
              ? baseMessage
              : '$baseMessage Local test code: $developmentCode';
        });
      } else if (_awaitingCode) {
        final Map<String, dynamic> response = await _authApi.post(
          'verify-email',
          <String, String>{
            'email': _authIdentity,
            'code': _authCode,
          },
        );
        if (!mounted) return;
        await _completeLogin(response);
      } else {
        final Map<String, dynamic> response = await _authApi.post(
          'login',
          <String, String>{
            'identity': _authIdentity,
            'password': _authPassword,
          },
        );
        if (!mounted) return;
        await _completeLogin(response);
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _authHasError = true;
          _authMessage = switch (error.message) {
            'That user id is already taken.' =>
              'User ID "$_authUsername" is already taken. Choose another User ID or select Login.',
            _ => error.message,
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() => _authLoading = false);
      }
    }
  }

  Future<void> _completeLogin(Map<String, dynamic> response) async {
    final String token = response['token'] as String? ?? '';
    final DateTime? expiresAt =
        DateTime.tryParse(response['expiresAt'] as String? ?? '');
    final Map<String, dynamic>? player =
        response['player'] as Map<String, dynamic>?;
    final String displayName =
        player?['displayName'] as String? ?? _authIdentity;
    if (token.isEmpty || expiresAt == null) {
      throw const AuthApiException('The server returned an invalid session.');
    }

    await _sessionStore.write(
      StoredAuthSession(
        token: token,
        expiresAt: expiresAt,
        displayName: displayName,
      ),
    );
    if (!mounted) return;
    setState(() {
      _authToken = token;
      _whitePlayerName = displayName;
      _signedIn = true;
      _awaitingCode = false;
      _authHasError = false;
      _authCode = '';
      _authPassword = '';
      _coachNote = 'Welcome $displayName. Your game is ready.';
    });
  }

  Future<void> _logout() async {
    final String? token = _authToken;
    if (token != null) {
      await _authApi.logout(token);
    }
    await _sessionStore.clear();
    if (!mounted) return;
    setState(() {
      _authToken = null;
      _signedIn = false;
      _registerMode = false;
      _awaitingCode = false;
      _authHasError = false;
      _authIdentity = '';
      _authPassword = '';
      _authMessage = 'Session closed securely. Sign in to continue.';
      _whitePlayerName = 'Player';
    });
  }

  void _changeGameMode(GameMode mode) {
    if (mode == GameMode.online) {
      _showOnlineMatchmakingInfo();
      return;
    }
    setState(() {
      _gameMode = mode;
      _blackPlayerName = switch (mode) {
        GameMode.computer => 'ChessVerse AI',
        GameMode.daily => 'Puzzle Defense',
        _ => 'Player 2',
      };
    });
    _reset();
  }

  void _changeDailyDifficulty(DailyChallengeDifficulty difficulty) {
    setState(() => _dailyDifficulty = difficulty);
    _reset();
  }

  int get _dailyPlayerMovesCompleted => (_dailyPlyIndex + 1) ~/ 2;

  DailyChallenge _challengeForToday(
    DailyChallengeDifficulty difficulty,
  ) {
    final DateTime today = DateTime.now().toUtc();
    final int dayNumber = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(2026))
        .inDays;
    final List<List<String>> quietOpenings = <List<String>>[
      <String>['a2a3', 'a7a6'],
      <String>['h2h3', 'h7h6'],
      <String>['b2b3', 'b7b6'],
    ];
    final List<String> fullLine = <String>[
      ...quietOpenings[dayNumber.abs() % quietOpenings.length],
      'e2e4',
      'e7e5',
      'f1c4',
      'b8c6',
      'd1h5',
      'g8f6',
      'h5f7',
    ];
    final int prefix = difficulty.prefixPlyCount;
    final String date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return DailyChallenge(
      id: '$date-${difficulty.name}',
      title: 'Royal Net · ${difficulty.label}',
      difficulty: difficulty,
      setupMoves: fullLine.take(prefix).toList(growable: false),
      solution: fullLine.skip(prefix).toList(growable: false),
    );
  }

  Map<String, ChessPiece> _dailyStartingPosition(DailyChallenge challenge) {
    Map<String, ChessPiece> position =
        Map<String, ChessPiece>.from(_initialPieces);
    for (final String move in challenge.setupMoves) {
      position = ChessRules.applyMove(
        move.substring(0, 2),
        move.substring(2, 4),
        position,
      );
    }
    return position;
  }

  Future<void> _editBlackPlayerName() async {
    String candidate = _blackPlayerName;
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Rename Player 2'),
        content: TextFormField(
          initialValue: candidate,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          onChanged: (String value) => candidate = value,
          decoration: const InputDecoration(
            labelText: 'Player name',
            prefixIcon: Icon(Icons.manage_accounts_outlined),
            border: OutlineInputBorder(),
          ),
          onFieldSubmitted: (String value) {
            final String clean = value.trim();
            if (clean.isNotEmpty) {
              Navigator.of(context).pop(clean);
            }
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final String clean = candidate.trim();
              if (clean.isNotEmpty) {
                Navigator.of(context).pop(clean);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && mounted) {
      setState(() => _blackPlayerName = name);
    }
  }

  void _handleSquareTap(String square) {
    if (_gameResultTitle != null || _aiThinking) {
      return;
    }
    String? promotionSquare;
    bool? promotionWhite;
    bool moveCommitted = false;

    setState(() {
      final bool whitesTurn = _moves.length.isEven;
      if (_gameMode == GameMode.computer && !whitesTurn) {
        _coachNote = 'ChessVerse AI is calculating its reply.';
        return;
      }
      if (_selectedSquare == null) {
        final ChessPiece? piece = _pieces[square];
        if (piece == null) {
          _coachNote = 'Choose one of your coins first.';
          return;
        }
        if (piece.white != whitesTurn) {
          _coachNote = '${whitesTurn ? 'White' : 'Black'} to move.';
          return;
        }
        final List<String> targets = _legalTargetsFor(square);
        if (targets.isEmpty) {
          _coachNote = '${piece.code} has no legal target from $square.';
        } else {
          _selectedSquare = square;
          final String suffix = targets.length == 1 ? '' : 's';
          _coachNote =
              '${piece.code} from $square has ${targets.length} option$suffix.';
        }
        return;
      }

      if (_selectedSquare == square) {
        _selectedSquare = null;
        return;
      }

      final List<String> legalTargets = _legalTargetsFor(_selectedSquare!);
      if (!legalTargets.contains(square)) {
        _coachNote = 'That move is blocked. Pick a highlighted square.';
        _selectedSquare = null;
        return;
      }

      final String from = _selectedSquare!;
      if (_gameMode == GameMode.daily) {
        final String expected = _dailyChallenge.solution[_dailyPlyIndex];
        if ('$from$square' != expected) {
          _dailyMistakes++;
          _coachNote =
              'Not the mating line. Try again — the position is unchanged.';
          _selectedSquare = null;
          return;
        }
      }
      _saveSnapshot();
      _lastFromSquare = from;
      _lastToSquare = square;
      _lastCaptureSquare = null;
      final bool castleMove = _isCastleMove(from, square);
      final String? enPassantCaptureSquare =
          _enPassantCaptureSquare(from, square);
      final ChessPiece? piece = _pieces.remove(from);
      if (piece != null) {
        final ChessPiece? captured = enPassantCaptureSquare == null
            ? _pieces[square]
            : _pieces.remove(enPassantCaptureSquare);
        if (captured != null) {
          if (captured.white) {
            _capturedWhite.add(captured);
          } else {
            _capturedBlack.add(captured);
          }
          _lastCaptureSquare = square;
        }
        _pieces[square] = piece;
        moveCommitted = true;
        if (castleMove) {
          _moveCastlingRook(square, piece.white);
        }
        final String move = castleMove
            ? (square.startsWith('g') ? 'O-O' : 'O-O-O')
            : enPassantCaptureSquare != null
                ? '$from x $square e.p.'
                : captured == null
                    ? '$from$square'
                    : '$from x $square';
        _moves.insert(0, move);
        if (_gameMode == GameMode.daily) {
          _dailyPlyIndex++;
        }
        _coachNote = castleMove
            ? '${piece.white ? 'White' : 'Black'} castles ${square.startsWith('g') ? 'king side' : 'queen side'}.'
            : captured == null
                ? '${piece.code} moves to $square.'
                : '${piece.code} captures ${captured.code} on $square.';
        if (piece.code == 'P' &&
            ((piece.white && square.endsWith('8')) ||
                (!piece.white && square.endsWith('1')))) {
          promotionSquare = square;
          promotionWhite = piece.white;
          _coachNote = 'Choose a promotion coin for $square.';
        } else {
          _coachNote = _gameStateNote(!piece.white, fallback: _coachNote);
          if (_gameMode == GameMode.daily && _gameResultDetail == 'Checkmate') {
            _gameResultTitle = 'Challenge complete';
            _gameResultDetail =
                '${_dailyChallenge.playerMoveGoal}-move checkmate';
            _coachNote =
                'Brilliant! Today’s ${_dailyDifficulty.label.toLowerCase()} challenge is complete.';
          }
        }
      }
      _selectedSquare = null;
    });

    if (promotionSquare != null && promotionWhite != null) {
      _showPromotionPicker(
        promotionSquare!,
        promotionWhite!,
      ).then((_) => _scheduleAiMove());
    } else if (moveCommitted) {
      _scheduleAiMove();
    }
  }

  String? _kingSquare(bool white) {
    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.code == 'K' && entry.value.white == white) {
        return entry.key;
      }
    }
    return null;
  }

  void _scheduleAiMove() {
    if (_gameMode == GameMode.daily) {
      _scheduleDailyReply();
      return;
    }
    if (_gameMode != GameMode.computer ||
        _moves.length.isEven ||
        _gameResultTitle != null ||
        _aiThinking) {
      return;
    }

    setState(() {
      _aiThinking = true;
      _selectedSquare = null;
      _coachNote =
          '${aiProfileFor(_aiLevel.round()).name} AI is calculating...';
    });
    Future<void>.delayed(const Duration(milliseconds: 650), _performAiMove);
  }

  void _scheduleDailyReply() {
    if (_dailyPlyIndex >= _dailyChallenge.solution.length ||
        _dailyPlyIndex.isEven ||
        _gameResultTitle != null ||
        _aiThinking) {
      return;
    }
    setState(() {
      _aiThinking = true;
      _selectedSquare = null;
      _coachNote = 'Puzzle defense is replying…';
    });
    Future<void>.delayed(
      const Duration(milliseconds: 520),
      _performDailyReply,
    );
  }

  void _performDailyReply() {
    if (!mounted ||
        _gameMode != GameMode.daily ||
        !_aiThinking ||
        _dailyPlyIndex >= _dailyChallenge.solution.length) {
      return;
    }
    final String uci = _dailyChallenge.solution[_dailyPlyIndex];
    final String from = uci.substring(0, 2);
    final String to = uci.substring(2, 4);
    if (_pieces[from]?.white != false || !_legalTargetsFor(from).contains(to)) {
      setState(() {
        _aiThinking = false;
        _coachNote = 'This daily puzzle could not continue. Reset and retry.';
      });
      return;
    }

    setState(() {
      _saveSnapshot();
      _lastFromSquare = from;
      _lastToSquare = to;
      _lastCaptureSquare = null;
      final ChessPiece piece = _pieces.remove(from)!;
      final ChessPiece? captured = _pieces[to];
      if (captured != null) {
        captured.white
            ? _capturedWhite.add(captured)
            : _capturedBlack.add(captured);
        _lastCaptureSquare = to;
      }
      _pieces[to] = piece;
      _moves.insert(0, captured == null ? '$from$to' : '$from x $to');
      _dailyPlyIndex++;
      _aiThinking = false;
      _coachNote = _gameStateNote(
        true,
        fallback:
            '${_dailyChallenge.playerMoveGoal - _dailyPlayerMovesCompleted} winning move(s) remain.',
      );
    });
  }

  Future<void> _performAiMove() async {
    if (!mounted ||
        _gameMode != GameMode.computer ||
        _gameResultTitle != null ||
        !_aiThinking ||
        _moves.length.isEven) {
      return;
    }

    AiCandidate? engineMove;
    if (widget.useRemoteEngine) {
      try {
        final Map<String, dynamic> response = await _engineApi.bestMove(
          fen: _toFen(),
          level: _aiLevel.round(),
        );
        final String uci = response['move'] as String? ?? '';
        if (uci.length >= 4) {
          final String from = uci.substring(0, 2);
          final String to = uci.substring(2, 4);
          if (_pieces[from]?.white == false &&
              _legalTargetsFor(from).contains(to)) {
            engineMove = AiCandidate(from, to, 1000);
          }
        }
      } on EngineApiException {
        // The deterministic local fallback keeps offline games playable.
      }
    }

    if (!mounted ||
        _gameMode != GameMode.computer ||
        _gameResultTitle != null ||
        !_aiThinking ||
        _moves.length.isEven) {
      return;
    }

    final List<AiCandidate> candidates = <AiCandidate>[];
    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white) {
        continue;
      }
      for (final String target in _legalTargetsFor(entry.key)) {
        final ChessPiece? captured = _pieces[target];
        final SquarePosition targetPosition = ChessRules.positionOf(target);
        final double centerBonus = 3.5 -
            (targetPosition.file - 3.5).abs() +
            3.5 -
            (targetPosition.rank - 4.5).abs();
        final double captureScore = captured == null
            ? 0
            : <String, double>{
                  'P': 1,
                  'N': 3.2,
                  'B': 3.3,
                  'R': 5,
                  'Q': 9,
                  'K': 100,
                }[captured.code] ??
                0;
        candidates.add(
          AiCandidate(
            entry.key,
            target,
            captureScore * 10 + centerBonus + _random.nextDouble(),
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      setState(() {
        _aiThinking = false;
        _coachNote = _gameStateNote(
          false,
          fallback: 'ChessVerse AI has no legal move.',
        );
      });
      return;
    }

    candidates.sort(
      (AiCandidate a, AiCandidate b) => b.score.compareTo(a.score),
    );
    final int level = _aiLevel.round();
    final int poolSize = math.min(
      candidates.length,
      math.max(1, ((11 - level) / 2).ceil()),
    );
    final AiCandidate move =
        engineMove ?? candidates[_random.nextInt(poolSize)];
    final bool stockfishPowered = engineMove != null;

    setState(() {
      _saveSnapshot();
      _lastFromSquare = move.from;
      _lastToSquare = move.to;
      _lastCaptureSquare = null;
      final bool castleMove = _isCastleMove(move.from, move.to);
      final String? enPassantCaptureSquare =
          _enPassantCaptureSquare(move.from, move.to);
      final ChessPiece piece = _pieces.remove(move.from)!;
      final ChessPiece? captured = enPassantCaptureSquare == null
          ? _pieces[move.to]
          : _pieces.remove(enPassantCaptureSquare);
      if (captured != null) {
        captured.white
            ? _capturedWhite.add(captured)
            : _capturedBlack.add(captured);
        _lastCaptureSquare = move.to;
      }
      _pieces[move.to] = piece;
      if (castleMove) {
        _moveCastlingRook(move.to, false);
      }
      if (piece.code == 'P' && move.to.endsWith('1')) {
        _pieces[move.to] = const ChessPiece('Q', false);
      }
      final String notation = castleMove
          ? (move.to.startsWith('g') ? 'O-O' : 'O-O-O')
          : captured == null
              ? '${move.from}${move.to}'
              : '${move.from} x ${move.to}';
      _moves.insert(0, notation);
      final String action = captured == null
          ? '${piece.code} moves to ${move.to}.'
          : '${piece.code} captures ${captured.code} on ${move.to}.';
      _coachNote = _gameStateNote(
        true,
        fallback: '${stockfishPowered ? 'Stockfish' : 'Offline AI'}: $action',
      );
      _aiThinking = false;
    });
  }

  String _toFen() {
    final List<String> ranks = <String>[];
    for (int rank = 8; rank >= 1; rank--) {
      int empty = 0;
      final StringBuffer row = StringBuffer();
      for (int file = 0; file < 8; file++) {
        final String square = '${String.fromCharCode(97 + file)}$rank';
        final ChessPiece? piece = _pieces[square];
        if (piece == null) {
          empty++;
          continue;
        }
        if (empty > 0) {
          row.write(empty);
          empty = 0;
        }
        row.write(piece.white ? piece.code : piece.code.toLowerCase());
      }
      if (empty > 0) {
        row.write(empty);
      }
      ranks.add(row.toString());
    }

    final String side = _moves.length.isEven ? 'w' : 'b';
    final String castling = _fenCastlingRights();
    final String enPassant = _fenEnPassantSquare();
    final int fullMove = _moves.length ~/ 2 + 1;
    return '${ranks.join('/')} $side $castling $enPassant 0 $fullMove';
  }

  String _fenCastlingRights() {
    final StringBuffer rights = StringBuffer();
    if (_pieces['e1']?.code == 'K' &&
        _pieces['e1']?.white == true &&
        !_hasMovedFrom('e1')) {
      if (_pieces['h1']?.code == 'R' &&
          _pieces['h1']?.white == true &&
          !_hasMovedFrom('h1')) {
        rights.write('K');
      }
      if (_pieces['a1']?.code == 'R' &&
          _pieces['a1']?.white == true &&
          !_hasMovedFrom('a1')) {
        rights.write('Q');
      }
    }
    if (_pieces['e8']?.code == 'K' &&
        _pieces['e8']?.white == false &&
        !_hasMovedFrom('e8')) {
      if (_pieces['h8']?.code == 'R' &&
          _pieces['h8']?.white == false &&
          !_hasMovedFrom('h8')) {
        rights.write('k');
      }
      if (_pieces['a8']?.code == 'R' &&
          _pieces['a8']?.white == false &&
          !_hasMovedFrom('a8')) {
        rights.write('q');
      }
    }
    return rights.isEmpty ? '-' : rights.toString();
  }

  String _fenEnPassantSquare() {
    if (_moves.isEmpty) {
      return '-';
    }
    final ParsedMove? last = _parseMove(_moves.first);
    if (last == null || _pieces[last.to]?.code != 'P') {
      return '-';
    }
    final int fromRank = int.parse(last.from.substring(1));
    final int toRank = int.parse(last.to.substring(1));
    if ((fromRank - toRank).abs() != 2) {
      return '-';
    }
    return '${last.to.substring(0, 1)}${(fromRank + toRank) ~/ 2}';
  }

  List<String> _legalTargetsFor(String square) {
    final ChessPiece? piece = _pieces[square];
    if (piece == null) {
      return <String>[];
    }

    final Set<String> targets =
        ChessRules.safeLegalTargets(square, _pieces).toSet();
    targets.addAll(_castlingTargets(square, piece));
    targets.addAll(_enPassantTargets(square, piece));
    return targets.toList();
  }

  List<String> _castlingTargets(String from, ChessPiece piece) {
    if (piece.code != 'K' || _hasMovedFrom(from)) {
      return <String>[];
    }

    final String rank = piece.white ? '1' : '8';
    if (from != 'e$rank' || ChessRules.isKingInCheck(piece.white, _pieces)) {
      return <String>[];
    }

    final List<String> targets = <String>[];
    if (_canCastle(
      white: piece.white,
      rookFrom: 'h$rank',
      emptySquares: <String>['f$rank', 'g$rank'],
      kingPath: <String>['f$rank', 'g$rank'],
    )) {
      targets.add('g$rank');
    }
    if (_canCastle(
      white: piece.white,
      rookFrom: 'a$rank',
      emptySquares: <String>['b$rank', 'c$rank', 'd$rank'],
      kingPath: <String>['d$rank', 'c$rank'],
    )) {
      targets.add('c$rank');
    }

    return targets;
  }

  bool _canCastle({
    required bool white,
    required String rookFrom,
    required List<String> emptySquares,
    required List<String> kingPath,
  }) {
    final ChessPiece? rook = _pieces[rookFrom];
    if (rook == null ||
        rook.code != 'R' ||
        rook.white != white ||
        _hasMovedFrom(rookFrom)) {
      return false;
    }

    for (final String square in emptySquares) {
      if (_pieces.containsKey(square)) {
        return false;
      }
    }

    for (final String square in kingPath) {
      final Map<String, ChessPiece> next =
          ChessRules.applyMove(white ? 'e1' : 'e8', square, _pieces);
      if (ChessRules.isKingInCheck(white, next)) {
        return false;
      }
    }
    return true;
  }

  List<String> _enPassantTargets(String from, ChessPiece piece) {
    if (piece.code != 'P' || _moves.isEmpty) {
      return <String>[];
    }

    final ParsedMove? lastMove = _parseMove(_moves.first);
    if (lastMove == null) {
      return <String>[];
    }

    final ChessPiece? movedPiece = _pieces[lastMove.to];
    if (movedPiece == null ||
        movedPiece.code != 'P' ||
        movedPiece.white == piece.white) {
      return <String>[];
    }

    final SquarePosition fromPosition = ChessRules.positionOf(lastMove.from);
    final SquarePosition toPosition = ChessRules.positionOf(lastMove.to);
    if ((fromPosition.rank - toPosition.rank).abs() != 2) {
      return <String>[];
    }

    final SquarePosition pawnPosition = ChessRules.positionOf(from);
    final int requiredRank = piece.white ? 5 : 4;
    if (pawnPosition.rank != requiredRank ||
        (pawnPosition.file - toPosition.file).abs() != 1 ||
        pawnPosition.rank != toPosition.rank) {
      return <String>[];
    }

    final String target = ChessRules.squareOf(
      toPosition.file,
      pawnPosition.rank + (piece.white ? 1 : -1),
    );
    final Map<String, ChessPiece> next = Map<String, ChessPiece>.from(_pieces)
      ..remove(from)
      ..remove(lastMove.to);
    next[target] = piece;

    return ChessRules.isKingInCheck(piece.white, next)
        ? <String>[]
        : <String>[target];
  }

  bool _isCastleMove(String from, String to) {
    final ChessPiece? piece = _pieces[from];
    return piece != null &&
        piece.code == 'K' &&
        from.startsWith('e') &&
        (to.startsWith('g') || to.startsWith('c'));
  }

  void _moveCastlingRook(String kingTarget, bool white) {
    final String rank = white ? '1' : '8';
    if (kingTarget == 'g$rank') {
      final ChessPiece? rook = _pieces.remove('h$rank');
      if (rook != null) {
        _pieces['f$rank'] = rook;
      }
    } else if (kingTarget == 'c$rank') {
      final ChessPiece? rook = _pieces.remove('a$rank');
      if (rook != null) {
        _pieces['d$rank'] = rook;
      }
    }
  }

  String? _enPassantCaptureSquare(String from, String to) {
    final ChessPiece? piece = _pieces[from];
    if (piece == null || piece.code != 'P' || _pieces.containsKey(to)) {
      return null;
    }

    final SquarePosition fromPosition = ChessRules.positionOf(from);
    final SquarePosition toPosition = ChessRules.positionOf(to);
    if ((fromPosition.file - toPosition.file).abs() != 1) {
      return null;
    }

    final String captureSquare =
        ChessRules.squareOf(toPosition.file, fromPosition.rank);
    final ChessPiece? captured = _pieces[captureSquare];
    if (captured == null ||
        captured.code != 'P' ||
        captured.white == piece.white) {
      return null;
    }
    return captureSquare;
  }

  bool _hasMovedFrom(String square) {
    for (final String move in _moves) {
      final ParsedMove? parsed = _parseMove(move);
      if (parsed?.from == square) {
        return true;
      }
    }
    return false;
  }

  ParsedMove? _parseMove(String move) {
    if (move.startsWith('O-O')) {
      return null;
    }

    final String cleaned =
        move.replaceAll(' x ', '').replaceAll(' e.p.', '').split('=').first;
    if (cleaned.length < 4) {
      return null;
    }
    return ParsedMove(cleaned.substring(0, 2), cleaned.substring(2, 4));
  }

  void _reset() {
    final DailyChallenge challenge = _challengeForToday(_dailyDifficulty);
    final Map<String, ChessPiece> resetPieces = _gameMode == GameMode.daily
        ? _dailyStartingPosition(challenge)
        : Map<String, ChessPiece>.from(_initialPieces);
    setState(() {
      _dailyChallenge = challenge;
      _dailyPlyIndex = 0;
      _dailyMistakes = 0;
      _pieces = resetPieces;
      _moves.clear();
      _capturedWhite.clear();
      _capturedBlack.clear();
      _history.clear();
      _lastFromSquare = null;
      _lastToSquare = null;
      _lastCaptureSquare = null;
      _whiteSeconds = 10 * 60;
      _blackSeconds = 10 * 60;
      _selectedSquare = null;
      _aiThinking = false;
      _coachNote = _gameMode == GameMode.daily
          ? 'Checkmate in ${challenge.playerMoveGoal} moves. Find the first move.'
          : 'Select a coin to see legal moves.';
      _gameResultTitle = null;
      _gameResultDetail = null;
      _resultVisible = true;
      _checkWarningActive = false;
    });
  }

  void _saveSnapshot() {
    _history.add(
      GameSnapshot(
        pieces: Map<String, ChessPiece>.from(_pieces),
        moves: List<String>.from(_moves),
        capturedWhite: List<ChessPiece>.from(_capturedWhite),
        capturedBlack: List<ChessPiece>.from(_capturedBlack),
        coachNote: _coachNote,
        lastFromSquare: _lastFromSquare,
        lastToSquare: _lastToSquare,
        lastCaptureSquare: _lastCaptureSquare,
        whiteSeconds: _whiteSeconds,
        blackSeconds: _blackSeconds,
      ),
    );
    if (_history.length > 80) {
      _history.removeAt(0);
    }
  }

  void _undo() {
    if (_history.isEmpty) {
      return;
    }

    setState(() {
      final int steps =
          (_gameMode == GameMode.computer || _gameMode == GameMode.daily) &&
                  _history.length >= 2
              ? 2
              : 1;
      final GameSnapshot snapshot = _history[_history.length - steps];
      _history.removeRange(_history.length - steps, _history.length);
      _pieces = Map<String, ChessPiece>.from(snapshot.pieces);
      _moves
        ..clear()
        ..addAll(snapshot.moves);
      if (_gameMode == GameMode.daily) {
        _dailyPlyIndex = _moves.length;
      }
      _capturedWhite
        ..clear()
        ..addAll(snapshot.capturedWhite);
      _capturedBlack
        ..clear()
        ..addAll(snapshot.capturedBlack);
      _lastFromSquare = snapshot.lastFromSquare;
      _lastToSquare = snapshot.lastToSquare;
      _lastCaptureSquare = snapshot.lastCaptureSquare;
      _whiteSeconds = snapshot.whiteSeconds;
      _blackSeconds = snapshot.blackSeconds;
      _selectedSquare = null;
      _aiThinking = false;
      _gameResultTitle = null;
      _gameResultDetail = null;
      _resultVisible = true;
      _checkWarningActive =
          ChessRules.isKingInCheck(_moves.length.isEven, _pieces);
      _coachNote = 'Move undone. ${snapshot.coachNote}';
    });
  }

  void _showHint() {
    if (_gameMode == GameMode.daily &&
        _dailyPlyIndex < _dailyChallenge.solution.length) {
      final String expected = _dailyChallenge.solution[_dailyPlyIndex];
      setState(() {
        _selectedSquare = expected.substring(0, 2);
        _coachNote =
            'Daily hint: start with ${expected.substring(0, 2)}. Find the winning destination.';
      });
      return;
    }
    final bool whiteToMove = _moves.length.isEven;
    String? bestFrom;
    List<String> bestTargets = <String>[];

    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white != whiteToMove) {
        continue;
      }
      final List<String> targets = _legalTargetsFor(entry.key);
      if (targets.length > bestTargets.length) {
        bestFrom = entry.key;
        bestTargets = targets;
      }
    }

    setState(() {
      _selectedSquare = bestFrom;
      if (bestFrom == null) {
        _coachNote = 'No legal moves found.';
      } else {
        _coachNote =
            'Coach hint: inspect $bestFrom. It has ${bestTargets.length} promising squares.';
      }
    });
  }

  void _showAnalysis() {
    final bool whiteToMove = _moves.length.isEven;
    final PositionAnalysis analysis = _analyzePosition(whiteToMove);

    setState(() {
      _coachNote = analysis.bestMove == null
          ? 'Analysis complete. No legal move is available.'
          : 'Coach recommends ${analysis.bestMove} for ${analysis.side}.';
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => PositionAnalysisSheet(
        analysis: analysis,
      ),
    );
  }

  PositionAnalysis _analyzePosition(bool whiteToMove) {
    int legalMoveCount = 0;
    int captureCount = 0;
    AiCandidate? bestMove;

    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white != whiteToMove) {
        continue;
      }
      for (final String target in _legalTargetsFor(entry.key)) {
        legalMoveCount++;
        if (_pieces[target] != null) {
          captureCount++;
        }
        final AiCandidate candidate = AiCandidate(
          entry.key,
          target,
          _analysisMoveScore(entry.key, target, entry.value),
        );
        if (bestMove == null || candidate.score > bestMove.score) {
          bestMove = candidate;
        }
      }
    }

    int material = 0;
    for (final ChessPiece piece in _pieces.values) {
      final int value = _pieceValue(piece.code);
      material += piece.white ? value : -value;
    }

    final double evaluation =
        material + (whiteToMove ? legalMoveCount : -legalMoveCount) * 0.03;
    return PositionAnalysis(
      side: whiteToMove ? 'White' : 'Black',
      evaluation: evaluation,
      material: material,
      legalMoves: legalMoveCount,
      captures: captureCount,
      bestMove: bestMove == null ? null : '${bestMove.from} to ${bestMove.to}',
      inCheck: ChessRules.isKingInCheck(whiteToMove, _pieces),
    );
  }

  double _analysisMoveScore(
    String from,
    String target,
    ChessPiece piece,
  ) {
    final ChessPiece? captured = _pieces[target];
    final SquarePosition position = ChessRules.positionOf(target);
    final double center =
        7 - (position.file - 3.5).abs() - (position.rank - 4.5).abs();
    final double capture = captured == null
        ? 0
        : _pieceValue(captured.code) * 10 - _pieceValue(piece.code) * 0.2;
    final Map<String, ChessPiece> next =
        ChessRules.applyMove(from, target, _pieces);
    final bool givesCheck = ChessRules.isKingInCheck(!piece.white, next);
    return capture + center + (givesCheck ? 6 : 0);
  }

  int _pieceValue(String code) {
    return switch (code) {
      'P' => 1,
      'N' => 3,
      'B' => 3,
      'R' => 5,
      'Q' => 9,
      _ => 0,
    };
  }

  Future<void> _showOnlineMatchmakingInfo() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const OnlineMatchmakingSheet(),
    );
  }

  Future<void> _showPromotionPicker(String square, bool white) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191A1F),
          title: const Text('Promote pawn'),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <String>['Q', 'R', 'B', 'N'].map((String code) {
              return PromotionChoice(
                piece: ChessPiece(code, white),
                onSelected: () {
                  setState(() {
                    _pieces[square] = ChessPiece(code, white);
                    _moves[0] = '${_moves.first}=$code';
                    _coachNote = _gameStateNote(
                      !white,
                      fallback: 'Pawn promoted to $code on $square.',
                    );
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _gameStateNote(bool sideToMoveWhite, {required String fallback}) {
    final bool inCheck = ChessRules.isKingInCheck(sideToMoveWhite, _pieces);
    final bool hasMove = ChessRules.hasAnySafeMove(sideToMoveWhite, _pieces);
    final String side = sideToMoveWhite ? 'White' : 'Black';

    if (inCheck && !_checkWarningActive) {
      _checkWarningActive = true;
      unawaited(_playCheckWarning());
    } else if (!inCheck) {
      _checkWarningActive = false;
    }

    if (inCheck && !hasMove) {
      _gameResultTitle = '${sideToMoveWhite ? 'Black' : 'White'} wins';
      _gameResultDetail = 'Checkmate';
      _resultVisible = true;
      return 'Checkmate. $_gameResultTitle.';
    }
    if (!inCheck && !hasMove) {
      _gameResultTitle = 'Draw';
      _gameResultDetail = 'Stalemate';
      _resultVisible = true;
      return 'Stalemate. No legal move for $side.';
    }
    if (inCheck) {
      return '$side is in check.';
    }
    return fallback;
  }

  Future<void> _playCheckWarning() async {
    try {
      final AudioPlayer player = _warningPlayer ??= AudioPlayer();
      await player.stop();
      await player.play(
        AssetSource('audio/check-warning.wav'),
        volume: 0.72,
      );
    } catch (_) {
      // A muted device or browser policy should never interrupt the game.
    }
  }

  String _formatClock(int seconds) {
    final int safeSeconds = math.max(0, seconds);
    final int minutes = safeSeconds ~/ 60;
    final int remainder = safeSeconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}

class CompactHeader extends StatelessWidget {
  const CompactHeader({
    required this.playerName,
    required this.onReset,
    required this.onLogout,
    super.key,
  });

  final String playerName;
  final VoidCallback onReset;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const ChessVerseMark(size: 36),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'ChessVerse AI  |  $playerName',
            style: Theme.of(context).textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Reset board',
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class ChessVerseMark extends StatelessWidget {
  const ChessVerseMark({this.size = 38, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/branding/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'ChessVerse logo',
      ),
    );
  }
}

class BoardStage extends StatelessWidget {
  const BoardStage({
    required this.palette,
    required this.child,
    super.key,
  });

  final BoardPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              palette.accent.withValues(alpha: 0.24),
              palette.frame,
            ),
            palette.frame,
            const Color(0xFF101A17),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: palette.accent.withValues(alpha: 0.75),
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.58),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.2),
            blurRadius: 18,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: child,
      ),
    );
  }
}

class ChessBoard extends StatelessWidget {
  const ChessBoard({
    required this.pieces,
    required this.selectedSquare,
    required this.legalTargets,
    required this.lastFromSquare,
    required this.lastToSquare,
    required this.lastCaptureSquare,
    required this.checkedKingSquare,
    required this.decisiveSquare,
    required this.flipped,
    required this.palette,
    required this.onSquareTap,
    super.key,
  });

  final Map<String, ChessPiece> pieces;
  final String? selectedSquare;
  final Set<String> legalTargets;
  final String? lastFromSquare;
  final String? lastToSquare;
  final String? lastCaptureSquare;
  final String? checkedKingSquare;
  final String? decisiveSquare;
  final bool flipped;
  final BoardPalette palette;
  final ValueChanged<String> onSquareTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: <Widget>[
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 64,
              itemBuilder: (BuildContext context, int index) {
                final int row = index ~/ 8;
                final int col = index % 8;
                final int file = flipped ? 7 - col : col;
                final int rank = flipped ? row + 1 : 8 - row;
                final String square = '${String.fromCharCode(97 + file)}$rank';
                final bool dark = (row + col).isOdd;
                final bool selected = square == selectedSquare;
                final ChessPiece? piece = pieces[square];
                final bool legalTarget = legalTargets.contains(square);
                final bool captureTarget =
                    legalTarget && piece != null && square != selectedSquare;
                final bool lastMoveSquare =
                    square == lastFromSquare || square == lastToSquare;
                final bool lastCapture = square == lastCaptureSquare;
                final bool checkedKing = square == checkedKingSquare;
                final bool decisiveMove = square == decisiveSquare;

                return BoardSquare(
                  key: ValueKey<String>('square-$square'),
                  square: square,
                  dark: dark,
                  selected: selected,
                  legalTarget: legalTarget,
                  captureTarget: captureTarget,
                  lastMoveSquare: lastMoveSquare,
                  lastCapture: lastCapture,
                  checkedKing: checkedKing,
                  decisiveMove: decisiveMove,
                  palette: palette,
                  piece: piece,
                  showRank: col == 0,
                  showFile: row == 7,
                  onTap: () => onSquareTap(square),
                );
              },
            ),
            if (lastFromSquare != null && lastToSquare != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>(
                      'move-trail-$lastFromSquare-$lastToSquare-$flipped',
                    ),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 560),
                    curve: Curves.easeOutCubic,
                    builder: (
                      BuildContext context,
                      double progress,
                      Widget? child,
                    ) {
                      return CustomPaint(
                        painter: LastMoveTrailPainter(
                          from: lastFromSquare!,
                          to: lastToSquare!,
                          flipped: flipped,
                          progress: progress,
                          accent: palette.accent,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LastMoveTrailPainter extends CustomPainter {
  const LastMoveTrailPainter({
    required this.from,
    required this.to,
    required this.flipped,
    required this.progress,
    required this.accent,
  });

  final String from;
  final String to;
  final bool flipped;
  final double progress;
  final Color accent;

  Offset _center(String square, Size size) {
    final int file = square.codeUnitAt(0) - 97;
    final int rank = int.parse(square.substring(1));
    final int col = flipped ? 7 - file : file;
    final int row = flipped ? rank - 1 : 8 - rank;
    final double cell = size.shortestSide / 8;
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset start = _center(from, size);
    final Offset target = _center(to, size);
    final Offset end = Offset.lerp(start, target, progress)!;
    final double cell = size.shortestSide / 8;
    final Offset delta = end - start;
    final double distance = delta.distance;
    if (distance < 1) {
      return;
    }

    final Offset direction = delta / distance;
    final double pieceClearance = cell * 0.27;
    final Offset visualStart = start + direction * pieceClearance;
    final Offset visualEnd = end - direction * pieceClearance;
    if ((visualEnd - visualStart).distance < cell * 0.18) {
      return;
    }
    final Offset mid = Offset.lerp(visualStart, visualEnd, 0.5)!;
    final double bend = math.min(cell * 0.22, distance * 0.12);
    final Offset normal = Offset(-direction.dy, direction.dx);
    final Offset control = mid + normal * bend;
    final Path trail = Path()
      ..moveTo(visualStart.dx, visualStart.dy)
      ..quadraticBezierTo(
        control.dx,
        control.dy,
        visualEnd.dx,
        visualEnd.dy,
      );
    final Paint glow = Paint()
      ..color = accent.withValues(alpha: 0.34 * progress)
      ..strokeWidth = cell * 0.19
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.32 * progress)
      ..strokeWidth = cell * 0.14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final Paint line = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.82),
          accent.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromPoints(visualStart, visualEnd))
      ..strokeWidth = cell * 0.075
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(trail, shadow);
    canvas.drawPath(trail, glow);
    canvas.drawPath(trail, line);
    canvas.drawCircle(
      start,
      cell * 0.11 * progress,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.045
        ..shader = line.shader,
    );
    canvas.drawCircle(
      target,
      cell * 0.24 * progress,
      Paint()
        ..color = accent.withValues(alpha: 0.12 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(LastMoveTrailPainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.flipped != flipped ||
        oldDelegate.progress != progress ||
        oldDelegate.accent != accent;
  }
}

class BoardSquare extends StatelessWidget {
  const BoardSquare({
    required this.square,
    required this.dark,
    required this.selected,
    required this.legalTarget,
    required this.captureTarget,
    required this.lastMoveSquare,
    required this.lastCapture,
    required this.checkedKing,
    required this.decisiveMove,
    required this.palette,
    required this.showRank,
    required this.showFile,
    required this.onTap,
    this.piece,
    super.key,
  });

  final String square;
  final bool dark;
  final bool selected;
  final bool legalTarget;
  final bool captureTarget;
  final bool lastMoveSquare;
  final bool lastCapture;
  final bool checkedKing;
  final bool decisiveMove;
  final BoardPalette palette;
  final bool showRank;
  final bool showFile;
  final VoidCallback onTap;
  final ChessPiece? piece;

  @override
  Widget build(BuildContext context) {
    final Color base = dark ? palette.dark : palette.light;
    final Color coordinateColor = dark
        ? palette.light.withValues(alpha: 0.72)
        : palette.dark.withValues(alpha: 0.72);

    final Color squareColor = checkedKing
        ? Color.alphaBlend(
            const Color(0xFFE11D48).withValues(alpha: 0.76),
            base,
          )
        : decisiveMove
            ? Color.alphaBlend(
                palette.accent.withValues(alpha: 0.62),
                base,
              )
            : lastCapture
                ? Color.alphaBlend(
                    const Color(0xFFE11D48).withValues(alpha: 0.62), base)
                : selected
                    ? Color.alphaBlend(
                        palette.accent.withValues(alpha: 0.55), base)
                    : lastMoveSquare
                        ? Color.alphaBlend(
                            const Color(0xFFFFFFFF).withValues(alpha: 0.26),
                            base,
                          )
                        : base;

    return InkWell(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: selected ||
                  legalTarget ||
                  lastCapture ||
                  checkedKing ||
                  decisiveMove
              ? 1
              : 0,
        ),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double glow, Widget? child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: squareColor,
              border: Border.all(
                color: selected
                    ? const Color(0xFFF8E7B0)
                    : (dark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.08),
                width: selected ? 3 : 1,
              ),
              boxShadow: <BoxShadow>[
                if (legalTarget)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.42 * glow),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                if (lastCapture || captureTarget)
                  BoxShadow(
                    color:
                        const Color(0xFFFF1744).withValues(alpha: 0.55 * glow),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                if (checkedKing)
                  BoxShadow(
                    color:
                        const Color(0xFFFF1744).withValues(alpha: 0.9 * glow),
                    blurRadius: 28,
                    spreadRadius: 5,
                  ),
                if (decisiveMove)
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.8 * glow),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: child,
          );
        },
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 5,
              left: 6,
              child: Text(
                showRank ? square.substring(1) : '',
                style: TextStyle(
                  color: coordinateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 4,
              child: Text(
                showFile ? square.substring(0, 1) : '',
                style: TextStyle(
                  color: coordinateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack,
                scale: legalTarget && piece == null ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.82),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.85),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const SizedBox(width: 20, height: 20),
                ),
              ),
            ),
            if (captureTarget)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFF1744),
                        width: 4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color:
                              const Color(0xFFFF1744).withValues(alpha: 0.72),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (checkedKing)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFD1D8),
                        width: 4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.48),
                          blurRadius: 9,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale:
                        Tween<double>(begin: 0.82, end: 1).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: piece == null
                    ? const SizedBox.shrink()
                    : ChessCoin(
                        key: ValueKey<String>(
                          '$square-${piece!.white}-${piece!.code}',
                        ),
                        piece: piece!,
                        selected: selected,
                        accent: palette.accent,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChessCoin extends StatelessWidget {
  const ChessCoin({
    required this.piece,
    required this.selected,
    required this.accent,
    super.key,
  });

  final ChessPiece piece;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double size =
            math.min(constraints.maxWidth, constraints.maxHeight);
        final double pieceSize = size * 0.94;

        return AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: selected ? 1.08 : 1,
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: pieceSize,
            height: pieceSize,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  bottom: pieceSize * 0.045,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(pieceSize),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.62),
                          blurRadius: pieceSize * 0.09,
                          spreadRadius: pieceSize * 0.025,
                        ),
                        if (selected)
                          BoxShadow(
                            color: accent.withValues(alpha: 0.68),
                            blurRadius: pieceSize * 0.2,
                            spreadRadius: pieceSize * 0.06,
                          ),
                      ],
                    ),
                    child: SizedBox(
                      width: pieceSize * 0.54,
                      height: pieceSize * 0.055,
                    ),
                  ),
                ),
                Image.asset(
                  pieceAsset(piece),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  semanticLabel:
                      '${piece.white ? 'White' : 'Black'} ${pieceName(piece.code)}',
                ),
                IgnorePointer(
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: const Alignment(-0.85, -1),
                        end: const Alignment(0.7, 0.9),
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.58),
                          Colors.white.withValues(alpha: 0.06),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.18),
                        ],
                        stops: const <double>[0, 0.24, 0.58, 1],
                      ).createShader(bounds);
                    },
                    child: Opacity(
                      opacity: piece.white ? 0.34 : 0.24,
                      child: Image.asset(
                        pieceAsset(piece),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: pieceSize * 0.11,
                  left: pieceSize * 0.25,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: piece.white ? 0.2 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(pieceSize),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.22),
                            blurRadius: pieceSize * 0.09,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: pieceSize * 0.13,
                        height: pieceSize * 0.035,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String pieceAsset(ChessPiece piece) {
  return 'assets/pieces/staunton_${piece.white ? 'white' : 'black'}_${pieceName(piece.code)}.png';
}

String pieceName(String code) {
  return switch (code) {
    'K' => 'king',
    'Q' => 'queen',
    'R' => 'rook',
    'B' => 'bishop',
    'N' => 'knight',
    _ => 'pawn',
  };
}

String pieceGlyph(ChessPiece piece) {
  if (piece.white) {
    return switch (piece.code) {
      'K' => '\u2654',
      'Q' => '\u2655',
      'R' => '\u2656',
      'B' => '\u2657',
      'N' => '\u2658',
      _ => '\u2659',
    };
  }
  return switch (piece.code) {
    'K' => '\u265A',
    'Q' => '\u265B',
    'R' => '\u265C',
    'B' => '\u265D',
    'N' => '\u265E',
    _ => '\u265F',
  };
}

class CoinRingPainter extends CustomPainter {
  const CoinRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2;
    final Paint ring = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * 0.08);
    canvas.drawCircle(center, radius * 0.68, ring);

    final Paint tick = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = math.max(1, radius * 0.035)
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 18; i++) {
      final double angle = i * math.pi / 9;
      final Offset start = Offset(
        center.dx + math.cos(angle) * radius * 0.82,
        center.dy + math.sin(angle) * radius * 0.82,
      );
      final Offset end = Offset(
        center.dx + math.cos(angle) * radius * 0.9,
        center.dy + math.sin(angle) * radius * 0.9,
      );
      canvas.drawLine(start, end, tick);
    }
  }

  @override
  bool shouldRepaint(CoinRingPainter oldDelegate) => oldDelegate.color != color;
}

class PieceSculpturePainter extends CustomPainter {
  const PieceSculpturePainter({required this.light, required this.accent});

  final bool light;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Color body =
        light ? const Color(0xFFF7E9C9) : const Color(0xFF252A32);
    final Color edge =
        light ? const Color(0xFFC09035) : const Color(0xFF68707D);
    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          light ? Colors.white : const Color(0xFF505763),
          body,
          light ? const Color(0xFFD8B56C) : const Color(0xFF16191F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final Paint edgePaint = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.035);

    final RRect base = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.66, w * 0.64, h * 0.18),
      Radius.circular(w * 0.12),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.18, h * 0.72, w * 0.64, h * 0.18),
      shadow,
    );
    canvas.drawRRect(base, bodyPaint);
    canvas.drawRRect(base, edgePaint);

    final Path stem = Path()
      ..moveTo(w * 0.38, h * 0.68)
      ..quadraticBezierTo(w * 0.32, h * 0.46, w * 0.43, h * 0.32)
      ..lineTo(w * 0.57, h * 0.32)
      ..quadraticBezierTo(w * 0.68, h * 0.46, w * 0.62, h * 0.68)
      ..close();
    canvas.drawPath(stem, shadow);
    canvas.drawPath(stem, bodyPaint);
    canvas.drawPath(stem, edgePaint);

    canvas.drawCircle(Offset(w * 0.5, h * 0.26), w * 0.16, bodyPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.26), w * 0.16, edgePaint);
    canvas.drawCircle(
      Offset(w * 0.43, h * 0.18),
      w * 0.035,
      Paint()..color = Colors.white.withValues(alpha: light ? 0.86 : 0.28),
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.3,
      Paint()
        ..color = accent.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035,
    );
  }

  @override
  bool shouldRepaint(PieceSculpturePainter oldDelegate) {
    return oldDelegate.light != light || oldDelegate.accent != accent;
  }
}

class PromotionChoice extends StatelessWidget {
  const PromotionChoice({
    required this.piece,
    required this.onSelected,
    super.key,
  });

  final ChessPiece piece;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: FilledButton(
        onPressed: onSelected,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: const Color(0xFF242128),
          foregroundColor: const Color(0xFFF6F1E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 48,
              height: 48,
              child: ChessCoin(
                piece: piece,
                selected: false,
                accent: const Color(0xFFD6A84F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              piece.code,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.compact,
    required this.collapsible,
    required this.expanded,
    required this.whitePlayerName,
    required this.blackPlayerName,
    required this.activeColor,
    required this.gameMode,
    required this.aiLevel,
    required this.aiThinking,
    required this.coachEnabled,
    required this.moves,
    required this.capturedWhite,
    required this.capturedBlack,
    required this.coachNote,
    required this.whiteClock,
    required this.blackClock,
    required this.skin,
    required this.onSkinChanged,
    required this.onGameModeChanged,
    required this.dailyDifficulty,
    required this.dailyProgress,
    required this.dailyGoal,
    required this.dailyMistakes,
    required this.onDailyDifficultyChanged,
    required this.onAiLevelChanged,
    required this.onCoachChanged,
    required this.onReset,
    required this.onUndo,
    required this.onHint,
    required this.onAnalyze,
    required this.onEditBlackPlayer,
    required this.onToggleExpanded,
    required this.onLogout,
    required this.canUndo,
    super.key,
  });

  final bool compact;
  final bool collapsible;
  final bool expanded;
  final String whitePlayerName;
  final String blackPlayerName;
  final String activeColor;
  final GameMode gameMode;
  final int aiLevel;
  final bool aiThinking;
  final bool coachEnabled;
  final List<String> moves;
  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;
  final String coachNote;
  final String whiteClock;
  final String blackClock;
  final BoardSkin skin;
  final ValueChanged<BoardSkin> onSkinChanged;
  final ValueChanged<GameMode> onGameModeChanged;
  final DailyChallengeDifficulty dailyDifficulty;
  final int dailyProgress;
  final int dailyGoal;
  final int dailyMistakes;
  final ValueChanged<DailyChallengeDifficulty> onDailyDifficultyChanged;
  final ValueChanged<double> onAiLevelChanged;
  final ValueChanged<bool> onCoachChanged;
  final VoidCallback onReset;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onAnalyze;
  final VoidCallback onEditBlackPlayer;
  final VoidCallback onToggleExpanded;
  final VoidCallback onLogout;
  final bool canUndo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final AiProfile aiProfile = aiProfileFor(aiLevel);
        final bool collapsed = collapsible && !expanded;
        final bool collapsedRail = constraints.maxWidth < 310;
        final Widget history = moves.isEmpty
            ? const EmptyMoveState()
            : ListView.separated(
                itemCount: moves.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    dense: true,
                    minLeadingWidth: 32,
                    leading: Text('${moves.length - index}.'),
                    title: Text(moves[index]),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  );
                },
              );

        if (collapsedRail) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF17231F).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF98743B).withValues(alpha: 0.72),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      key: const ValueKey<String>('game-controls-handle'),
                      onTap: onToggleExpanded,
                      borderRadius: BorderRadius.circular(8),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.tune_rounded, size: 30),
                            SizedBox(height: 8),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                'GAME CONTROLS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Icon(Icons.chevron_left_rounded, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reset board',
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    tooltip: 'Undo move',
                    onPressed: canUndo ? onUndo : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }

        final List<Widget> controls = <Widget>[
          if (collapsible)
            Semantics(
              button: true,
              label:
                  expanded ? 'Collapse game controls' : 'Expand game controls',
              child: InkWell(
                key: const ValueKey<String>('game-controls-handle'),
                onTap: onToggleExpanded,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.drag_handle_rounded, size: 28),
                      const SizedBox(width: 6),
                      Text(
                        expanded ? 'Less controls' : 'More controls',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  switch (gameMode) {
                    GameMode.computer => 'Solo Challenge',
                    GameMode.daily => 'Daily Checkmate',
                    GameMode.local => 'Pass & Play',
                    GameMode.online => 'Online Battle',
                  },
                  style: compact
                      ? Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          )
                      : Theme.of(context).textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Reset board',
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Undo move',
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              if (!compact)
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GameMode>(
            key: const ValueKey<String>('game-mode-menu'),
            initialValue: gameMode,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Play mode',
              prefixIcon:
                  compact ? null : const Icon(Icons.sports_esports_rounded),
              border: const OutlineInputBorder(),
              isDense: compact,
            ),
            items: const <DropdownMenuItem<GameMode>>[
              DropdownMenuItem<GameMode>(
                value: GameMode.computer,
                child: Text('Vs Computer'),
              ),
              DropdownMenuItem<GameMode>(
                value: GameMode.daily,
                child: Text('Daily Checkmate'),
              ),
              DropdownMenuItem<GameMode>(
                value: GameMode.local,
                child: Text('Local 2P'),
              ),
              DropdownMenuItem<GameMode>(
                value: GameMode.online,
                child: Text('Online Match'),
              ),
            ],
            onChanged: (GameMode? mode) {
              if (mode != null) {
                onGameModeChanged(mode);
              }
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusPill(
                icon: Icons.auto_awesome_rounded,
                label: coachEnabled ? 'Coach on' : 'Coach off',
              ),
              if (gameMode == GameMode.computer)
                StatusPill(
                  icon: aiThinking
                      ? Icons.hourglass_top_rounded
                      : Icons.speed_rounded,
                  label: aiThinking ? 'Thinking' : aiProfile.name,
                ),
              if (gameMode == GameMode.daily)
                StatusPill(
                  icon: Icons.local_fire_department_rounded,
                  label: '$dailyProgress/$dailyGoal solved',
                ),
              StatusPill(icon: Icons.memory_rounded, label: activeColor),
            ],
          ),
          if (gameMode == GameMode.local) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey<String>('rename-player-two'),
              onPressed: onEditBlackPlayer,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: Text('Player 2: $blackPlayerName'),
            ),
          ],
          if (gameMode == GameMode.daily) ...<Widget>[
            const SizedBox(height: 10),
            DropdownButtonFormField<DailyChallengeDifficulty>(
              key: const ValueKey<String>('daily-difficulty-menu'),
              initialValue: dailyDifficulty,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Challenge difficulty',
                prefixIcon: Icon(Icons.emoji_events_outlined),
                border: OutlineInputBorder(),
              ),
              items: DailyChallengeDifficulty.values
                  .map(
                    (DailyChallengeDifficulty difficulty) =>
                        DropdownMenuItem<DailyChallengeDifficulty>(
                      value: difficulty,
                      child: Text(difficulty.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (DailyChallengeDifficulty? difficulty) {
                if (difficulty != null) {
                  onDailyDifficultyChanged(difficulty);
                }
              },
            ),
            if (dailyMistakes > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '$dailyMistakes attempt${dailyMistakes == 1 ? '' : 's'} missed · keep calculating',
                style: const TextStyle(color: Color(0xFFE2B458)),
              ),
            ],
          ],
          if (collapsed) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: MatchClock(label: whitePlayerName, value: whiteClock),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MatchClock(label: blackPlayerName, value: blackClock),
                ),
              ],
            ),
          ],
          if (collapsed) const SizedBox(height: 10),
        ];

        final List<Widget> expandedOnlyControls = <Widget>[
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                  child: MatchClock(label: whitePlayerName, value: whiteClock)),
              const SizedBox(width: 10),
              Expanded(
                  child: MatchClock(label: blackPlayerName, value: blackClock)),
            ],
          ),
          const SizedBox(height: 18),
          CoachInsight(note: coachNote, enabled: coachEnabled),
          if (!compact) ...<Widget>[
            const SizedBox(height: 18),
            CapturedMaterial(
              capturedWhite: capturedWhite,
              capturedBlack: capturedBlack,
            ),
          ],
          const SizedBox(height: 18),
          Text('Board', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<BoardSkin>(
            key: const ValueKey<String>('board-theme-menu'),
            initialValue: skin,
            decoration: const InputDecoration(
              labelText: 'Board theme',
              prefixIcon: Icon(Icons.palette_outlined),
              border: OutlineInputBorder(),
            ),
            items: boardPalettes.entries
                .map(
                  (MapEntry<BoardSkin, BoardPalette> entry) =>
                      DropdownMenuItem<BoardSkin>(
                    value: entry.key,
                    child: BoardThemeMenuItem(palette: entry.value),
                  ),
                )
                .toList(),
            onChanged: (BoardSkin? selectedSkin) {
              if (selectedSkin != null) {
                onSkinChanged(selectedSkin);
              }
            },
          ),
          if (gameMode == GameMode.computer) ...<Widget>[
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${aiProfile.name} - Level $aiLevel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '~${aiProfile.elo} Elo',
                  style: const TextStyle(
                    color: Color(0xFF63D2B8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              aiProfile.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              value: aiLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${aiProfile.name} - ~${aiProfile.elo} Elo',
              onChanged: onAiLevelChanged,
            ),
          ],
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: coachEnabled,
              onChanged: onCoachChanged,
              title: const Text('AI coach'),
              secondary: const Icon(Icons.psychology_alt_rounded),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onHint,
                  icon: const Icon(Icons.psychology_alt_rounded),
                  label: const Text('Hint'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text('Analyze'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Move history',
            style: compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
        ];

        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...controls,
            if (!collapsed) ...<Widget>[
              ...expandedOnlyControls,
              SizedBox(height: compact ? 120 : 220, child: history),
            ],
          ],
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF17231F).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF98743B).withValues(alpha: 0.72),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 18),
            child: SingleChildScrollView(child: content),
          ),
        );
      },
    );
  }
}

class BoardThemeMenuItem extends StatelessWidget {
  const BoardThemeMenuItem({required this.palette, super.key});

  final BoardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            width: 34,
            height: 24,
            child: Row(
              children: <Widget>[
                Expanded(child: ColoredBox(color: palette.light)),
                Expanded(child: ColoredBox(color: palette.dark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(palette.label),
      ],
    );
  }
}

class PositionAnalysisSheet extends StatelessWidget {
  const PositionAnalysisSheet({required this.analysis, super.key});

  final PositionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final String evaluation = analysis.evaluation == 0
        ? 'Equal'
        : analysis.evaluation > 0
            ? 'White +${analysis.evaluation.toStringAsFixed(1)}'
            : 'Black +${analysis.evaluation.abs().toStringAsFixed(1)}';

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF17231F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFF8B7147)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF786B58),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.analytics_rounded,
                        color: Color(0xFFD6A84F),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Position analysis',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close analysis',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnalysisMetric(
                    icon: Icons.balance_rounded,
                    label: 'Evaluation',
                    value: evaluation,
                  ),
                  AnalysisMetric(
                    icon: Icons.route_rounded,
                    label: '${analysis.side} legal moves',
                    value: '${analysis.legalMoves}',
                  ),
                  AnalysisMetric(
                    icon: Icons.gps_fixed_rounded,
                    label: 'Immediate captures',
                    value: '${analysis.captures}',
                  ),
                  AnalysisMetric(
                    icon: analysis.inCheck
                        ? Icons.warning_amber_rounded
                        : Icons.shield_outlined,
                    label: 'King safety',
                    value: analysis.inCheck ? 'In check' : 'Safe',
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6A84F).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: const Color(0xFFD6A84F).withValues(alpha: 0.48),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFD6A84F),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              analysis.bestMove == null
                                  ? 'No legal move'
                                  : 'Recommended: ${analysis.bestMove}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnalysisMetric extends StatelessWidget {
  const AnalysisMetric({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: const Color(0xFF63D2B8)),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class OnlineMatchmakingSheet extends StatelessWidget {
  const OnlineMatchmakingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF17231F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.public_rounded,
                size: 38,
                color: Color(0xFF63D2B8),
              ),
              const SizedBox(height: 12),
              Text(
                'Online matchmaking',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'The realtime match gateway is not deployed yet. Local 2P remains available while authenticated matchmaking, reconnect and anti-cheat services are completed.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BoardThemeChoice extends StatelessWidget {
  const BoardThemeChoice({
    required this.palette,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final BoardPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${palette.label} board',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 104,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? palette.accent.withValues(alpha: 0.16)
                : const Color(0xFF202329),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? palette.accent : const Color(0xFF45474C),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  width: 25,
                  height: 25,
                  child: Row(
                    children: <Widget>[
                      Expanded(child: ColoredBox(color: palette.light)),
                      Expanded(child: ColoredBox(color: palette.dark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  palette.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyMoveState extends StatelessWidget {
  const EmptyMoveState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF242128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3B352D)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Select a coin, then choose its target square.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class SessionLoadingOverlay extends StatelessWidget {
  const SessionLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF07120F),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ChessVerseMark(size: 76),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Color(0xFFD6A84F)),
            SizedBox(height: 14),
            Text('Restoring your secure session...'),
          ],
        ),
      ),
    );
  }
}

class AuthOverlay extends StatelessWidget {
  const AuthOverlay({
    required this.registerMode,
    required this.awaitingCode,
    required this.message,
    required this.hasError,
    required this.onModeChanged,
    required this.onUsernameChanged,
    required this.onDisplayNameChanged,
    required this.onIdentityChanged,
    required this.onPasswordChanged,
    required this.onCodeChanged,
    required this.onSubmit,
    required this.onContinueDefault,
    required this.onFacebookLogin,
    required this.onForgotPassword,
    required this.onResendCode,
    required this.onBackFromCode,
    required this.loading,
    super.key,
  });

  final bool registerMode;
  final bool awaitingCode;
  final String message;
  final bool hasError;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<String> onDisplayNameChanged;
  final ValueChanged<String> onIdentityChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onContinueDefault;
  final VoidCallback onFacebookLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onResendCode;
  final VoidCallback onBackFromCode;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF07120F).withValues(alpha: 0.97),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF15161B).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD6A84F)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFD6A84F).withValues(alpha: 0.18),
                      blurRadius: 38,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const ChessVerseMark(size: 34),
                          const SizedBox(width: 8),
                          Text(
                            'CHESSVERSE',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        registerMode ? 'Create ChessVerse ID' : 'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      if (!hasError && message.trim().isNotEmpty)
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 16),
                      if (!awaitingCode)
                        SegmentedButton<bool>(
                          segments: const <ButtonSegment<bool>>[
                            ButtonSegment<bool>(
                                value: true, label: Text('Register')),
                            ButtonSegment<bool>(
                                value: false, label: Text('Login')),
                          ],
                          selected: <bool>{registerMode},
                          onSelectionChanged: (Set<bool> selected) {
                            onModeChanged(selected.first);
                          },
                        ),
                      if (!awaitingCode) const SizedBox(height: 14),
                      if (!awaitingCode) ...<Widget>[
                        if (registerMode) ...<Widget>[
                          TextField(
                            onChanged: onUsernameChanged,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'User ID',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: onDisplayNameChanged,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Player name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          onChanged: onIdentityChanged,
                          textInputAction: TextInputAction.next,
                          keyboardType: registerMode
                              ? TextInputType.emailAddress
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText:
                                registerMode ? 'Email' : 'User ID or email',
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: onPasswordChanged,
                          obscureText: true,
                          onSubmitted: (_) => onSubmit(),
                          decoration: InputDecoration(
                            labelText:
                                registerMode ? 'Create password' : 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            helperText:
                                registerMode ? 'At least 8 characters' : null,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        if (!registerMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: loading ? null : onForgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                      ],
                      if (awaitingCode) ...<Widget>[
                        const SizedBox(height: 18),
                        Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFD6A84F)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Icon(
                                Icons.mark_email_read_outlined,
                                color: Color(0xFFD6A84F),
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          onChanged: onCodeChanged,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                          onSubmitted: (_) => onSubmit(),
                          decoration: const InputDecoration(
                            labelText: 'Six-digit verification code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (hasError) ...<Widget>[
                        const SizedBox(height: 14),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF5350).withValues(alpha: 0.12),
                            border: Border.all(
                              color: const Color(0xFFEF5350)
                                  .withValues(alpha: 0.65),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFFF7774),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      color: Color(0xFFFFB4B2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: loading ? null : onSubmit,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                awaitingCode
                                    ? Icons.verified_rounded
                                    : Icons.login_rounded,
                              ),
                        label: Text(
                          awaitingCode
                              ? 'Verify and Continue'
                              : registerMode
                                  ? 'Send Code'
                                  : 'Login',
                        ),
                      ),
                      if (!awaitingCode) ...<Widget>[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: loading ? null : onContinueDefault,
                          icon: const Icon(Icons.person_pin_circle_outlined),
                          label: const Text('Continue as Guest Player'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: loading ? null : onFacebookLogin,
                          icon: const Icon(Icons.facebook_rounded),
                          label: const Text(
                            'Facebook Login',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (awaitingCode)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: loading ? null : onResendCode,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Resend code'),
                            ),
                            TextButton.icon(
                              onPressed: loading ? null : onBackFromCode,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Change details'),
                            ),
                          ],
                        ),
                      if (!awaitingCode) ...<Widget>[
                        const SizedBox(height: 14),
                        const Text(
                          'Use a verified ChessVerse account to save games, ratings and coach history. Guest Player is local-only for quick testing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFAAA69E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameResultOverlay extends StatelessWidget {
  const GameResultOverlay({
    required this.title,
    required this.detail,
    required this.onNewGame,
    required this.onReview,
    super.key,
  });

  final String title;
  final String detail;
  final VoidCallback onNewGame;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF17181D),
              border: Border.all(color: const Color(0xFFD6A84F)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFFD6A84F).withValues(alpha: 0.25),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFD6A84F),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReview,
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('Review board'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onNewGame,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('New game'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CoachInsight extends StatelessWidget {
  const CoachInsight({required this.note, required this.enabled, super.key});

  final String note;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF242128) : const Color(0xFF17171B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? const Color(0xFF6C5530) : const Color(0xFF323238),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              enabled
                  ? Icons.psychology_alt_rounded
                  : Icons.visibility_off_rounded,
              color: const Color(0xFFD6A84F),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                enabled ? note : 'AI coach is paused.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CapturedMaterial extends StatelessWidget {
  const CapturedMaterial({
    required this.capturedWhite,
    required this.capturedBlack,
    super.key,
  });

  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Captured', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: CaptureRow(label: 'White', pieces: capturedWhite),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CaptureRow(label: 'Black', pieces: capturedBlack),
            ),
          ],
        ),
      ],
    );
  }
}

class CaptureRow extends StatelessWidget {
  const CaptureRow({required this.label, required this.pieces, super.key});

  final String label;
  final List<ChessPiece> pieces;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF202127),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B352D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: pieces.isEmpty
                  ? <Widget>[
                      const Text(
                        '-',
                        style: TextStyle(color: Color(0xFF9B948A)),
                      ),
                    ]
                  : pieces
                      .map(
                        (ChessPiece piece) => MiniCapturedPiece(piece: piece),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniCapturedPiece extends StatelessWidget {
  const MiniCapturedPiece({required this.piece, super.key});

  final ChessPiece piece;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: piece.white
              ? const <Color>[Color(0xFFFFF6E1), Color(0xFFC99B49)]
              : const <Color>[Color(0xFF41454D), Color(0xFF111319)],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFD6A84F).withValues(alpha: 0.9),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Image.asset(
            pieceAsset(piece),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            semanticLabel:
                'Captured ${piece.white ? 'white' : 'black'} ${pieceName(piece.code)}',
          ),
        ),
      ),
    );
  }
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final String initial =
        name.trim().isEmpty ? 'P' : name.trim().substring(0, 1).toUpperCase();
    return Tooltip(
      message: 'Signed in as $name',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF245A4A),
          border: Border.all(color: const Color(0xFF63D2B8), width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF63D2B8).withValues(alpha: 0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MatchClock extends StatelessWidget {
  const MatchClock({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1C20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3124)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF242128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B352D)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xFFD6A84F)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF6F1E8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
