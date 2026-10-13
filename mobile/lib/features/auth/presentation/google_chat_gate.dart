import 'package:flutter/material.dart';

import '../../../core/app_language.dart';
import '../data/auth_api.dart';
import '../data/auth_session_store.dart';
import 'auth_screen.dart';
import 'chat_access_copy.dart';

/// Installed by the app root so login also switches archive, presence and sync.
abstract final class GoogleChatGate {
  static Future<void> Function(ChessVerseAuthResult, StoredAuthSession?)?
  onAuthenticated;

  static bool hasGoogle(Map<String, dynamic> data) {
    final Object? providers = data['providers'];
    return providers is List &&
        providers.any(
          (item) =>
              item is Map &&
              item['provider'] == 'google' &&
              item['linked'] == true,
        );
  }

  static Future<StoredAuthSession?> ensure(BuildContext context) async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (!context.mounted) return null;
    if (session != null && !session.isExpired && !session.isGuest) {
      try {
        if (hasGoogle(await const AuthApi().linkedAccounts(session.token))) {
          return session;
        }
      } on AuthApiException {
        // Offline or expired verification cannot grant access to chat.
      }
    }
    final String language = await AppLanguageController.effectiveCode();
    if (!context.mounted) return null;
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lock_outline),
        content: Text(googleChatMessage(language)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Google'),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return null;
    String? previousPlayerId;
    if (session?.isGuest == true) {
      try {
        final player = await const AuthApi().currentPlayer(session!.token);
        previousPlayerId = player['id']?.toString();
      } on AuthApiException catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
        }
        return null;
      }
    }
    if (!context.mounted) return null;
    return Navigator.of(context).push<StoredAuthSession>(
      MaterialPageRoute(
        builder: (loginContext) => AuthScreen(
          googleChatOnly: true,
          chatLanguage: language,
          guestUpgradeToken: session?.isGuest == true ? session!.token : null,
          onAuthenticated: (result) async {
            final upgradedGuest =
                previousPlayerId != null && previousPlayerId == result.playerId
                ? session
                : null;
            await onAuthenticated?.call(result, upgradedGuest);
            if (loginContext.mounted) {
              Navigator.pop(loginContext, result.session);
            }
          },
        ),
      ),
    );
  }
}
