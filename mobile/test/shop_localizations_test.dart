import 'dart:io';

import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/shop_localizations.dart';
import 'package:chessverse_ai/features/shop/data/shop_api.dart';
import 'package:chessverse_ai/features/shop/presentation/cosmetic_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'coin_credit_flow_test.dart' as fixtures;

class Catalog extends ShopApi {
  @override
  Future<ShopDto> load(String token) async => ShopDto(
    playerId: 'test',
    wallet: const WalletDto(coins: 2370, diamonds: 0),
    items: [
      for (final category in ['BOARD', 'PIECES', 'FRAME'])
        CosmeticItemDto(
          id: category,
          slug: 'test',
          category: category,
          name: 'Royal',
          description: 'Server product description',
          priceCurrency: 'COINS',
          priceAmount: 500,
          owned: false,
          equipped: false,
        ),
    ],
  );
}

void main() {
  setUpAll(() async {
    if (Platform.environment['SHOP_VISUAL_FONTS'] != '1') return;
    for (final entry in {
      'Roboto': 'Nirmala.ttc',
      'ArabicPreview': 'segoeui.ttf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(
            Future.value(
              ByteData.sublistView(
                await File('C:/Windows/Fonts/${entry.value}').readAsBytes(),
              ),
            ),
          ))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final codes = AppLanguageController.supported
      .where((l) => l.code != 'system')
      .map((l) => l.code);
  test('all shop keys and placeholders translated for all 34 languages', () {
    expect(shopTranslations.keys.toSet(), codes.toSet());
    for (final code in codes) {
      expect(shopTranslations[code]!.length, shopKeys.length, reason: code);
      for (var i = 0; i < shopKeys.length; i++) {
        final text = shopTranslations[code]![i];
        expect(text.trim(), isNotEmpty, reason: '$code ${shopKeys[i]}');
        Set<String> vars(String s) =>
            RegExp(r'\{\w+\}').allMatches(s).map((m) => m[0]!).toSet();
        expect(
          vars(text),
          vars(shopTranslations['en']![i]),
          reason: '$code ${shopKeys[i]}',
        );
      }
    }
  });
  for (final config in [
    for (final code in codes) (code, 1.0),
    ('en', 1.6),
    ('te', 1.6),
    ('ar', 1.6),
  ]) {
    final code = config.$1;
    testWidgets(
      'Shop fits 360px with $code labels at ${config.$2} and category guides',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        AppLanguageController.effectiveLanguageChanges.value = code;
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(config.$2)),
              child: child!,
            ),
            theme: ThemeData.dark().copyWith(
              textTheme: ThemeData.dark().textTheme.apply(
                fontFamily: code == 'ar' ? 'ArabicPreview' : 'Roboto',
              ),
            ),
            home: CosmeticShopScreen(
              token: 'test',
              shopApi: Catalog(),
              rewardsApi: fixtures.Rewards(),
              rewardedCoins: fixtures.Video(),
            ),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text(shopText('watch', code)), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (config.$2 == 1 &&
            Platform.environment['SHOP_VISUAL_FONTS'] == '1' &&
            ['en', 'te', 'ar'].contains(code)) {
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile('goldens/shop_$code.png'),
          );
        }
        for (final key in ['pieces', 'badges', 'boards']) {
          final tab = find.widgetWithText(ChoiceChip, shopText(key, code));
          await tester.ensureVisible(tab);
          await tester.tap(tab);
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull, reason: '$code $key');
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
