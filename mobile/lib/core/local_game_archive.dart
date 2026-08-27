import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedMoveReview {
  const SavedMoveReview({
    required this.ply,
    required this.fenBefore,
    required this.playedMove,
    required this.bestMove,
    required this.classification,
    this.coachingTheme = 'calculation',
    required this.centipawnLoss,
    required this.opponentThreat,
    required this.explanation,
    required this.principalVariation,
  });

  final int ply;
  final String fenBefore;
  final String playedMove;
  final String bestMove;
  final String classification;
  final String coachingTheme;
  final int centipawnLoss;
  final String opponentThreat;
  final String explanation;
  final List<String> principalVariation;

  factory SavedMoveReview.fromJson(Map<String, dynamic> json) {
    return SavedMoveReview(
      ply: (json['ply'] as num?)?.toInt() ?? 0,
      fenBefore: json['fenBefore'] as String? ?? '',
      playedMove: json['playedMove'] as String? ?? '',
      bestMove: json['bestMove'] as String? ?? '',
      classification: json['classification'] as String? ?? 'Unreviewed',
      coachingTheme: json['coachingTheme'] as String? ?? 'calculation',
      centipawnLoss: (json['centipawnLoss'] as num?)?.toInt() ?? 0,
      opponentThreat: json['opponentThreat'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      principalVariation:
          (json['principalVariation'] as List<dynamic>? ?? <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ply': ply,
        'fenBefore': fenBefore,
        'playedMove': playedMove,
        'bestMove': bestMove,
        'classification': classification,
        'coachingTheme': coachingTheme,
        'centipawnLoss': centipawnLoss,
        'opponentThreat': opponentThreat,
        'explanation': explanation,
        'principalVariation': principalVariation,
      };
}

class SavedGameRecord {
  const SavedGameRecord({
    required this.mode,
    required this.result,
    required this.detail,
    required this.moves,
    required this.playedAt,
    required this.whitePlayer,
    required this.blackPlayer,
    this.playerOutcome,
    this.moveReviews = const <SavedMoveReview>[],
  });

  final String mode;
  final String result;
  final String detail;
  final List<String> moves;
  final DateTime playedAt;
  final String whitePlayer;
  final String blackPlayer;
  final String? playerOutcome;
  final List<SavedMoveReview> moveReviews;

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

  int get winRate => wins + draws + losses == 0
      ? 0
      : ((wins / (wins + draws + losses)) * 100).round();
}

String playerOutcomeForResult(
  String result, {
  required bool humanPlaysWhite,
  required bool tracksPlayer,
}) {
  if (!tracksPlayer) return 'untracked';
  final String normalized = result.toLowerCase();
  if (normalized.contains('draw') || normalized.contains('stalemate')) {
    return 'draw';
  }
  if (normalized.contains('challenge complete') ||
      normalized.contains('puzzle complete') ||
      normalized.contains('you win') ||
      normalized.contains('victory')) {
    return 'win';
  }
  if (normalized.contains('challenge missed') ||
      normalized.contains('opponent wins') ||
      normalized.contains('defeat')) {
    return 'loss';
  }
  if (normalized.contains('white wins')) {
    return humanPlaysWhite ? 'win' : 'loss';
  }
  if (normalized.contains('black wins')) {
    return humanPlaysWhite ? 'loss' : 'win';
  }
  return 'untracked';
}

int dailyStreakAfterCompletion({
  required int currentStreak,
  required DateTime? previousCompletion,
  required DateTime completion,
}) {
  if (previousCompletion == null) return 1;
  final DateTime previousDay = DateTime.utc(
    previousCompletion.toUtc().year,
    previousCompletion.toUtc().month,
    previousCompletion.toUtc().day,
  );
  final DateTime completionDay = DateTime.utc(
    completion.toUtc().year,
    completion.toUtc().month,
    completion.toUtc().day,
  );
  final int elapsedDays = completionDay.difference(previousDay).inDays;
  if (elapsedDays <= 0) {
    return currentStreak.clamp(1, 1 << 30).toInt();
  }
  if (elapsedDays == 1) return currentStreak + 1;
  return 1;
}

class RewardBadge {
  const RewardBadge({
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.progress,
    required this.target,
  });

  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final int progress;
  final int target;

  double get completion => (progress / target).clamp(0, 1).toDouble();
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

  static const Duration dailyChallengeLockDuration = Duration(hours: 24);
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _completedDailyKey =
      'chessverse_completed_daily_challenges';
  static const String _lastDailyCompletionKey =
      'chessverse_last_daily_completion_utc';
  static const String _dailyStreakKey = 'chessverse_daily_streak';
  static const String _completedPuzzlesKey =
      'chessverse_completed_independent_puzzles';
  static const String _profileCountryKey = 'chessverse_profile_country';
  static const String _profileLevelKey = 'chessverse_profile_level';
  static const String _profileAvatarKey = 'chessverse_profile_avatar';
  static const String _profileUsernameKey = 'chessverse_profile_username';
  static const String _profileUpdatedAtKey = 'chessverse_profile_updated_at';
  static const String _savedGamesKey = 'chessverse_saved_games_v1';
  static const String _activeIdentityKey =
      'chessverse_active_archive_identity_v2';
  static final List<SavedGameRecord> _games = <SavedGameRecord>[];
  static final Map<String, int> _cloudWeaknessScores = <String, int>{};
  static final Set<String> _completedDailyChallengeIds = <String>{};
  static final Set<String> _completedPuzzleIds = <String>{};
  static final Set<String> _completedAcademyLessonIds = <String>{};
  static DateTime? _lastDailyCompletedAt;
  static int _dailySolved = 0;
  static int _puzzlesSolved = 0;
  static int _dailyStreak = 0;
  static String _profileCountry = 'India';
  static String? _profileUsername;
  static int _profileLevel = 0;
  static int _profileAvatar = 0;
  static DateTime? _profileUpdatedAt;
  static Future<void> Function()? onCloudRelevantChange;
  static final ValueNotifier<int> activityRevision = ValueNotifier<int>(0);
  static bool _mergingCloud = false;

  static List<SavedGameRecord> get games =>
      List<SavedGameRecord>.unmodifiable(_games);

  static Map<String, int> get cloudWeaknessScores =>
      Map<String, int>.unmodifiable(_cloudWeaknessScores);

  static Future<void> init() async {
    _resetMemory();
    final String? savedGamesRaw = await _storage.read(key: _savedGamesKey);
    if (savedGamesRaw != null && savedGamesRaw.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded =
            jsonDecode(savedGamesRaw) as List<dynamic>;
        _games
          ..clear()
          ..addAll(
            decoded.take(50).map((dynamic value) {
              final Map<String, dynamic> game = value as Map<String, dynamic>;
              return SavedGameRecord(
                mode: game['mode'] as String? ?? 'Game',
                result: game['result'] as String? ?? 'Game complete',
                detail: game['detail'] as String? ?? 'Game complete',
                moves: (game['moves'] as List<dynamic>? ?? <dynamic>[])
                    .whereType<String>()
                    .toList(growable: false),
                playedAt:
                    DateTime.tryParse(game['playedAt'] as String? ?? '') ??
                        DateTime.now(),
                whitePlayer: game['whitePlayer'] as String? ?? 'White',
                blackPlayer: game['blackPlayer'] as String? ?? 'Black',
                playerOutcome: game['playerOutcome'] as String?,
                moveReviews:
                    (game['moveReviews'] as List<dynamic>? ?? <dynamic>[])
                        .whereType<Map<String, dynamic>>()
                        .map(SavedMoveReview.fromJson)
                        .toList(growable: false),
              );
            }),
          );
      } on Object {
        // Ignore a legacy or partially written archive and start clean.
        _games.clear();
      }
    }
    final String? raw = await _storage.read(key: _completedDailyKey);
    if (raw != null && raw.trim().isNotEmpty) {
      _completedDailyChallengeIds.addAll(
        raw
            .split(',')
            .map((String id) => id.trim())
            .where((String id) => id.isNotEmpty),
      );
      _dailySolved = _completedDailyChallengeIds.length;
    }
    final String? completionRaw =
        await _storage.read(key: _lastDailyCompletionKey);
    _lastDailyCompletedAt = completionRaw == null
        ? null
        : DateTime.tryParse(completionRaw)?.toUtc();
    _dailyStreak = int.tryParse(
          await _storage.read(key: _dailyStreakKey) ?? '',
        ) ??
        0;
    final String? puzzlesRaw = await _storage.read(key: _completedPuzzlesKey);
    if (puzzlesRaw != null && puzzlesRaw.trim().isNotEmpty) {
      _completedPuzzleIds.addAll(
        puzzlesRaw
            .split(',')
            .map((String id) => id.trim())
            .where((String id) => id.isNotEmpty),
      );
      _puzzlesSolved = _completedPuzzleIds.length;
    }
    _profileCountry =
        await _storage.read(key: _profileCountryKey) ?? _profileCountry;
    _profileUsername = await _storage.read(key: _profileUsernameKey);
    _profileLevel =
        int.tryParse(await _storage.read(key: _profileLevelKey) ?? '') ?? 0;
    _profileAvatar =
        int.tryParse(await _storage.read(key: _profileAvatarKey) ?? '') ?? 0;
    _profileUpdatedAt = DateTime.tryParse(
      await _storage.read(key: _profileUpdatedAtKey) ?? '',
    )?.toUtc();
  }

  /// Prevents games, rewards and puzzle completion from one account being
  /// shown or uploaded for another account on the same device.
  ///
  /// The cloud remains the durable source for signed-in/guest progress. When
  /// the authenticated identity changes we discard the old device cache
  /// before the new identity is merged from the server.
  static Future<void> activateIdentity(String identity) async {
    final String normalized = identity.trim().toLowerCase();
    final String? active = await _storage.read(key: _activeIdentityKey);
    if (active == normalized) return;

    _resetMemory();
    await Future.wait(<Future<void>>[
      for (final String key in <String>[
        _completedDailyKey,
        _lastDailyCompletionKey,
        _dailyStreakKey,
        _completedPuzzlesKey,
        _profileCountryKey,
        _profileLevelKey,
        _profileAvatarKey,
        _profileUsernameKey,
        _profileUpdatedAtKey,
        _savedGamesKey,
      ])
        _storage.delete(key: key),
      _storage.write(key: _activeIdentityKey, value: normalized),
    ]);
    activityRevision.value++;
  }

  static void _resetMemory() {
    _games.clear();
    _cloudWeaknessScores.clear();
    _completedDailyChallengeIds.clear();
    _completedPuzzleIds.clear();
    _completedAcademyLessonIds.clear();
    _lastDailyCompletedAt = null;
    _dailySolved = 0;
    _puzzlesSolved = 0;
    _dailyStreak = 0;
    _profileCountry = 'India';
    _profileUsername = null;
    _profileLevel = 0;
    _profileAvatar = 0;
    _profileUpdatedAt = null;
  }

  static void addGame(SavedGameRecord record) {
    _games.insert(0, record);
    if (_games.length > 50) {
      _games.removeLast();
    }
    unawaited(_persistGames());
    _notifyCloudChange();
  }

  static Future<void> _persistGames() async {
    final String encoded = jsonEncode(
      _games
          .map(
            (SavedGameRecord game) => <String, dynamic>{
              'mode': game.mode,
              'result': game.result,
              'detail': game.detail,
              'moves': game.moves,
              'playedAt': game.playedAt.toUtc().toIso8601String(),
              'whitePlayer': game.whitePlayer,
              'blackPlayer': game.blackPlayer,
              'playerOutcome': game.playerOutcome,
              'moveReviews': game.moveReviews
                  .map((SavedMoveReview review) => review.toJson())
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    );
    await _storage.write(key: _savedGamesKey, value: encoded);
  }

  static bool isDailyChallengeComplete(String challengeId) {
    return isDailyChallengeLocked ||
        _completedDailyChallengeIds.contains(challengeId);
  }

  static bool get isDailyChallengeLocked {
    return isDailyChallengeLockedAt(DateTime.now());
  }

  static bool isDailyChallengeLockedAt(DateTime now) {
    final DateTime? completedAt = _lastDailyCompletedAt;
    if (completedAt == null) {
      return false;
    }
    final Duration elapsed = now.toUtc().difference(completedAt);
    return !elapsed.isNegative && elapsed < dailyChallengeLockDuration;
  }

  static Duration get dailyChallengeRemaining {
    return dailyChallengeRemainingAt(DateTime.now());
  }

  static Duration dailyChallengeRemainingAt(DateTime now) {
    final DateTime? completedAt = _lastDailyCompletedAt;
    if (completedAt == null) {
      return Duration.zero;
    }
    final Duration remaining =
        completedAt.add(dailyChallengeLockDuration).difference(now.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static void markDailyChallengeComplete(String challengeId) {
    if (_completedDailyChallengeIds.add(challengeId)) {
      _dailySolved++;
      final DateTime now = DateTime.now().toUtc();
      _dailyStreak = dailyStreakAfterCompletion(
        currentStreak: _dailyStreak,
        previousCompletion: _lastDailyCompletedAt,
        completion: now,
      );
      unawaited(
        _storage.write(
          key: _completedDailyKey,
          value: _completedDailyChallengeIds.join(','),
        ),
      );
      unawaited(
        _storage.write(key: _dailyStreakKey, value: '$_dailyStreak'),
      );
    }
    _lastDailyCompletedAt = DateTime.now().toUtc();
    unawaited(
      _storage.write(
        key: _lastDailyCompletionKey,
        value: _lastDailyCompletedAt!.toIso8601String(),
      ),
    );
    _notifyCloudChange();
  }

  static Set<String> get completedPuzzleIds =>
      Set<String>.unmodifiable(_completedPuzzleIds);

  static Set<String> get completedAcademyLessonIds =>
      Set<String>.unmodifiable(_completedAcademyLessonIds);

  static void replaceAcademyLessonProgress(
    Iterable<String> lessonIds, {
    bool notify = false,
  }) {
    _completedAcademyLessonIds
      ..clear()
      ..addAll(lessonIds.where((String id) => id.isNotEmpty));
    if (notify) _notifyCloudChange();
  }

  static void markAcademyLessonComplete(String lessonId) {
    if (_completedAcademyLessonIds.add(lessonId)) _notifyCloudChange();
  }

  static void clearAccountScopedCloudState() {
    _resetMemory();
    activityRevision.value++;
  }

  /// Removes all cached player data from this device during logout. The
  /// installation identifier is intentionally owned by AuthSessionStore and
  /// retained so an unsecured guest can resume on the same installation.
  static Future<void> clearDeviceUserData() async {
    _resetMemory();
    await Future.wait(<Future<void>>[
      for (final String key in <String>[
        _completedDailyKey,
        _lastDailyCompletionKey,
        _dailyStreakKey,
        _completedPuzzlesKey,
        _profileCountryKey,
        _profileLevelKey,
        _profileAvatarKey,
        _profileUsernameKey,
        _profileUpdatedAtKey,
        _savedGamesKey,
        _activeIdentityKey,
      ])
        _storage.delete(key: key),
    ]);
    activityRevision.value++;
  }

  static String get profileCountry => _profileCountry;
  static String? get profileUsername => _profileUsername;
  static int get profileLevel => _profileLevel.clamp(0, 4);
  static int get profileAvatar => _profileAvatar.clamp(0, 5);

  static void savePlayerProfile({
    required String username,
    required String country,
    required int level,
    required int avatar,
  }) {
    _profileUsername = username.trim();
    _profileCountry = country;
    _profileLevel = level.clamp(0, 4);
    _profileAvatar = avatar.clamp(0, 5);
    _profileUpdatedAt = DateTime.now().toUtc();
    unawaited(
      Future.wait(<Future<void>>[
        _storage.write(key: _profileUsernameKey, value: _profileUsername),
        _storage.write(key: _profileCountryKey, value: _profileCountry),
        _storage.write(key: _profileLevelKey, value: '$_profileLevel'),
        _storage.write(key: _profileAvatarKey, value: '$_profileAvatar'),
        _storage.write(
          key: _profileUpdatedAtKey,
          value: _profileUpdatedAt!.toIso8601String(),
        ),
      ]),
    );
    _notifyCloudChange();
  }

  static bool isPuzzleComplete(String puzzleId) {
    return _completedPuzzleIds.contains(puzzleId);
  }

  static int puzzleSolvedCount(String difficulty) {
    return _completedPuzzleIds
        .where((String id) => id.startsWith('$difficulty-'))
        .length;
  }

  static void markPuzzleSolved(String puzzleId) {
    if (!_completedPuzzleIds.add(puzzleId)) {
      return;
    }
    _puzzlesSolved = _completedPuzzleIds.length;
    unawaited(
      _storage.write(
        key: _completedPuzzlesKey,
        value: _completedPuzzleIds.join(','),
      ),
    );
    _notifyCloudChange();
  }

  static Map<String, dynamic> cloudSnapshot() {
    final Map<String, int> weaknesses = _localWeaknessScores();
    return <String, dynamic>{
      'profileUsername': _profileUsername,
      'country': _profileCountry,
      'chessLevel': _profileLevel,
      'avatar': _profileAvatar,
      'profileUpdatedAt': _profileUpdatedAt?.toIso8601String(),
      'dailyStreak': _dailyStreak,
      'openingWeakness': weaknesses['opening'] ?? 0,
      'kingSafetyWeakness': weaknesses['kingSafety'] ?? 0,
      'hangingPiecesWeakness': weaknesses['hangingPieces'] ?? 0,
      'missedCapturesWeakness': weaknesses['missedCaptures'] ?? 0,
      'timeManagementWeakness': weaknesses['timeManagement'] ?? 0,
      'endgameWeakness': weaknesses['endgame'] ?? 0,
      'lastDailyCompletedAt': _lastDailyCompletedAt?.toIso8601String(),
      'completedPuzzleIds': _completedPuzzleIds.toList()..sort(),
      'completedDailyChallengeIds': _completedDailyChallengeIds.toList()
        ..sort(),
      'completedAcademyLessonIds': _completedAcademyLessonIds.toList()..sort(),
    };
  }

  static Map<String, int> _localWeaknessScores() {
    final Map<String, int> scores = <String, int>{
      'opening': 0,
      'kingSafety': 0,
      'hangingPieces': 0,
      'missedCaptures': 0,
      'timeManagement': 0,
      'endgame': 0,
    };
    for (final SavedGameRecord game in _games.take(20)) {
      final bool loss = game.result.toLowerCase().contains('wins') &&
          !game.result.toLowerCase().startsWith('you');
      final bool castled = game.moves.any(
        (String move) => move.contains('O-O') || move.contains('0-0'),
      );
      final int captures =
          game.moves.where((String move) => move.contains('x')).length;
      if (loss && game.moves.length < 24) {
        scores['opening'] = scores['opening']! + 3;
      }
      if (!castled && game.moves.length >= 12) {
        scores['kingSafety'] = scores['kingSafety']! + 2;
      }
      if (loss && captures >= 5) {
        scores['hangingPieces'] = scores['hangingPieces']! + 2;
      }
      if (captures < (game.moves.length / 10).floor()) {
        scores['missedCaptures'] = scores['missedCaptures']! + 1;
      }
      if (game.result.toLowerCase().contains('time')) {
        scores['timeManagement'] = scores['timeManagement']! + 4;
      }
      if (loss && game.moves.length >= 36) {
        scores['endgame'] = scores['endgame']! + 3;
      }
    }
    for (final MapEntry<String, int> remote in _cloudWeaknessScores.entries) {
      if ((scores[remote.key] ?? 0) < remote.value) {
        scores[remote.key] = remote.value;
      }
    }
    return scores;
  }

  static Future<void> mergeCloudSnapshot(Map<String, dynamic> cloud) async {
    _mergingCloud = true;
    try {
      final Iterable<dynamic> puzzles =
          cloud['completedPuzzleIds'] as Iterable<dynamic>? ??
              const <dynamic>[];
      final Iterable<dynamic> daily =
          cloud['completedDailyChallengeIds'] as Iterable<dynamic>? ??
              const <dynamic>[];
      final Iterable<dynamic> academy =
          cloud['completedAcademyLessonIds'] as Iterable<dynamic>? ??
              const <dynamic>[];
      _completedPuzzleIds.addAll(puzzles.whereType<String>());
      _completedDailyChallengeIds.addAll(daily.whereType<String>());
      _completedAcademyLessonIds.addAll(academy.whereType<String>());
      _puzzlesSolved = _completedPuzzleIds.length;
      _dailySolved = _completedDailyChallengeIds.length;
      _dailyStreak = mathMax(
        _dailyStreak,
        (cloud['dailyStreak'] as num?)?.toInt() ?? 0,
      );
      for (final String key in <String>[
        'opening',
        'kingSafety',
        'hangingPieces',
        'missedCaptures',
        'timeManagement',
        'endgame',
      ]) {
        final String responseKey = '${key}Weakness';
        _cloudWeaknessScores[key] = mathMax(
          _cloudWeaknessScores[key] ?? 0,
          (cloud[responseKey] as num?)?.toInt() ?? 0,
        );
      }
      final DateTime? remoteDaily = DateTime.tryParse(
        cloud['lastDailyCompletedAt'] as String? ?? '',
      )?.toUtc();
      if (remoteDaily != null &&
          (_lastDailyCompletedAt == null ||
              remoteDaily.isAfter(_lastDailyCompletedAt!))) {
        _lastDailyCompletedAt = remoteDaily;
      }
      final DateTime? remoteProfileUpdatedAt = DateTime.tryParse(
        cloud['profileUpdatedAt'] as String? ?? '',
      )?.toUtc();
      if (remoteProfileUpdatedAt != null &&
          (_profileUpdatedAt == null ||
              remoteProfileUpdatedAt.isAfter(_profileUpdatedAt!))) {
        final String? remoteUsername = cloud['profileUsername'] as String?;
        if (remoteUsername != null && remoteUsername.trim().isNotEmpty) {
          _profileUsername = remoteUsername.trim();
        }
        final String? remoteCountry = cloud['country'] as String?;
        if (remoteCountry != null && remoteCountry.trim().isNotEmpty) {
          _profileCountry = remoteCountry.trim();
        }
        _profileLevel =
            ((cloud['chessLevel'] as num?)?.toInt() ?? _profileLevel)
                .clamp(0, 4);
        _profileAvatar =
            ((cloud['avatar'] as num?)?.toInt() ?? _profileAvatar).clamp(0, 5);
        _profileUpdatedAt = remoteProfileUpdatedAt;
      }
      await Future.wait(<Future<void>>[
        _storage.write(
          key: _completedPuzzlesKey,
          value: _completedPuzzleIds.join(','),
        ),
        _storage.write(
          key: _completedDailyKey,
          value: _completedDailyChallengeIds.join(','),
        ),
        _storage.write(key: _dailyStreakKey, value: '$_dailyStreak'),
        if (_lastDailyCompletedAt != null)
          _storage.write(
            key: _lastDailyCompletionKey,
            value: _lastDailyCompletedAt!.toIso8601String(),
          ),
        if (_profileUsername != null)
          _storage.write(key: _profileUsernameKey, value: _profileUsername),
        _storage.write(key: _profileCountryKey, value: _profileCountry),
        _storage.write(key: _profileLevelKey, value: '$_profileLevel'),
        _storage.write(key: _profileAvatarKey, value: '$_profileAvatar'),
        if (_profileUpdatedAt != null)
          _storage.write(
            key: _profileUpdatedAtKey,
            value: _profileUpdatedAt!.toIso8601String(),
          ),
      ]);
    } finally {
      _mergingCloud = false;
    }
  }

  static int mathMax(int left, int right) => left > right ? left : right;

  static void _notifyCloudChange() {
    activityRevision.value++;
    if (_mergingCloud) return;
    final Future<void> Function()? callback = onCloudRelevantChange;
    if (callback != null) unawaited(callback());
  }

  static LocalGameStats stats() {
    int wins = 0;
    int draws = 0;
    int losses = 0;
    for (final SavedGameRecord game in _games) {
      final String outcome = game.playerOutcome ??
          playerOutcomeForResult(
            game.result,
            humanPlaysWhite: true,
            tracksPlayer: true,
          );
      if (outcome == 'draw') {
        draws++;
      } else if (outcome == 'win') {
        wins++;
      } else if (outcome == 'loss') {
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
    final int reviewedGames = _games
        .where((SavedGameRecord game) => game.moveReviews.isNotEmpty)
        .length;

    return RewardSnapshot(
      xp: xp,
      coins: coins,
      level: level,
      levelProgress: progress,
      streak: localStats.dailyStreak,
      badges: <RewardBadge>[
        RewardBadge(
          title: 'First Move',
          description: 'Finish your first ChessVerseAI match.',
          icon: '♟',
          unlocked: localStats.gamesPlayed >= 1,
          progress: localStats.gamesPlayed,
          target: 1,
        ),
        RewardBadge(
          title: 'Tactical Spark',
          description: 'Solve a daily checkmate.',
          icon: '🔥',
          unlocked: localStats.dailySolved >= 1,
          progress: localStats.dailySolved,
          target: 1,
        ),
        RewardBadge(
          title: 'Winner Mindset',
          description: 'Win three local/AI games.',
          icon: '🏆',
          unlocked: localStats.wins >= 3,
          progress: localStats.wins,
          target: 3,
        ),
        RewardBadge(
          title: 'Study Streak',
          description: 'Build a 3-day ChessVerseAI streak.',
          icon: '⚡',
          unlocked: localStats.dailyStreak >= 3,
          progress: localStats.dailyStreak,
          target: 3,
        ),
        RewardBadge(
          title: 'Game Detective',
          description: 'Complete your first engine-reviewed game.',
          icon: '🔎',
          unlocked: reviewedGames >= 1,
          progress: reviewedGames,
          target: 1,
        ),
        RewardBadge(
          title: 'Deep Analyst',
          description: 'Review five games with ChessVerseAI.',
          icon: '🧠',
          unlocked: reviewedGames >= 5,
          progress: reviewedGames,
          target: 5,
        ),
        RewardBadge(
          title: 'Puzzle Hunter',
          description: 'Solve ten academy puzzles.',
          icon: '🧩',
          unlocked: localStats.puzzlesSolved >= 10,
          progress: localStats.puzzlesSolved,
          target: 10,
        ),
        RewardBadge(
          title: 'Arena Regular',
          description: 'Finish twenty-five matches.',
          icon: '🎯',
          unlocked: localStats.gamesPlayed >= 25,
          progress: localStats.gamesPlayed,
          target: 25,
        ),
        RewardBadge(
          title: 'Winning Habit',
          description: 'Win ten tracked matches.',
          icon: '👑',
          unlocked: localStats.wins >= 10,
          progress: localStats.wins,
          target: 10,
        ),
        RewardBadge(
          title: 'Century Club',
          description: 'Finish one hundred matches.',
          icon: '💯',
          unlocked: localStats.gamesPlayed >= 100,
          progress: localStats.gamesPlayed,
          target: 100,
        ),
      ],
    );
  }
}
