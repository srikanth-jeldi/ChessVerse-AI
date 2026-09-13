import 'package:chessverse_ai/core/notifications/notification_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats chat media markers for notification surfaces', () {
    expect(
      notificationMessagePreview('::giphy::gif::https://example.com/a.gif'),
      'Shared a GIF',
    );
    expect(
      notificationMessagePreview(
        '::giphy::sticker::https://example.com/a.webp',
      ),
      'Shared a sticker',
    );
  });

  test('preserves normal text and formats attachments', () {
    expect(notificationMessagePreview('hello'), 'hello');
    expect(
      notificationMessagePreview('{"kind":"attachment","caption":"Photo"}'),
      'Photo',
    );
    expect(
      notificationMessagePreview('{"kind":"attachment","caption":""}'),
      'Shared an attachment',
    );
  });
}
