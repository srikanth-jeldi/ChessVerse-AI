import 'dart:typed_data';
import 'dart:ui' as ui;

/// Uses actual image bytes, not filenames. Converts the first frame to a bounded
/// PNG shared by every client. Unsupported device codecs fail before uploading.
Future<Uint8List> normalizeProfilePhoto(Uint8List bytes) async {
  if (bytes.length > 20 * 1024 * 1024) {
    throw const FormatException('Choose an image up to 20 MB.');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width * descriptor.height > 40000000) {
      throw const FormatException('Unable to read this image.');
    }
    final longest = descriptor.width > descriptor.height
        ? descriptor.width
        : descriptor.height;
    final scale = longest > 512 ? 512 / longest : 1.0;
    codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round().clamp(1, 512),
      targetHeight: (descriptor.height * scale).round().clamp(1, 512),
    );
    image = (await codec.getNextFrame()).image;
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) throw const FormatException('Unable to read this image.');
    return png.buffer.asUint8List();
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}
