import 'dart:async';

/// Reuses completed engine reviews. Never launches analysis or queues speech.
class LiveMoveVoice {
  LiveMoveVoice({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  DateTime? _lastSpoken;
  int _generation = 0;
  int _lastPly = 0;
  bool enabled = false;

  static String? phrase(String classification) => switch (classification) {
    'Blunder' => 'That move was a big mistake. Take a moment to check the safer move in your review.',
    'Mistake' => 'That move gives your opponent an advantage. Your review shows a safer choice.',
    'Inaccuracy' => 'There was a more accurate move here. Check your review when you are ready.',
    'Best' => 'Well played! You found the strongest move.',
    _ => null,
  };

  void cancel({bool newGame = false}) {
    _generation++;
    if (newGame) {
      _lastPly = 0;
      _lastSpoken = null;
    }
  }

  Future<void> review({
    required int ply,
    required String classification,
    required bool Function() isCurrent,
    required Future<void> Function(String phrase, bool Function() canSpeak)
    speak,
  }) async {
    if (!enabled || !isCurrent() || ply <= _lastPly) return;
    _lastPly = ply;
    final text = phrase(classification);
    final now = _now();
    if (text == null ||
        (_lastSpoken != null &&
            now.difference(_lastSpoken!) < const Duration(seconds: 20))) {
      return;
    }
    _lastSpoken = now;
    final generation = ++_generation;
    bool current() => enabled && generation == _generation && isCurrent();
    try {
      await speak(text, current);
    } on Object {
      // Optional audio must never fail or delay the game.
    }
  }
}
