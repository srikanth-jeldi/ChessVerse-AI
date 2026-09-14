import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class SavedPositionApi {
  const SavedPositionApi();

  Future<void> save(
    String token, {
    required String fen,
    String? label,
    String sourceFormat = 'FEN',
    List<String> tags = const <String>[],
  }) async {
    final response = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/api/v1/positions'),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, Object?>{
            'fen': fen,
            'label': label,
            'sourceFormat': sourceFormat,
            'tags': tags,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Position cloud sync failed.');
    }
  }
}
