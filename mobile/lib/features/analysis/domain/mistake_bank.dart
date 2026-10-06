import '../../../core/local_game_archive.dart';

class MistakeBankItem {
  const MistakeBankItem({
    required this.id,
    required this.game,
    required this.review,
  });

  final String id;
  final SavedGameRecord game;
  final SavedMoveReview review;

  bool get isPlayable =>
      review.fenBefore.isNotEmpty &&
      review.bestMove.isNotEmpty &&
      review.playedMove.isNotEmpty &&
      review.bestMove != review.playedMove;

  List<String> get choices => <String>{
    review.bestMove,
    review.playedMove,
    ...review.principalVariation.take(2),
  }.where((String move) => move.trim().isNotEmpty).take(3).toList();
}

class MistakePatternInsight {
  const MistakePatternInsight({
    required this.similarPreviousGames,
    required this.similarOccurrences,
    required this.biggestWeaknessKey,
    required this.biggestWeakness,
    required this.biggestWeaknessOccurrences,
    required this.trainingTheme,
    required this.trainingTitle,
    required this.trainingReason,
  });

  final int similarPreviousGames;
  final int similarOccurrences;
  final String biggestWeaknessKey;
  final String biggestWeakness;
  final int biggestWeaknessOccurrences;
  final String trainingTheme;
  final String trainingTitle;
  final String trainingReason;
}

abstract final class MistakeBank {
  static const int maxItems = 100;

  static const Set<String> _mistakeLabels = <String>{
    'inaccuracy',
    'mistake',
    'blunder',
  };

  static List<MistakeBankItem> weekly(
    Iterable<SavedGameRecord> games, {
    DateTime? now,
    int? limit,
  }) {
    final DateTime today = (now ?? DateTime.now()).toUtc();
    final DateTime cutoff = today.subtract(const Duration(days: 7));
    final List<MistakeBankItem> recent = _collect(
      games.where(
        (SavedGameRecord game) => game.playedAt.toUtc().isAfter(cutoff),
      ),
    );
    final List<MistakeBankItem> source = recent.isNotEmpty
        ? recent
        : _collect(games);
    return _rank(source, limit);
  }

  static List<MistakeBankItem> all(Iterable<SavedGameRecord> games) =>
      _rank(_collect(games), null);

  static MistakePatternInsight insightFor(
    Iterable<MistakeBankItem> items,
    MistakeBankItem current,
  ) {
    final List<MistakeBankItem> bank = items.toList();
    if (bank.isEmpty) bank.add(current);
    final String currentTheme = _theme(current);
    final List<MistakeBankItem> similar = bank
        .where((MistakeBankItem item) => _theme(item) == currentTheme)
        .toList(growable: false);
    final int currentGame = current.game.playedAt
        .toUtc()
        .millisecondsSinceEpoch;
    final int previousGames = similar
        .map(
          (MistakeBankItem item) =>
              item.game.playedAt.toUtc().millisecondsSinceEpoch,
        )
        .where((int game) => game != currentGame)
        .toSet()
        .length;

    final Map<String, List<MistakeBankItem>> byTheme =
        <String, List<MistakeBankItem>>{};
    for (final MistakeBankItem item in bank) {
      byTheme.putIfAbsent(_theme(item), () => <MistakeBankItem>[]).add(item);
    }
    final MapEntry<String, List<MistakeBankItem>> biggest = byTheme.entries
        .reduce((
          MapEntry<String, List<MistakeBankItem>> a,
          MapEntry<String, List<MistakeBankItem>> b,
        ) {
          if (b.value.length != a.value.length) {
            return b.value.length > a.value.length ? b : a;
          }
          final int aLoss = a.value.fold<int>(
            0,
            (int sum, MistakeBankItem item) => sum + item.review.centipawnLoss,
          );
          final int bLoss = b.value.fold<int>(
            0,
            (int sum, MistakeBankItem item) => sum + item.review.centipawnLoss,
          );
          return bLoss > aLoss ? b : a;
        });
    final ({String title, String reason}) training = _trainingFor(currentTheme);
    return MistakePatternInsight(
      similarPreviousGames: previousGames,
      similarOccurrences: similar.length,
      biggestWeaknessKey: biggest.key,
      biggestWeakness: _themeLabel(biggest.key),
      biggestWeaknessOccurrences: biggest.value.length,
      trainingTheme: currentTheme,
      trainingTitle: training.title,
      trainingReason: training.reason,
    );
  }

  static String _theme(MistakeBankItem item) {
    final String theme = item.review.coachingTheme.trim();
    return theme.isEmpty ? 'calculation' : theme;
  }

  static String _themeLabel(String theme) => switch (theme) {
    'opening' => 'Opening decisions',
    'kingSafety' => 'King safety',
    'hangingPieces' => 'Piece safety',
    'missedCaptures' => 'Missed captures',
    'timeManagement' => 'Time management',
    'endgame' => 'Endgame technique',
    'tactics' => 'Tactical vision',
    _ => 'Calculation',
  };

  static ({String title, String reason}) _trainingFor(
    String theme,
  ) => switch (theme) {
    'opening' => (
      title: 'Develop, control the centre, castle',
      reason: 'Train a three-question opening scan before choosing a move.',
    ),
    'kingSafety' => (
      title: 'King-safety decision training',
      reason:
          'Practise spotting checks and castling before starting an attack.',
    ),
    'hangingPieces' => (
      title: 'Piece-safety scan',
      reason: 'Before every move, verify every attacked and undefended piece.',
    ),
    'missedCaptures' => (
      title: 'Checks, captures and threats',
      reason: 'Build a forcing-move scan so winning captures are not missed.',
    ),
    'timeManagement' => (
      title: 'Candidate-move routine',
      reason:
          'Compare two candidates quickly, then commit before time pressure.',
    ),
    'endgame' => (
      title: 'Endgame conversion practice',
      reason: 'Activate the king and calculate pawn races from real positions.',
    ),
    'tactics' => (
      title: 'Personal tactical pattern set',
      reason: 'Replay forks, pins and forcing lines taken from your own games.',
    ),
    _ => (
      title: 'Two-line calculation drill',
      reason: 'Calculate the opponent reply before committing to your candidate move.',
    ),
  };

  static List<MistakeBankItem> _rank(List<MistakeBankItem> source, int? limit) {
    // Keep the bank bounded. Prefer the newest reviewed positions when the
    // seven-day window (or its all-time fallback) contains more than the
    // training capacity, then rank that retained set by severity.
    source.sort(
      (MistakeBankItem a, MistakeBankItem b) =>
          b.game.playedAt.compareTo(a.game.playedAt),
    );
    final List<MistakeBankItem> retained = source.take(maxItems).toList()
      ..sort(
        (MistakeBankItem a, MistakeBankItem b) =>
            b.review.centipawnLoss.compareTo(a.review.centipawnLoss),
      );
    final Iterable<MistakeBankItem> playable = retained.where(
      (MistakeBankItem item) => item.isPlayable,
    );
    return (limit == null ? playable : playable.take(limit)).toList();
  }

  static List<MistakeBankItem> _collect(
    Iterable<SavedGameRecord> games,
  ) => <MistakeBankItem>[
    for (final SavedGameRecord game in games)
      for (final SavedMoveReview review in game.moveReviews)
        if (_mistakeLabels.contains(review.classification.trim().toLowerCase()))
          MistakeBankItem(
            id: '${game.playedAt.toUtc().millisecondsSinceEpoch}-${review.ply}',
            game: game,
            review: review,
          ),
  ];
}
