import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/core/profile_photo_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('oversized or non-image bytes never upload', () async {
    await expectLater(
      normalizeProfilePhoto(Uint8List(20 * 1024 * 1024 + 1)),
      throwsFormatException,
    );
    await expectLater(
      normalizeProfilePhoto(Uint8List.fromList('not an image'.codeUnits)),
      throwsA(anything),
    );
  });
  test(
    'normalises large source to aspect-preserving PNG under 512 pixels',
    () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 1024, 512),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      final picture = recorder.endRecording();
      final source = await picture.toImage(1024, 512);
      final input = (await source.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      final output = await normalizeProfilePhoto(input);
      expect(output.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(output);
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 512);
      expect(image.height, 256);
      image.dispose();
      codec.dispose();
      source.dispose();
      picture.dispose();
    },
  );
}
