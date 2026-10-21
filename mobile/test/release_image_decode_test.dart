import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all bundled WebP images decode using the Flutter engine', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest.listAssets().where(
      (path) => path.startsWith('assets/') && path.endsWith('.webp'),
    );
    expect(paths, isNotEmpty);
    for (final path in paths) {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: 64,
      );
      try {
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0), reason: path);
        expect(frame.image.height, greaterThan(0), reason: path);
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    }
  });
}
