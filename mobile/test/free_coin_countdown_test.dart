import 'package:chessverse_ai/features/shop/presentation/cosmetic_shop_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free coin countdown never displays more than eight hours', () {
    expect(
      formatFreeCoinCountdown(const Duration(hours: 8, seconds: 2)),
      '08:00:00',
    );
  });

  test('free coin countdown shows the first elapsed second precisely', () {
    expect(
      formatFreeCoinCountdown(
        const Duration(hours: 7, minutes: 59, seconds: 59),
      ),
      '07:59:59',
    );
  });
}
