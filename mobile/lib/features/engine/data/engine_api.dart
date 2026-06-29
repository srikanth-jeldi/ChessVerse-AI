import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class EngineApi {
  const EngineApi();

  Future<Map<String, dynamic>> bestMove({
    required String fen,
    required int level,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/v1/engine/best-move'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, Object>{'fen': fen, 'level': level}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      throw const EngineApiException('Chess engine is unavailable.');
    }

    final Object? decoded = jsonDecode(response.body);
    final Map<String, dynamic> data =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EngineApiException(
        data['message'] as String? ?? 'Chess engine is unavailable.',
      );
    }
    return data;
  }
}

class EngineApiException implements Exception {
  const EngineApiException(this.message);

  final String message;
}
