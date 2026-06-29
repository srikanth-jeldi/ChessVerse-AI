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
      throw const AuthApiException(
        'Cannot reach the ChessVerse server. Check your connection.',
      );
    }

    final Object? decoded = jsonDecode(response.body);
    final Map<String, dynamic> data =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        data['message'] as String? ?? 'Authentication failed.',
      );
    }
    return data;
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;
}
