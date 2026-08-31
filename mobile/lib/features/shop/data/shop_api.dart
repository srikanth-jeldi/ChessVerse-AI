import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

class WalletDto {
  const WalletDto({required this.coins, required this.diamonds});
  final int coins, diamonds;
  factory WalletDto.fromJson(Map<String, dynamic> json) => WalletDto(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      diamonds: (json['diamonds'] as num?)?.toInt() ?? 0);
}

class CosmeticItemDto {
  const CosmeticItemDto(
      {required this.id,
      required this.slug,
      required this.category,
      required this.name,
      required this.description,
      required this.priceCurrency,
      required this.priceAmount,
      this.primaryColor,
      this.secondaryColor,
      this.assetKey,
      required this.owned,
      required this.equipped});
  final String id, slug, category, name, description, priceCurrency;
  final int priceAmount;
  final String? primaryColor, secondaryColor, assetKey;
  final bool owned, equipped;
  factory CosmeticItemDto.fromJson(Map<String, dynamic> j) => CosmeticItemDto(
      id: j['id'] as String? ?? '',
      slug: j['slug'] as String? ?? '',
      category: j['category'] as String? ?? '',
      name: j['name'] as String? ?? '',
      description: j['description'] as String? ?? '',
      priceCurrency: j['priceCurrency'] as String? ?? 'FREE',
      priceAmount: (j['priceAmount'] as num?)?.toInt() ?? 0,
      primaryColor: j['primaryColor'] as String?,
      secondaryColor: j['secondaryColor'] as String?,
      assetKey: j['assetKey'] as String?,
      owned: j['owned'] as bool? ?? false,
      equipped: j['equipped'] as bool? ?? false);
}

class ShopDto {
  const ShopDto(
      {required this.playerId, required this.wallet, required this.items});
  final String playerId;
  final WalletDto wallet;
  final List<CosmeticItemDto> items;
  factory ShopDto.fromJson(Map<String, dynamic> j) => ShopDto(
      playerId: j['playerId'] as String? ?? '',
      wallet:
          WalletDto.fromJson(j['wallet'] as Map<String, dynamic>? ?? const {}),
      items: (j['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CosmeticItemDto.fromJson)
          .toList());
}

class ShopApi {
  const ShopApi();
  Future<ShopDto> load(String token) => _request(token, 'GET', '/api/v1/shop');
  Future<ShopDto> purchase(String token, String id) =>
      _request(token, 'POST', '/api/v1/shop/items/$id/purchase');
  Future<ShopDto> equip(String token, String slot, String id) =>
      _request(token, 'PUT', '/api/v1/shop/loadout/$slot',
          body: {'itemId': id});
  Future<ShopDto> _request(String token, String method, String path,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      final http.Response response = switch (method) {
        'POST' => await http
            .post(uri, headers: headers)
            .timeout(const Duration(seconds: 12)),
        'PUT' => await http
            .put(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 12)),
        _ => await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 12)),
      };
      final Object? decoded =
          response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final map = decoded is Map<String, dynamic> ? decoded : null;
        throw ShopException(
            map?['message'] as String? ?? 'Purchase could not be completed.');
      }
      return ShopDto.fromJson(decoded as Map<String, dynamic>);
    } on ShopException {
      rethrow;
    } catch (_) {
      throw const ShopException('Cannot reach the ChessVerseAI shop.');
    }
  }
}

class ShopException implements Exception {
  const ShopException(this.message);
  final String message;
}
