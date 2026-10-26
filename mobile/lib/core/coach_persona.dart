import 'app_preferences.dart';

enum CoachPersona {
  mira(
    'Mira',
    'Friendly mentor',
    'Learn at your pace with patient encouragement.',
    'female',
    'encouraging',
  ),
  tara(
    'Tara',
    'Tactical guide',
    'Look for threats, safe pieces and tactical opportunities.',
    'female',
    'neutral',
  ),
  arjun(
    'Arjun',
    'Calm teacher',
    'Slow down and build a clear plan, one move at a time.',
    'male',
    'gentle',
  ),
  vikram(
    'Vikram',
    'Challenge coach',
    'Test your ideas with short questions and focused challenges.',
    'male',
    'encouraging',
  );

  const CoachPersona(
    this.name,
    this.title,
    this.description,
    this.gender,
    this.tone,
  );
  final String name, title, description, gender, tone;
  String get image => 'assets/coaches/$name.webp'.toLowerCase();
  String get preview => switch (this) {
    mira => 'Welcome! Mistakes are part of learning. Let us find your next good move together.',
    tara => 'Before you move, look for checks, captures and threats. Keep your pieces protected.',
    arjun => 'Take your time. Check your king, protect your pieces, then choose a clear plan.',
    vikram => 'Ready for a challenge? Find your opponent’s threat before choosing your next move.',
  };

  String review(String grade, String fallback) {
    final good = grade == 'Best' || grade == 'Great';
    final bad = grade == 'Blunder' || grade == 'Mistake';
    return switch (this) {
      mira => fallback,
      tara =>
        good
            ? 'Strong choice. Now check your opponent’s checks, captures and threats.'
            : bad
            ? 'That move gave away an advantage. Check what is attacked before your next move.'
            : 'Look for forcing moves and keep your pieces protected.',
      arjun =>
        good
            ? 'Well played. Take a calm look at the new position before making your plan.'
            : bad
            ? 'There was a better choice. Take a breath and look for a safer plan.'
            : 'Take your time. Check king safety and consider your opponent’s reply.',
      vikram =>
        good
            ? 'Good work! Your next challenge: what is your opponent planning?'
            : bad
            ? 'A chance to learn! Can you spot the danger before your next move?'
            : 'Your challenge: compare two possible moves before choosing one.',
    };
  }

  static Future<CoachPersona> load() async {
    try {
      final id = await const AppPreferences().readString(
        'coachPersona',
        fallback: 'Mira',
      );
      return values.firstWhere((c) => c.name == id, orElse: () => mira);
    } on Object {
      return mira;
    }
  }

  Future<void> save() =>
      const AppPreferences().writeString('coachPersona', name);
}
