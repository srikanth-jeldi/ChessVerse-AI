import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'app_preferences.dart';

bool isStoreReviewEligible({
  required bool isAndroid,
  required bool completedGame,
  required bool alreadyRequested,
}) {
  return isAndroid && completedGame && !alreadyRequested;
}

class StoreReviewService {
  const StoreReviewService();

  static const String _requestedKey = 'playStoreReviewRequested';
  static const AppPreferences _preferences = AppPreferences();
  static bool _requestInProgress = false;

  Future<void> maybeRequestReview({required bool completedGame}) async {
    if (!completedGame ||
        _requestInProgress ||
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
      // Every completed game's outcome is eligible, including a loss or draw.
      // Preserve the existing request key so upgrades don't prompt again.
      if (!isStoreReviewEligible(
        isAndroid: true,
        completedGame: completedGame,
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
