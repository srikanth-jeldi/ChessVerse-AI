import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class CloudProgressApi {
  const CloudProgressApi();

  Future<Map<String, dynamic>> merge(
    String token,
    Map<String, dynamic> localProgress,
  ) async {
    try {
      final http.Response response = await http
          .put(
            Uri.parse('${AppConfig.apiBaseUrl}/api/v1/progress'),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(localProgress),
          )
          .timeout(const Duration(seconds: 15));
      final Object? decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const CloudProgressException();
      }
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      throw const CloudProgressException();
    }
  }
}

class CloudProgressException implements Exception {
  const CloudProgressException();
}
