import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio/chess_sound_service.dart';
import 'core/config/app_config.dart';
import 'core/local_game_archive.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_session_store.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/engine/data/engine_api.dart';
import 'features/analysis/presentation/analysis_screen.dart';
import 'features/home/presentation/home_dashboard_screen.dart';
import 'features/library/presentation/reference_screens.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/tutorial/presentation/learn_chess_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );
  await LocalGameArchive.init();
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
  _RootStage _stage = _RootStage.splash;
  String _playerName = 'Guest Player';

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) {
        setState(() => _stage = _RootStage.loading);
        _timer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() => _stage = _RootStage.onboarding);
          }
        });
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
      child: switch (_stage) {
        _RootStage.splash => const BrandedSplash(
            key: ValueKey<String>('splash'),
          ),
        _RootStage.loading => const ChessVerseLoadingScreen(
            key: ValueKey<String>('loading'),
          ),
        _RootStage.onboarding => OnboardingScreen(
            key: const ValueKey<String>('onboarding'),
            onComplete: () => setState(() => _stage = _RootStage.auth),
          ),
        _RootStage.auth => AuthScreen(
            key: const ValueKey<String>('auth'),
            onAuthenticated: (ChessVerseAuthResult result) {
              setState(() {
                _playerName = result.playerName;
                _stage = _RootStage.home;
              });
            },
          ),
        _RootStage.home => HomeDashboardScreen(
            key: const ValueKey<String>('home'),
            playerName: _playerName,
            onPlayVsAi: () => _chooseSideAndOpen(context, GameMode.computer),
            onDailyChallenge: () => _openGame(context, GameMode.daily),
            onLocalGame: () => _chooseSideAndOpen(context, GameMode.local),
            onAnalysis: () => _push(context, const AnalysisScreen()),
            onPuzzles: () => _push(context, const PuzzlesScreen()),
            onSavedGames: () => _push(context, const SavedGamesScreen()),
            onLearnChess: () => _push(context, const LearnChessScreen()),
            onProfile: () => _push(context, const ProfileScreen()),
            onSettings: () => _push(context, const SettingsScreen()),
          ),
      },
    );
  }

  Future<void> _chooseSideAndOpen(BuildContext context, GameMode mode) async {
    final PlayerSideChoice? choice =
        await showModalBottomSheet<PlayerSideChoice>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF15161B),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Choose your side',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  mode == GameMode.local
                      ? 'Player 1 side for this match.'
                      : 'ChessVerse AI will take the opposite side.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      PlayerSideChoice.values.map((PlayerSideChoice side) {
                    return ChoiceChip(
                      selected: side == PlayerSideChoice.white,
                      avatar: Icon(side.icon, size: 18),
                      label: Text(side.label),
                      onSelected: (_) => Navigator.of(context).pop(side),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(PlayerSideChoice.white),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start as White'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice != null && context.mounted) {
      _openGame(context, mode, sideChoice: choice);
    }
  }

  void _openGame(
    BuildContext context,
    GameMode mode, {
    PlayerSideChoice sideChoice = PlayerSideChoice.white,
  }) {
    _push(
      context,
      GameScreen(
        initiallySignedIn: true,
        useRemoteEngine: false,
        initialGameMode: mode,
        initialPlayerName: _playerName,
        initialSideChoice: sideChoice,
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }
}

enum _RootStage {
  splash,
  loading,
  onboarding,
  auth,
  home,
}

class BrandedSplash extends StatelessWidget {
  const BrandedSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02070D),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = kIsWeb ||
              constraints.maxWidth >= 720 ||
              constraints.maxWidth <= 0;
          final String asset = wide
              ? 'assets/branding/splash_screen_wide.png'
              : 'assets/branding/splash_screen_mobile.png';
          final double maxHeroWidth = wide
              ? constraints.maxWidth.clamp(520.0, 980.0)
              : constraints.maxWidth * 0.96;
          final double maxHeroHeight = wide
              ? constraints.maxHeight * 0.9
              : constraints.maxHeight * 0.86;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Image(
                  image: AssetImage(asset),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.08),
                    radius: 0.9,
                    colors: <Color>[
                      Color(0x66066C63),
                      Color(0xD902070D),
                      Color(0xFF02070D),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxHeroWidth,
                      maxHeight: maxHeroHeight,
                    ),
                    child: Image(
                      image: AssetImage(asset),
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
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

class ChessVerseLoadingScreen extends StatelessWidget {
  const ChessVerseLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02070D),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = kIsWeb ||
              constraints.maxWidth >= 720 ||
              constraints.maxWidth <= 0;
          final bool short = constraints.maxHeight > 0 &&
              constraints.maxHeight < (wide ? 420 : 620);
          final double logoSize = short ? 62 : (wide ? 126 : 106);
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.05),
                    radius: 1.05,
                    colors: <Color>[
                      Color(0xFF0A5A50),
                      Color(0xFF071B22),
                      Color(0xFF02070D),
                    ],
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 560 : 360),
                    child: Padding(
                      padding: EdgeInsets.all(short ? 14 : 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: logoSize,
                            height: logoSize,
                            padding: EdgeInsets.all(short ? 8 : 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A111A)
                                  .withValues(alpha: 0.82),
                              borderRadius:
                                  BorderRadius.circular(short ? 20 : 32),
                              border: Border.all(
                                color: const Color(0xFFD6A84F)
                                    .withValues(alpha: 0.7),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0xFF63D2B8)
                                      .withValues(alpha: 0.28),
                                  blurRadius: short ? 22 : 42,
                                  offset: Offset(0, short ? 8 : 18),
                                ),
                              ],
                            ),
                            child: Image.asset('assets/branding/app_icon.png'),
                          ),
                          SizedBox(height: short ? 10 : 26),
                          Text(
                            'CHESSVERSE AI',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  letterSpacing: 2,
                                  fontSize: short ? 20 : null,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFF8F2E4),
                                ),
                          ),
                          SizedBox(height: short ? 4 : 8),
                          Text(
                            'Think  -  Move  -  Master',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: const Color(0xFFE0C47C),
                                  fontSize: short ? 10 : null,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          SizedBox(height: short ? 14 : 44),
                          Text(
                            'LOADING...',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  letterSpacing: 2,
                                  fontSize: short ? 10 : null,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          SizedBox(height: short ? 8 : 14),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.08, end: 0.88),
                            duration: const Duration(milliseconds: 1100),
                            curve: Curves.easeOutCubic,
                            builder: (
                              BuildContext context,
                              double value,
                              Widget? child,
                            ) {
                              return Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A210C),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFFE0C47C)
                                        .withValues(alpha: 0.38),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    minHeight: short ? 9 : 14,
                                    backgroundColor: const Color(0xFF3B1C0F),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFE0C47C),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

enum PlayerSideChoice { white, random, black }

extension PlayerSideChoiceDetails on PlayerSideChoice {
  String get label => switch (this) {
        PlayerSideChoice.white => 'White',
        PlayerSideChoice.random => 'Random',
        PlayerSideChoice.black => 'Black',
      };

  IconData get icon => switch (this) {
        PlayerSideChoice.white => Icons.circle_outlined,
        PlayerSideChoice.random => Icons.shuffle_rounded,
        PlayerSideChoice.black => Icons.circle,
      };
}

extension DailyChallengeDifficultyDetails on DailyChallengeDifficulty {
  String get label => switch (this) {
        DailyChallengeDifficulty.easy => 'Easy - 3-step finish',
        DailyChallengeDifficulty.medium => 'Medium - 4-step finish',
        DailyChallengeDifficulty.hard => 'Hard - 5-step finish',
      };
}

class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.pattern,
    required this.setupMoves,
    required this.solution,
  });

  final String id;
  final String title;
  final DailyChallengeDifficulty difficulty;
  final int pattern;
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
    required this.quality,
    required this.coachLine,
    required this.inCheck,
  });

  final String side;
  final double evaluation;
  final int material;
  final int legalMoves;
  final int captures;
  final String? bestMove;
  final String quality;
  final String coachLine;
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
    this.initialGameMode = GameMode.computer,
    this.initialPlayerName,
    this.initialSideChoice = PlayerSideChoice.white,
    super.key,
  });

  final bool initiallySignedIn;
  final bool useRemoteEngine;
  final GameMode initialGameMode;
  final String? initialPlayerName;
  final PlayerSideChoice initialSideChoice;

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
  Timer? _moveQualityTimer;
  String? _selectedSquare;
  String? _lastFromSquare;
  String? _lastToSquare;
  String? _lastCaptureSquare;
  String? _moveQualityText;
  String _coachNote = 'Select a coin to see legal moves.';
  BoardSkin _skin = BoardSkin.royalWalnut;
  GameMode _gameMode = GameMode.computer;
  double _aiLevel = 4;
  bool _aiThinking = false;
  bool _coachEnabled = true;
  bool _humanPlaysWhite = true;
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
  bool _resultSaved = false;
  bool _soundEnabled = true;
  bool _showCoordinates = true;
  bool _showMoveHints = true;
  DailyChallengeDifficulty _dailyDifficulty = DailyChallengeDifficulty.medium;
  late DailyChallenge _dailyChallenge;
  bool _dailyCompletedToday = false;
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
    _dailyCompletedToday =
        LocalGameArchive.isDailyChallengeComplete(_dailyChallenge.id);
    _gameMode = widget.initialGameMode;
    _humanPlaysWhite = switch (widget.initialSideChoice) {
      PlayerSideChoice.white => true,
      PlayerSideChoice.black => false,
      PlayerSideChoice.random => _random.nextBool(),
    };
    _pieces = _gameMode == GameMode.daily
        ? _dailyStartingPosition(_dailyChallenge)
        : Map<String, ChessPiece>.from(_initialPieces);
    _signedIn = widget.initiallySignedIn;
    final String playerName = widget.initialPlayerName != null &&
            widget.initialPlayerName!.trim().isNotEmpty
        ? widget.initialPlayerName!.trim()
        : widget.initiallySignedIn
            ? 'Guest Player'
            : 'Guest Player';
    if (widget.initialPlayerName != null &&
        widget.initialPlayerName!.trim().isNotEmpty) {
      _whitePlayerName = playerName;
    } else if (widget.initiallySignedIn) {
      _whitePlayerName = 'Guest Player';
    }
    _applyPlayerSideNames(playerName);
    if (_gameMode == GameMode.daily) {
      _applyDailyCompletionState();
      if (!_dailyCompletedToday) {
        _coachNote =
            'Checkmate in ${_dailyChallenge.playerMoveGoal} moves. Find the first move.';
      }
    }
    if (_gameMode == GameMode.computer && !_humanPlaysWhite) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAiMove());
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
          _archiveFinishedGame();
          unawaited(ChessSoundService.instance.victory());
        }
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _moveQualityTimer?.cancel();
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
    final Set<String> legalTargets = !_showMoveHints || _selectedSquare == null
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
                flipped: _shouldFlipBoard(sideToMoveWhite),
                showCoordinates: _showCoordinates,
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
                onNewGameRequested: _confirmNewGame,
                onResign: _resignGame,
                onOfferDraw: _offerDraw,
                onMoveHistory: _showMoveHistory,
                onUndo: _undo,
                onHint: _showHint,
                onAnalyze: _showAnalysis,
                soundEnabled: _soundEnabled,
                showCoordinates: _showCoordinates,
                showMoveHints: _showMoveHints,
                onSoundChanged: _setSoundEnabled,
                onShowCoordinatesChanged: (bool value) {
                  setState(() => _showCoordinates = value);
                },
                onShowMoveHintsChanged: (bool value) {
                  setState(() => _showMoveHints = value);
                },
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
                    if (wide) ...<Widget>[
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: widePanelWidth + 8,
                        child: Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: boardDimension,
                            height: boardDimension,
                            child: BoardStage(
                              palette: palette,
                              child: board,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: AnimatedContainer(
                          key: const ValueKey<String>(
                            'landscape-game-controls',
                          ),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          width: widePanelWidth,
                          child: panel,
                        ),
                      ),
                    ] else
                      Column(
                        children: <Widget>[
                          CompactHeader(
                            playerName: _whitePlayerName,
                            onReset: _confirmNewGame,
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
                          title: _resultDisplayTitle(),
                          detail: _gameResultDetail ?? 'Game complete',
                          scoreLabel: _resultScoreLabel(),
                          onNewGame: _reset,
                          onReview: () => setState(() {
                            _resultVisible = false;
                          }),
                        ),
                      ),
                    if (_moveQualityText != null &&
                        _gameMode == GameMode.computer &&
                        _gameResultTitle == null)
                      Positioned(
                        left: wide ? 22 : 18,
                        right: wide ? widePanelWidth + 30 : 18,
                        bottom: wide
                            ? 18
                            : math.max(
                                18,
                                constraints.maxHeight -
                                    mobileHeaderHeight -
                                    boardDimension -
                                    2,
                              ),
                        child: IgnorePointer(
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF16171C)
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFD6A84F)
                                      .withValues(alpha: 0.72),
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.32),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.psychology_alt_rounded,
                                      color: Color(0xFFD6A84F),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _moveQualityText!,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFF6F1E8),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
      _authMessage = AppConfig.usesDummySocialConfig
          ? 'Google, Apple, Facebook, and VPS placeholders are wired. Replace dummy IDs/tokens in CI/VPS before store release. ChessVerse login and Guest Player work now.'
          : 'Social login config is present. Backend OAuth callback endpoints must be enabled on the live VPS before store release.';
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
      _applyPlayerSideNames(_playerDisplayName);
    });
    _reset();
  }

  String get _playerDisplayName {
    final String trimmed = widget.initialPlayerName?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return widget.initiallySignedIn ? 'Guest Player' : _whitePlayerName;
  }

  void _applyPlayerSideNames(String playerName) {
    switch (_gameMode) {
      case GameMode.computer:
        _whitePlayerName = _humanPlaysWhite ? playerName : 'ChessVerse AI';
        _blackPlayerName = _humanPlaysWhite ? 'ChessVerse AI' : playerName;
      case GameMode.daily:
        _whitePlayerName = 'Guest Player';
        _blackPlayerName = 'Puzzle Defense';
      case GameMode.local:
        _whitePlayerName = _humanPlaysWhite ? playerName : 'Player 2';
        _blackPlayerName = _humanPlaysWhite ? 'Player 2' : playerName;
      case GameMode.online:
        _whitePlayerName = playerName;
        _blackPlayerName = 'Online Rival';
    }
  }

  bool _shouldFlipBoard(bool sideToMoveWhite) {
    if (_gameMode == GameMode.computer) {
      return !_humanPlaysWhite;
    }
    if (_gameMode == GameMode.local) {
      return !sideToMoveWhite;
    }
    return false;
  }

  void _changeDailyDifficulty(DailyChallengeDifficulty difficulty) {
    setState(() => _dailyDifficulty = difficulty);
    _reset();
  }

  int get _dailyPlayerMovesCompleted => (_dailyPlyIndex + 1) ~/ 2;

  String? get _dailyExpectedMove => _gameMode == GameMode.daily &&
          _dailyPlyIndex < _dailyChallenge.solution.length
      ? _dailyChallenge.solution[_dailyPlyIndex]
      : null;

  bool get _dailyPuzzleSolved =>
      _gameMode == GameMode.daily &&
      _dailyPlyIndex >= _dailyChallenge.solution.length;

  String _moveFeedback({
    required ChessPiece piece,
    required String from,
    required String to,
    required ChessPiece? captured,
    required bool castleMove,
  }) {
    final bool givesCheck = ChessRules.isKingInCheck(!piece.white, _pieces);
    final SquarePosition target = ChessRules.positionOf(to);
    final bool central = target.file >= 2 &&
        target.file <= 5 &&
        target.rank >= 3 &&
        target.rank <= 6;
    if (givesCheck && captured != null) {
      return 'Amazing step - check with material gain.';
    }
    if (givesCheck || castleMove || captured?.code == 'Q') {
      return 'Superb step - strong chess idea.';
    }
    if (captured != null || central) {
      return 'Good step - useful improvement.';
    }
    if (piece.code == 'K' && !castleMove) {
      return 'Not good step - king safety first.';
    }
    return 'Average step - playable, but look for more pressure.';
  }

  String _moveSuggestionText(
    PositionAnalysis analysis,
    String from,
    String to,
  ) {
    final String playedMove = '$from to $to';
    final String? bestMove = analysis.bestMove;
    if (bestMove == null) {
      return 'No stronger coach suggestion found.';
    }
    if (bestMove == playedMove) {
      return 'Coach agrees: this was the best move.';
    }
    return 'Coach idea: move $bestMove for a ${analysis.quality.toLowerCase()}.';
  }

  void _scheduleMoveQualityDismiss() {
    _moveQualityTimer?.cancel();
    _moveQualityTimer = Timer(const Duration(milliseconds: 2300), () {
      if (mounted) {
        setState(() => _moveQualityText = null);
      }
    });
  }

  String _resultScoreLabel() {
    final String lowerTitle = (_gameResultTitle ?? '').toLowerCase();
    if (lowerTitle.contains('draw')) {
      return '1/2 - 1/2';
    }
    if (lowerTitle.contains('challenge complete')) {
      return '1 - 0';
    }
    final bool whiteWon = lowerTitle.startsWith('white');
    final bool blackWon = lowerTitle.startsWith('black');
    if (!whiteWon && !blackWon) {
      return '1 - 0';
    }
    final bool userWon = _humanPlaysWhite ? whiteWon : blackWon;
    return userWon ? '1 - 0' : '0 - 1';
  }

  String _resultDisplayTitle() {
    final String title = _gameResultTitle ?? 'Game complete';
    final String lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('draw') ||
        lowerTitle.contains('challenge complete') ||
        _gameMode != GameMode.computer) {
      return title;
    }
    final bool whiteWon = lowerTitle.startsWith('white');
    final bool blackWon = lowerTitle.startsWith('black');
    if (!whiteWon && !blackWon) {
      return title;
    }
    final bool userWon = _humanPlaysWhite ? whiteWon : blackWon;
    return userWon ? 'You win' : 'ChessVerse AI wins';
  }

  DailyChallenge _challengeForToday(
    DailyChallengeDifficulty difficulty,
  ) {
    final DateTime today = DateTime.now().toUtc();
    final DateTime dayKey = DateTime.utc(today.year, today.month, today.day);
    final int seed = dayKey.difference(DateTime.utc(2026)).inDays;
    final int pattern = seed % 3;
    final String date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final String title = switch (pattern) {
      0 => 'Royal Net',
      1 => 'Back Rank Spark',
      _ => 'Moonlight Mate',
    };
    return DailyChallenge(
      id: '$date-${difficulty.name}-p$pattern',
      title: '$title - ${difficulty.label}',
      difficulty: difficulty,
      pattern: pattern,
      setupMoves: _dailySetupLine(difficulty, pattern),
      solution: _dailySolutionLine(difficulty, pattern),
    );
  }

  List<String> _dailySetupLine(
    DailyChallengeDifficulty difficulty,
    int pattern,
  ) {
    // Start from a real chess position after legal opening moves. Keeping the
    // setup legal is more important than making a flashy position: the user
    // must never see same-colour captures or a false mate.
    return switch (difficulty) {
      DailyChallengeDifficulty.easy => <String>['e2e4', 'e7e5'],
      DailyChallengeDifficulty.medium => const <String>[],
      DailyChallengeDifficulty.hard => const <String>[],
    };
  }

  List<String> _dailySolutionLine(
    DailyChallengeDifficulty difficulty,
    int pattern,
  ) {
    final List<List<String>> lines = <List<String>>[
      // Easy: position starts after 1. e4 e5, then White finds the
      // three-move Scholar mate pattern.
      <String>['d1h5', 'b8c6', 'f1c4', 'g8f6', 'h5f7'],
      // Medium: same legal pattern from the starting board, four White moves.
      <String>['e2e4', 'e7e5', 'd1h5', 'b8c6', 'f1c4', 'g8f6', 'h5f7'],
      // Hard: one waiting move is included before the forced mating pattern,
      // giving the player five legal White moves before checkmate.
      <String>[
        'a2a3',
        'a7a6',
        'e2e4',
        'e7e5',
        'd1h5',
        'b8c6',
        'f1c4',
        'g8f6',
        'h5f7',
      ],
    ];
    return switch (difficulty) {
      DailyChallengeDifficulty.easy => lines[0],
      DailyChallengeDifficulty.medium => lines[1],
      DailyChallengeDifficulty.hard => lines[2],
    };
  }

  Map<String, ChessPiece> _dailyStartingPosition(DailyChallenge challenge) {
    Map<String, ChessPiece> pieces = Map<String, ChessPiece>.from(
      _initialPieces,
    );
    for (final String move in challenge.setupMoves) {
      final String from = move.substring(0, 2);
      final String to = move.substring(2, 4);
      final ChessPiece? piece = pieces[from];
      if (piece == null ||
          !ChessRules.safeLegalTargets(from, pieces).contains(to)) {
        return Map<String, ChessPiece>.from(_initialPieces);
      }
      pieces = ChessRules.applyMove(from, to, pieces);
    }
    return pieces;
  }

  void _applyDailyCompletionState() {
    if (!_dailyCompletedToday || _gameMode != GameMode.daily) {
      return;
    }
    _gameResultTitle = 'Challenge complete';
    _gameResultDetail = 'Come back tomorrow for a new checkmate puzzle';
    _resultVisible = true;
    _coachNote =
        "Today's Daily Checkmate is complete. A new challenge unlocks tomorrow.";
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
      if (_gameMode == GameMode.computer && whitesTurn != _humanPlaysWhite) {
        _coachNote = 'ChessVerse AI is calculating its reply.';
        return;
      }
      if (_selectedSquare == null) {
        final ChessPiece? piece = _pieces[square];
        if (piece == null) {
          _coachNote = 'Choose one of your coins first.';
          unawaited(ChessSoundService.instance.error());
          return;
        }
        final String? expectedMove = _dailyExpectedMove;
        if (_gameMode == GameMode.daily &&
            expectedMove != null &&
            square != expectedMove.substring(0, 2)) {
          _coachNote =
              'Daily Checkmate is a tactical line. Find the forcing coin.';
          unawaited(ChessSoundService.instance.error());
          return;
        }
        if (piece.white != whitesTurn) {
          _coachNote = '${whitesTurn ? 'White' : 'Black'} to move.';
          unawaited(ChessSoundService.instance.error());
          return;
        }
        final List<String> targets = _legalTargetsFor(square);
        if (targets.isEmpty) {
          _coachNote = '${piece.code} has no legal target from $square.';
          unawaited(ChessSoundService.instance.error());
        } else {
          _selectedSquare = square;
          final String suffix = targets.length == 1 ? '' : 's';
          _coachNote =
              '${piece.code} from $square has ${targets.length} option$suffix.';
          unawaited(ChessSoundService.instance.tap());
        }
        return;
      }

      if (_selectedSquare == square) {
        _selectedSquare = null;
        unawaited(ChessSoundService.instance.tap());
        return;
      }

      final List<String> legalTargets = _legalTargetsFor(_selectedSquare!);
      if (!legalTargets.contains(square)) {
        _coachNote = 'That move is blocked. Pick a highlighted square.';
        _selectedSquare = null;
        unawaited(ChessSoundService.instance.error());
        return;
      }

      final String from = _selectedSquare!;
      final PositionAnalysis preMoveAnalysis = _analyzePosition(whitesTurn);
      if (_gameMode == GameMode.daily) {
        final String expected = _dailyChallenge.solution[_dailyPlyIndex];
        if ('$from$square' != expected) {
          _dailyMistakes++;
          _coachNote =
              'Not the mating line. Try again - the position is unchanged.';
          _selectedSquare = null;
          unawaited(ChessSoundService.instance.error());
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
        unawaited(
          captured == null
              ? ChessSoundService.instance.move()
              : ChessSoundService.instance.capture(),
        );
        if (_gameMode == GameMode.daily) {
          _dailyPlyIndex++;
        }
        final String moveFeedback = _moveFeedback(
          piece: piece,
          from: from,
          to: square,
          captured: captured,
          castleMove: castleMove,
        );
        if (_gameMode == GameMode.computer) {
          _moveQualityText =
              '$moveFeedback ${_moveSuggestionText(preMoveAnalysis, from, square)}';
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
          if (_gameResultTitle == null) {
            _coachNote = '$moveFeedback $_coachNote';
          }
          if (_gameMode == GameMode.daily && _dailyPuzzleSolved) {
            final bool opponentMated =
                ChessRules.isKingInCheck(!piece.white, _pieces) &&
                    !ChessRules.hasAnySafeMove(!piece.white, _pieces);
            if (opponentMated) {
              _gameResultTitle = 'Challenge complete';
              _gameResultDetail =
                  '${_dailyChallenge.playerMoveGoal}-move checkmate';
              _resultVisible = true;
              _dailyCompletedToday = true;
              LocalGameArchive.markDailyChallengeComplete(_dailyChallenge.id);
              _archiveFinishedGame();
              unawaited(ChessSoundService.instance.checkmate());
              _coachNote =
                  "Brilliant! Today's ${_dailyDifficulty.label.toLowerCase()} challenge is complete.";
            } else {
              _coachNote =
                  'Puzzle line reached, but this is not true checkmate. Please reset and retry.';
              _gameResultTitle = null;
              _gameResultDetail = null;
            }
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
      if (_moveQualityText != null) {
        _scheduleMoveQualityDismiss();
      }
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
    final bool aiPlaysWhite = !_humanPlaysWhite;
    final bool aiTurn = _moves.length.isEven == aiPlaysWhite;
    if (_gameMode != GameMode.computer ||
        !aiTurn ||
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
      _coachNote = 'Puzzle defense is replying...';
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
      unawaited(
        captured == null
            ? ChessSoundService.instance.move()
            : ChessSoundService.instance.capture(),
      );
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
    final bool aiPlaysWhite = !_humanPlaysWhite;
    final bool aiTurn = _moves.length.isEven == aiPlaysWhite;
    if (!mounted ||
        _gameMode != GameMode.computer ||
        _gameResultTitle != null ||
        !_aiThinking ||
        !aiTurn) {
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
          if (_pieces[from]?.white == aiPlaysWhite &&
              _legalTargetsFor(from).contains(to)) {
            engineMove = AiCandidate(from, to, 1000);
          }
        }
      } on EngineApiException {
        // The deterministic local fallback keeps offline games playable.
      }
    }

    final bool aiStillTurn = _moves.length.isEven == aiPlaysWhite;
    if (!mounted ||
        _gameMode != GameMode.computer ||
        _gameResultTitle != null ||
        !_aiThinking ||
        !aiStillTurn) {
      return;
    }

    final List<AiCandidate> candidates = <AiCandidate>[];
    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white != aiPlaysWhite) {
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
        _moveCastlingRook(move.to, piece.white);
      }
      if (piece.code == 'P' &&
          ((piece.white && move.to.endsWith('8')) ||
              (!piece.white && move.to.endsWith('1')))) {
        _pieces[move.to] = ChessPiece('Q', piece.white);
      }
      final String notation = castleMove
          ? (move.to.startsWith('g') ? 'O-O' : 'O-O-O')
          : captured == null
              ? '${move.from}${move.to}'
              : '${move.from} x ${move.to}';
      _moves.insert(0, notation);
      unawaited(
        captured == null
            ? ChessSoundService.instance.move()
            : ChessSoundService.instance.capture(),
      );
      final String action = captured == null
          ? '${piece.code} moves to ${move.to}.'
          : '${piece.code} captures ${captured.code} on ${move.to}.';
      _coachNote = _gameStateNote(
        !piece.white,
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
    final bool completedToday =
        LocalGameArchive.isDailyChallengeComplete(challenge.id);
    final Map<String, ChessPiece> resetPieces = _gameMode == GameMode.daily
        ? _dailyStartingPosition(challenge)
        : Map<String, ChessPiece>.from(_initialPieces);
    setState(() {
      _applyPlayerSideNames(_playerDisplayName);
      _dailyChallenge = challenge;
      _dailyCompletedToday = completedToday;
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
      _moveQualityText = null;
      _whiteSeconds = 10 * 60;
      _blackSeconds = 10 * 60;
      _selectedSquare = null;
      _aiThinking = false;
      _coachNote = _gameMode == GameMode.daily
          ? completedToday
              ? "Today's Daily Checkmate is complete. A new challenge unlocks tomorrow."
              : 'Checkmate in ${challenge.playerMoveGoal} moves. Find the first move.'
          : 'Select a coin to see legal moves.';
      _gameResultTitle = completedToday && _gameMode == GameMode.daily
          ? 'Challenge complete'
          : null;
      _gameResultDetail = completedToday && _gameMode == GameMode.daily
          ? 'Come back tomorrow for a new checkmate puzzle'
          : null;
      _resultVisible = true;
      _resultSaved = false;
      _checkWarningActive = false;
    });
  }

  Future<void> _confirmNewGame() async {
    if (_moves.isEmpty && _gameResultTitle == null) {
      _reset();
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Start new game?'),
        content: const Text(
          'Current board will be cleared. Finished games are saved automatically.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('New game'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _reset();
    }
  }

  void _setSoundEnabled(bool value) {
    setState(() => _soundEnabled = value);
    ChessSoundService.instance.enabled = value;
  }

  void _resignGame() {
    if (_gameResultTitle != null) {
      return;
    }
    final bool whiteToMove = _moves.length.isEven;
    setState(() {
      _gameResultTitle = whiteToMove ? 'Black wins' : 'White wins';
      _gameResultDetail =
          '${whiteToMove ? _whitePlayerName : _blackPlayerName} resigned';
      _resultVisible = true;
      _coachNote = 'Resignation accepted. $_gameResultTitle.';
      _archiveFinishedGame();
    });
    unawaited(ChessSoundService.instance.victory());
  }

  Future<void> _offerDraw() async {
    if (_gameResultTitle != null) {
      return;
    }
    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Offer draw?'),
        content: const Text(
          'For offline play this records a mutual draw immediately.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accept draw'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      setState(() {
        _gameResultTitle = 'Draw';
        _gameResultDetail = 'Draw agreed';
        _resultVisible = true;
        _coachNote = 'Draw agreed by both players.';
        _archiveFinishedGame();
      });
      unawaited(ChessSoundService.instance.draw());
    }
  }

  void _archiveFinishedGame() {
    if (_resultSaved || _gameResultTitle == null) {
      return;
    }
    _resultSaved = true;
    LocalGameArchive.addGame(
      SavedGameRecord(
        mode: switch (_gameMode) {
          GameMode.computer => 'Play vs AI',
          GameMode.daily => 'Daily Checkmate',
          GameMode.local => '2 Players',
          GameMode.online => 'Online',
        },
        result: _gameResultTitle!,
        detail: _gameResultDetail ?? 'Game complete',
        moves: List<String>.from(_moves.reversed),
        playedAt: DateTime.now(),
        whitePlayer: _whitePlayerName,
        blackPlayer: _blackPlayerName,
      ),
    );
  }

  void _showMoveHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => MoveHistorySheet(moves: _moves),
    );
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
    final double bestScore = bestMove?.score ?? 0;
    final String quality = bestMove == null
        ? 'No move'
        : bestScore >= 14
            ? 'Best move'
            : bestScore >= 7
                ? 'Good move'
                : bestScore >= 3
                    ? 'Ordinary move'
                    : 'Quiet move';
    final String coachLine = bestMove == null
        ? 'No legal move is available in this position.'
        : bestScore >= 14
            ? 'This move creates a strong tactical threat or wins material.'
            : bestScore >= 7
                ? 'This is a healthy move: it improves the position and keeps pressure.'
                : bestScore >= 3
                    ? 'Playable, but keep looking for forcing checks, captures, or threats.'
                    : 'Safe but quiet. A sharper move may exist if you calculate forcing lines.';
    return PositionAnalysis(
      side: whiteToMove ? 'White' : 'Black',
      evaluation: evaluation,
      material: material,
      legalMoves: legalMoveCount,
      captures: captureCount,
      bestMove: bestMove == null ? null : '${bestMove.from} to ${bestMove.to}',
      quality: quality,
      coachLine: coachLine,
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
      isScrollControlled: true,
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
      unawaited(ChessSoundService.instance.check());
      unawaited(_playCheckWarning());
    } else if (!inCheck) {
      _checkWarningActive = false;
    }

    if (inCheck && !hasMove) {
      _gameResultTitle = '${sideToMoveWhite ? 'Black' : 'White'} wins';
      _gameResultDetail = 'Checkmate';
      _resultVisible = true;
      _archiveFinishedGame();
      unawaited(ChessSoundService.instance.checkmate());
      return 'Checkmate. $_gameResultTitle.';
    }
    if (!inCheck && !hasMove) {
      _gameResultTitle = 'Draw';
      _gameResultDetail = 'Stalemate';
      _resultVisible = true;
      _archiveFinishedGame();
      unawaited(ChessSoundService.instance.draw());
      return 'Stalemate. No legal move for $side.';
    }
    if (inCheck) {
      return '$side is in check.';
    }
    return fallback;
  }

  Future<void> _playCheckWarning() async {
    if (!ChessSoundService.instance.enabled) {
      return;
    }
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.62),
            blurRadius: 38,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.24),
            blurRadius: 26,
            spreadRadius: -4,
            offset: const Offset(-5, -7),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                Colors.white.withValues(alpha: 0.22),
                palette.frame,
              ),
              Color.alphaBlend(
                palette.accent.withValues(alpha: 0.18),
                palette.frame,
              ),
              Color.alphaBlend(
                Colors.black.withValues(alpha: 0.42),
                palette.frame,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1.4,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: palette.accent.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: child,
            ),
          ),
        ),
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
    required this.showCoordinates,
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
  final bool showCoordinates;
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
                  showRank: showCoordinates && col == 0,
                  showFile: showCoordinates && row == 7,
                  onTap: () => onSquareTap(square),
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.10),
                        blurRadius: 18,
                        spreadRadius: -6,
                        offset: const Offset(-8, -8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        spreadRadius: -6,
                        offset: const Offset(8, 10),
                      ),
                    ],
                  ),
                ),
              ),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: dark ? 0.10 : 0.22),
                    squareColor,
                  ),
                  squareColor,
                  Color.alphaBlend(
                    Colors.black.withValues(alpha: dark ? 0.18 : 0.08),
                    squareColor,
                  ),
                ],
                stops: const <double>[0, 0.48, 1],
              ),
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
                    color:
                        const Color(0xFFBDE6FF).withValues(alpha: 0.72 * glow),
                    blurRadius: 22,
                    spreadRadius: 4,
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
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: dark ? 0.045 : 0.09),
                        Colors.transparent,
                        Colors.black.withValues(alpha: dark ? 0.10 : 0.045),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                    borderRadius: BorderRadius.circular(12),
                    gradient: RadialGradient(
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.92),
                        const Color(0xFFCBEAFF).withValues(alpha: 0.72),
                        const Color(0xFF6DBDFF).withValues(alpha: 0.28),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF8EDBFF).withValues(alpha: 0.72),
                        blurRadius: 24,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.42),
                        blurRadius: 8,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: const SizedBox(width: 28, height: 28),
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
                  bottom: pieceSize * 0.08,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          (piece.white
                                  ? const Color(0xFFFFF0C8)
                                  : const Color(0xFF5D6674))
                              .withValues(alpha: 0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SizedBox(
                      width: pieceSize * 0.72,
                      height: pieceSize * 0.34,
                    ),
                  ),
                ),
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
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: pieceSize * 0.16,
                          offset: Offset(0, pieceSize * 0.08),
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
                Transform.translate(
                  offset: Offset(0, selected ? -pieceSize * 0.035 : 0),
                  child: Image.asset(
                    pieceAsset(piece),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    semanticLabel:
                        '${piece.white ? 'White' : 'Black'} ${pieceName(piece.code)}',
                  ),
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
    required this.onNewGameRequested,
    required this.onResign,
    required this.onOfferDraw,
    required this.onMoveHistory,
    required this.onUndo,
    required this.onHint,
    required this.onAnalyze,
    required this.soundEnabled,
    required this.showCoordinates,
    required this.showMoveHints,
    required this.onSoundChanged,
    required this.onShowCoordinatesChanged,
    required this.onShowMoveHintsChanged,
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
  final VoidCallback onNewGameRequested;
  final VoidCallback onResign;
  final VoidCallback onOfferDraw;
  final VoidCallback onMoveHistory;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onAnalyze;
  final bool soundEnabled;
  final bool showCoordinates;
  final bool showMoveHints;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onShowCoordinatesChanged;
  final ValueChanged<bool> onShowMoveHintsChanged;
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
                  final bool whiteMove = (moves.length - 1 - index).isEven;
                  final String move = moves[index];
                  return ListTile(
                    dense: true,
                    minLeadingWidth: 32,
                    leading: Text('${moves.length - index}.'),
                    title: Row(
                      children: <Widget>[
                        Expanded(child: Text(move)),
                        MoveQualityBadge(move: move),
                      ],
                    ),
                    subtitle: Text(
                      moveCoachNoteForMove(move, whiteMove),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    tooltip: 'New game',
                    onPressed: onNewGameRequested,
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
                tooltip: 'New game',
                onPressed: onNewGameRequested,
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
          GameModeLauncher(
            selected: gameMode,
            compact: compact,
            onChanged: onGameModeChanged,
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
            DailyDifficultyChips(
              selected: dailyDifficulty,
              onChanged: onDailyDifficultyChanged,
            ),
            if (dailyMistakes > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '$dailyMistakes attempt${dailyMistakes == 1 ? '' : 's'} missed - keep calculating',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              SizedBox(
                width: compact ? 116 : 132,
                child: _PanelActionButton(
                  onPressed: onMoveHistory,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('History'),
                ),
              ),
              SizedBox(
                width: compact ? 100 : 118,
                child: _PanelActionButton(
                  onPressed: onOfferDraw,
                  icon: const Icon(Icons.handshake_rounded),
                  label: const Text('Draw'),
                ),
              ),
              SizedBox(
                width: compact ? 108 : 124,
                child: _PanelActionButton(
                  onPressed: onResign,
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Resign'),
                ),
              ),
            ],
          ),
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
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: soundEnabled,
              onChanged: onSoundChanged,
              title: const Text('Sound effects'),
              secondary: const Icon(Icons.volume_up_rounded),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: showCoordinates,
              onChanged: onShowCoordinatesChanged,
              title: const Text('Show coordinates'),
              secondary: const Icon(Icons.grid_4x4_rounded),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: showMoveHints,
              onChanged: onShowMoveHintsChanged,
              title: const Text('Move hints'),
              secondary: const Icon(Icons.lightbulb_outline_rounded),
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.view_in_ar_rounded),
            title: Text('Piece theme'),
            subtitle: Text('Staunton 3D active - more themes coming soon'),
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

class _PanelActionButton extends StatelessWidget {
  const _PanelActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: IconTheme.merge(
        data: const IconThemeData(size: 18),
        child: icon,
      ),
      label: DefaultTextStyle.merge(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: label,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 50),
      ),
    );
  }
}

class GameModeLauncher extends StatelessWidget {
  const GameModeLauncher({
    required this.selected,
    required this.compact,
    required this.onChanged,
    super.key,
  });

  final GameMode selected;
  final bool compact;
  final ValueChanged<GameMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<_GameModeChoice> choices = <_GameModeChoice>[
      const _GameModeChoice(
        mode: GameMode.computer,
        icon: Icons.smart_toy_rounded,
        title: 'Play vs AI',
        subtitle: 'Challenge ChessVerse',
      ),
      const _GameModeChoice(
        mode: GameMode.daily,
        icon: Icons.local_fire_department_rounded,
        title: 'Daily Checkmate',
        subtitle: 'Finish a late-game puzzle',
      ),
      const _GameModeChoice(
        mode: GameMode.local,
        icon: Icons.groups_2_rounded,
        title: '2 Players',
        subtitle: 'Same-device match',
      ),
      const _GameModeChoice(
        mode: GameMode.online,
        icon: Icons.public_rounded,
        title: 'Online',
        subtitle: 'Coming soon',
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices.map((choice) {
        final bool active = selected == choice.mode;
        return SizedBox(
          width: compact ? 148 : 178,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(choice.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: active
                      ? const <Color>[Color(0xFF2B2140), Color(0xFF6D4FD8)]
                      : <Color>[
                          const Color(0xFF211D24),
                          const Color(0xFF111C18).withValues(alpha: 0.92),
                        ],
                ),
                border: Border.all(
                  color: active
                      ? const Color(0xFFE2B458)
                      : const Color(0xFF7A6038).withValues(alpha: 0.55),
                ),
                boxShadow: <BoxShadow>[
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF6D4FD8).withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Icon(choice.icon, color: const Color(0xFFE2B458), size: 22),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          choice.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          choice.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _GameModeChoice {
  const _GameModeChoice({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final GameMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
}

class DailyDifficultyChips extends StatelessWidget {
  const DailyDifficultyChips({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final DailyChallengeDifficulty selected;
  final ValueChanged<DailyChallengeDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DailyChallengeDifficulty.values.map((difficulty) {
        final bool active = selected == difficulty;
        return ChoiceChip(
          selected: active,
          avatar: Icon(
            Icons.emoji_events_outlined,
            size: 18,
            color: active ? Colors.black : const Color(0xFFE2B458),
          ),
          label: Text(difficulty.label),
          onSelected: (_) => onChanged(difficulty),
        );
      }).toList(growable: false),
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
                          'AI Agent Coach',
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
                    icon: Icons.auto_graph_rounded,
                    label: 'Move quality',
                    value: analysis.quality,
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
                                  : 'Recommended: ${analysis.bestMove}\n${analysis.coachLine}',
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
    const String roomCode = 'CV-7429';
    final Size size = MediaQuery.sizeOf(context);
    final bool landscape = size.width > size.height;
    final double maxWidth = landscape ? 760 : 560;
    final double maxHeight = size.height * (landscape ? 0.82 : 0.9);

    return SafeArea(
      child: Align(
        alignment: landscape ? Alignment.center : Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF17231F),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(18),
                bottom: Radius.circular(landscape ? 18 : 0),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22,
                landscape ? 16 : 18,
                22,
                landscape ? 18 : 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.public_rounded,
                        size: 34,
                        color: Color(0xFF63D2B8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Online 2 Players',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose Play with Friend using a room code, or Random Match to pair with another online player after VPS/WebSocket deployment.',
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF3B2376), Color(0xFF10251E)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8B7147)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.travel_explore_rounded,
                                color: Color(0xFFD6A84F),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Random Match',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const Chip(label: Text('Coming soon')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Auto-match with any available ChessVerse player worldwide.',
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.bolt_rounded),
                            label: const Text('Find random player'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF242128),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF6C5530)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Text('Play with Friend - invite room code'),
                          const SizedBox(height: 8),
                          SelectableText(
                            roomCode,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: const Color(0xFFD6A84F),
                                  letterSpacing: 2,
                                  fontSize: landscape ? 30 : null,
                                ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(text: roomCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invite code copied'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy invite code'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Join code',
                      prefixIcon: Icon(Icons.login_rounded),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.group_add_rounded),
                        label: const Text('Create room'),
                      ),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.sports_esports_rounded),
                        label: const Text('Join mock'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Waiting screen, room code, and invite flow are local UI only until backend is live.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFAAA69E), fontSize: 12),
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

class MoveHistorySheet extends StatelessWidget {
  const MoveHistorySheet({required this.moves, super.key});

  final List<String> moves;

  @override
  Widget build(BuildContext context) {
    final List<String> chronological = moves.reversed.toList(growable: false);
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (BuildContext context, ScrollController controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF17231F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Move History',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: chronological.isEmpty
                      ? const EmptyMoveState()
                      : ListView.separated(
                          controller: controller,
                          itemCount: chronological.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final bool whiteMove = index.isEven;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: whiteMove
                                    ? const Color(0xFFE9D5B7)
                                    : const Color(0xFF242128),
                                foregroundColor:
                                    whiteMove ? Colors.black : Colors.white,
                                child: Text('${index + 1}'),
                              ),
                              title: Row(
                                children: <Widget>[
                                  Expanded(child: Text(chronological[index])),
                                  MoveQualityBadge(move: chronological[index]),
                                ],
                              ),
                              subtitle: Text(
                                moveCoachNoteForMove(
                                  chronological[index],
                                  whiteMove,
                                ),
                              ),
                            );
                          },
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

class MoveQualityBadge extends StatelessWidget {
  const MoveQualityBadge({required this.move, super.key});

  final String move;

  @override
  Widget build(BuildContext context) {
    final String label = moveCoachLabelForMove(move);
    final Color color = moveCoachColorForLabel(label);
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String moveCoachLabelForMove(String move) {
  final String clean = move.replaceAll(' e.p.', '').trim().toLowerCase();
  if (clean.contains('o-o') ||
      clean.contains('+') ||
      clean.contains('check')) {
    return 'Superb';
  }
  if (clean.contains('x')) {
    return 'Good';
  }
  if (clean.length >= 4 &&
      <String>{'d4', 'd5', 'e4', 'e5'}.contains(
        clean.substring(clean.length - 2),
      )) {
    return 'Good';
  }
  return 'Average';
}

Color moveCoachColorForLabel(String label) {
  return switch (label) {
    'Superb' => const Color(0xFF63D2B8),
    'Good' => const Color(0xFFD6A84F),
    _ => const Color(0xFFAAA69E),
  };
}

String moveCoachNoteForMove(String move, bool whiteMove) {
  final String side = whiteMove ? 'White' : 'Black';
  final String clean = move.replaceAll(' e.p.', '').trim();
  if (clean.contains('O-O')) {
    return '$side superb step: king safety improved. Best follow-up is central pressure.';
  }
  if (clean.contains('+') || clean.toLowerCase().contains('check')) {
    return '$side superb step: check creates tempo. Calculate every king reply.';
  }
  if (clean.contains('x')) {
    return '$side good step: capture found. Before moving, compare checks and stronger captures.';
  }
  if (clean.length >= 4 &&
      <String>{'d4', 'd5', 'e4', 'e5'}.contains(
        clean.substring(clean.length - 2),
      )) {
    return '$side good step: central square controlled. Next develop with tempo.';
  }
  return '$side average step: playable. Best habit: check checks, captures, then threats.';
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
    required this.scoreLabel,
    required this.onNewGame,
    required this.onReview,
    super.key,
  });

  final String title;
  final String detail;
  final String scoreLabel;
  final VoidCallback onNewGame;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final bool draw = title.toLowerCase().contains('draw');
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
                  Icon(
                    draw ? Icons.handshake_rounded : Icons.emoji_events_rounded,
                    color: draw
                        ? const Color(0xFFAAA69E)
                        : const Color(0xFFD6A84F),
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
                    scoreLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: const Color(0xFFD6A84F),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(detail, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'Saved locally. Open Saved Games to review this match.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFAAA69E)),
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
