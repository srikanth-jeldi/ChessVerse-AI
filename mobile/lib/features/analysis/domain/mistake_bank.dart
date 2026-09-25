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
