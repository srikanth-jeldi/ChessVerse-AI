import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class AuthApi {
  const AuthApi();

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, String> body,
  ) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/auth/$path'),
            headers: const <String, String>{'Content-Type': 'application/json'},
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

  Map<String, dynamic> _decode(http.Response response) {
    final Object? decoded =
        response.body.isEmpty ? null : jsonDecode(response.body);
    final Map<String, dynamic> data =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        data['message'] as String? ?? 'Authentication failed.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  static const String _connectionMessage =
      'Cannot reach ChessVerse. Check your connection and try again.';
}

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
}
