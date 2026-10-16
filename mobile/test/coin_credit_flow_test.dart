import 'package:chessverse_ai/core/ads/rewarded_coin_service.dart';
import 'package:chessverse_ai/features/shop/data/economy_rewards_api.dart';
import 'package:chessverse_ai/features/shop/data/shop_api.dart';
import 'package:chessverse_ai/features/shop/presentation/cosmetic_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class Shop extends ShopApi {
  @override
  Future<ShopDto> load(String token) async => const ShopDto(
    playerId: 'player',
    wallet: WalletDto(coins: 100, diamonds: 0),
    items: [],
  );
}

class Rewards extends EconomyRewardsApi {
  int calls = 0;
  int? failAt;
  bool credit = false;
  @override
  Future<EconomyRewardStatus> status(String token) async {
    calls++;
    if (calls == failAt) throw const EconomyRewardsException('expired', 401);
    return EconomyRewardStatus(
      coins: calls > 2 ? 130 : 100,
      dailyAvailable: false,
      nextDailyAt: null,
      rewardedAdsRemaining: credit && calls > 2 ? 14 : 15,
      nextRewardedAdAt: null,
      dailyCoins: 100,
      coinsPerAd: 30,
    );
  }
}

class Video extends RewardedCoinService {
  Video() : super.forTesting();
  int shows = 0;
  @override
  bool get supported => true;
  @override
  Future<bool> load({Duration timeout = const Duration(seconds: 12)}) async =>
      true;
  @override
  Future<RewardedCoinOutcome> show({
    required String playerId,
    required String token,
  }) async {
    shows++;
    return RewardedCoinOutcome.earned;
  }
}

void main() {
  for (final scenario in [
    'credit',
    'expired before',
    'expired after',
    'unrelated coins',
  ]) {
    testWidgets('video reward flow: $scenario', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final rewards = Rewards()
        ..credit = scenario == 'credit'
        ..failAt = scenario == 'expired before'
            ? 2
            : scenario == 'expired after'
            ? 3
            : null;
      final video = Video();
      await tester.pumpWidget(
        MaterialApp(
          home: CosmeticShopScreen(
            token: 'token',
            shopApi: Shop(),
            rewardsApi: rewards,
            rewardedCoins: video,
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.ensureVisible(find.text('WATCH VIDEO'));
      await tester.tap(find.text('WATCH VIDEO'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      if (scenario == 'credit') {
        expect(
          find.text('Reward confirmed. Your coin balance is up to date.'),
          findsOneWidget,
        );
        expect(video.shows, 1);
      } else if (scenario.startsWith('expired')) {
        expect(
          find.textContaining('Your session has expired.'),
          findsOneWidget,
        );
        expect(video.shows, scenario == 'expired before' ? 0 : 1);
        final calls = rewards.calls;
        await tester.pump(const Duration(seconds: 10));
        expect(rewards.calls, calls);
      } else {
        expect(
          find.text('Reward confirmed. Your coin balance is up to date.'),
          findsNothing,
        );
        expect(find.textContaining('Confirming your +30'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
