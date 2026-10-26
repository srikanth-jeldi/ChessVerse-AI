import 'dart:async';

/// Reuses completed engine reviews. Never launches analysis or queues speech.
class LiveMoveVoice {
  int _generation = 0;
  int _lastPly = 0;
  bool enabled = false;

  static String? phrase(String classification) => switch (classification) {
    'Blunder' => 'Oh, careful! That was a big mistake. Stay calm and focus on your next move.',
    'Mistake' =>
      'Careful, that helps your opponent. Stay calm and look for a safer plan.',
    'Inaccuracy' => 'Almost! There was a stronger move. Keep an eye on your opponent’s threats.',
    'Best' => 'Excellent! That was the strongest move. Keep it up!',
    'Great' => 'Nicely played! That was a good choice. Stay focused!',
    _ => 'Move played. Let’s see what your opponent does next.',
  };

  void cancel({bool newGame = false}) {
    _generation++;
    if (newGame) {
      _lastPly = 0;
    }
  }

  Future<void> review({
    required int ply,
    required String classification,
    required bool Function() isCurrent,
    required Future<bool> Function(String phrase, bool Function() canSpeak)
    speak,
  }) async {
    if (!enabled || !isCurrent() || ply <= _lastPly) return;
    _lastPly = ply;
    final text = phrase(classification);
    if (text == null) return;
    final generation = ++_generation;
    bool current() => enabled && generation == _generation && isCurrent();
    try {
      await speak(text, current);
    } on Object {
      // Optional audio must never fail or delay the game.
    }
  }
}
