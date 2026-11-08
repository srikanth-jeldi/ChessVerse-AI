import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chessverse_ai/core/audio/chess_sound_service.dart';

// Real platform audio smoke test; never uses the production account or ads.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('repeated board sounds keep the screen interactive', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Audio test'),
            ),
          ),
        ),
      ),
    );
    final sounds = ChessSoundService.instance;
    sounds.enabled = true;
    for (var round = 0; round < 3; round++) {
      for (final piece in ['P', 'N', 'B', 'R', 'Q', 'K']) {
        await sounds.pieceMove(piece).timeout(const Duration(seconds: 5));
        await tester.tap(find.text('Audio test'));
        await tester.pump(const Duration(milliseconds: 400));
      }
    }
    expect(taps, 18);
    expect(sounds.preparedEffectCount, 6);
    sounds.enabled = false;
    await sounds.move();
    await sounds.dispose();
    expect(sounds.preparedEffectCount, 0);
    sounds.enabled = true;
    await sounds.move().timeout(const Duration(seconds: 5));
    expect(sounds.preparedEffectCount, 1);
    await tester.pump(const Duration(seconds: 1));
    await sounds.dispose();
    expect(tester.takeException(), isNull);
  });
}
