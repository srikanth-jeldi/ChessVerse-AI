import 'package:flutter/foundation.dart';

import '../../../core/local_game_archive.dart';

@immutable
class AiMoveInsight {
  const AiMoveInsight({
    required this.number,
    required this.notation,
    required this.side,
    required this.phase,
    required this.label,
    required this.explanation,
    this.bestMove,
    this.opponentThreat,
    this.fenBefore,
    this.centipawnLoss,
    this.evaluationBeforeCp,
    this.evaluationAfterCp,
    this.mateBefore,
    this.mateAfter,
    this.coachingTheme,
    this.principalVariation = const <String>[],
  });

  final int number;
  final String notation;
  final String side;
  final String phase;
  final String label;
  final String explanation;
  final String? bestMove;
  final String? opponentThreat;
  final String? fenBefore;
  final int? centipawnLoss;
  final int? evaluationBeforeCp;
  final int? evaluationAfterCp;
  final int? mateBefore;
  final int? mateAfter;
  final String? coachingTheme;
  final List<String> principalVariation;

  bool get hasEngineEvidence => fenBefore?.isNotEmpty == true;
}

@immutable
class AiReviewReport {
  const AiReviewReport({
    required this.accuracy,
    required this.headline,
    required this.summary,
    required this.strength,
    required this.trainingFocus,
    required this.turningPoint,
    required this.recommendedLesson,
    required this.importantMistakes,
    required this.insights,
    required this.openingName,
    required this.trainingRecommendations,
  });

  final int accuracy;
  final String headline;
  final String summary;
  final String strength;
  final String trainingFocus;
  final String turningPoint;
  final String recommendedLesson;
  final List<String> importantMistakes;
  final List<AiMoveInsight> insights;
  final String openingName;
  final List<String> trainingRecommendations;

  factory AiReviewReport.fromMoves(
    List<String> moves, {
    bool newestFirst = true,
    String? result,
    int? knownAccuracy,
    String? knownTurningPoint,
    List<String>? knownMistakes,
    List<SavedMoveReview> knownReviews = const <SavedMoveReview>[],
    String? knownOpeningName,
  }) {
    final List<String> chronological = newestFirst
        ? moves.reversed.toList(growable: false)
        : List<String>.from(moves, growable: false);
    final List<AiMoveInsight> insights = <AiMoveInsight>[];
    int forcingMoves = 0;
    int captures = 0;
    int developmentMoves = 0;
    int quietMoves = 0;
    for (int index = 0; index < chronological.length; index++) {
      final String move = chronological[index].trim();
      final SavedMoveReview? reviewed =
          knownReviews.cast<SavedMoveReview?>().firstWhere(
                (SavedMoveReview? item) => item!.ply == index + 1,
                orElse: () => null,
              );
      final String lower = move.toLowerCase();
      final bool check = move.contains('+') || lower.contains('check');
      final bool capture = move.contains('x');
      final bool castle = lower.contains('o-o');
      final bool central = RegExp(r'(d4|d5|e4|e5)$').hasMatch(lower);
      final bool develops = RegExp(r'^[nb].*[3-6]$', caseSensitive: false)
          .hasMatch(move.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''));
      final String label;
      final String explanation;
      if (reviewed != null) {
        label = reviewed.classification;
        explanation = reviewed.explanation;
      } else if (check) {
        forcingMoves++;
        label = 'Power move';
        explanation =
            'A forcing check gains tempo. Verify every legal king reply before committing.';
      } else if (castle) {
        developmentMoves++;
        label = 'Excellent';
        explanation =
            'Castling improves king safety and connects a rook to the game.';
      } else if (capture) {
        captures++;
        label = 'Tactical';
        explanation =
            'A capture changes the material balance. Recheck recaptures and zwischenzugs.';
      } else if (central || develops) {
        developmentMoves++;
        label = 'Principled';
        explanation =
            'This move improves central influence or development. Keep king safety in view.';
      } else {
        quietMoves++;
        label = 'Playable';
        explanation =
            'A quiet move. Compare it with forcing checks, captures, and direct threats.';
      }
      insights.add(AiMoveInsight(
        number: index + 1,
        notation: move,
        side: index.isEven ? 'White' : 'Black',
        phase: index < 12
            ? 'Opening'
            : index < 32
                ? 'Middlegame'
                : 'Endgame',
        label: label,
        explanation: explanation,
        bestMove: reviewed?.bestMove,
        opponentThreat: reviewed?.opponentThreat,
        fenBefore: reviewed?.fenBefore,
        centipawnLoss: reviewed?.centipawnLoss,
        evaluationBeforeCp: reviewed?.evaluationBeforeCp,
        evaluationAfterCp: reviewed?.evaluationAfterCp,
        mateBefore: reviewed?.mateBefore,
        mateAfter: reviewed?.mateAfter,
        coachingTheme: reviewed?.coachingTheme,
        principalVariation: reviewed?.principalVariation ?? const <String>[],
      ));
    }

    final String lowerResult = (result ?? '').toLowerCase();
    final int calculated = knownReviews.isNotEmpty
        ? (knownReviews
                    .map((SavedMoveReview review) =>
                        (100 - (review.centipawnLoss / 3).round())
                            .clamp(0, 100))
                    .reduce((int left, int right) => left + right) /
                knownReviews.length)
            .round()
        : (62 +
                forcingMoves * 3 +
                developmentMoves * 2 +
                captures -
                quietMoves ~/ 3 -
                (lowerResult.contains('loss') ? 7 : 0))
            .clamp(38, 96);
    final int accuracy = (knownAccuracy ?? calculated).clamp(0, 100);
    final List<AiMoveInsight> reviewedByLoss = insights
        .where((AiMoveInsight item) => item.centipawnLoss != null)
        .toList()
      ..sort((AiMoveInsight a, AiMoveInsight b) =>
          b.centipawnLoss!.compareTo(a.centipawnLoss!));
    final AiMoveInsight? pivotal = reviewedByLoss.isNotEmpty
        ? reviewedByLoss.first
        : insights.cast<AiMoveInsight?>().firstWhere(
              (AiMoveInsight? item) =>
                  item!.label == 'Power move' || item.label == 'Tactical',
              orElse: () =>
                  insights.isEmpty ? null : insights[insights.length ~/ 2],
            );
    final String focus;
    final String lesson;
    final Map<String, int> themeCounts = <String, int>{};
    for (final AiMoveInsight item in reviewedByLoss.where(
      (AiMoveInsight item) => const <String>{'Inaccuracy', 'Mistake', 'Blunder'}
          .contains(item.label),
    )) {
      final String theme = item.coachingTheme ?? 'calculation';
      themeCounts[theme] = (themeCounts[theme] ?? 0) + 1;
    }
    final String? dominantTheme = themeCounts.isEmpty
        ? null
        : themeCounts.entries
            .reduce((MapEntry<String, int> a, MapEntry<String, int> b) =>
                b.value > a.value ? b : a)
            .key;
    if (dominantTheme == 'kingSafety') {
      focus =
          'King safety: your engine-reviewed mistakes repeatedly exposed checks or mating threats. Secure the king before attacking.';
      lesson = 'King Safety • Castling safely';
    } else if (dominantTheme == 'hangingPieces') {
      focus =
          'Piece safety: run a final opponent-captures scan before every move so loose pieces stop deciding your games.';
      lesson = 'Tactics • Hanging pieces';
    } else if (dominantTheme == 'endgame') {
      focus =
          'Endgame conversion: activate the king, improve the worst piece, and calculate pawn races before exchanging.';
      lesson = 'Endgames • Promoting a pawn';
    } else if (dominantTheme == 'tactics') {
      focus =
          'Tactical vision: pause on every move and scan checks, captures, forks, and direct threats in order.';
      lesson = 'Tactics • Knight forks';
    } else if (dominantTheme == 'opening' ||
        (lowerResult.contains('loss') && chronological.length < 24)) {
      focus =
          'Opening survival: develop pieces once, fight for the centre, and castle before starting an attack.';
      lesson = 'King Safety • Castling safely';
    } else if (forcingMoves == 0 && captures < 2) {
      focus =
          'Tactical vision: pause on every move and scan checks, captures, and threats in that order.';
      lesson = 'Tactics • Knight forks';
    } else if (chronological.length >= 36) {
      focus =
          'Endgame conversion: activate the king, create a passed pawn, and simplify only into a winning ending.';
      lesson = 'Endgames • Promoting a pawn';
    } else {
      focus =
          'Calculation discipline: compare at least two candidate moves before choosing the most forcing line.';
      lesson = 'Tactics • Back-rank mates';
    }
    final List<String> importantMistakes = knownMistakes == null ||
            knownMistakes.isEmpty
        ? insights
            .where((AiMoveInsight insight) => const <String>{
                  'Inaccuracy',
                  'Mistake',
                  'Blunder'
                }.contains(insight.label))
            .take(3)
            .map((AiMoveInsight insight) =>
                'Move ${insight.number}: ${insight.notation} • ${insight.explanation}')
            .toList(growable: false)
        : knownMistakes.take(3).toList(growable: false);
    return AiReviewReport(
      accuracy: accuracy,
      headline: accuracy >= 85
          ? 'Confident, accurate chess'
          : accuracy >= 70
              ? 'Good ideas with room to sharpen'
              : 'A useful game to learn from',
      summary: chronological.isEmpty
          ? 'No recorded moves are available yet.'
          : '${chronological.length} half-moves reviewed across opening, middlegame, and endgame decisions.',
      strength: knownReviews.isNotEmpty
          ? '${knownReviews.where((SavedMoveReview review) => const <String>{
                'Best',
                'Great'
              }.contains(review.classification)).length} of ${knownReviews.length} reviewed moves were Best or Great.'
          : forcingMoves > 0
              ? 'You recognised $forcingMoves forcing move${forcingMoves == 1 ? '' : 's'} and created concrete problems.'
              : developmentMoves > 0
                  ? 'Your strongest habit was central control and piece development.'
                  : 'You kept the position playable and created a base for deeper calculation.',
      trainingFocus: focus,
      turningPoint: knownTurningPoint ??
          (pivotal == null
              ? 'Play a complete game to unlock a move-level turning point.'
              : 'Move ${pivotal.number}: ${pivotal.notation} — ${pivotal.explanation}'),
      recommendedLesson: lesson,
      importantMistakes: importantMistakes,
      insights: insights,
      openingName: knownOpeningName ?? recognizeOpening(chronological),
      trainingRecommendations: _recommendations(dominantTheme, accuracy),
    );
  }
}

List<String> _recommendations(String? theme, int accuracy) {
  final List<String> focus = switch (theme) {
    'opening' => <String>[
        'Replay the first 10 moves and identify every repeated piece move.',
        'Complete one centre-control lesson before the next rated game.',
      ],
    'kingSafety' => <String>[
        'Train 5 positions where castling or meeting a check is urgent.',
        'Use a king-safety scan before starting any attack.',
      ],
    'hangingPieces' => <String>[
        'Solve 5 loose-piece and overloaded-defender puzzles.',
        'After every candidate move, verify that each piece is defended.',
      ],
    'endgame' => <String>[
        'Practice king activation and one pawn race today.',
        'Replay the game from the first endgame mistake.',
      ],
    'tactics' => <String>[
        'Solve 5 puzzles using checks, captures, and threats in order.',
        'Retry the largest evaluation swing without a hint.',
      ],
    _ => <String>[
        'Compare two candidate moves before every decision.',
        'Retry each reviewed mistake until solved twice.',
      ],
  };
  return <String>[
    ...focus,
    accuracy >= 85
        ? 'Maintain form with one slow game and a full review.'
        : 'Play one slower game and apply the same thinking routine.',
  ];
}

String recognizeOpening(List<String> moves) {
  final String line = moves
      .take(8)
      .map((String move) =>
          move.toLowerCase().replaceAll(RegExp(r'[^a-h1-8o-]'), ''))
      .join(' ');
  if (line.startsWith('e2e4 c7c5')) return 'Sicilian Defence';
  if (line.startsWith('e2e4 e7e5 g1f3 b8c6 f1b5')) return 'Ruy Lopez';
  if (line.startsWith('e2e4 e7e5 g1f3 b8c6 f1c4')) return 'Italian Game';
  if (line.startsWith('e2e4 e7e6')) return 'French Defence';
  if (line.startsWith('e2e4 c7c6')) return 'Caro-Kann Defence';
  if (line.startsWith('d2d4 g8f6 c2c4 g7g6')) return "King's Indian Defence";
  if (line.startsWith('d2d4 d7d5 c2c4')) return "Queen's Gambit";
  if (line.startsWith('d2d4 g8f6 c2c4 e7e6')) return 'Nimzo/Indian setup';
  if (line.startsWith('d2d4 d7d5')) return "Queen's Pawn Game";
  if (line.startsWith('e2e4 e7e5')) return "King's Pawn Game";
  if (line.startsWith('e2e4')) return "King's Pawn Opening";
  if (line.startsWith('d2d4')) return "Queen's Pawn Opening";
  if (line.startsWith('c2c4')) return 'English Opening';
  if (line.startsWith('g1f3')) return 'Réti Opening';
  return moves.isEmpty ? 'Opening not available' : 'Unclassified opening';
}
