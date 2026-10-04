import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class AcademyApi {
  AcademyApi(this.token, {http.Client? client})
    : _client = client ?? http.Client();
  final String token;
  final http.Client _client;
  void close() => _client.close();
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final request =
        http.Request(
            method,
            Uri.parse('${AppConfig.apiBaseUrl}/api/v1/academy$path'),
          )
          ..headers.addAll({
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          });
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 20)),
    );
    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      throw Exception('Academy service is unavailable. Please try again.');
    }
    if (response.statusCode >= 400) {
      throw Exception(
        data is Map
            ? data['message'] ?? data['detail'] ?? 'Unable to access this academy. Check your sign-in and membership.'
            : 'Academy request failed.',
      );
    }
    return data;
  }
}
