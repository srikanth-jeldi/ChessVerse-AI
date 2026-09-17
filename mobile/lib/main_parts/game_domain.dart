part of '../main.dart';

enum BoardSkin {
  royalWalnut,
  oceanTeal,
  midnightSapphire,
  emeraldArena,
  amethystClash,
  desertGold,
  frostMarble,
  jadeDynasty,
  azureTemple,
  volcanicObsidian,
  roseQuartz,
  celestialSilver,
  jadeGlass,
  tournament,
  marble,
  sapphire,
}

enum GameMode { computer, daily, puzzle, local, online }

enum DailyChallengeDifficulty { easy, medium, hard }

String dailyChallengeDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

int dailyChallengePatternForDate(DateTime date) {
  final DateTime day = DateTime(date.year, date.month, date.day);
  final int rawPattern =
      day.difference(DateTime(2026)).inDays % dailyChallengeRotationLength;
  return rawPattern < 0
      ? rawPattern + dailyChallengeRotationLength
      : rawPattern;
}

const int dailyChallengeRotationLength = 49;

const List<String> dailyChallengeQueenFiles = <String>[
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
];

String dailyChallengeQueenFileForPattern(int pattern) {
  final int normalized =
      ((pattern % dailyChallengeQueenFiles.length) +
          dailyChallengeQueenFiles.length) %
      dailyChallengeQueenFiles.length;
  return dailyChallengeQueenFiles[normalized];
}

List<String> dailyChallengeSolutionFor(
  DailyChallengeDifficulty difficulty,
  int pattern,
) {
  final String file = dailyChallengeQueenFileForPattern(pattern);
  return switch (difficulty) {
    DailyChallengeDifficulty.easy => <String>[
      '${file}1${file}3',
      'a7a6',
      '${file}3h3',
      'a6a5',
      'h3h7',
    ],
    DailyChallengeDifficulty.medium => <String>[
      '${file}1${file}2',
      'a7a6',
      '${file}2${file}3',
      'a6a5',
      '${file}3h3',
      'b7b6',
      'h3h7',
    ],
    DailyChallengeDifficulty.hard => <String>[
      '${file}1${file}2',
      'a7a6',
      '${file}2${file}3',
      'a6a5',
      '${file}3h3',
      'b7b6',
      'h3h4',
      'b6b5',
      'h4h7',
    ],
  };
}

enum PlayerSideChoice { white, random, black }

enum _FriendPlayChoice { online, local }

class _FriendPlayChoiceCard extends StatelessWidget {
  const _FriendPlayChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2234),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: .72)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: .7)),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFF8ED),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFAFBCCB),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameLaunchChoice {
  const _GameLaunchChoice(this.side, this.aiLevel, this.aiStyle);

  final PlayerSideChoice side;
  final double aiLevel;
  final AiBotStyle aiStyle;
}

Future<void> _restoreDailyReminder() async {
  const AppPreferences preferences = AppPreferences();
  final bool enabled = await preferences.readBool(
    'dailyReminder',
    fallback: true,
  );
  if (enabled) {
    final bool allowed = await DailyReminderService.instance.enable();
    await preferences.writeBool('dailyReminder', allowed);
  }
}

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
    DailyChallengeDifficulty.easy => 'Easy - mate in 3',
    DailyChallengeDifficulty.medium => 'Medium - mate in 4',
    DailyChallengeDifficulty.hard => 'Hard - mate in 5',
  };

  int get moveGoal => switch (this) {
    DailyChallengeDifficulty.easy => 3,
    DailyChallengeDifficulty.medium => 4,
    DailyChallengeDifficulty.hard => 5,
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
    this.initialFen,
    this.forcedPlayerMoves,
  });

  final String id;
  final String title;
  final DailyChallengeDifficulty difficulty;
  final int pattern;
  final List<String> setupMoves;
  final List<String> solution;
  final String? initialFen;
  final int? forcedPlayerMoves;

  int get playerMoveGoal => forcedPlayerMoves ?? difficulty.moveGoal;
}

class AiProfile {
  const AiProfile(
    this.name,
    this.elo,
    this.description, {
    required this.engineMoveProbability,
    required this.mistakeProbability,
  });

  final String name;
  final int elo;
  final String description;
  final double engineMoveProbability;
  final double mistakeProbability;
}

AiProfile aiProfileFor(int level) {
  return switch (level.clamp(1, 10)) {
    1 => const AiProfile(
      'New to Chess',
      600,
      'Frequent human-like mistakes',
      engineMoveProbability: 0,
      mistakeProbability: .58,
    ),
    2 => const AiProfile(
      'Beginner',
      850,
      'Sees simple captures, still blunders',
      engineMoveProbability: .05,
      mistakeProbability: .44,
    ),
    3 => const AiProfile(
      'Learner',
      1100,
      'Basic tactics and development',
      engineMoveProbability: .15,
      mistakeProbability: .32,
    ),
    4 => const AiProfile(
      'Intermediate',
      1400,
      'Plans one or two ideas ahead',
      engineMoveProbability: .35,
      mistakeProbability: .23,
    ),
    5 => const AiProfile(
      'Club',
      1600,
      'Solid play with occasional inaccuracies',
      engineMoveProbability: .50,
      mistakeProbability: .17,
    ),
    6 => const AiProfile(
      'Advanced',
      1800,
      'Finds tactical combinations',
      engineMoveProbability: .65,
      mistakeProbability: .11,
    ),
    7 => const AiProfile(
      'Expert',
      2000,
      'Deep calculation and defense',
      engineMoveProbability: .78,
      mistakeProbability: .07,
    ),
    8 => const AiProfile(
      'Candidate Master',
      2200,
      'Tournament strength',
      engineMoveProbability: .90,
      mistakeProbability: .035,
    ),
    9 => const AiProfile(
      'Master',
      2500,
      'Elite engine pressure',
      engineMoveProbability: .97,
      mistakeProbability: .012,
    ),
    _ => const AiProfile(
      'Grandmaster',
      2900,
      'Maximum challenge',
      engineMoveProbability: 1,
      mistakeProbability: 0,
    ),
  };
}

Duration aiThinkDelayFor(int level) => Duration(
  milliseconds: switch (level.clamp(1, 10)) {
    1 => 1250,
    2 => 1050,
    3 => 850,
    4 => 700,
    5 => 620,
    6 => 540,
    7 => 470,
    8 => 410,
    9 => 360,
    _ => 320,
  },
);

class _SideChoiceArtwork extends StatelessWidget {
  const _SideChoiceArtwork({
    required this.side,
    required this.size,
    required this.active,
  });

  final PlayerSideChoice side;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color glow = side == PlayerSideChoice.white
        ? const Color(0xFF57DDC3)
        : const Color(0xFFDDAF4E);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            glow.withValues(alpha: active ? .36 : .2),
            const Color(0xFF081724),
          ],
        ),
        border: Border.all(color: glow.withValues(alpha: active ? .85 : .35)),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(color: glow.withValues(alpha: .24), blurRadius: 22),
              ]
            : const <BoxShadow>[],
      ),
      child: side == PlayerSideChoice.random
          ? Icon(Icons.shuffle_rounded, color: glow, size: size * .5)
          : Image.asset(
              side == PlayerSideChoice.white
                  ? 'assets/pieces/staunton_white_pawn.png'
                  : 'assets/pieces/staunton_black_pawn.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
    );
  }
}

class AiCandidate {
  const AiCandidate(this.from, this.to, this.score, {this.promotion});

  final String from;
  final String to;
  final double score;
  final String? promotion;
}

double _aiPieceValue(String code) => switch (code) {
  'P' => 1.0,
  'N' => 3.2,
  'B' => 3.3,
  'R' => 5.0,
  'Q' => 9.0,
  'K' => 100.0,
  _ => 0.0,
};

/// Scores a local AI move defensively when Stockfish cannot be reached.
/// The previous offline fallback ignored the opponent's next reply and could
/// hang major pieces. This one-ply safety pass prevents those obvious blunders.
double scoreOfflineAiCandidate(
  AiCandidate candidate,
  Map<String, ChessPiece> pieces, {
  required bool aiPlaysWhite,
}) {
  final ChessPiece? moving = pieces[candidate.from];
  if (moving == null || moving.white != aiPlaysWhite) {
    return double.negativeInfinity;
  }
  final ChessPiece? captured = pieces[candidate.to];
  final Map<String, ChessPiece> after = ChessRules.applyMove(
    candidate.from,
    candidate.to,
    pieces,
  );
  if (!ChessRules.hasOneKingPerSide(after)) {
    return double.negativeInfinity;
  }

  double material(Map<String, ChessPiece> board) => board.values.fold<double>(
    0,
    (double total, ChessPiece piece) =>
        total +
        (piece.white == aiPlaysWhite ? 1 : -1) * _aiPieceValue(piece.code),
  );

  double worstReply = material(after);
  bool opponentHasReply = false;
  bool allowsImmediateMate = false;
  for (final MapEntry<String, ChessPiece> entry in after.entries) {
    if (entry.value.white == aiPlaysWhite) continue;
    for (final String target in ChessRules.safeLegalTargets(entry.key, after)) {
      opponentHasReply = true;
      final Map<String, ChessPiece> replied = ChessRules.applyMove(
        entry.key,
        target,
        after,
      );
      if (ChessRules.isCheckmate(aiPlaysWhite, replied)) {
        allowsImmediateMate = true;
      }
      worstReply = math.min(worstReply, material(replied));
    }
  }

  final bool givesCheck = ChessRules.isKingInCheck(!aiPlaysWhite, after);
  final bool checkmate = givesCheck && !opponentHasReply;
  final SquarePosition target = ChessRules.positionOf(candidate.to);
  final double centre =
      3.5 - (target.file - 3.5).abs() + 3.5 - (target.rank - 4.5).abs();
  return (allowsImmediateMate ? -1000000 : 0) +
      worstReply * 100 +
      (captured == null ? 0 : _aiPieceValue(captured.code) * 12) +
      centre +
      (givesCheck ? 8 : 0) +
      (checkmate ? 100000 : 0);
}

AiCandidate chooseAiCandidateForLevel(
  List<AiCandidate> sortedCandidates,
  int level,
  math.Random random, {
  AiCandidate? engineMove,
}) {
  assert(sortedCandidates.isNotEmpty);
  final List<AiCandidate> nonLosingCandidates = sortedCandidates
      .where((AiCandidate candidate) => candidate.score > -500000)
      .toList(growable: false);
  final List<AiCandidate> selectableCandidates = nonLosingCandidates.isEmpty
      ? sortedCandidates
      : nonLosingCandidates;
  final int boundedLevel = level.clamp(1, 10);
  final AiProfile profile = aiProfileFor(boundedLevel);
  if (engineMove != null &&
      random.nextDouble() < profile.engineMoveProbability) {
    final bool engineMoveAllowsImmediateMate = sortedCandidates.any(
      (AiCandidate candidate) =>
          candidate.from == engineMove.from &&
          candidate.to == engineMove.to &&
          candidate.score <= -500000,
    );
    if (!engineMoveAllowsImmediateMate) return engineMove;
  }

  // Beginner levels intentionally inspect a much wider set of legal moves.
  // This creates human-like inaccuracies instead of exposing Stockfish's
  // minimum UCI strength (which is already too strong for a new player).
  final double candidateFraction = switch (boundedLevel) {
    1 => 1.0,
    2 => .80,
    3 => .60,
    4 => .48,
    5 => .34,
    6 => .24,
    7 => .15,
    8 => .08,
    9 => .03,
    _ => .01,
  };
  final int poolSize = math.max(
    1,
    math.min(
      selectableCandidates.length,
      (selectableCandidates.length * candidateFraction).ceil(),
    ),
  );
  return selectableCandidates[random.nextInt(poolSize)];
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
    light: Color(0xFFD8C3A5),
    dark: Color(0xFF7A4F2A),
    frame: Color(0xFF342113),
    accent: Color(0xFFD6A84F),
  ),
  BoardSkin.oceanTeal: BoardPalette(
    label: 'Ocean Teal',
    light: Color(0xFFB8E3DF),
    dark: Color(0xFF176B70),
    frame: Color(0xFF082E38),
    accent: Color(0xFF5DE9D3),
  ),
  BoardSkin.midnightSapphire: BoardPalette(
    label: 'Midnight Sapphire',
    light: Color(0xFFAFC8E8),
    dark: Color(0xFF183B66),
    frame: Color(0xFF091A35),
    accent: Color(0xFF5BA8FF),
  ),
  BoardSkin.emeraldArena: BoardPalette(
    label: 'Emerald Arena',
    light: Color(0xFFE9E2C5),
    dark: Color(0xFF226B4B),
    frame: Color(0xFF0B3527),
    accent: Color(0xFF63D99E),
  ),
  BoardSkin.amethystClash: BoardPalette(
    label: 'Amethyst Clash',
    light: Color(0xFF8EEBE7),
    dark: Color(0xFF603CB2),
    frame: Color(0xFF241441),
    accent: Color(0xFFBE7BFF),
  ),
  BoardSkin.desertGold: BoardPalette(
    label: 'Desert Gold',
    light: Color(0xFFF3D59A),
    dark: Color(0xFF8A5B2B),
    frame: Color(0xFF4A2D15),
    accent: Color(0xFFFFC85A),
  ),
  BoardSkin.frostMarble: BoardPalette(
    label: 'Frost Marble',
    light: Color(0xFFEEF3F8),
    dark: Color(0xFF56616F),
    frame: Color(0xFF28323E),
    accent: Color(0xFFBEEAFF),
  ),
  BoardSkin.jadeDynasty: BoardPalette(
    label: 'Jade Dynasty',
    light: Color(0xFFDDE8CF),
    dark: Color(0xFF176844),
    frame: Color(0xFF0A3525),
    accent: Color(0xFFE0B957),
  ),
  BoardSkin.azureTemple: BoardPalette(
    label: 'Azure Temple',
    light: Color(0xFFCFDFEE),
    dark: Color(0xFF296990),
    frame: Color(0xFF12364D),
    accent: Color(0xFF69C9FF),
  ),
  BoardSkin.volcanicObsidian: BoardPalette(
    label: 'Volcanic Obsidian',
    light: Color(0xFFD7C2AA),
    dark: Color(0xFF5B1714),
    frame: Color(0xFF1C0C0B),
    accent: Color(0xFFFF6547),
  ),
  BoardSkin.roseQuartz: BoardPalette(
    label: 'Rose Quartz',
    light: Color(0xFFF5D6DC),
    dark: Color(0xFFA84D6A),
    frame: Color(0xFF4D2230),
    accent: Color(0xFFFF9DB8),
  ),
  BoardSkin.celestialSilver: BoardPalette(
    label: 'Celestial Silver',
    light: Color(0xFFEEF2F7),
    dark: Color(0xFF263B62),
    frame: Color(0xFF111D34),
    accent: Color(0xFFCADCFF),
  ),
  BoardSkin.jadeGlass: BoardPalette(
    label: 'Jade',
    light: Color(0xFFC4DCCF),
    dark: Color(0xFF2F7D66),
    frame: Color(0xFF12372E),
    accent: Color(0xFF63D2B8),
  ),
  BoardSkin.tournament: BoardPalette(
    label: 'Classic',
    light: Color(0xFFDEC6A2),
    dark: Color(0xFFB58863),
    frame: Color(0xFF30251E),
    accent: Color(0xFFE2B458),
  ),
  BoardSkin.marble: BoardPalette(
    label: 'Marble',
    light: Color(0xFFD9D8D3),
    dark: Color(0xFF667078),
    frame: Color(0xFF252A2D),
    accent: Color(0xFFB9E4EE),
  ),
  BoardSkin.sapphire: BoardPalette(
    label: 'Sapphire',
    light: Color(0xFFC6D3D6),
    dark: Color(0xFF28546A),
    frame: Color(0xFF142B35),
    accent: Color(0xFF60D6D0),
  ),
};

BoardSkin tournamentBoardSkin(String? tournamentName) {
  final String name = tournamentName?.toLowerCase() ?? '';
  if (name.contains('tokyo')) return BoardSkin.sapphire;
  if (name.contains('dubai')) return BoardSkin.royalWalnut;
  if (name.contains('london')) return BoardSkin.tournament;
  if (name.contains('new york')) return BoardSkin.marble;
  if (name.contains('hyderabad')) return BoardSkin.jadeGlass;
  return BoardSkin.tournament;
}

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

int computerUndoSnapshotIndex(
  List<GameSnapshot> history, {
  required bool humanPlaysWhite,
}) {
  for (int index = history.length - 1; index >= 0; index--) {
    final bool whiteToMove = history[index].moves.length.isEven;
    if (whiteToMove == humanPlaysWhite) {
      return index;
    }
  }
  return -1;
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

  static bool hasOneKingPerSide(Map<String, ChessPiece> pieces) {
    int whiteKings = 0;
    int blackKings = 0;
    for (final ChessPiece piece in pieces.values) {
      if (piece.code != 'K') continue;
      piece.white ? whiteKings++ : blackKings++;
    }
    return whiteKings == 1 && blackKings == 1;
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
      if (pieces[target]?.code == 'K') {
        return false;
      }
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

  static bool isCheckmate(bool white, Map<String, ChessPiece> pieces) {
    return isKingInCheck(white, pieces) && !hasAnySafeMove(white, pieces);
  }

  static bool isStalemate(bool white, Map<String, ChessPiece> pieces) {
    return !isKingInCheck(white, pieces) && !hasAnySafeMove(white, pieces);
  }

  static bool isKingInCheck(bool white, Map<String, ChessPiece> pieces) {
    return checkingAttackers(white, pieces).isNotEmpty;
  }

  static String? kingSquare(bool white, Map<String, ChessPiece> pieces) {
    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white == white && entry.value.code == 'K') {
        return entry.key;
      }
    }
    return null;
  }

  static List<String> checkingAttackers(
    bool white,
    Map<String, ChessPiece> pieces,
  ) {
    final String? target = kingSquare(white, pieces);
    if (target == null) return <String>[];

    final List<String> attackers = <String>[];
    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white != white &&
          attacksSquare(entry.key, target, pieces)) {
        attackers.add(entry.key);
      }
    }
    return attackers;
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

    final SquarePosition origin = positionOf(from);
    final SquarePosition attacked = positionOf(target);
    final int fileDelta = attacked.file - origin.file;
    final int rankDelta = attacked.rank - origin.rank;

    return switch (piece.code) {
      'P' => rankDelta == (piece.white ? 1 : -1) && fileDelta.abs() == 1,
      'N' =>
        (fileDelta.abs() == 1 && rankDelta.abs() == 2) ||
            (fileDelta.abs() == 2 && rankDelta.abs() == 1),
      'K' =>
        fileDelta.abs() <= 1 &&
            rankDelta.abs() <= 1 &&
            (fileDelta != 0 || rankDelta != 0),
      'B' =>
        (fileDelta != 0 || rankDelta != 0) &&
            fileDelta.abs() == rankDelta.abs() &&
            _rayIsClear(origin, attacked, pieces),
      'R' =>
        (fileDelta == 0 || rankDelta == 0) &&
            (fileDelta != 0 || rankDelta != 0) &&
            _rayIsClear(origin, attacked, pieces),
      'Q' =>
        ((fileDelta == 0 || rankDelta == 0) ||
                fileDelta.abs() == rankDelta.abs()) &&
            (fileDelta != 0 || rankDelta != 0) &&
            _rayIsClear(origin, attacked, pieces),
      _ => false,
    };
  }

  static bool _rayIsClear(
    SquarePosition origin,
    SquarePosition target,
    Map<String, ChessPiece> pieces,
  ) {
    final int fileStep = (target.file - origin.file).sign;
    final int rankStep = (target.rank - origin.rank).sign;
    int file = origin.file + fileStep;
    int rank = origin.rank + rankStep;
    while (file != target.file || rank != target.rank) {
      if (pieces.containsKey(squareOf(file, rank))) return false;
      file += fileStep;
      rank += rankStep;
    }
    return true;
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
