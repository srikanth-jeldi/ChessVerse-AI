import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'auth_session_store.dart';

class AuthApi {
  const AuthApi();

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, String> body,
  ) async {
    final String installationId =
        await const AuthSessionStore().installationId();
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/auth/$path'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'X-Device-Id': installationId,
              'X-Device-Name': 'ChessVerseAI app',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthApiException('The server took too long to respond.');
    } catch (_) {
      throw const AuthApiException(_connectionMessage);
    }

    return _decode(response);
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) =>
      post('refresh', <String, String>{'refreshToken': refreshToken});

  Future<List<Map<String, dynamic>>> sessions(String token) async {
    final http.Response response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/auth/sessions'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decode(response);
    }
    final Object? decoded =
        response.body.isEmpty ? null : jsonDecode(response.body);
    return decoded is List
        ? decoded.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
  }

  Future<void> revokeSession(String token, String sessionId) async {
    final http.Response response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/api/auth/sessions/$sessionId'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    _decode(response);
  }

  Future<void> logoutAll(String token) async {
    final http.Response response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/auth/logout-all'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    _decode(response);
  }

  Future<Map<String, dynamic>> currentPlayer(String token) async {
    final http.Response response;
    try {
      response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/me'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
    } catch (_) {
      throw const AuthApiException(_connectionMessage);
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> updateProfile(
    String token,
    String displayName,
  ) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/auth/profile'),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{'displayName': displayName}),
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const AuthApiException('The server took too long to respond.');
    } catch (_) {
      throw const AuthApiException(_connectionMessage);
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(
    String token,
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/profile-photo'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ));
      final streamed =
          await request.send().timeout(const Duration(seconds: 25));
      return _decode(await http.Response.fromStream(streamed));
    } on TimeoutException {
      throw const AuthApiException('The photo upload took too long.');
    } catch (error) {
      if (error is AuthApiException) rethrow;
      throw const AuthApiException(_connectionMessage);
    }
  }

  Future<Map<String, dynamic>> upgradeGuestWithGoogle(
    String token,
    String idToken,
  ) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/auth/google/upgrade'),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthApiException('The server took too long to respond.');
    } catch (_) {
      throw const AuthApiException(_connectionMessage);
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> upgradeGuestWithFacebook(
    String token,
    String accessToken,
  ) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/auth/facebook/upgrade'),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{'accessToken': accessToken}),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthApiException('The server took too long to respond.');
    } catch (_) {
      throw const AuthApiException(_connectionMessage);
    }
    return _decode(response);
  }

  Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/logout'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Local session removal must still succeed when the server is offline.
    }
  }

  Future<void> deleteAccount(String token) async {
    http.Response response;
    try {
      response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/account/delete'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      // Older deployed backends expose only the canonical DELETE endpoint.
      // Keep Android compatible during rolling deployments without asking the
      // user to install a server-matched APK.
      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await http.delete(
          Uri.parse('${AppConfig.apiBaseUrl}/api/auth/account'),
          headers: <String, String>{'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 15));
      }
    } on TimeoutException {
      throw const AuthApiException('The server took too long to respond.');
    } catch (_) {
      throw const AuthApiException(_connectionMessage);
    }
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }
    }
    final Map<String, dynamic> data =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        data['message'] as String? ??
            'ChessVerseAI server rejected the request (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  static const String _connectionMessage =
      'Cannot reach ChessVerseAI. Check your connection and try again.';
}

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
