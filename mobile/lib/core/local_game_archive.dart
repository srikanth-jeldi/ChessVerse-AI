class SavedGameRecord {
  const SavedGameRecord({
    required this.mode,
    required this.result,
    required this.detail,
    required this.moves,
    required this.playedAt,
    required this.whitePlayer,
    required this.blackPlayer,
  });

  final String mode;
  final String result;
  final String detail;
  final List<String> moves;
  final DateTime playedAt;
  final String whitePlayer;
  final String blackPlayer;

  String get summary => '$whitePlayer vs $blackPlayer';
}

class LocalGameStats {
  const LocalGameStats({
    required this.gamesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.dailySolved,
    required this.puzzlesSolved,
    required this.dailyStreak,
  });

  final int gamesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int dailySolved;
  final int puzzlesSolved;
  final int dailyStreak;

  int get winRate =>
      gamesPlayed == 0 ? 0 : ((wins / gamesPlayed) * 100).round();
}

class LocalGameArchive {
  LocalGameArchive._();

  static final List<SavedGameRecord> _games = <SavedGameRecord>[];
  static final Set<String> _completedDailyChallengeIds = <String>{};
  static int _dailySolved = 0;
  static int _puzzlesSolved = 0;
  static int _dailyStreak = 0;

  static List<SavedGameRecord> get games =>
      List<SavedGameRecord>.unmodifiable(_games);

  static void addGame(SavedGameRecord record) {
    _games.insert(0, record);
    if (_games.length > 50) {
      _games.removeLast();
    }
  }

  static bool isDailyChallengeComplete(String challengeId) {
    return _completedDailyChallengeIds.contains(challengeId);
  }

  static void markDailyChallengeComplete(String challengeId) {
    if (_completedDailyChallengeIds.add(challengeId)) {
      _dailySolved++;
      _puzzlesSolved++;
      _dailyStreak = _dailyStreak == 0 ? 1 : _dailyStreak + 1;
    }
  }

  static void markPuzzleSolved() {
    _puzzlesSolved++;
  }

  static LocalGameStats stats() {
    int wins = 0;
    int draws = 0;
    int losses = 0;
    for (final SavedGameRecord game in _games) {
      final String result = game.result.toLowerCase();
      if (result.contains('draw')) {
        draws++;
      } else if (result.contains('white wins') ||
          result.contains('challenge complete')) {
        wins++;
      } else if (result.contains('black wins')) {
        losses++;
      }
    }
    return LocalGameStats(
      gamesPlayed: _games.length,
      wins: wins,
      draws: draws,
      losses: losses,
      dailySolved: _dailySolved,
      puzzlesSolved: _puzzlesSolved,
      dailyStreak: _dailyStreak,
    );
  }
}
