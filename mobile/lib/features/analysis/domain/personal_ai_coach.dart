import 'ai_review_report.dart';

enum CoachQuestion { whyBad, opponentThreat, bestPlan, pattern, practice }

class PersonalAiCoach {
  const PersonalAiCoach._();

  static String label(CoachQuestion question) => switch (question) {
        CoachQuestion.whyBad => 'Why was this move bad?',
        CoachQuestion.opponentThreat => 'What was the threat?',
        CoachQuestion.bestPlan => 'What should I play?',
        CoachQuestion.pattern => 'What pattern did I miss?',
        CoachQuestion.practice => 'How do I improve?',
      };

  static String answer(AiMoveInsight insight, CoachQuestion question) {
    final String best = _move(insight.bestMove);
    final String played = _move(insight.notation);
    final String threat = _move(insight.opponentThreat);
    final String variation = insight.principalVariation.isEmpty
        ? 'Calculate the opponent’s strongest reply before committing.'
        : 'A concrete line is ${insight.principalVariation.take(6).map(_move).join(' → ')}.';
    final String loss = insight.centipawnLoss == null
        ? ''
        : insight.centipawnLoss == 0
            ? ' Stockfish measured no meaningful evaluation loss.'
            : ' Stockfish measured a ${insight.centipawnLoss} centipawn loss.';
    return switch (question) {
      CoachQuestion.whyBad =>
        '$played was graded ${insight.label.toLowerCase()} because it did not solve the position’s ${_theme(insight.coachingTheme)} priority.$loss ${insight.explanation}',
      CoachQuestion.opponentThreat => insight.opponentThreat?.isNotEmpty == true
          ? 'After $played, the immediate engine reply is $threat. $variation'
          : 'Stockfish did not return a single forcing reply here. Check all opponent checks, captures, and direct threats.',
      CoachQuestion.bestPlan =>
        'Play $best. It best addresses ${_theme(insight.coachingTheme)} in this ${insight.phase.toLowerCase()} position. $variation',
      CoachQuestion.pattern =>
        'Pattern: ${_pattern(insight.coachingTheme)}. Before moving, ask: “What changes after my move, and what is the opponent’s most forcing reply?”',
      CoachQuestion.practice =>
        'Retry the exact position and find $best without moving immediately. Then calculate the first ${insight.principalVariation.length.clamp(2, 6)} half-moves. Repeat until you solve it twice without a hint.',
    };
  }

  static String _move(String? move) {
    if (move == null || move.trim().isEmpty) return 'the best engine move';
    final String clean = move.trim();
    if (RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$', caseSensitive: false)
        .hasMatch(clean)) {
      return '${clean.substring(0, 2)} → ${clean.substring(2)}';
    }
    return clean;
  }

  static String _theme(String? theme) => switch (theme) {
        'opening' => 'development and centre control',
        'kingSafety' => 'king safety',
        'hangingPieces' => 'piece safety',
        'missedCaptures' => 'forcing-move scan',
        'timeManagement' => 'candidate-move selection',
        'endgame' => 'endgame technique',
        'tactics' => 'tactical calculation',
        _ => 'calculation',
      };

  static String _pattern(String? theme) => switch (theme) {
        'opening' => 'finish development before launching an attack',
        'kingSafety' => 'meet checks and mating threats first',
        'hangingPieces' => 'loose pieces and overloaded defenders',
        'missedCaptures' => 'checks, captures, and threats',
        'timeManagement' => 'compare two candidate moves before deciding',
        'endgame' => 'activate the king and calculate pawn races',
        'tactics' => 'forcing sequences and tactical motifs',
        _ => 'opponent-response calculation',
      };
}
