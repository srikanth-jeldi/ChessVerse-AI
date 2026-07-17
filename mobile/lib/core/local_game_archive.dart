import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

class RewardBadge {
  const RewardBadge({
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  final String title;
  final String description;
  final String icon;
  final bool unlocked;
}

class RewardSnapshot {
  const RewardSnapshot({
    required this.xp,
    required this.coins,
    required this.level,
    required this.levelProgress,
    required this.streak,
    required this.badges,
  });

  final int xp;
  final int coins;
  final int level;
  final double levelProgress;
  final int streak;
  final List<RewardBadge> badges;

  int get unlockedBadges =>
      badges.where((RewardBadge badge) => badge.unlocked).length;

  int get nextLevelXp => level * 120;
}

class LocalGameArchive {
  LocalGameArchive._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _completedDailyKey =
      'chessverse_completed_daily_challenges';
  static final List<SavedGameRecord> _games = <SavedGameRecord>[];
  static final Set<String> _completedDailyChallengeIds = <String>{};
  static int _dailySolved = 0;
  static int _puzzlesSolved = 0;
  static int _dailyStreak = 0;

  static List<SavedGameRecord> get games =>
      List<SavedGameRecord>.unmodifiable(_games);

  static Future<void> init() async {
    final String? raw = await _storage.read(key: _completedDailyKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }
    _completedDailyChallengeIds.addAll(
      raw
          .split(',')
          .map((String id) => id.trim())
          .where((String id) => id.isNotEmpty),
    );
  }

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
      unawaited(
        _storage.write(
          key: _completedDailyKey,
          value: _completedDailyChallengeIds.join(','),
        ),
      );
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

  static RewardSnapshot rewards() {
    final LocalGameStats localStats = stats();
    final int xp = (localStats.gamesPlayed * 25) +
        (localStats.wins * 45) +
        (localStats.draws * 15) +
        (localStats.dailySolved * 80) +
        (localStats.puzzlesSolved * 35) +
        (localStats.dailyStreak * 20);
    final int level = (xp ~/ 120) + 1;
    final int levelBase = (level - 1) * 120;
    final double progress = ((xp - levelBase) / 120).clamp(0, 1).toDouble();
    final int coins = (localStats.gamesPlayed * 8) +
        (localStats.wins * 18) +
        (localStats.dailySolved * 35) +
        (localStats.puzzlesSolved * 12) +
        (localStats.dailyStreak * 10);

    return RewardSnapshot(
      xp: xp,
      coins: coins,
      level: level,
      levelProgress: progress,
      streak: localStats.dailyStreak,
      badges: <RewardBadge>[
        RewardBadge(
          title: 'First Move',
          description: 'Finish your first ChessVerse match.',
          icon: '♟',
          unlocked: localStats.gamesPlayed >= 1,
        ),
        RewardBadge(
          title: 'Tactical Spark',
          description: 'Solve a daily checkmate.',
          icon: '🔥',
          unlocked: localStats.dailySolved >= 1,
        ),
        RewardBadge(
          title: 'Winner Mindset',
          description: 'Win three local/AI games.',
          icon: '🏆',
          unlocked: localStats.wins >= 3,
        ),
        RewardBadge(
          title: 'Study Streak',
          description: 'Build a 3-day ChessVerse streak.',
          icon: '⚡',
          unlocked: localStats.dailyStreak >= 3,
        ),
      ],
    );
  }
}
