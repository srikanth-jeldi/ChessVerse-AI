import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class EconomyRewardStatus {
  const EconomyRewardStatus({
    required this.coins,
    required this.dailyAvailable,
    required this.nextDailyAt,
    required this.rewardedAdsRemaining,
    required this.dailyCoins,
    required this.coinsPerAd,
  });

  final int coins;
  final bool dailyAvailable;
  final DateTime? nextDailyAt;
  final int rewardedAdsRemaining;
  final int dailyCoins;
  final int coinsPerAd;

  factory EconomyRewardStatus.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> wallet =
        json['wallet'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return EconomyRewardStatus(
      coins: (wallet['coins'] as num?)?.toInt() ?? 0,
      dailyAvailable: json['dailyAvailable'] as bool? ?? false,
      nextDailyAt: DateTime.tryParse(json['nextDailyAt'] as String? ?? ''),
      rewardedAdsRemaining:
          (json['rewardedAdsRemaining'] as num?)?.toInt() ?? 0,
      dailyCoins: (json['dailyCoins'] as num?)?.toInt() ?? 100,
      coinsPerAd: (json['coinsPerAd'] as num?)?.toInt() ?? 150,
    );
  }
}

class EconomyRewardsApi {
  const EconomyRewardsApi();

  Future<EconomyRewardStatus> status(String token) =>
      _request(token, 'GET', '/api/v1/economy/rewards');

  Future<EconomyRewardStatus> claimDaily(String token) =>
      _request(token, 'POST', '/api/v1/economy/daily-reward');

  Future<EconomyRewardStatus> _request(
      String token, String method, String path) async {
    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final http.Response response = method == 'POST'
        ? await http.post(uri, headers: headers)
        : await http.get(uri, headers: headers);
    final Object? decoded =
        response.body.isEmpty ? null : jsonDecode(response.body);
    final Map<String, dynamic> json =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          json['message'] as String? ?? 'Reward service unavailable.');
    }
    return EconomyRewardStatus.fromJson(json);
  }
}
