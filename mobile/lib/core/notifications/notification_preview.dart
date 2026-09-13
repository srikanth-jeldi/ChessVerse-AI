import 'dart:convert';

String notificationMessagePreview(String? body) {
  final String value = body?.trim() ?? '';
  if (value.isEmpty) return 'New message';
  if (value.startsWith('::giphy::gif::')) return 'Shared a GIF';
  if (value.startsWith('::giphy::sticker::')) return 'Shared a sticker';
  try {
    final dynamic decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic> && decoded['kind'] == 'attachment') {
      final String caption = (decoded['caption'] as String? ?? '').trim();
      return caption.isEmpty ? 'Shared an attachment' : caption;
    }
  } on FormatException {
    // Ordinary messages are plain text.
  }
  return value;
}
