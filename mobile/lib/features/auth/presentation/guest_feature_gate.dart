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
    String? identity;
    if (session?.isGuest == true) {
      identity = await store.progressIdentity(session!);
      final status = await const GuestFeatureTrial().attempt(identity, feature);
      if (status.allowed) return true;
      if (!context.mounted) return false;
      if (status.lockedUntil != null) {
        _showCooldown(context, session, status.lockedUntil!);
        return false;
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
                ? 'Your two free uses for today are complete. Sign in to continue, or choose Not now to pause free access to this feature for 10 days.'
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
    if (!context.mounted) return false;
    if (proceed == false && identity != null) {
      final until = await const GuestFeatureTrial().defer(identity, feature);
      if (context.mounted) _showCooldown(context, session, until);
      return false;
    }
    if (proceed != true) return false;
    return _login(context, session);
  }

  static void _showCooldown(
    BuildContext context,
    StoredAuthSession? session,
    DateTime until,
  ) {
    final days =
        (until.difference(DateTime.now()).inSeconds / Duration.secondsPerDay)
            .ceil()
            .clamp(1, 10);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UiCopy.text(
                'Free access to this feature reopens in {days} days. You can keep playing as a guest.',
              ).replaceAll('{days}', '$days'),
            ),
            TextButton(
              onPressed: () {
                _login(context, session);
              },
              child: const UiText('Login now'),
            ),
          ],
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  static Future<bool> _login(
    BuildContext context,
    StoredAuthSession? session,
  ) async {
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
