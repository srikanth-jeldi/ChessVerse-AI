import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../data/auth_session_store.dart';
import '../data/guest_feature_trial.dart';
import 'auth_screen.dart';
import 'google_chat_gate.dart';

abstract final class GuestFeatureGate {
  static Future<bool> allow(BuildContext context, GuestFeature feature) async {
    const store = AuthSessionStore();
    final session = await store.read();
    // Existing signed-in users are never asked to link an additional provider.
    if (session != null && !session.isGuest) return true;
    if (session?.isGuest == true) {
      final identity = await store.progressIdentity(session!);
      if (await const GuestFeatureTrial().consume(identity, feature)) {
        return true;
      }
    }
    if (!context.mounted) return false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        icon: const Icon(Icons.lock_outline_rounded),
        title: const UiText('Save your chess progress'),
        content: SingleChildScrollView(
          child: UiText(
            session?.isGuest == true
                ? 'Your two free uses are complete. Continue with Google to save your games and Mistake Bank. Your existing progress stays safe.'
                : 'Save your games and Mistake Bank with your free Google account.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const UiText('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const UiText('Continue with Google'),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return false;
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (loginContext) => AuthScreen(
          googleChatOnly: true,
          googleAccessMessage:
              'Save your games and Mistake Bank with your free Google account.',
          guestUpgradeToken: session?.isGuest == true ? session!.token : null,
          onAuthenticated: (result) async {
            await GoogleChatGate.onAuthenticated?.call(result, null);
            if (loginContext.mounted) {
              Navigator.pop(loginContext, !result.isGuest);
            }
          },
        ),
      ),
    );
    return signedIn == true;
  }
}
