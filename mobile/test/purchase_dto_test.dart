import 'package:chessverse_ai/features/purchases/data/purchase_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('direct coin catalog and purchase history parse without payment secrets',
      () {
    final center = PurchaseCenterDto.fromJson({
      'products': [
        {
          'id': 'pack-1',
          'sku': 'coins_500',
          'name': '500 Coins',
          'description': 'Starter coin pack',
          'grantAmount': 500,
          'priceMinor': 38000,
          'priceCurrency': 'INR'
        }
      ],
      'orders': [
        {
          'id': 'order-1',
          'productId': 'pack-1',
          'sku': 'coins_500',
          'productName': '500 Coins',
          'provider': 'GOOGLE_PLAY',
          'status': 'FULFILLED',
          'priceMinor': 38000,
          'priceCurrency': 'INR',
          'grantAmount': 500,
          'createdAt': '2026-08-31T00:00:00Z',
          'updatedAt': '2026-08-31T00:01:00Z'
        }
      ],
      'webCheckoutAvailable': false,
      'googlePlayAvailable': false,
      'appleStoreKitAvailable': false,
      'securityNotice': 'No money wallet.'
    });
    expect(center.products.single.coins, 500);
    expect(center.products.single.priceMinor, 38000);
    expect(center.orders.single.status, 'FULFILLED');
    expect(center.securityNotice, contains('wallet'));
  });
}
