import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/local_game_archive.dart';
import '../../analysis/domain/mistake_review.dart';
import '../../tutorial/data/academy_progress_store.dart';

/// Durable, account-bound local merge. No wallet/streak/cosmetic data is copied.
abstract final class GuestProgressMerge {
  static const _storage = FlutterSecureStorage();
  static const _key = 'guest.progress.pending.v1';

  static Future<void> save({
    required String previous,
    required String target,
    required bool samePlayer,
  }) async {
    if (!await LocalGameArchive.hasActiveIdentity(previous)) return;
    final reviews = await const AcademyProgressStore().readMistakeReviewsFor(
      previous,
    );
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'previous': previous,
        'target': target,
        'samePlayer': samePlayer,
        'games': LocalGameArchive.games.map((game) => game.toJson()).toList(),
        'reviews': reviews.map((key, value) => MapEntry(key, value.toJson())),
      }),
    );
  }

  static Future<void> restore(String target) async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['target'] != target) return;
    if (data['samePlayer'] == true) {
      await LocalGameArchive.upgradeGuestIdentity(
        data['previous'] as String,
        target,
      );
    } else {
      await LocalGameArchive.activateIdentity(target);
    }
    await LocalGameArchive.restoreMistakeGames(
      target,
      (data['games'] as List).map(
        (game) =>
            SavedGameRecord.fromJson(Map<String, dynamic>.from(game as Map)),
      ),
    );
    await const AcademyProgressStore().mergeMistakeReviewsFor(
      target,
      (data['reviews'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          MistakeReview.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
    await _storage.delete(key: _key);
  }
}
