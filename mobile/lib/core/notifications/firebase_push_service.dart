import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_session_store.dart';
import '../../features/notifications/data/notification_api.dart';
import '../../features/social/data/community_api.dart';
import '../../features/social/data/e2ee_chat_service.dart';
import '../academy_story_localizations.dart';
import '../app_language.dart';
import '../live_coach_localizations.dart';
import 'daily_reminder_service.dart';
import 'notification_preview.dart';

@pragma('vm:entry-point')
Future<void> chessVerseFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showPushMessage(message);
}

Future<void> _showPushMessage(RemoteMessage message) async {
  final RemoteNotification? notification = message.notification;
  String title = notification?.title ?? message.data['title'] ?? 'ChessVerseAI';
  String body =
      notification?.body ?? message.data['body'] ?? 'You have a new update.';
  final String? encryptedBody = message.data['encryptedBody'];
  if (encryptedBody != null && encryptedBody.isNotEmpty) {
    try {
      final String? plaintext = await E2eeChatService(api: const CommunityApi())
          .decryptNotification(encryptedBody);
      body = notificationMessagePreview(plaintext);
    } on Object {
      final String language = await AppLanguageController.effectiveCode();
      body = localizeLiveCoach('Your turn.', language);
    }
  }
  final String language = await AppLanguageController.effectiveCode();
  final (String, String) localized = localizePushCopy(
    actionType: message.data['actionType'] ?? '',
    title: title,
    body: body,
    languageCode: language,
  );
  title = localized.$1;
  body = localized.$2;
  final String stableId =
      message.data['notificationId'] ?? message.messageId ?? '$title|$body';
  await DailyReminderService.instance.showRealtime(
    stableId.hashCode,
    title,
    body,
  );
}

/// Localizes semantic push categories on-device so foreground, background and
/// terminated delivery all follow the same selected AI language.
(String, String) localizePushCopy({
  required String actionType,
  required String title,
  required String body,
  required String languageCode,
}) {
  final String language = AppLanguageController.resolveCode(languageCode);
  if (language == 'en') return (title, body);
  final String action = actionType.toUpperCase();
  final String? person = RegExp(
    r'^(.+?)\s+(?:wants|challenged|accepted|declined|is)\b',
  ).firstMatch(body)?.group(1)?.trim();
  if (action == 'CHALLENGE' || action == 'MATCH') {
    return (
      localizeLiveCoach('ONLINE BATTLE', language),
      '${person == null ? '' : '$person • '}${localizeLiveCoach('Play a live opponent', language)}',
    );
  }
  if (action == 'FRIEND_REQUEST' ||
      action == 'FRIEND_ONLINE' ||
      action == 'COMMUNITY') {
    return (
      localizeLiveCoach('ONLINE BATTLE', language),
      person == null
          ? localizeLiveCoach('Play a live opponent', language)
          : localizeLiveCoach('Welcome $person. Your game is ready.', language),
    );
  }
  if (action == 'CHAT') {
    return (localizeLiveCoach('ONLINE BATTLE', language), body);
  }
  if (action == 'CLUB' || action == 'TOURNAMENTS') {
    return (
      localizeLiveCoach('ONLINE BATTLE', language),
      localizeLiveCoach('Play a live opponent', language),
    );
  }
  if (action == 'ANALYSIS' || action == 'REVIEW') {
    final AcademyStoryLocalizations copy = AcademyStoryLocalizations(language);
    return (copy.text('report.title'), copy.text('report.empty'));
  }
  return (
    title == 'ChessVerseAI' ? title : localizeLiveCoach(title, language),
    localizeLiveCoach(body, language),
  );
}

class FirebasePushService {
  FirebasePushService._();
  static final FirebasePushService instance = FirebasePushService._();

  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _foregroundMessages;
  String? _authToken;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        chessVerseFirebaseBackgroundHandler,
      );
      _foregroundMessages ??= FirebaseMessaging.onMessage.listen((message) {
        unawaited(_showPushMessage(message));
      });
    } on Object {
      // Missing platform configuration must never block app startup.
    }
  }

  Future<void> configureForSession(String authToken) async {
    if (kIsWeb) return;
    _authToken = authToken;
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final String? token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await _register(token);
      await _tokenRefresh?.cancel();
      _tokenRefresh = messaging.onTokenRefresh.listen(
        (token) => unawaited(_register(token)),
      );
    } on Object {
      // Persistent in-app notifications remain available when FCM is offline.
    }
  }

  Future<void> _register(String pushToken) async {
    final String? authToken = _authToken;
    if (authToken == null) return;
    const AuthSessionStore store = AuthSessionStore();
    await const NotificationApi().registerDevice(
      authToken,
      installationId: await store.installationId(),
      token: pushToken,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
  }

  Future<void> unregister(String authToken) async {
    if (kIsWeb) return;
    try {
      const AuthSessionStore store = AuthSessionStore();
      await const NotificationApi().unregisterDevice(
        authToken,
        await store.installationId(),
      );
      _authToken = null;
      await _tokenRefresh?.cancel();
      _tokenRefresh = null;
    } on Object {
      // Logout remains available if the network is offline.
    }
  }
}
