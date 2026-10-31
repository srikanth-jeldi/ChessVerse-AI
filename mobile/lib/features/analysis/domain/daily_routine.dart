import '../../../core/local_game_archive.dart';
import '../../puzzles/domain/puzzle_catalog.dart';
import 'mistake_bank.dart';
import 'mistake_weaknesses.dart';

class DailyRoutine {
  const DailyRoutine({
    required this.puzzles,
    required this.mistakes,
    required this.focus,
    this.successBaseline = const {},
  });
  final List<String> puzzles, mistakes;
  final Map<String, int> successBaseline;
  final MistakeCategory? focus;
  bool get personalised => focus != null;

  factory DailyRoutine.create(
    List<SavedGameRecord> games,
    Set<String> solved,
    DateTime now,
  ) {
    final recent = MistakeWeaknesses.recent(
      MistakeBank.all(games),
      days: 30,
      now: now,
    ).where((item) => item.isPlayable).toList();
    final counts = <MistakeCategory, int>{};
    for (final item in recent) {
      for (final category in MistakeWeaknesses.tags(item)) {
        counts[category] = (counts[category] ?? 0) + 1;
      }
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final difference = b.value.compareTo(a.value);
        return difference != 0
            ? difference
            : a.key.index.compareTo(b.key.index);
      });
    final focus = ranked.isEmpty ? null : ranked.first.key;
    final theme = switch (focus) {
      MistakeCategory.endgame => 'endgame',
      MistakeCategory.opening => 'opening',
      MistakeCategory.kingSafety => 'mate',
      _ => 'mate',
    };
    final candidates = PuzzleCatalog.all
        .where(
          (p) =>
              !solved.contains(p.id) &&
              p.difficulty ==
                  (recent.isEmpty
                      ? PuzzleDifficulty.easy
                      : PuzzleDifficulty.medium),
        )
        .toList();
    candidates.sort((a, b) {
      final matchedA = a.themes.contains(theme),
          matchedB = b.themes.contains(theme);
      if (matchedA != matchedB) return matchedA ? -1 : 1;
      return a.id.compareTo(b.id);
    });
    // Only claim the category as the practice focus when the selected positions
    // really carry that tag. Otherwise label the puzzle task general practice.
    return DailyRoutine(
      focus: focus,
      puzzles: candidates.take(3).map((p) => p.id).toList(),
      mistakes: recent
          .where(
            (item) =>
                focus == null || MistakeWeaknesses.tags(item).contains(focus),
          )
          .take(1)
          .map((item) => item.id)
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => {
    'puzzles': puzzles,
    'mistakes': mistakes,
    'focus': focus?.name,
    'successBaseline': successBaseline,
  };
  factory DailyRoutine.fromJson(Map<String, dynamic> json) => DailyRoutine(
    successBaseline: Map<String, int>.from(
      json['successBaseline'] as Map? ?? {},
    ),
    puzzles: (json['puzzles'] as List).cast<String>(),
    mistakes: (json['mistakes'] as List).cast<String>(),
    focus: MistakeCategory.values
        .where((c) => c.name == json['focus'])
        .firstOrNull,
  );
}
