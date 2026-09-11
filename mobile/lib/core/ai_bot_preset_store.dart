import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/auth/data/auth_session_store.dart';
import 'config/app_config.dart';

enum AiBotStyle { balanced, aggressive, defensive }

extension AiBotStyleDetails on AiBotStyle {
  String get label => switch (this) {
    AiBotStyle.balanced => 'Balanced',
    AiBotStyle.aggressive => 'Aggressive',
    AiBotStyle.defensive => 'Defensive',
  };
}

class AiBotPreset {
  const AiBotPreset({
    required this.id,
    required this.name,
    required this.rating,
    required this.style,
  });

  final String id;
  final String name;
  final int rating;
  final AiBotStyle style;

  int get engineLevel => ratingToEngineLevel(rating);

  factory AiBotPreset.fromJson(Map<String, dynamic> json) => AiBotPreset(
    id: json['id'] as String,
    name: json['name'] as String,
    rating: (json['rating'] as num).toInt(),
    style: AiBotStyle.values.byName(json['style'] as String),
  );
}

int ratingToEngineLevel(int rating) =>
    (((rating.clamp(400, 3000) - 400) / 260).floor() + 1).clamp(1, 10);

double aiStyleMoveBonus(
  AiBotStyle style, {
  required double capturedValue,
  required bool givesCheck,
  required bool castles,
  required bool queenMove,
  required int movesPlayed,
}) => switch (style) {
  AiBotStyle.balanced => 0,
  AiBotStyle.aggressive => capturedValue * 4 + (givesCheck ? 10 : 0),
  AiBotStyle.defensive =>
    (castles ? 14 : 0) + (queenMove && movesPlayed < 12 ? -5 : 0),
};

class AiBotPresetStore {
  AiBotPresetStore({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> _token() async {
    final String token = (await const AuthSessionStore().read())?.token ?? '';
    if (token.isEmpty) throw StateError('Sign in to sync AI bot presets');
    return token;
  }

  Uri get _uri => Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ai-bot-presets');

  Future<List<AiBotPreset>> list() async {
    final String token = await _token();
    final http.Response response = await _client
        .get(_uri, headers: <String, String>{'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw StateError('Preset sync unavailable');
    return (jsonDecode(response.body) as List<dynamic>)
        .map(
          (dynamic item) =>
              AiBotPreset.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<AiBotPreset> save({
    required String name,
    required int rating,
    required AiBotStyle style,
  }) async {
    final String token = await _token();
    final http.Response response = await _client
        .post(
          _uri,
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, Object>{
            'name': name.trim(),
            'rating': rating.clamp(400, 3000),
            'style': style.name,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw StateError('Could not save preset');
    return AiBotPreset.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<void> delete(String id) async {
    final String token = await _token();
    final http.Response response = await _client
        .delete(
          _uri.resolve('/api/v1/ai-bot-presets/$id'),
          headers: <String, String>{'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw StateError('Could not delete preset');
  }
}
