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
    actionType: message.data['actionType'],
    actionId: message.data['actionId'],
  );
}

void _openPushMessage(RemoteMessage message) {
  final String actionType = (message.data['actionType'] ?? '').trim();
  if (actionType.isEmpty) return;
  DailyReminderService.instance.openAction(
    NotificationOpenRequest(
      actionType: actionType.toUpperCase(),
      actionId: message.data['actionId'],
    ),
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
  if (action == 'DAILY_PUZZLE') {
    if (language == 'te') {
      return (
        'రోజువారీ పజిల్',
        'ఈరోజు చెస్ ఛాలెంజ్ సిద్ధంగా ఉంది. పూర్తి చేసి నీ స్ట్రీక్‌ను పెంచుకో!',
      );
    }
    return (
      localizeLiveCoach('DAILY PUZZLE', language),
      localizeLiveCoach('Find the strongest move', language),
    );
  }
  if (action == 'DAILY_GAME_REMINDER') {
    if (language == 'te') {
      return (
        'నీ బోర్డ్ ఎదురుచూస్తోంది',
        'ఈరోజు ఒక క్విక్ గేమ్ ఆడి నీ మొదటి స్ట్రీక్‌ను ప్రారంభించు!',
      );
    }
    return (
      localizeLiveCoach('ONLINE BATTLE', language),
      localizeLiveCoach('Play a live opponent', language),
    );
  }
  if (action.startsWith('STREAK_REMINDER_DAY_')) {
    final int day = int.tryParse(action.split('_').last) ?? 1;
    if (language == 'te') return _teluguStreakReminder(day);
  }
  if (action == 'STREAK_MILESTONE' && language == 'te') {
    return (
      '🎉 కాంగ్రాట్స్ ఛాంప్!',
      'నువ్వు సక్సెస్‌ఫుల్‌గా 7 రోజుల స్ట్రీక్ పూర్తి చేశావు. ఇదే జోష్‌తో రేపటి నుండి కొత్త వారం స్టార్ట్ చేద్దాం!',
    );
  }
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

(String, String) _teluguStreakReminder(int day) {
  const List<(String, String)> copy = <(String, String)>[
    ('', ''),
    (
      '🔥 నీ మొదటి స్ట్రీక్ ప్రమాదంలో ఉంది బ్రో!',
      'నువ్వు నిన్న సూపర్ గేమ్ ఆడావు. ఈరోజు కూడా ఒక ఆట ఆడి నీ డే-2 స్ట్రీక్‌ని అందుకో!',
    ),
    (
      '⚡ జోరు మీదున్నావ్ బ్రో!',
      '2 రోజుల స్ట్రీక్ పూర్తయింది. ఈరోజు నీ AI కోచ్‌తో ఆడి 3వ రోజుకి చేరుకో!',
    ),
    (
      '🧠 నువ్వు సీరియస్ ప్లేయర్‌వి బ్రో!',
      'నీ 3 రోజుల స్ట్రీక్ కంటిన్యూ చేయడానికి ఇదో మంచి ఛాన్స్. ఇప్పుడే బోర్డ్ ఓపెన్ చెయ్!',
    ),
    (
      '🏆 హాఫ్-వే మార్క్ దాటేశావ్!',
      '4 రోజుల స్ట్రీక్ అంటే మామూలు విషయం కాదు. గ్రాండ్ మాస్టర్ లాగా కన్సిస్టెన్సీ మెయింటైన్ చెయ్!',
    ),
    (
      '🚀 ఇంకా రెండు రోజులే బ్రో!',
      'నీ 5-Day Streak ని కోల్పోవద్దు. ఈరోజు ఒక క్విక్ మ్యాచ్ ఆడి రికార్డ్ వైపు అడుగులేయ్!',
    ),
    (
      '👑 వారం పూర్తి కావడానికి ఒక్క అడుగు!',
      'రేపటితో నీ వారం రోజుల స్ట్రీక్ పూర్తవుతుంది. ఈరోజు మ్యాచ్ అస్సలు మిస్ అవ్వద్దు బ్రో!',
    ),
  ];
  return copy[day.clamp(1, 6)];
}

class FirebasePushService {
  FirebasePushService._();
  static final FirebasePushService instance = FirebasePushService._();

  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _foregroundMessages;
  StreamSubscription<RemoteMessage>? _openedMessages;
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
      _openedMessages ??= FirebaseMessaging.onMessageOpenedApp.listen(
        _openPushMessage,
      );
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) _openPushMessage(initialMessage);
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
