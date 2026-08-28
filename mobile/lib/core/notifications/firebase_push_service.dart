import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_session_store.dart';
import '../../features/notifications/data/notification_api.dart';
import 'daily_reminder_service.dart';

@pragma('vm:entry-point')
Future<void> chessVerseFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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
        final RemoteNotification? notification = message.notification;
        if (notification == null) return;
        final String stableId = message.data['notificationId'] ??
            message.messageId ??
            '${notification.title}|${notification.body}';
        unawaited(DailyReminderService.instance.showRealtime(
          stableId.hashCode,
          notification.title ?? 'ChessVerseAI',
          notification.body ?? 'You have a new update.',
        ));
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
