import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'app_preferences.dart';

bool isStoreReviewEligible({
  required bool isAndroid,
  required int consecutiveWins,
  required bool alreadyRequested,
}) {
  return isAndroid && consecutiveWins >= 2 && !alreadyRequested;
}

class StoreReviewService {
  const StoreReviewService();

  static const String _requestedKey = 'playStoreReviewRequested';
  static const String _consecutiveWinsKey = 'playStoreReviewConsecutiveWins';
  static const AppPreferences _preferences = AppPreferences();
  static bool _requestInProgress = false;

  Future<void> maybeRequestReview({required bool playerWon}) async {
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
      final int previousWins =
          int.tryParse(
            await _preferences.readString(_consecutiveWinsKey, fallback: '0'),
          ) ??
          0;
      final int consecutiveWins = playerWon ? previousWins + 1 : 0;
      await _preferences.writeString(_consecutiveWinsKey, '$consecutiveWins');
      if (!isStoreReviewEligible(
        isAndroid: true,
        consecutiveWins: consecutiveWins,
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
