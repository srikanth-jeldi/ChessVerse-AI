import 'package:flutter/foundation.dart';

@immutable
class AiMoveInsight {
  const AiMoveInsight({
    required this.number,
    required this.notation,
    required this.side,
    required this.phase,
    required this.label,
    required this.explanation,
  });

  final int number;
  final String notation;
  final String side;
  final String phase;
  final String label;
  final String explanation;
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
    required this.insights,
  });

  final int accuracy;
  final String headline;
  final String summary;
  final String strength;
  final String trainingFocus;
  final String turningPoint;
  final String recommendedLesson;
  final List<AiMoveInsight> insights;

  factory AiReviewReport.fromMoves(
    List<String> moves, {
    bool newestFirst = true,
    String? result,
    int? knownAccuracy,
    String? knownTurningPoint,
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
      final String lower = move.toLowerCase();
      final bool check = move.contains('+') || lower.contains('check');
      final bool capture = move.contains('x');
      final bool castle = lower.contains('o-o');
      final bool central = RegExp(r'(d4|d5|e4|e5)$').hasMatch(lower);
      final bool develops = RegExp(r'^[nb].*[3-6]$', caseSensitive: false)
          .hasMatch(move.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''));
      final String label;
      final String explanation;
      if (check) {
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
      ));
    }

    final String lowerResult = (result ?? '').toLowerCase();
    final int calculated = (62 +
            forcingMoves * 3 +
            developmentMoves * 2 +
            captures -
            quietMoves ~/ 3 -
            (lowerResult.contains('loss') ? 7 : 0))
        .clamp(38, 96);
    final int accuracy = (knownAccuracy ?? calculated).clamp(0, 100);
    final AiMoveInsight? pivotal = insights.cast<AiMoveInsight?>().firstWhere(
          (AiMoveInsight? item) =>
              item!.label == 'Power move' || item.label == 'Tactical',
          orElse: () => insights.isEmpty
              ? null
              : insights[insights.length ~/ 2],
        );
    final String focus;
    final String lesson;
    if (lowerResult.contains('loss') && chronological.length < 24) {
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
      strength: forcingMoves > 0
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
      insights: insights,
    );
  }
}
