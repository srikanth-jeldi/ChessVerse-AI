
import 'package:chessverse_ai/core/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailedImage extends ImageProvider<_FailedImage> {
  const _FailedImage();
  @override
  Future<_FailedImage> obtainKey(ImageConfiguration configuration) async =>
      this;
  @override
  ImageStreamCompleter loadImage(
    _FailedImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(StateError('offline')),
  );
}

void main() {
  testWidgets('failed remote avatar retains initials without framework error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlayerAvatar(
          name: 'Mira',
          photoUrl: 'https://example.com/avatar.png',
        ),
      ),
    );
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.onForegroundImageError, isNotNull);
    // Exercise the same image error listener with a deterministic failed stream.
    await tester.pumpWidget(
      MaterialApp(
        home: CircleAvatar(
          foregroundImage: const _FailedImage(),
          onForegroundImageError: avatar.onForegroundImageError,
          child: avatar.child,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('M'), findsOneWidget);
  });
  testWidgets('empty and invalid photos do not request a remote image', (
    tester,
  ) async {
    for (final url in [null, '', ' ', 'file:///photo']) {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerAvatar(name: '', photoUrl: url),
        ),
      );
      expect(
        tester.widget<CircleAvatar>(find.byType(CircleAvatar)).foregroundImage,
        isNull,
      );
      expect(find.text('?'), findsOneWidget);
    }
  });
}
