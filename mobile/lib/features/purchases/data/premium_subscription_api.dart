import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/data/auth_session_store.dart';

class PremiumPlanDto {
  const PremiumPlanDto({
    required this.productId,
    required this.basePlanId,
    required this.billingPeriod,
    required this.indiaPriceMinor,
    required this.currency,
  });
  final String productId, basePlanId, billingPeriod, currency;
  final int indiaPriceMinor;
  factory PremiumPlanDto.fromJson(Map<String, dynamic> json) => PremiumPlanDto(
    productId: json['productId'] as String? ?? '',
    basePlanId: json['basePlanId'] as String? ?? '',
    billingPeriod: json['billingPeriod'] as String? ?? '',
    indiaPriceMinor: (json['indiaPriceMinor'] as num?)?.toInt() ?? 0,
    currency: json['currency'] as String? ?? 'INR',
  );
}

class PremiumOfferDto {
  const PremiumOfferDto({
    required this.code,
    required this.basePlanId,
    required this.label,
    required this.discountType,
    required this.discountValue,
    required this.playOfferTag,
  });
  final String code, basePlanId, label, discountType, playOfferTag;
  final int discountValue;
  factory PremiumOfferDto.fromJson(Map<String, dynamic> json) =>
      PremiumOfferDto(
        code: json['code'] as String? ?? '',
        basePlanId: json['basePlanId'] as String? ?? '',
        label: json['label'] as String? ?? '',
        discountType: json['discountType'] as String? ?? '',
        discountValue: (json['discountValue'] as num?)?.toInt() ?? 0,
        playOfferTag: json['playOfferTag'] as String? ?? '',
      );
}

class PremiumStatusDto {
  const PremiumStatusDto({
    required this.premium,
    required this.status,
    required this.trialDays,
    required this.expiresAt,
    required this.plans,
    required this.offers,
    required this.googlePlayAvailable,
  });
  final bool premium;
  final String status;
  final int trialDays;
  final DateTime? expiresAt;
  final List<PremiumPlanDto> plans;
  final List<PremiumOfferDto> offers;
  final bool googlePlayAvailable;
  factory PremiumStatusDto.fromJson(Map<String, dynamic> json) =>
      PremiumStatusDto(
        premium: json['premium'] as bool? ?? false,
        status: json['status'] as String? ?? 'NONE',
        trialDays: (json['trialDays'] as num?)?.toInt() ?? 7,
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
        plans: (json['plans'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(PremiumPlanDto.fromJson)
            .toList(),
        offers: (json['eligibleOffers'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(PremiumOfferDto.fromJson)
            .toList(),
        googlePlayAvailable: json['googlePlayAvailable'] as bool? ?? false,
      );
}

class PremiumSubscriptionApi {
  const PremiumSubscriptionApi();

  Future<PremiumStatusDto> status(String token) => _request(token, 'GET');
  Future<PremiumStatusDto> startTrial(String token) => _request(token, 'POST');

  Future<PremiumStatusDto> verifyGooglePlay(
    String token,
    String purchaseToken,
  ) async {
    final String installationId = await const AuthSessionStore()
        .installationId();
    final String country =
        PlatformDispatcher.instance.locale.countryCode?.toUpperCase() ?? 'IN';
    final http.Response response = await http.post(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/subscriptions/google-play/verify',
      ),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'X-Device-Id': installationId,
        'X-Country-Code': country,
      },
      body: jsonEncode(<String, String>{
        'productId': 'chessverse_premium',
        'purchaseToken': purchaseToken,
      }),
    );
    final Object? decoded = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String? message = decoded is Map<String, dynamic>
          ? decoded['message'] as String?
          : null;
      throw PremiumSubscriptionException(
        message ?? 'Premium purchase verification failed.',
      );
    }
    return PremiumStatusDto.fromJson(decoded as Map<String, dynamic>);
  }

  Future<PremiumStatusDto> _request(String token, String method) async {
    final String installationId = await const AuthSessionStore()
        .installationId();
    final String country =
        PlatformDispatcher.instance.locale.countryCode?.toUpperCase() ?? 'IN';
    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/subscriptions${method == 'POST' ? '/trial' : ''}',
    );
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $token',
      'X-Device-Id': installationId,
      'X-Country-Code': country,
    };
    final http.Response response = method == 'POST'
        ? await http.post(uri, headers: headers)
        : await http.get(uri, headers: headers);
    final Object? decoded = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String? message = decoded is Map<String, dynamic>
          ? decoded['message'] as String?
          : null;
      throw PremiumSubscriptionException(
        message ?? 'Premium service is unavailable.',
      );
    }
    return PremiumStatusDto.fromJson(decoded as Map<String, dynamic>);
  }
}

class PremiumSubscriptionException implements Exception {
  const PremiumSubscriptionException(this.message);
  final String message;
}
