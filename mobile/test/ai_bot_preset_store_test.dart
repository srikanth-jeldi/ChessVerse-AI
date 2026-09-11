import 'package:chessverse_ai/core/ai_bot_preset_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rating maps safely across all ten engine levels', () {
    expect(ratingToEngineLevel(400), 1);
    expect(ratingToEngineLevel(659), 1);
    expect(ratingToEngineLevel(660), 2);
    expect(ratingToEngineLevel(3000), 10);
    expect(ratingToEngineLevel(9999), 10);
  });

  test('preset exposes account payload as a playable engine level', () {
    final AiBotPreset preset = AiBotPreset.fromJson(<String, dynamic>{
      'id': 'one',
      'name': 'Attacker',
      'rating': 1450,
      'style': 'aggressive',
    });
    expect(preset.style, AiBotStyle.aggressive);
    expect(preset.engineLevel, inInclusiveRange(1, 10));
  });

  test('personalities produce distinct move preferences', () {
    final double attack = aiStyleMoveBonus(
      AiBotStyle.aggressive,
      capturedValue: 3,
      givesCheck: true,
      castles: false,
      queenMove: false,
      movesPlayed: 4,
    );
    final double defend = aiStyleMoveBonus(
      AiBotStyle.defensive,
      capturedValue: 0,
      givesCheck: false,
      castles: true,
      queenMove: false,
      movesPlayed: 4,
    );
    final double earlyQueen = aiStyleMoveBonus(
      AiBotStyle.defensive,
      capturedValue: 0,
      givesCheck: false,
      castles: false,
      queenMove: true,
      movesPlayed: 4,
    );
    expect(attack, 22);
    expect(defend, 14);
    expect(earlyQueen, -5);
  });
}
