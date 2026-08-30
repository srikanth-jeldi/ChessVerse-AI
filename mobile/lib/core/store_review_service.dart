import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'app_preferences.dart';

bool isStoreReviewEligible({
  required bool isAndroid,
  required bool positiveOutcome,
  required int completedGames,
  required bool alreadyRequested,
}) {
  return isAndroid &&
      positiveOutcome &&
      completedGames >= 3 &&
      !alreadyRequested;
}

class StoreReviewService {
  const StoreReviewService();

  static const String _requestedKey = 'playStoreReviewRequested';
  static const AppPreferences _preferences = AppPreferences();
  static bool _requestInProgress = false;

  Future<void> maybeRequestReview({
    required int completedGames,
    required bool positiveOutcome,
  }) async {
    if (_requestInProgress ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    _requestInProgress = true;
    try {
      final bool alreadyRequested = await _preferences.readBool(
        _requestedKey,
        fallback: false,
      );
      if (!isStoreReviewEligible(
        isAndroid: true,
        positiveOutcome: positiveOutcome,
        completedGames: completedGames,
        alreadyRequested: alreadyRequested,
      )) {
        return;
      }

      final InAppReview review = InAppReview.instance;
      if (!await review.isAvailable()) return;

      // Persist before handing control to Play so navigation/restarts cannot
      // trigger repeated prompts. Google Play may choose not to display it.
      await _preferences.writeBool(_requestedKey, true);
      await review.requestReview();
    } catch (_) {
      // A store/account without review support must never affect gameplay.
    } finally {
      _requestInProgress = false;
    }
  }
}
