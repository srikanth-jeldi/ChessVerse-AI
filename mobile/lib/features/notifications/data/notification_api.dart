import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

class PlayerNotificationDto {
  const PlayerNotificationDto(
      {required this.id,
      required this.type,
      required this.title,
      required this.body,
      required this.actionType,
      required this.actionId,
      required this.createdAt,
      required this.read});
  final String id, type, title, body;
  final String? actionType, actionId;
  final DateTime createdAt;
  final bool read;
  factory PlayerNotificationDto.fromJson(Map<String, dynamic> j) =>
      PlayerNotificationDto(
          id: j['id'] as String? ?? '',
          type: j['type'] as String? ?? 'INFO',
          title: j['title'] as String? ?? 'ChessVerseAI',
          body: j['body'] as String? ?? '',
          actionType: j['actionType'] as String?,
          actionId: j['actionId'] as String?,
          createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
              DateTime.now(),
          read: j['read'] as bool? ?? false);
}

class NotificationInboxDto {
  const NotificationInboxDto(
      {required this.unreadCount, required this.notifications});
  final int unreadCount;
  final List<PlayerNotificationDto> notifications;
  factory NotificationInboxDto.fromJson(Map<String, dynamic> j) =>
      NotificationInboxDto(
          unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
          notifications:
              (j['notifications'] as List<dynamic>? ?? const <dynamic>[])
                  .whereType<Map<String, dynamic>>()
                  .map(PlayerNotificationDto.fromJson)
                  .toList());
}

class NotificationApi {
  const NotificationApi();
  Future<NotificationInboxDto> load(String token) =>
      _request(token, 'GET', '/api/v1/notifications');
  Future<NotificationInboxDto> read(String token, String id) =>
      _request(token, 'PUT', '/api/v1/notifications/$id/read');
  Future<NotificationInboxDto> readAll(String token) =>
      _request(token, 'PUT', '/api/v1/notifications/read-all');
  Future<void> registerDevice(String authToken,
      {required String installationId,
      required String token,
      required String platform}) async {
    final response = await http
        .post(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/notifications/devices'),
            headers: <String, String>{
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json'
            },
            body: jsonEncode(<String, String>{
              'installationId': installationId,
              'token': token,
              'platform': platform
            }))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const NotificationException(
          'Push registration is temporarily unavailable.');
    }
  }

  Future<void> unregisterDevice(String authToken, String installationId) async {
    final response = await http.delete(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/api/v1/notifications/devices/$installationId'),
        headers: <String, String>{
          'Authorization': 'Bearer $authToken'
        }).timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const NotificationException(
          'Push sign-out is temporarily unavailable.');
    }
  }

  Future<NotificationInboxDto> _request(
      String token, String method, String path) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      final headers = <String, String>{'Authorization': 'Bearer $token'};
      final response = method == 'PUT'
          ? await http
              .put(uri, headers: headers)
              .timeout(const Duration(seconds: 12))
          : await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 12));
      final Object? decoded =
          response.body.isEmpty ? null : jsonDecode(response.body);
      final Map<String, dynamic> data =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const NotificationException(
            'Notifications are temporarily unavailable.');
      }
      final inbox = NotificationInboxDto.fromJson(data);
      NotificationBadgeState.unread.value = inbox.unreadCount;
      return inbox;
    } on NotificationException {
      rethrow;
    } catch (_) {
      throw const NotificationException(
          'Cannot reach ChessVerseAI notifications.');
    }
  }
}

class NotificationBadgeState {
  static final ValueNotifier<int> unread = ValueNotifier<int>(0);
}

class NotificationException implements Exception {
  const NotificationException(this.message);
  final String message;
}
