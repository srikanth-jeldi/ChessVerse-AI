import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chessverse_ai/core/audio/live_move_voice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opt-in, cooldown, duplicate and out-of-order results', () async {
    var now = DateTime(2026);
    final voice = LiveMoveVoice(now: () => now);
    final spoken = <String>[];
    Future<void> review(int ply, [String grade = 'Blunder']) => voice.review(
      ply: ply,
      classification: grade,
      isCurrent: () => true,
      speak: (text, valid) async {
        if (valid()) spoken.add(text);
      },
    );
    await review(1);
    expect(spoken, isEmpty);
    voice.enabled = true;
    await review(1);
    await review(1);
    await review(3);
    now = now.add(const Duration(seconds: 21));
    await review(1);
    await review(5, 'Unknown');
    await review(7, 'Best');
    expect(spoken, [
      LiveMoveVoice.phrase('Blunder'),
      LiveMoveVoice.phrase('Best'),
    ]);
  });

  test(
    'pending audio invalidated by mute, navigation, undo or reset',
    () async {
      final voice = LiveMoveVoice()..enabled = true;
      final ready = Completer<void>();
      var played = false;
      final work = voice.review(
        ply: 1,
        classification: 'Mistake',
        isCurrent: () => true,
        speak: (_, valid) async {
          await ready.future;
          played = valid();
        },
      );
      voice.cancel(newGame: true);
      ready.complete();
      await work;
      expect(played, isFalse);
      await voice.review(
        ply: 1,
        classification: 'Best',
        isCurrent: () => false,
        speak: (_, _) async => fail('Inactive game must not request speech'),
      );
    },
  );

  test('audio errors cannot escape into gameplay', () async {
    final voice = LiveMoveVoice()..enabled = true;
    await voice.review(
      ply: 1,
      classification: 'Blunder',
      isCurrent: () => true,
      speak: (_, _) async => throw StateError('offline'),
    );
  });

  test('every supported catalog contains all live coach phrases', () {
    final files = Directory('assets/i18n/ui')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    expect(files.length, 34);
    for (final file in files) {
      final catalog = jsonDecode(file.readAsStringSync()) as Map;
      for (final text in [
        'Automatic voice coach',
        'Short cloud voice tips after reviewed moves. Internet required.',
        ...[
          'Blunder',
          'Mistake',
          'Inaccuracy',
          'Best',
        ].map((c) => LiveMoveVoice.phrase(c)!),
      ]) {
        expect(catalog[text], isA<String>(), reason: '${file.path}: $text');
        expect((catalog[text] as String).trim(), isNotEmpty);
      }
    }
  });
}
