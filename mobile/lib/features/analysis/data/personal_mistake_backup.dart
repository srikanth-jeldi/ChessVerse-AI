import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/local_game_archive.dart';
import '../../auth/data/auth_session_store.dart';
import '../../tutorial/data/academy_progress_store.dart';
import '../domain/mistake_bank.dart';
import '../domain/mistake_review.dart';

/// Account-owned backup; does not change or depend on academy sharing consent.
class PersonalMistakeBackup with WidgetsBindingObserver {
  PersonalMistakeBackup({
    http.Client? client,
    this.sessions = const AuthSessionStore(),
    this.progress = const AcademyProgressStore(),
  }) : _client = client ?? http.Client();

  static final instance = PersonalMistakeBackup();
  final http.Client _client;
  final AuthSessionStore sessions;
  final AcademyProgressStore progress;
  Future<bool>? _pending;
  Timer? _debounce;
  bool _started = false;
  bool _queued = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    LocalGameArchive.activityRevision.addListener(_schedule);
    AcademyProgressStore.mistakeRevision.addListener(_schedule);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(sync()));
  }

  Future<bool> sync() {
    if (_pending != null) {
      _queued = true;
      return _pending!;
    }
    return _pending = _sync().whenComplete(() {
      _pending = null;
      if (_queued) {
        _queued = false;
        _schedule();
      }
    });
  }

  Future<bool> _sync() async {
    try {
      final session = await sessions.read();
      if (session == null || session.isGuest || session.isExpired) return false;
      final identity = await sessions.progressIdentity(session);
      if (!await LocalGameArchive.hasActiveIdentity(identity)) return false;
      final reviews = await progress.readMistakeReviewsFor(identity);
      final items = MistakeBank.all(LocalGameArchive.games).map((item) {
        final review = reviews[item.id];
        return <String, dynamic>{
          'id': item.id,
          'updatedAt': (review?.updatedAt ?? item.game.playedAt)
              .toUtc()
              .toIso8601String(),
          'game': item.game.toJson(reviews: [item.review]),
          'practice': review?.toJson(),
        };
      }).toList();
      final body = await compute(jsonEncode, {'items': items});
      if (!await _sameAccount(session.token, identity)) return false;
      final response = await _client
          .put(
            Uri.parse('${AppConfig.apiBaseUrl}/api/v1/progress/mistakes'),
            headers: {
              'Authorization': 'Bearer ${session.token}',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('Backup unavailable');
      final decoded =
          await compute(jsonDecode, response.body) as Map<String, dynamic>;
      final games = <SavedGameRecord>[];
      final restoredReviews = <String, MistakeReview>{};
      for (final raw in (decoded['items'] as List).take(MistakeBank.maxItems)) {
        // A malformed legacy row must not prevent the other positions restoring.
        try {
          final item = Map<String, dynamic>.from(raw as Map);
          final game = SavedGameRecord.fromJson(
            Map<String, dynamic>.from(item['game'] as Map),
          );
          final matches = MistakeBank.all([game]);
          if (matches.length != 1 || matches.single.id != item['id']) continue;
          games.add(game);
          if (item['practice'] is Map) {
            restoredReviews[item['id'] as String] = MistakeReview.fromJson(
              Map<String, dynamic>.from(item['practice'] as Map),
            );
          }
        } catch (_) {
          /* Keep the remaining valid backup rows. */
        }
      }
      if (!await _sameAccount(session.token, identity)) return false;
      // Write progress to an explicit account key, never to whichever account
      // happens to be logged in after the HTTP request finishes.
      await progress.mergeMistakeReviewsFor(identity, restoredReviews);
      if (!await _sameAccount(session.token, identity)) return false;
      await LocalGameArchive.restoreMistakeGames(identity, games);
      return true;
    } catch (_) {
      // Local data stays intact. Retry while the app is running, and on login,
      // app resume, practice activity, or opening the Mistake Bank.
      if (_started) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(minutes: 1), () => unawaited(sync()));
      }
      return false;
    }
  }

  Future<bool> _sameAccount(String token, String identity) async =>
      (await sessions.read())?.token == token &&
      await LocalGameArchive.hasActiveIdentity(identity);
}
