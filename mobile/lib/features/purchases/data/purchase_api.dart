import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';

class CoinPackDto {
  const CoinPackDto(
      {required this.id,
      required this.sku,
      required this.name,
      required this.description,
      required this.coins,
      required this.priceMinor,
      required this.currency});
  final String id, sku, name, description, currency;
  final int coins, priceMinor;
  factory CoinPackDto.fromJson(Map<String, dynamic> j) => CoinPackDto(
      id: j['id'] as String? ?? '',
      sku: j['sku'] as String? ?? '',
      name: j['name'] as String? ?? '',
      description: j['description'] as String? ?? '',
      coins: (j['grantAmount'] as num?)?.toInt() ?? 0,
      priceMinor: (j['priceMinor'] as num?)?.toInt() ?? 0,
      currency: j['priceCurrency'] as String? ?? 'INR');
}

class PurchaseOrderDto {
  const PurchaseOrderDto(
      {required this.id,
      required this.productId,
      required this.sku,
      required this.productName,
      required this.provider,
      required this.status,
      required this.priceMinor,
      required this.currency,
      required this.coins,
      required this.createdAt,
      required this.updatedAt});
  final String id, productId, sku, productName, provider, status, currency;
  final int priceMinor, coins;
  final DateTime? createdAt, updatedAt;
  factory PurchaseOrderDto.fromJson(Map<String, dynamic> j) => PurchaseOrderDto(
      id: j['id'] as String? ?? '',
      productId: j['productId'] as String? ?? '',
      sku: j['sku'] as String? ?? '',
      productName: j['productName'] as String? ?? '',
      provider: j['provider'] as String? ?? '',
      status: j['status'] as String? ?? '',
      priceMinor: (j['priceMinor'] as num?)?.toInt() ?? 0,
      currency: j['priceCurrency'] as String? ?? 'INR',
      coins: (j['grantAmount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''));
}

class PurchaseCenterDto {
  const PurchaseCenterDto(
      {required this.products,
      required this.orders,
      required this.googlePlayAvailable,
      required this.appleStoreKitAvailable,
      required this.webCheckoutAvailable,
      required this.securityNotice});
  final List<CoinPackDto> products;
  final List<PurchaseOrderDto> orders;
  final bool webCheckoutAvailable;
  final bool googlePlayAvailable, appleStoreKitAvailable;
  final String securityNotice;
  factory PurchaseCenterDto.fromJson(Map<String, dynamic> j) =>
      PurchaseCenterDto(
          products: (j['products'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(CoinPackDto.fromJson)
              .toList(),
          orders: (j['orders'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(PurchaseOrderDto.fromJson)
              .toList(),
          webCheckoutAvailable: j['webCheckoutAvailable'] as bool? ?? false,
          googlePlayAvailable: j['googlePlayAvailable'] as bool? ?? false,
          appleStoreKitAvailable: j['appleStoreKitAvailable'] as bool? ?? false,
          securityNotice:
              j['securityNotice'] as String? ?? 'Secure provider checkout.');
}

class RazorpayCheckoutDto {
  const RazorpayCheckoutDto(
      {required this.orderId,
      required this.providerOrderId,
      required this.publicKeyId,
      required this.amountMinor,
      required this.currency,
      required this.name,
      required this.description});
  final String orderId, providerOrderId, publicKeyId, currency, name, description;
  final int amountMinor;
  factory RazorpayCheckoutDto.fromJson(Map<String, dynamic> j) =>
      RazorpayCheckoutDto(
          orderId: j['orderId'] as String? ?? '',
          providerOrderId: j['providerOrderId'] as String? ?? '',
          publicKeyId: j['publicKeyId'] as String? ?? '',
          amountMinor: (j['amountMinor'] as num?)?.toInt() ?? 0,
          currency: j['currency'] as String? ?? 'INR',
          name: j['name'] as String? ?? 'ChessVerseAI',
          description: j['description'] as String? ?? 'Coin purchase');
}

class RazorpayPaymentResult {
  const RazorpayPaymentResult(
      {required this.paymentId,
      required this.orderId,
      required this.signature});
  final String paymentId, orderId, signature;
}

class PurchaseApi {
  const PurchaseApi();
  Future<PurchaseCenterDto> center(String token) async =>
      PurchaseCenterDto.fromJson(
          await _json(token, 'GET', '/api/v1/purchases'));

  Future<PurchaseOrderDto> createOrder(
          String token, CoinPackDto pack, String provider) async =>
      PurchaseOrderDto.fromJson(
          await _json(token, 'POST', '/api/v1/purchases/orders', body: {
        'productId': pack.id,
        'idempotencyKey': const Uuid().v4(),
        'provider': provider,
      }));

  Future<PurchaseOrderDto> verifyGooglePlay(
          String token, String orderId, String purchaseToken) async =>
      PurchaseOrderDto.fromJson(await _json(
          token, 'POST', '/api/v1/purchases/orders/$orderId/google-play/verify',
          body: {'purchaseToken': purchaseToken}));

  Future<RazorpayCheckoutDto> razorpayCheckout(
          String token, String orderId) async =>
      RazorpayCheckoutDto.fromJson(await _json(token, 'POST',
          '/api/v1/purchases/orders/$orderId/razorpay/checkout'));

  Future<PurchaseOrderDto> verifyRazorpay(String token, String orderId,
          RazorpayPaymentResult payment) async =>
      PurchaseOrderDto.fromJson(await _json(token, 'POST',
          '/api/v1/purchases/orders/$orderId/razorpay/verify',
          body: {
            'razorpayOrderId': payment.orderId,
            'razorpayPaymentId': payment.paymentId,
            'razorpaySignature': payment.signature,
          }));

  Future<Map<String, dynamic>> _json(String token, String method, String path,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      final response = method == 'POST'
          ? await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 20))
          : await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message'] as String?
            : null;
        throw PurchaseException(message ?? 'Purchase service is unavailable.');
      }
      return decoded as Map<String, dynamic>;
    } on PurchaseException {
      rethrow;
    } catch (_) {
      throw const PurchaseException('Cannot reach secure purchase service.');
    }
  }
}

class PurchaseException implements Exception {
  const PurchaseException(this.message);
  final String message;
}
