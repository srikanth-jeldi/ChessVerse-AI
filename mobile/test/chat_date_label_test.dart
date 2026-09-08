import 'package:chessverse_ai/features/social/presentation/social_hub_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 8, 14, 30);

  test('uses relative labels only for the current and previous local day', () {
    expect(chatDateLabel(DateTime(2026, 9, 8, 1), now: now), 'Today');
    expect(chatDateLabel(DateTime(2026, 9, 7, 23), now: now), 'Yesterday');
  });

  test('uses an actual date for older messages', () {
    expect(chatDateLabel(DateTime(2026, 9, 1), now: now), 'Sep 1');
    expect(chatDateLabel(DateTime(2025, 12, 31), now: now), 'Dec 31 2025');
  });
}
