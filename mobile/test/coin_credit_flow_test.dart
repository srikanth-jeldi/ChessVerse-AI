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
  int creditAfter = 2;
  @override
  Future<EconomyRewardStatus> status(String token) async {
    calls++;
    if (calls == failAt) throw const EconomyRewardsException('expired', 401);
    return EconomyRewardStatus(
      coins: calls > creditAfter ? 130 : 100,
      dailyAvailable: false,
      nextDailyAt: null,
      rewardedAdsRemaining: credit && calls > creditAfter ? 14 : 15,
      nextRewardedAdAt: null,
      dailyCoins: 100,
      coinsPerAd: 30,
    );
  }
}

class Video extends RewardedCoinService {
  Video() : super.forTesting();
  int shows = 0;
  RewardedCoinOutcome outcome = RewardedCoinOutcome.earned;
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
    return outcome;
  }
}

void main() {
  for (final scenario in [
    'credit',
    'expired before',
    'expired after',
    'unrelated coins',
    'delayed credit',
    'unavailable',
    'dismissed',
  ]) {
    testWidgets('video reward flow: $scenario', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final rewards = Rewards()
        ..credit = scenario == 'credit' || scenario == 'delayed credit'
        ..creditAfter = scenario == 'delayed credit' ? 3 : 2
        ..failAt = scenario == 'expired before'
            ? 2
            : scenario == 'expired after'
            ? 3
            : null;
      final video = Video();
      if (scenario == 'unavailable') {
        video.outcome = RewardedCoinOutcome.unavailable;
      }
      if (scenario == 'dismissed') {
        video.outcome = RewardedCoinOutcome.dismissed;
      }
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
      await tester.ensureVisible(find.text('Watch video'));
      await tester.tap(find.text('Watch video'));
      await tester.pump();
      await tester.pump();
      if (scenario == 'credit') {
        // Credit and gain animation must appear without a two-second wait.
        expect(rewards.calls, 3);
        expect(find.byKey(const ValueKey('coin-reward-gain')), findsOneWidget);
        expect(find.text('+30'), findsOneWidget);
      }
      if (scenario == 'credit') {
        expect(find.text('+30 coins added · Balance 130'), findsOneWidget);
        expect(video.shows, 1);
      } else if (scenario == 'delayed credit') {
        expect(find.byKey(const ValueKey('coin-reward-gain')), findsNothing);
        expect(find.textContaining('Confirming +30'), findsWidgets);
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        expect(find.text('+30 coins added · Balance 130'), findsOneWidget);
        expect(find.byKey(const ValueKey('coin-reward-gain')), findsOneWidget);
      } else if (scenario == 'unavailable' || scenario == 'dismissed') {
        expect(rewards.calls, 2);
        expect(find.byKey(const ValueKey('coin-reward-gain')), findsNothing);
        expect(
          find.textContaining(
            scenario == 'unavailable'
                ? 'No video available'
                : 'Video closed early',
          ),
          findsOneWidget,
        );
      } else if (scenario.startsWith('expired')) {
        expect(find.textContaining('Session expired.'), findsOneWidget);
        expect(video.shows, scenario == 'expired before' ? 0 : 1);
        final calls = rewards.calls;
        await tester.pump(const Duration(seconds: 10));
        expect(rewards.calls, calls);
      } else {
        expect(find.text('+30 coins added · Balance 130'), findsNothing);
        expect(find.textContaining('Confirming +30'), findsWidgets);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
