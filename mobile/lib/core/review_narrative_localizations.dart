import 'app_language.dart';
import 'coach_localizations.dart';

/// Offline review templates. Placeholders contain engine evidence, never prose.
/// Unknown server/AI prose is returned verbatim rather than replaced by advice.
const reviewNarrativeKeys = <String>[
  'forcing',
  'castle',
  'capture',
  'quiet',
  'best',
  'major',
  'advantage',
  'playable',
  'threat',
  'confident',
  'goodIdeas',
  'useful',
  'noMoves',
  'summary',
  'bestCount',
  'forcingCount',
  'centralHabit',
  'playableHabit',
  'unlock',
  'move',
  'unavailable',
  'unclassified',
  'stronger',
  'sicilian',
  'ruy',
  'italian',
  'french',
  'caro',
  'kingsIndian',
  'queensGambit',
  'nimzo',
  'queensPawnGame',
  'kingsPawnGame',
  'kingsPawnOpening',
  'queensPawnOpening',
  'english',
  'reti',
  'power',
  'excellent',
  'tactical',
  'bookMetadata',
  'plyGraph',
  'mateGraph',
  'advantageGraph',
  'graphAccessibility',
  'foundContinuation',
  'moreAccurate',
  'prefer',
  'matchedStockfish',
  'strongerBy',
];

final Map<String, List<String>> reviewNarrativeTranslations = {
  for (final row in _rows.entries)
    row.key: [
      ...row.value.split('|'),
      ..._extras[row.key]!.split('|'),
      ..._graphExtras[row.key]!.split('|'),
      ..._fallbackExtras[row.key]!.split('|'),
      ..._cloudExtras[row.key]!.split('|')
    ],
};

const _sources = <String, String>{
  'Power move': 'power',
  'You found the strongest continuation.': 'foundContinuation',
  'This matched Stockfish’s strongest continuation.': 'matchedStockfish',
  "This matched Stockfish's strongest continuation.": 'matchedStockfish',
  'Excellent': 'excellent',
  'Tactical': 'tactical',
  'Interactive Stockfish evaluation graph. Swipe or tap to inspect a move.':
      'graphAccessibility',
  'A forcing check gains tempo. Verify every legal king reply before committing.':
      'forcing',
  'Castling improves king safety and connects a rook to the game.': 'castle',
  'A capture changes the material balance. Recheck recaptures and zwischenzugs.':
      'capture',
  'A quiet move. Compare it with forcing checks, captures, and direct threats.':
      'quiet',
  "You found the engine's strongest continuation and kept control of the position.":
      'best',
  'This gives the opponent a major tactical opportunity.': 'major',
  'This concedes a clear advantage that can be avoided.': 'advantage',
  'The move is playable, but it misses a more accurate continuation.':
      'playable',
  'This move is playable, but it misses a more accurate continuation.':
      'playable',
  'Confident, accurate chess': 'confident',
  'Good ideas with room to sharpen': 'goodIdeas',
  'A useful game to learn from': 'useful',
  'No recorded moves are available yet.': 'noMoves',
  'Your strongest habit was central control and piece development.':
      'centralHabit',
  'You kept the position playable and created a base for deeper calculation.':
      'playableHabit',
  'Play a complete game to unlock a move-level turning point.': 'unlock',
  'Opening not available': 'unavailable',
  'Unclassified opening': 'unclassified',
  'Sicilian Defence': 'sicilian',
  'Ruy Lopez': 'ruy',
  'Italian Game': 'italian',
  'French Defence': 'french',
  'Caro-Kann Defence': 'caro',
  "King's Indian Defence": 'kingsIndian',
  "Queen's Gambit": 'queensGambit',
  'Nimzo/Indian setup': 'nimzo',
  "Queen's Pawn Game": 'queensPawnGame',
  "King's Pawn Game": 'kingsPawnGame',
  "King's Pawn Opening": 'kingsPawnOpening',
  "Queen's Pawn Opening": 'queensPawnOpening',
  'English Opening': 'english',
  'Réti Opening': 'reti',
};

const reviewNarrativeSources = _sources;

const _sharedSources = <String>{
  'This move improves central influence or development. Keep king safety in view.',
  'Complete one centre-control lesson before the next rated game.',
  'Play one slower game and apply the same thinking routine.',
};

class _TemplateMatch {
  const _TemplateMatch(this.key, this.values);
  final String key;
  final Map<String, String> values;
}

_TemplateMatch? _match(String value) {
  final direct = _sources[value];
  if (direct != null) return _TemplateMatch(direct, const {});
  final patterns = <(String, String, List<String>)>[
    (
      r'^([a-h][1-8][a-h][1-8][qrbn]?) was stronger by (\d+) centipawns\.$',
      'strongerBy',
      ['move', 'count']
    ),
    (
      r'^([a-h][1-8][a-h][1-8][qrbn]?) was more accurate\.$',
      'moreAccurate',
      ['move']
    ),
    (r'^Prefer ([a-h][1-8][a-h][1-8][qrbn]?)\.$', 'prefer', ['move']),
    (
      r'^Ply (\d+) • (White|Black) (\S+)$',
      'plyGraph',
      ['count', 'side', 'move']
    ),
    (r'^Mate ([+-]?\d+)$', 'mateGraph', ['count']),
    (
      r'^(White|Black) advantage • ([+-]?\d+(?:\.\d+)?)$',
      'advantageGraph',
      ['side', 'score']
    ),
    (
      r'^(\d+) half-moves reviewed across opening, middlegame, and endgame decisions\.$',
      'summary',
      ['count']
    ),
    (
      r'^(\d+) of (\d+) reviewed moves were Best or Great\.$',
      'bestCount',
      ['count', 'total']
    ),
    (
      r'^You recognised (\d+) forcing moves? and created concrete problems\.$',
      'forcingCount',
      ['count']
    ),
    (
      r'^([a-h][1-8][a-h][1-8][qrbn]?) was stronger; the immediate opponent threat is (\S+)\.$',
      'threat',
      ['best', 'threat']
    ),
    (r'^([a-h][1-8][a-h][1-8][qrbn]?) was stronger\.$', 'stronger', ['best']),
  ];
  for (final pattern in patterns) {
    final match = RegExp(pattern.$1).firstMatch(value);
    if (match != null) {
      return _TemplateMatch(pattern.$2, {
        for (var i = 0; i < pattern.$3.length; i++)
          pattern.$3[i]: match.group(i + 1)!,
      });
    }
  }
  return null;
}

bool supportsReviewNarrative(String value) {
  if (_match(value) != null || _sharedSources.contains(value)) return true;
  final metadata =
      RegExp(r'^(.+?) • (.+?) • (\d+) book plies • first deviation ply (\d+)$')
          .firstMatch(value);
  if (metadata != null) return _sources.containsKey(metadata.group(2));
  final wrapper = RegExp(r'^Move (\d+): (.+?) ([•—]) (.+)$').firstMatch(value);
  if (wrapper != null) return supportsReviewNarrative(wrapper.group(4)!);
  final turn = RegExp(
          r'^([a-h][1-8](?: ?x ?)?[a-h][1-8][qrbn]?(?: e\.p\.)?|O-O(?:-O)?) ([•—]) (.+)$')
      .firstMatch(value);
  if (turn != null) return supportsReviewNarrative(turn.group(3)!);
  final preferred = RegExp(r'^(Prefer [a-h][1-8][a-h][1-8][qrbn]?\.) (.+)$')
      .firstMatch(value);
  if (preferred != null) return supportsReviewNarrative(preferred.group(2)!);
  final evidence = RegExp(
          r'^(.+\.) ([a-h][1-8][a-h][1-8][qrbn]? was stronger; the immediate opponent threat is \S+\.)$')
      .firstMatch(value);
  if (evidence != null) {
    return supportsReviewNarrative(evidence.group(1)!) &&
        supportsReviewNarrative(evidence.group(2)!);
  }
  return false;
}

String localizeReviewNarrative(String value, String code) {
  final language = AppLanguageController.resolveCode(code);
  if (language == 'en') return value;
  String text(String key, Map<String, String> values) {
    var result = reviewNarrativeTranslations[language]![
        reviewNarrativeKeys.indexOf(key)];
    for (final entry in values.entries) {
      result = result.replaceAll(
          '{${entry.key}}',
          entry.key == 'side'
              ? CoachLocalizations(language).source(entry.value)
              : entry.value);
    }
    return result;
  }

  final match = _match(value);
  if (match != null) return text(match.key, match.values);
  final metadata =
      RegExp(r'^(.+?) • (.+?) • (\d+) book plies • first deviation ply (\d+)$')
          .firstMatch(value);
  if (metadata != null && supportsReviewNarrative(value)) {
    return '${metadata.group(1)} • ${localizeReviewNarrative(metadata.group(2)!, language)} • ${text('bookMetadata', {
          'count': metadata.group(3)!,
          'ply': metadata.group(4)!
        })}';
  }
  if (_sharedSources.contains(value)) {
    return CoachLocalizations(language).source(value);
  }
  final wrapper = RegExp(r'^Move (\d+): (.+?) ([•—]) (.+)$').firstMatch(value);
  if (wrapper != null && supportsReviewNarrative(wrapper.group(4)!)) {
    return '${text('move', {
          'count': wrapper.group(1)!
        })}: ${wrapper.group(2)} ${wrapper.group(3)} ${localizeReviewNarrative(wrapper.group(4)!, language)}';
  }
  final turn = RegExp(
          r'^([a-h][1-8](?: ?x ?)?[a-h][1-8][qrbn]?(?: e\.p\.)?|O-O(?:-O)?) ([•—]) (.+)$')
      .firstMatch(value);
  if (turn != null && supportsReviewNarrative(turn.group(3)!)) {
    return '${turn.group(1)} ${turn.group(2)} ${localizeReviewNarrative(turn.group(3)!, language)}';
  }
  final preferred = RegExp(r'^(Prefer [a-h][1-8][a-h][1-8][qrbn]?\.) (.+)$')
      .firstMatch(value);
  if (preferred != null && supportsReviewNarrative(preferred.group(2)!)) {
    return '${localizeReviewNarrative(preferred.group(1)!, language)} ${localizeReviewNarrative(preferred.group(2)!, language)}';
  }
  final evidence = RegExp(
          r'^(.+\.) ([a-h][1-8][a-h][1-8][qrbn]? was stronger; the immediate opponent threat is \S+\.)$')
      .firstMatch(value);
  if (evidence != null && supportsReviewNarrative(value)) {
    return '${localizeReviewNarrative(evidence.group(1)!, language)} ${localizeReviewNarrative(evidence.group(2)!, language)}';
  }
  return value;
}

const _cloudExtras = <String, String>{
  'en':
      'This matched Stockfish’s strongest continuation.|{move} was stronger by {count} centipawns.',
  'te':
      'ఇది స్టాక్‌ఫిష్ అత్యంత బలమైన కొనసాగింపుతో సరిపోలింది.|{move} ఎత్తు {count} సెంటిపాన్‌ల మేర బలంగా ఉంది.',
  'hi':
      'यह स्टॉकफिश के सबसे मजबूत क्रम से मेल खाती थी।|{move} चाल {count} सेंटीपॉन अधिक मजबूत थी।',
  'ta':
      'இது ஸ்டாக்ஃபிஷின் வலுவான தொடர்ச்சியுடன் பொருந்தியது.|{move} நகர்வு {count} சென்டிபான் அளவு வலுவானது.',
  'kn':
      'ಇದು ಸ್ಟಾಕ್‌ಫಿಷ್‌ನ ಅತ್ಯಂತ ಬಲವಾದ ಮುಂದುವರಿಕೆಗೆ ಹೊಂದಿತ್ತು.|{move} ನಡೆ {count} ಸೆಂಟಿಪಾನ್‌ಗಳಷ್ಟು ಹೆಚ್ಚು ಬಲವಾಗಿತ್ತು.',
  'ml':
      'ഇത് സ്റ്റോക്ക്ഫിഷിന്റെ ഏറ്റവും ശക്തമായ തുടർച്ചയുമായി പൊരുത്തപ്പെട്ടു.|{move} നീക്കം {count} സെന്റിപോൺ കൂടുതൽ ശക്തമായിരുന്നു.',
  'mr':
      'ही स्टॉकफिशच्या सर्वात मजबूत क्रमाशी जुळली.|{move} चाल {count} सेंटिपॉनने अधिक मजबूत होती.',
  'bn':
      'এটি স্টকফিশের সবচেয়ে শক্তিশালী ধারাবাহিকতার সঙ্গে মিলেছিল।|{move} চালটি {count} সেন্টিপন বেশি শক্তিশালী ছিল।',
  'gu':
      'આ સ્ટોકફિશના સૌથી મજબૂત ક્રમ સાથે મેળ ખાતી હતી.|{move} ચાલ {count} સેન્ટિપોન જેટલી વધુ મજબૂત હતી.',
  'pa':
      'ਇਹ ਸਟਾਕਫਿਸ਼ ਦੇ ਸਭ ਤੋਂ ਮਜ਼ਬੂਤ ਕ੍ਰਮ ਨਾਲ ਮੇਲ ਖਾਂਦੀ ਸੀ।|{move} ਚਾਲ {count} ਸੈਂਟੀਪਾਨ ਵਧੇਰੇ ਮਜ਼ਬੂਤ ਸੀ।',
  'ur':
      'یہ اسٹاک فش کے مضبوط ترین تسلسل سے مطابقت رکھتی تھی۔|{move} چال {count} سینٹی پون زیادہ مضبوط تھی۔',
  'ar':
      'طابقت هذه أقوى تكملة لستوكفيش.|كانت {move} أقوى بمقدار {count} سنتيبيدق.',
  'fa':
      'این با قوی‌ترین ادامهٔ استاک‌فیش مطابقت داشت.|{move} به اندازهٔ {count} سنتی‌پیاده قوی‌تر بود.',
  'es':
      'Esto coincidía con la continuación más fuerte de Stockfish.|{move} era más fuerte por {count} centipeones.',
  'fr':
      'Cela correspondait à la suite la plus forte de Stockfish.|{move} était plus fort de {count} centipions.',
  'de':
      'Dies entsprach der stärksten Fortsetzung von Stockfish.|{move} war um {count} Zentibauern stärker.',
  'it':
      'Questo corrispondeva alla continuazione più forte di Stockfish.|{move} era più forte di {count} centesimi di pedone.',
  'pt':
      'Isso correspondia à continuação mais forte do Stockfish.|{move} era mais forte por {count} centipeões.',
  'ru':
      'Это совпало с сильнейшим продолжением Stockfish.|{move} было сильнее на {count} сантипешек.',
  'uk':
      'Це збіглося з найсильнішим продовженням Stockfish.|{move} було сильніше на {count} сантипішаків.',
  'tr':
      'Bu, Stockfish’in en güçlü devam yoluyla eşleşti.|{move}, {count} centipawn daha güçlüydü.',
  'zh': '这与Stockfish的最强后续变化一致。|{move} 强了 {count} 厘兵。',
  'ja': 'Stockfishの最強の継続手順と一致していました。|{move} は {count} センチポーン分強い手でした。',
  'ko': 'Stockfish의 가장 강한 후속 수순과 일치했습니다.|{move}이 {count} 센티폰 더 강했습니다.',
  'id':
      'Ini cocok dengan kelanjutan terkuat Stockfish.|{move} lebih kuat sebesar {count} centipawn.',
  'ms':
      'Ini sepadan dengan sambungan terkuat Stockfish.|{move} lebih kuat sebanyak {count} centipawn.',
  'th':
      'ตานี้ตรงกับแนวเดินต่อที่แข็งแกร่งที่สุดของ Stockfish|{move} แข็งแกร่งกว่า {count} เซนติพอน',
  'vi':
      'Nước này khớp với diễn biến mạnh nhất của Stockfish.|{move} mạnh hơn {count} centipawn.',
  'pl':
      'To odpowiadało najsilniejszej kontynuacji Stockfisha.|{move} było silniejsze o {count} centypionów.',
  'nl':
      'Dit kwam overeen met de sterkste voortzetting van Stockfish.|{move} was {count} centipionnen sterker.',
  'sv':
      'Detta motsvarade Stockfishs starkaste fortsättning.|{move} var {count} centibönder starkare.',
  'el':
      'Αυτό ταίριαζε με την ισχυρότερη συνέχεια του Stockfish.|Το {move} ήταν ισχυρότερο κατά {count} εκατοστά πιονιού.',
  'he':
      'זה תאם להמשך החזק ביותר של Stockfish.|{move} היה חזק יותר ב-{count} סנטי-רגלי.',
  'sw':
      'Hii ililingana na mwendelezo wenye nguvu zaidi wa Stockfish.|{move} ilikuwa na nguvu zaidi kwa centipawn {count}.',
};

const _fallbackExtras = <String, String>{
  'en':
      'You found the strongest continuation.|{move} was more accurate.|Prefer {move}.',
  'te':
      'అత్యంత బలమైన కొనసాగింపును కనుగొన్నారు.|{move} మరింత ఖచ్చితమైనది.|{move} ఎత్తుకు ప్రాధాన్యం ఇవ్వండి.',
  'hi':
      'आपने सबसे मजबूत क्रम खोज लिया।|{move} अधिक सटीक थी।|{move} को प्राथमिकता दें।',
  'ta':
      'வலுவான தொடர்ச்சியைக் கண்டறிந்தீர்கள்.|{move} இன்னும் துல்லியமானது.|{move}க்கு முன்னுரிமை தரவும்.',
  'kn':
      'ಅತ್ಯಂತ ಬಲವಾದ ಮುಂದುವರಿಕೆಯನ್ನು ಕಂಡಿರಿ.|{move} ಹೆಚ್ಚು ನಿಖರವಾಗಿತ್ತು.|{move}ಗೆ ಆದ್ಯತೆ ನೀಡಿ.',
  'ml':
      'ഏറ്റവും ശക്തമായ തുടർച്ച കണ്ടെത്തി.|{move} കൂടുതൽ കൃത്യമായിരുന്നു.|{move}ന് മുൻഗണന നൽകുക.',
  'mr':
      'तुम्ही सर्वात मजबूत क्रम शोधला.|{move} अधिक अचूक होती.|{move} ला प्राधान्य द्या.',
  'bn':
      'সবচেয়ে শক্তিশালী ধারাবাহিকতা খুঁজেছেন।|{move} বেশি নির্ভুল ছিল।|{move} বেছে নিন।',
  'gu':
      'તમે સૌથી મજબૂત ક્રમ શોધ્યો.|{move} વધુ સચોટ હતી.|{move} ને પ્રાધાન્ય આપો.',
  'pa':
      'ਤੁਸੀਂ ਸਭ ਤੋਂ ਮਜ਼ਬੂਤ ਕ੍ਰਮ ਲੱਭਿਆ।|{move} ਵਧੇਰੇ ਸਹੀ ਸੀ।|{move} ਨੂੰ ਪਹਿਲ ਦਿਓ।',
  'ur':
      'آپ نے مضبوط ترین تسلسل تلاش کیا۔|{move} زیادہ درست تھی۔|{move} کو ترجیح دیں۔',
  'ar': 'وجدت أقوى تكملة.|كانت {move} أدق.|فضّل {move}.',
  'fa': 'قوی‌ترین ادامه را یافتید.|{move} دقیق‌تر بود.|{move} را ترجیح دهید.',
  'es':
      'Encontraste la continuación más fuerte.|{move} era más precisa.|Prefiere {move}.',
  'fr':
      'Vous avez trouvé la suite la plus forte.|{move} était plus précis.|Préférez {move}.',
  'de':
      'Du hast die stärkste Fortsetzung gefunden.|{move} war genauer.|Bevorzuge {move}.',
  'it':
      'Hai trovato la continuazione più forte.|{move} era più precisa.|Preferisci {move}.',
  'pt':
      'Você encontrou a continuação mais forte.|{move} era mais preciso.|Prefira {move}.',
  'ru':
      'Вы нашли сильнейшее продолжение.|{move} было точнее.|Предпочтите {move}.',
  'uk':
      'Ви знайшли найсильніше продовження.|{move} було точніше.|Віддайте перевагу {move}.',
  'tr':
      'En güçlü devam yolunu buldunuz.|{move} daha doğruydu.|{move} tercih edin.',
  'zh': '你找到了最强的后续变化。|{move} 更精确。|优先考虑 {move}。',
  'ja': '最強の継続手順を見つけました。|{move} のほうが正確でした。|{move} を優先しましょう。',
  'ko': '가장 강한 후속 수순을 찾았습니다.|{move}이 더 정확했습니다.|{move}을 우선하세요.',
  'id':
      'Anda menemukan kelanjutan terkuat.|{move} lebih akurat.|Utamakan {move}.',
  'ms': 'Anda menemui sambungan terkuat.|{move} lebih tepat.|Utamakan {move}.',
  'th':
      'คุณพบแนวเดินต่อที่แข็งแกร่งที่สุด|{move} แม่นยำกว่า|เลือก {move} เป็นหลัก',
  'vi':
      'Bạn tìm được diễn biến mạnh nhất.|{move} chính xác hơn.|Ưu tiên {move}.',
  'pl':
      'Znalazłeś najsilniejszą kontynuację.|{move} było dokładniejsze.|Wybierz {move}.',
  'nl':
      'Je vond de sterkste voortzetting.|{move} was nauwkeuriger.|Kies liever {move}.',
  'sv':
      'Du hittade den starkaste fortsättningen.|{move} var mer exakt.|Föredra {move}.',
  'el':
      'Βρήκατε την ισχυρότερη συνέχεια.|Το {move} ήταν ακριβέστερο.|Προτιμήστε {move}.',
  'he': 'מצאתם את ההמשך החזק ביותר.|{move} היה מדויק יותר.|העדיפו {move}.',
  'sw':
      'Umepata mwendelezo wenye nguvu zaidi.|{move} ilikuwa sahihi zaidi.|Pendelea {move}.',
};

const _graphExtras = <String, String>{
  'en':
      'Ply {count} • {side} {move}|Mate {count}|{side} advantage • {score}|Interactive Stockfish evaluation graph. Swipe or tap to inspect a move.',
  'te':
      'అర్ధ-ఎత్తు {count} • {side} {move}|మేట్ {count}|{side} ఆధిక్యం • {score}|స్టాక్‌ఫిష్ మూల్యాంకన గ్రాఫ్. ఎత్తును పరిశీలించడానికి తాకండి లేదా స్వైప్ చేయండి.',
  'hi':
      'अर्ध-चाल {count} • {side} {move}|मात {count}|{side} की बढ़त • {score}|इंटरैक्टिव स्टॉकफिश मूल्यांकन ग्राफ। चाल देखने के लिए स्वाइप या टैप करें।',
  'ta':
      'அரைநகர்வு {count} • {side} {move}|மேட் {count}|{side} முன்னிலை • {score}|ஸ்டாக்ஃபிஷ் மதிப்பீட்டு வரைபடம். நகர்வைப் பார்க்கத் தொடவும் அல்லது ஸ்வைப் செய்யவும்.',
  'kn':
      'ಅರ್ಧನಡೆ {count} • {side} {move}|ಮೇಟ್ {count}|{side} ಮುನ್ನಡೆ • {score}|ಸಂವಾದಾತ್ಮಕ ಸ್ಟಾಕ್‌ಫಿಷ್ ಮೌಲ್ಯಮಾಪನ ಗ್ರಾಫ್. ನಡೆ ನೋಡಲು ಸ್ವೈಪ್ ಅಥವಾ ಟ್ಯಾಪ್ ಮಾಡಿ.',
  'ml':
      'അർധനീക്കം {count} • {side} {move}|മേറ്റ് {count}|{side} മേൽക്കൈ • {score}|സ്റ്റോക്ക്ഫിഷ് മൂല്യനിർണയ ഗ്രാഫ്. നീക്കം പരിശോധിക്കാൻ സ്വൈപ്പ് ചെയ്യുക അല്ലെങ്കിൽ തൊടുക.',
  'mr':
      'अर्धचाल {count} • {side} {move}|मात {count}|{side} आघाडी • {score}|परस्परसंवादी स्टॉकफिश मूल्यमापन आलेख. चाल पाहण्यासाठी स्वाइप किंवा टॅप करा.',
  'bn':
      'অর্ধচাল {count} • {side} {move}|মাত {count}|{side} সুবিধা • {score}|ইন্টারঅ্যাক্টিভ স্টকফিশ মূল্যায়ন গ্রাফ। চাল দেখতে সোয়াইপ বা ট্যাপ করুন।',
  'gu':
      'અર્ધચાલ {count} • {side} {move}|માત {count}|{side} સરસાઈ • {score}|ઇન્ટરેક્ટિવ સ્ટોકફિશ મૂલ્યાંકન ગ્રાફ. ચાલ જોવા સ્વાઇપ અથવા ટેપ કરો.',
  'pa':
      'ਅੱਧੀ ਚਾਲ {count} • {side} {move}|ਮਾਤ {count}|{side} ਬੜ੍ਹਤ • {score}|ਇੰਟਰਐਕਟਿਵ ਸਟਾਕਫਿਸ਼ ਮੁਲਾਂਕਣ ਗ੍ਰਾਫ਼। ਚਾਲ ਵੇਖਣ ਲਈ ਸਵਾਈਪ ਜਾਂ ਟੈਪ ਕਰੋ।',
  'ur':
      'نصف چال {count} • {side} {move}|مات {count}|{side} برتری • {score}|اسٹاک فش کا تعاملی جائزہ گراف۔ چال دیکھنے کے لیے سوائپ یا ٹیپ کریں۔',
  'ar':
      'نصف النقلة {count} • {side} {move}|مات {count}|أفضلية {side} • {score}|مخطط تقييم ستوكفيش تفاعلي. اسحب أو انقر لفحص نقلة.',
  'fa':
      'نیم‌حرکت {count} • {side} {move}|مات {count}|برتری {side} • {score}|نمودار تعاملی ارزیابی استاک‌فیش. برای بررسی حرکت بکشید یا ضربه بزنید.',
  'es':
      'Media jugada {count} • {side} {move}|Mate {count}|Ventaja de {side} • {score}|Gráfico interactivo de evaluación de Stockfish. Desliza o toca para examinar una jugada.',
  'fr':
      'Demi-coup {count} • {side} {move}|Mat {count}|Avantage {side} • {score}|Graphique interactif de Stockfish. Glissez ou touchez pour examiner un coup.',
  'de':
      'Halbzug {count} • {side} {move}|Matt {count}|Vorteil {side} • {score}|Interaktiver Stockfish-Bewertungsgraph. Wischen oder tippen, um einen Zug zu untersuchen.',
  'it':
      'Semimossa {count} • {side} {move}|Matto {count}|Vantaggio {side} • {score}|Grafico interattivo di valutazione Stockfish. Scorri o tocca per esaminare una mossa.',
  'pt':
      'Meio-lance {count} • {side} {move}|Mate {count}|Vantagem de {side} • {score}|Gráfico interativo de avaliação Stockfish. Deslize ou toque para inspecionar um lance.',
  'ru':
      'Полуход {count} • {side} {move}|Мат {count}|Преимущество {side} • {score}|Интерактивный график оценки Stockfish. Проведите или нажмите, чтобы изучить ход.',
  'uk':
      'Півхід {count} • {side} {move}|Мат {count}|Перевага {side} • {score}|Інтерактивний графік оцінки Stockfish. Проведіть або торкніться, щоб переглянути хід.',
  'tr':
      'Yarım hamle {count} • {side} {move}|Mat {count}|{side} üstünlüğü • {score}|Etkileşimli Stockfish değerlendirme grafiği. Hamleyi incelemek için kaydırın veya dokunun.',
  'zh':
      '半回合 {count} • {side} {move}|将杀 {count}|{side}优势 • {score}|交互式 Stockfish 评估图。滑动或点击以查看走棋。',
  'ja':
      '半手 {count} • {side} {move}|メイト {count}|{side}優勢 • {score}|Stockfishの対話型評価グラフ。スワイプまたはタップして指し手を確認します。',
  'ko':
      '반수 {count} • {side} {move}|메이트 {count}|{side} 우세 • {score}|대화형 Stockfish 평가 그래프. 수를 살펴보려면 밀거나 탭하세요.',
  'id':
      'Setengah langkah {count} • {side} {move}|Mat {count}|Keunggulan {side} • {score}|Grafik evaluasi Stockfish interaktif. Geser atau ketuk untuk memeriksa langkah.',
  'ms':
      'Separuh langkah {count} • {side} {move}|Mat {count}|Kelebihan {side} • {score}|Graf penilaian Stockfish interaktif. Leret atau ketik untuk memeriksa langkah.',
  'th':
      'ครึ่งตา {count} • {side} {move}|รุกจน {count}|{side} ได้เปรียบ • {score}|กราฟประเมิน Stockfish แบบโต้ตอบ ปัดหรือแตะเพื่อตรวจสอบตาเดิน',
  'vi':
      'Nửa nước {count} • {side} {move}|Chiếu hết {count}|Lợi thế {side} • {score}|Biểu đồ đánh giá Stockfish tương tác. Vuốt hoặc chạm để xem nước đi.',
  'pl':
      'Półruch {count} • {side} {move}|Mat {count}|Przewaga {side} • {score}|Interaktywny wykres oceny Stockfish. Przesuń lub dotknij, aby sprawdzić ruch.',
  'nl':
      'Halfzet {count} • {side} {move}|Mat {count}|Voordeel {side} • {score}|Interactieve Stockfish-evaluatiegrafiek. Veeg of tik om een zet te bekijken.',
  'sv':
      'Halvdrag {count} • {side} {move}|Matt {count}|Fördel {side} • {score}|Interaktiv Stockfish-utvärderingsgraf. Svep eller tryck för att granska ett drag.',
  'el':
      'Ημικίνηση {count} • {side} {move}|Ματ {count}|Πλεονέκτημα {side} • {score}|Διαδραστικό γράφημα αξιολόγησης Stockfish. Σύρετε ή αγγίξτε για να εξετάσετε κίνηση.',
  'he':
      'חצי מסע {count} • {side} {move}|מט {count}|יתרון {side} • {score}|גרף הערכה אינטראקטיבי של Stockfish. החליקו או הקישו לבדיקת מסע.',
  'sw':
      'Hatua nusu {count} • {side} {move}|Mati {count}|Faida ya {side} • {score}|Grafu shirikishi ya tathmini ya Stockfish. Telezesha au gusa kukagua hatua.',
};

const _extras = <String, String>{
  'en':
      'Power move|Excellent|Tactical|{count} book plies • first deviation ply {ply}',
  'te':
      'శక్తివంతమైన ఎత్తు|అద్భుతం|వ్యూహాత్మకం|పుస్తకంలోని అర్ధ-ఎత్తులు {count} • మొదటి భిన్న అర్ధ-ఎత్తు {ply}',
  'hi':
      'शक्तिशाली चाल|उत्कृष्ट|सामरिक|पुस्तक की {count} अर्ध-चालें • पहला विचलन अर्ध-चाल {ply}',
  'ta':
      'வலுவான நகர்வு|அருமை|தந்திரம்|நூல் அரைநகர்வுகள் {count} • முதல் விலகல் அரைநகர்வு {ply}',
  'kn':
      'ಶಕ್ತಿಶಾಲಿ ನಡೆ|ಅದ್ಭುತ|ತಂತ್ರದ ನಡೆ|ಪುಸ್ತಕದ ಅರ್ಧನಡೆಗಳು {count} • ಮೊದಲ ಭಿನ್ನ ಅರ್ಧನಡೆ {ply}',
  'ml':
      'ശക്തമായ നീക്കം|ഉജ്ജ്വലം|തന്ത്രപരം|പുസ്തകത്തിലെ അർധനീക്കങ്ങൾ {count} • ആദ്യ വ്യതിയാന അർധനീക്കം {ply}',
  'mr':
      'शक्तिशाली चाल|उत्कृष्ट|डावपेचात्मक|पुस्तकातील {count} अर्धचाली • पहिला बदल अर्धचाल {ply}',
  'bn':
      'শক্তিশালী চাল|চমৎকার|কৌশলগত|বইয়ের {count} অর্ধচাল • প্রথম বিচ্যুতি অর্ধচাল {ply}',
  'gu':
      'શક્તિશાળી ચાલ|ઉત્તમ|વ્યૂહાત્મક|પુસ્તકની {count} અર્ધચાલો • પ્રથમ ભિન્ન અર્ધચાલ {ply}',
  'pa':
      'ਸ਼ਕਤੀਸ਼ਾਲੀ ਚਾਲ|ਸ਼ਾਨਦਾਰ|ਰਣਨੀਤਕ|ਕਿਤਾਬ ਦੀਆਂ {count} ਅੱਧੀਆਂ ਚਾਲਾਂ • ਪਹਿਲਾ ਬਦਲਾਅ ਅੱਧੀ ਚਾਲ {ply}',
  'ur':
      'طاقتور چال|عمدہ|تدبیری|کتابی نصف چالیں {count} • پہلی مختلف نصف چال {ply}',
  'ar':
      'نقلة قوية|ممتازة|تكتيكية|أنصاف النقلات النظرية {count} • أول انحراف عند نصف النقلة {ply}',
  'fa':
      'حرکت قدرتمند|عالی|تاکتیکی|نیم‌حرکت‌های کتابی {count} • اولین انحراف در نیم‌حرکت {ply}',
  'es':
      'Jugada potente|Excelente|Táctica|{count} medias jugadas teóricas • primera desviación en media jugada {ply}',
  'fr':
      'Coup puissant|Excellent|Tactique|{count} demi-coups théoriques • premier écart au demi-coup {ply}',
  'de':
      'Kraftvoller Zug|Ausgezeichnet|Taktisch|{count} Buchhalbzüge • erste Abweichung bei Halbzug {ply}',
  'it':
      'Mossa potente|Eccellente|Tattica|{count} semimosse teoriche • prima deviazione alla semimossa {ply}',
  'pt':
      'Lance forte|Excelente|Tático|{count} meios-lances teóricos • primeiro desvio no meio-lance {ply}',
  'ru':
      'Мощный ход|Отлично|Тактический|Теоретических полуходов: {count} • первое отклонение на полуходе {ply}',
  'uk':
      'Потужний хід|Відмінно|Тактичний|Теоретичних півходів: {count} • перше відхилення на півході {ply}',
  'tr':
      'Güçlü hamle|Mükemmel|Taktik|{count} kitap yarım hamlesi • ilk sapma yarım hamle {ply}',
  'zh': '强力着|优秀|战术着|定式半回合 {count} • 首次偏离在半回合 {ply}',
  'ja': '力強い手|優秀|戦術的|定跡の半手 {count} • 初めて外れた半手 {ply}',
  'ko': '강력한 수|우수|전술적|정석 반수 {count} • 첫 이탈 반수 {ply}',
  'id':
      'Langkah kuat|Luar biasa|Taktis|{count} setengah langkah teori • penyimpangan pertama pada setengah langkah {ply}',
  'ms':
      'Langkah kuat|Cemerlang|Taktikal|{count} separuh langkah teori • penyimpangan pertama pada separuh langkah {ply}',
  'th':
      'ตาเดินทรงพลัง|ยอดเยี่ยม|เชิงกลยุทธ์|ครึ่งตาตามตำรา {count} • เบี่ยงเบนครั้งแรกที่ครึ่งตา {ply}',
  'vi':
      'Nước mạnh|Xuất sắc|Chiến thuật|{count} nửa nước theo sách • lệch đầu tiên ở nửa nước {ply}',
  'pl':
      'Mocny ruch|Doskonały|Taktyczny|{count} półruchów książkowych • pierwsze odejście w półruchu {ply}',
  'nl':
      'Krachtige zet|Uitstekend|Tactisch|{count} boekhalfzetten • eerste afwijking bij halfzet {ply}',
  'sv':
      'Kraftfullt drag|Utmärkt|Taktiskt|{count} bokhalvdrag • första avvikelsen vid halvdrag {ply}',
  'el':
      'Ισχυρή κίνηση|Εξαιρετική|Τακτική|{count} θεωρητικές ημικινήσεις • πρώτη απόκλιση στην ημικίνηση {ply}',
  'he':
      'מסע עוצמתי|מצוין|טקטי|חצאי מסעים תאורטיים {count} • סטייה ראשונה בחצי מסע {ply}',
  'sw':
      'Hatua yenye nguvu|Bora sana|Ya mbinu|Hatua nusu za kitabu {count} • tofauti ya kwanza hatua nusu {ply}',
};

const _indianRows = <String, String>{
  'ta':
      '''கட்டாயப் பதில் தேவைப்படும் செக் ஒரு டெம்போவைப் பெறுகிறது. நகர்த்துமுன் ராஜாவின் ஒவ்வொரு சட்டப்பூர்வ பதிலையும் சரிபார்க்கவும்.|காஸ்லிங் ராஜாவின் பாதுகாப்பை மேம்படுத்தி கோட்டையை ஆட்டத்தில் இணைக்கிறது.|வெட்டுவது காய்களின் பலச் சமநிலையை மாற்றுகிறது. திரும்ப வெட்டுதல்களையும் இடைநகர்வுகளையும் மீண்டும் சரிபார்க்கவும்.|அமைதியான நகர்வு. கட்டாய செக்குகள், வெட்டுதல்கள், நேரடி அச்சுறுத்தல்களுடன் ஒப்பிடவும்.|இயந்திரத்தின் வலுவான தொடர்ச்சியைக் கண்டறிந்து நிலையின் கட்டுப்பாட்டைத் தக்கவைத்தீர்கள்.|இது எதிராளிக்கு பெரிய தந்திர வாய்ப்பை அளிக்கிறது.|இது தவிர்க்கக்கூடிய தெளிவான முன்னிலையை எதிராளிக்கு அளிக்கிறது.|நகர்வு விளையாடத்தக்கது, ஆனால் இன்னும் துல்லியமான தொடர்ச்சியைத் தவறவிடுகிறது.|{best} வலுவானது; எதிராளியின் உடனடி அச்சுறுத்தல் {threat}.|நம்பிக்கையான, துல்லியமான சதுரங்கம்|மேலும் மெருகேற்றக்கூடிய நல்ல யோசனைகள்|கற்றுக்கொள்ள உதவும் ஆட்டம்|பதிவுசெய்யப்பட்ட நகர்வுகள் இன்னும் இல்லை.|தொடக்கம், நடு ஆட்டம், இறுதி ஆட்ட முடிவுகளில் {count} அரைநகர்வுகள் மதிப்பாய்வு செய்யப்பட்டன.|மதிப்பாய்வு செய்த {total} நகர்வுகளில் {count} மிகச் சிறந்தவை அல்லது அருமையானவை.|{count} கட்டாய நகர்வுகளை அறிந்து தெளிவான சிக்கல்களை உருவாக்கினீர்கள்.|மையக் கட்டுப்பாடும் காய்களின் வளர்ச்சியும் உங்கள் வலுவான பழக்கம்.|நிலையை விளையாடத்தக்கதாக வைத்து ஆழமான கணக்கீட்டுக்கு அடித்தளம் அமைத்தீர்கள்.|திருப்புமுனை நகர்வைக் கண்டறிய முழு ஆட்டம் விளையாடவும்.|நகர்வு {count}|தொடக்கம் கிடைக்கவில்லை|வகைப்படுத்தாத தொடக்கம்|{best} வலுவானது.|சிசிலியன் தற்காப்பு|ரூய் லோபெஸ்|இத்தாலிய ஆட்டம்|பிரெஞ்சு தற்காப்பு|காரோ-கான் தற்காப்பு|கிங்ஸ் இந்தியன் தற்காப்பு|குயின்ஸ் காம்பிட்|நிம்சோ/இந்திய அமைப்பு|ராணிச் சிப்பாய் ஆட்டம்|ராஜாச் சிப்பாய் ஆட்டம்|ராஜாச் சிப்பாய் தொடக்கம்|ராணிச் சிப்பாய் தொடக்கம்|ஆங்கிலத் தொடக்கம்|ரெட்டி தொடக்கம்''',
  'kn':
      '''ಒತ್ತಾಯದ ಚೆಕ್ ಒಂದು ಟೆಂಪೋ ಗಳಿಸುತ್ತದೆ. ನಡೆಯುವ ಮೊದಲು ರಾಜನ ಪ್ರತಿಯೊಂದು ಕಾನೂನುಬದ್ಧ ಉತ್ತರವನ್ನು ಪರಿಶೀಲಿಸಿ.|ಕ್ಯಾಸ್ಲಿಂಗ್ ರಾಜನ ಸುರಕ್ಷತೆಯನ್ನು ಸುಧಾರಿಸಿ ಆನೆಯನ್ನು ಆಟಕ್ಕೆ ತರುತ್ತದೆ.|ಕಾಯಿಯನ್ನು ಹೊಡೆಯುವುದು ಬಲದ ಸಮತೋಲನವನ್ನು ಬದಲಾಯಿಸುತ್ತದೆ. ಮರುಹೊಡೆತಗಳು ಮತ್ತು ಮಧ್ಯದ ನಡೆಗಳನ್ನು ಮತ್ತೆ ಪರಿಶೀಲಿಸಿ.|ಒಂದು ಶಾಂತ ನಡೆ. ಒತ್ತಾಯದ ಚೆಕ್‌ಗಳು, ಹೊಡೆತಗಳು ಮತ್ತು ನೇರ ಬೆದರಿಕೆಗಳೊಂದಿಗೆ ಹೋಲಿಸಿ.|ಇಂಜಿನ್‌ನ ಅತ್ಯಂತ ಬಲವಾದ ಮುಂದುವರಿಕೆಯನ್ನು ಕಂಡು ಸ್ಥಿತಿಯ ನಿಯಂತ್ರಣ ಉಳಿಸಿಕೊಂಡಿರಿ.|ಇದು ಎದುರಾಳಿಗೆ ದೊಡ್ಡ ತಂತ್ರದ ಅವಕಾಶ ನೀಡುತ್ತದೆ.|ಇದು ತಪ್ಪಿಸಬಹುದಾದ ಸ್ಪಷ್ಟ ಮುನ್ನಡೆಯನ್ನು ಎದುರಾಳಿಗೆ ನೀಡುತ್ತದೆ.|ನಡೆಯು ಆಡಲು ಯೋಗ್ಯವಾಗಿದೆ, ಆದರೆ ಹೆಚ್ಚು ನಿಖರವಾದ ಮುಂದುವರಿಕೆಯನ್ನು ತಪ್ಪಿಸುತ್ತದೆ.|{best} ಹೆಚ್ಚು ಬಲವಾಗಿತ್ತು; ಎದುರಾಳಿಯ ತಕ್ಷಣದ ಬೆದರಿಕೆ {threat}.|ಆತ್ಮವಿಶ್ವಾಸದ, ನಿಖರ ಚದುರಂಗ|ಇನ್ನಷ್ಟು ಸುಧಾರಿಸಬಹುದಾದ ಉತ್ತಮ ಆಲೋಚನೆಗಳು|ಕಲಿಯಲು ಉಪಯುಕ್ತ ಆಟ|ಇನ್ನೂ ದಾಖಲಾದ ನಡೆಗಳು ಲಭ್ಯವಿಲ್ಲ.|ಆರಂಭ, ಮಧ್ಯ ಮತ್ತು ಅಂತಿಮ ಆಟದ ನಿರ್ಧಾರಗಳಲ್ಲಿ {count} ಅರ್ಧನಡೆಗಳನ್ನು ವಿಮರ್ಶಿಸಲಾಗಿದೆ.|ವಿಮರ್ಶಿಸಿದ {total} ನಡೆಗಳಲ್ಲಿ {count} ಅತ್ಯುತ್ತಮ ಅಥವಾ ಅದ್ಭುತವಾಗಿದ್ದವು.|ನೀವು {count} ಒತ್ತಾಯದ ನಡೆಗಳನ್ನು ಗುರುತಿಸಿ ಸ್ಪಷ್ಟ ಸಮಸ್ಯೆಗಳನ್ನು ಸೃಷ್ಟಿಸಿದಿರಿ.|ಕೇಂದ್ರ ನಿಯಂತ್ರಣ ಮತ್ತು ಕಾಯಿಗಳ ಅಭಿವೃದ್ಧಿ ನಿಮ್ಮ ಬಲವಾದ ಅಭ್ಯಾಸ.|ಸ್ಥಿತಿಯನ್ನು ಆಡಲು ಯೋಗ್ಯವಾಗಿಟ್ಟು ಆಳವಾದ ಲೆಕ್ಕಾಚಾರಕ್ಕೆ ಅಡಿಪಾಯ ಹಾಕಿದಿರಿ.|ತಿರುವು ನೀಡಿದ ನಡೆಯನ್ನು ತಿಳಿಯಲು ಪೂರ್ಣ ಆಟ ಆಡಿ.|ನಡೆ {count}|ಆರಂಭ ಲಭ್ಯವಿಲ್ಲ|ವರ್ಗೀಕರಿಸದ ಆರಂಭ|{best} ಹೆಚ್ಚು ಬಲವಾಗಿತ್ತು.|ಸಿಸಿಲಿಯನ್ ರಕ್ಷಣೆ|ರುಯ್ ಲೋಪೆಜ್|ಇಟಾಲಿಯನ್ ಆಟ|ಫ್ರೆಂಚ್ ರಕ್ಷಣೆ|ಕಾರೊ-ಕಾನ್ ರಕ್ಷಣೆ|ಕಿಂಗ್ಸ್ ಇಂಡಿಯನ್ ರಕ್ಷಣೆ|ಕ್ವೀನ್ಸ್ ಗ್ಯಾಂಬಿಟ್|ನಿಮ್ಜೊ/ಇಂಡಿಯನ್ ವ್ಯವಸ್ಥೆ|ರಾಣಿ ಸೈನಿಕನ ಆಟ|ರಾಜ ಸೈನಿಕನ ಆಟ|ರಾಜ ಸೈನಿಕನ ಆರಂಭ|ರಾಣಿ ಸೈನಿಕನ ಆರಂಭ|ಇಂಗ್ಲಿಷ್ ಆರಂಭ|ರೆಟಿ ಆರಂಭ''',
  'ml':
      '''നിർബന്ധിത മറുപടി വേണ്ട ചെക്ക് ഒരു ടെമ്പോ നേടുന്നു. നീക്കുന്നതിനു മുമ്പ് രാജാവിന്റെ ഓരോ നിയമപരമായ മറുപടിയും പരിശോധിക്കുക.|കാസ്ലിംഗ് രാജാവിന്റെ സുരക്ഷ മെച്ചപ്പെടുത്തി തേരിനെ കളിയിൽ സജീവമാക്കുന്നു.|വെട്ടുന്നത് കരുക്കളുടെ ശക്തിസന്തുലനം മാറ്റുന്നു. തിരിച്ചുവെട്ടലുകളും ഇടനീക്കങ്ങളും വീണ്ടും പരിശോധിക്കുക.|ശാന്തമായ നീക്കം. നിർബന്ധിത ചെക്കുകൾ, വെട്ടലുകൾ, നേരിട്ടുള്ള ഭീഷണികൾ എന്നിവയുമായി താരതമ്യം ചെയ്യുക.|എൻജിന്റെ ഏറ്റവും ശക്തമായ തുടർച്ച കണ്ടെത്തി സ്ഥിതിയുടെ നിയന്ത്രണം നിലനിർത്തി.|ഇത് എതിരാളിക്ക് വലിയ തന്ത്രപരമായ അവസരം നൽകുന്നു.|ഇത് ഒഴിവാക്കാവുന്ന വ്യക്തമായ മേൽക്കൈ എതിരാളിക്ക് നൽകുന്നു.|നീക്കം കളിക്കാവുന്നതാണ്, എന്നാൽ കൂടുതൽ കൃത്യമായ തുടർച്ച നഷ്ടപ്പെടുന്നു.|{best} കൂടുതൽ ശക്തമായിരുന്നു; എതിരാളിയുടെ ഉടനെയുള്ള ഭീഷണി {threat} ആണ്.|ആത്മവിശ്വാസമുള്ള, കൃത്യമായ ചെസ്|കൂടുതൽ മെച്ചപ്പെടുത്താവുന്ന നല്ല ആശയങ്ങൾ|പഠിക്കാൻ ഉപകാരമുള്ള കളി|രേഖപ്പെടുത്തിയ നീക്കങ്ങൾ ഇനിയും ലഭ്യമല്ല.|തുടക്കം, മധ്യഘട്ടം, അവസാനഘട്ടം എന്നിവയിലെ തീരുമാനങ്ങളിൽ {count} അർധനീക്കങ്ങൾ അവലോകനം ചെയ്തു.|അവലോകനം ചെയ്ത {total} നീക്കങ്ങളിൽ {count} ഏറ്റവും മികച്ചതോ ഉജ്ജ്വലമോ ആയിരുന്നു.|നിങ്ങൾ {count} നിർബന്ധിത നീക്കങ്ങൾ തിരിച്ചറിഞ്ഞ് വ്യക്തമായ പ്രശ്നങ്ങൾ സൃഷ്ടിച്ചു.|കേന്ദ്ര നിയന്ത്രണവും കരുക്കളുടെ വികസനവുമായിരുന്നു നിങ്ങളുടെ മികച്ച ശീലം.|സ്ഥിതി കളിക്കാവുന്നതായി നിലനിർത്തി ആഴത്തിലുള്ള കണക്കുകൂട്ടലിന് അടിത്തറയിട്ടു.|വഴിത്തിരിവായ നീക്കം കണ്ടെത്താൻ ഒരു പൂർണ്ണ കളി കളിക്കുക.|നീക്കം {count}|ഓപ്പണിംഗ് ലഭ്യമല്ല|വർഗ്ഗീകരിക്കാത്ത ഓപ്പണിംഗ്|{best} കൂടുതൽ ശക്തമായിരുന്നു.|സിസിലിയൻ പ്രതിരോധം|റൂയ് ലോപെസ്|ഇറ്റാലിയൻ കളി|ഫ്രഞ്ച് പ്രതിരോധം|കാരോ-കാൻ പ്രതിരോധം|കിങ്സ് ഇന്ത്യൻ പ്രതിരോധം|ക്വീൻസ് ഗാംബിറ്റ്|നിംസോ/ഇന്ത്യൻ വിന്യാസം|റാണിയുടെ കാലാൾ കളി|രാജാവിന്റെ കാലാൾ കളി|രാജാവിന്റെ കാലാൾ ഓപ്പണിംഗ്|റാണിയുടെ കാലാൾ ഓപ്പണിംഗ്|ഇംഗ്ലീഷ് ഓപ്പണിംഗ്|റെറ്റി ഓപ്പണിംഗ്''',
  'mr':
      '''सक्तीच्या शहाने टेम्पो मिळतो. चाल करण्याआधी राजाचे प्रत्येक वैध उत्तर तपासा.|कॅसलिंग राजाची सुरक्षितता वाढवते आणि हत्तीला खेळात आणते.|मोहरा मारल्याने बळाचे संतुलन बदलते. पुन्हा मारण्याच्या आणि मधल्या चाली तपासा.|एक शांत चाल. सक्तीचे शह, मोहरे मारणे आणि थेट धमक्यांशी तुलना करा.|तुम्ही इंजिनचा सर्वात मजबूत क्रम शोधून स्थितीवर नियंत्रण ठेवले.|यामुळे प्रतिस्पर्ध्याला मोठी डावपेचाची संधी मिळते.|यामुळे टाळता येणारी स्पष्ट आघाडी प्रतिस्पर्ध्याला मिळते.|चाल खेळण्यायोग्य आहे, पण अधिक अचूक क्रम सुटला.|{best} अधिक मजबूत होती; प्रतिस्पर्ध्याची तातडीची धमकी {threat} आहे.|आत्मविश्वासपूर्ण, अचूक बुद्धिबळ|आणखी सुधारता येतील अशा चांगल्या कल्पना|शिकण्यासाठी उपयुक्त खेळ|अद्याप नोंदवलेल्या चाली उपलब्ध नाहीत.|सुरुवात, मध्य आणि अंतिम खेळाच्या निर्णयांतील {count} अर्धचाली तपासल्या.|तपासलेल्या {total} चालींपैकी {count} सर्वोत्तम किंवा उत्कृष्ट होत्या.|तुम्ही {count} सक्तीच्या चाली ओळखून ठोस समस्या निर्माण केल्या.|केंद्रावरील नियंत्रण आणि मोहऱ्यांचा विकास ही तुमची सर्वोत्तम सवय होती.|स्थिती खेळण्यायोग्य ठेवून सखोल गणनेसाठी पाया घातला.|निर्णायक वळण देणारी चाल शोधण्यासाठी पूर्ण खेळ खेळा.|चाल {count}|सुरुवात उपलब्ध नाही|अवर्गीकृत सुरुवात|{best} अधिक मजबूत होती.|सिसिलियन बचाव|रुय लोपेझ|इटालियन खेळ|फ्रेंच बचाव|कारो-कान बचाव|किंग्स इंडियन बचाव|क्वीन्स गॅम्बिट|निम्झो/इंडियन मांडणी|राणीच्या प्याद्याचा खेळ|राजाच्या प्याद्याचा खेळ|राजाच्या प्याद्याची सुरुवात|राणीच्या प्याद्याची सुरुवात|इंग्लिश सुरुवात|रेटी सुरुवात''',
  'bn':
      '''বাধ্যতামূলক জবাব চাওয়া চেক একটি টেম্পো লাভ করে। চাল দেওয়ার আগে রাজার প্রতিটি বৈধ জবাব যাচাই করুন।|ক্যাসলিং রাজার নিরাপত্তা বাড়ায় এবং নৌকাকে খেলায় আনে।|ঘুঁটি ধরলে শক্তির ভারসাম্য বদলে যায়। পাল্টা ধরা ও মধ্যবর্তী চাল আবার যাচাই করুন।|একটি শান্ত চাল। বাধ্যতামূলক চেক, ঘুঁটি ধরা ও সরাসরি হুমকির সঙ্গে তুলনা করুন।|আপনি ইঞ্জিনের সবচেয়ে শক্তিশালী ধারাবাহিকতা খুঁজে অবস্থানের নিয়ন্ত্রণ ধরে রেখেছেন।|এতে প্রতিপক্ষ বড় কৌশলগত সুযোগ পায়।|এতে প্রতিপক্ষকে এড়ানো সম্ভব এমন স্পষ্ট সুবিধা দেওয়া হয়।|চালটি খেলার যোগ্য, কিন্তু আরও নির্ভুল ধারাবাহিকতা বাদ পড়েছে।|{best} বেশি শক্তিশালী ছিল; প্রতিপক্ষের তাৎক্ষণিক হুমকি {threat}।|আত্মবিশ্বাসী, নির্ভুল দাবা|ভালো ধারণা, আরও শান দেওয়ার সুযোগ|শেখার জন্য উপকারী খেলা|এখনও কোনো নথিভুক্ত চাল নেই।|শুরু, মধ্য ও শেষ খেলার সিদ্ধান্তে {count} অর্ধচাল পর্যালোচনা করা হয়েছে।|পর্যালোচিত {total} চালের মধ্যে {count} সেরা বা অসাধারণ ছিল।|আপনি {count} বাধ্যতামূলক চাল চিনে সুনির্দিষ্ট সমস্যা তৈরি করেছেন।|কেন্দ্র নিয়ন্ত্রণ ও ঘুঁটির বিকাশ ছিল আপনার সেরা অভ্যাস।|অবস্থান খেলার যোগ্য রেখে গভীর গণনার ভিত্তি তৈরি করেছেন।|কোন চালে মোড় ঘুরেছে জানতে একটি সম্পূর্ণ খেলা খেলুন।|চাল {count}|ওপেনিং উপলব্ধ নয়|অশ্রেণিবদ্ধ ওপেনিং|{best} বেশি শক্তিশালী ছিল।|সিসিলিয়ান প্রতিরক্ষা|রুই লোপেজ|ইতালীয় খেলা|ফরাসি প্রতিরক্ষা|কারো-কান প্রতিরক্ষা|কিংস ইন্ডিয়ান প্রতিরক্ষা|কুইন্স গ্যাম্বিট|নিমজো/ইন্ডিয়ান বিন্যাস|রানির বোড়ের খেলা|রাজার বোড়ের খেলা|রাজার বোড়ের ওপেনিং|রানির বোড়ের ওপেনিং|ইংলিশ ওপেনিং|রেটি ওপেনিং''',
  'gu':
      '''ફરજિયાત જવાબ માંગતી શાહથી ટેમ્પો મળે છે. ચાલતાં પહેલાં રાજાના દરેક કાયદેસર જવાબને તપાસો.|કેસલિંગ રાજાની સુરક્ષા સુધારે છે અને હાથીને રમતમાં લાવે છે.|મોહરું મારવાથી બળનું સંતુલન બદલાય છે. સામે મારવાની અને વચ્ચેની ચાલો ફરી તપાસો.|એક શાંત ચાલ. તેની સરખામણી ફરજિયાત શાહ, મારવાની ચાલો અને સીધી ધમકીઓ સાથે કરો.|તમે એન્જિનનો સૌથી મજબૂત ક્રમ શોધી સ્થિતિ પર નિયંત્રણ જાળવ્યું.|આનાથી વિરોધીને મોટી વ્યૂહાત્મક તક મળે છે.|આનાથી વિરોધીને ટાળી શકાય તેવી સ્પષ્ટ સરસાઈ મળે છે.|ચાલ રમવાલાયક છે, પરંતુ વધુ સચોટ ક્રમ ચૂકી જાય છે.|{best} વધુ મજબૂત હતી; વિરોધીની તાત્કાલિક ધમકી {threat} છે.|આત્મવિશ્વાસપૂર્ણ, સચોટ ચેસ|વધુ સુધારી શકાય તેવા સારા વિચારો|શીખવા માટે ઉપયોગી રમત|હજુ નોંધાયેલી ચાલો ઉપલબ્ધ નથી.|શરૂઆત, મધ્ય અને અંતિમ રમતના નિર્ણયોમાં {count} અર્ધચાલોની સમીક્ષા થઈ.|સમીક્ષા કરેલી {total} ચાલોમાંથી {count} શ્રેષ્ઠ કે ઉત્તમ હતી.|તમે {count} ફરજિયાત ચાલો ઓળખી ચોક્કસ સમસ્યાઓ ઊભી કરી.|કેન્દ્ર નિયંત્રણ અને મોહરાંનો વિકાસ તમારી શ્રેષ્ઠ ટેવ હતી.|સ્થિતિ રમવાલાયક રાખી ઊંડી ગણતરી માટે પાયો બનાવ્યો.|વળાંક લાવનાર ચાલ જાણવા સંપૂર્ણ રમત રમો.|ચાલ {count}|ઓપનિંગ ઉપલબ્ધ નથી|અવર્ગીકૃત ઓપનિંગ|{best} વધુ મજબૂત હતી.|સિસિલિયન સંરક્ષણ|રુય લોપેઝ|ઇટાલિયન રમત|ફ્રેન્ચ સંરક્ષણ|કારો-કાન સંરક્ષણ|કિંગ્સ ઇન્ડિયન સંરક્ષણ|ક્વીન્સ ગેમ્બિટ|નિમ્ઝો/ઇન્ડિયન ગોઠવણી|રાણીના પ્યાદાની રમત|રાજાના પ્યાદાની રમત|રાજાના પ્યાદાનું ઓપનિંગ|રાણીના પ્યાદાનું ઓપનિંગ|ઇંગ્લિશ ઓપનિંગ|રેટી ઓપનિંગ''',
  'pa':
      '''ਮਜਬੂਰ ਕਰਨ ਵਾਲੀ ਸ਼ਹ ਨਾਲ ਟੈਂਪੋ ਮਿਲਦਾ ਹੈ। ਚਾਲ ਤੋਂ ਪਹਿਲਾਂ ਰਾਜੇ ਦੇ ਹਰ ਕਾਨੂੰਨੀ ਜਵਾਬ ਨੂੰ ਜਾਂਚੋ।|ਕੈਸਲਿੰਗ ਰਾਜੇ ਦੀ ਸੁਰੱਖਿਆ ਸੁਧਾਰਦੀ ਹੈ ਅਤੇ ਹਾਥੀ ਨੂੰ ਖੇਡ ਵਿੱਚ ਲਿਆਉਂਦੀ ਹੈ।|ਮੋਹਰਾ ਮਾਰਨ ਨਾਲ ਤਾਕਤ ਦਾ ਸੰਤੁਲਨ ਬਦਲਦਾ ਹੈ। ਵਾਪਸ ਮਾਰਨ ਅਤੇ ਵਿਚਕਾਰਲੀਆਂ ਚਾਲਾਂ ਨੂੰ ਫਿਰ ਜਾਂਚੋ।|ਇੱਕ ਸ਼ਾਂਤ ਚਾਲ। ਇਸ ਦੀ ਤੁਲਨਾ ਮਜਬੂਰ ਸ਼ਹਾਂ, ਮਾਰਨ ਵਾਲੀਆਂ ਚਾਲਾਂ ਅਤੇ ਸਿੱਧੇ ਖਤਰਿਆਂ ਨਾਲ ਕਰੋ।|ਤੁਸੀਂ ਇੰਜਣ ਦਾ ਸਭ ਤੋਂ ਮਜ਼ਬੂਤ ਕ੍ਰਮ ਲੱਭ ਕੇ ਸਥਿਤੀ ਉੱਤੇ ਕਾਬੂ ਰੱਖਿਆ।|ਇਸ ਨਾਲ ਵਿਰੋਧੀ ਨੂੰ ਵੱਡਾ ਰਣਨੀਤਕ ਮੌਕਾ ਮਿਲਦਾ ਹੈ।|ਇਸ ਨਾਲ ਵਿਰੋਧੀ ਨੂੰ ਸਪਸ਼ਟ ਬੜ੍ਹਤ ਮਿਲਦੀ ਹੈ ਜਿਸ ਤੋਂ ਬਚਿਆ ਜਾ ਸਕਦਾ ਸੀ।|ਚਾਲ ਖੇਡਣਯੋਗ ਹੈ, ਪਰ ਹੋਰ ਸਹੀ ਕ੍ਰਮ ਖੁੰਝ ਗਿਆ।|{best} ਵਧੇਰੇ ਮਜ਼ਬੂਤ ਸੀ; ਵਿਰੋਧੀ ਦਾ ਤੁਰੰਤ ਖਤਰਾ {threat} ਹੈ।|ਭਰੋਸੇਮੰਦ, ਸਹੀ ਸ਼ਤਰੰਜ|ਹੋਰ ਨਿਖਾਰਨਯੋਗ ਚੰਗੇ ਵਿਚਾਰ|ਸਿੱਖਣ ਲਈ ਲਾਭਦਾਇਕ ਖੇਡ|ਹਾਲੇ ਕੋਈ ਦਰਜ ਚਾਲ ਉਪਲਬਧ ਨਹੀਂ।|ਸ਼ੁਰੂਆਤ, ਮੱਧ ਅਤੇ ਅੰਤਲੀ ਖੇਡ ਦੇ ਫੈਸਲਿਆਂ ਵਿੱਚ {count} ਅੱਧੀਆਂ ਚਾਲਾਂ ਦੀ ਸਮੀਖਿਆ ਹੋਈ।|ਸਮੀਖਿਆ ਕੀਤੀਆਂ {total} ਚਾਲਾਂ ਵਿੱਚੋਂ {count} ਸਭ ਤੋਂ ਵਧੀਆ ਜਾਂ ਸ਼ਾਨਦਾਰ ਸਨ।|ਤੁਸੀਂ {count} ਮਜਬੂਰ ਕਰਨ ਵਾਲੀਆਂ ਚਾਲਾਂ ਪਛਾਣ ਕੇ ਠੋਸ ਮੁਸ਼ਕਲਾਂ ਪੈਦਾ ਕੀਤੀਆਂ।|ਕੇਂਦਰ ਉੱਤੇ ਕਾਬੂ ਅਤੇ ਮੋਹਰਿਆਂ ਦਾ ਵਿਕਾਸ ਤੁਹਾਡੀ ਸਭ ਤੋਂ ਮਜ਼ਬੂਤ ਆਦਤ ਸੀ।|ਤੁਸੀਂ ਸਥਿਤੀ ਖੇਡਣਯੋਗ ਰੱਖ ਕੇ ਡੂੰਘੀ ਗਿਣਤੀ ਦੀ ਨੀਂਹ ਰੱਖੀ।|ਮੋੜ ਲਿਆਉਣ ਵਾਲੀ ਚਾਲ ਜਾਣਨ ਲਈ ਪੂਰੀ ਖੇਡ ਖੇਡੋ।|ਚਾਲ {count}|ਓਪਨਿੰਗ ਉਪਲਬਧ ਨਹੀਂ|ਬਿਨਾਂ ਸ਼੍ਰੇਣੀ ਵਾਲੀ ਓਪਨਿੰਗ|{best} ਵਧੇਰੇ ਮਜ਼ਬੂਤ ਸੀ।|ਸਿਸਿਲੀਅਨ ਰੱਖਿਆ|ਰੂਈ ਲੋਪੇਜ਼|ਇਤਾਲਵੀ ਖੇਡ|ਫਰਾਂਸੀਸੀ ਰੱਖਿਆ|ਕਾਰੋ-ਕਾਨ ਰੱਖਿਆ|ਕਿੰਗਜ਼ ਇੰਡੀਅਨ ਰੱਖਿਆ|ਕਵੀਨਜ਼ ਗੈਂਬਿਟ|ਨਿਮਜ਼ੋ/ਇੰਡੀਅਨ ਬਣਤਰ|ਰਾਣੀ ਦੇ ਪਿਆਦੇ ਦੀ ਖੇਡ|ਰਾਜੇ ਦੇ ਪਿਆਦੇ ਦੀ ਖੇਡ|ਰਾਜੇ ਦੇ ਪਿਆਦੇ ਦੀ ਓਪਨਿੰਗ|ਰਾਣੀ ਦੇ ਪਿਆਦੇ ਦੀ ਓਪਨਿੰਗ|ਇੰਗਲਿਸ਼ ਓਪਨਿੰਗ|ਰੇਟੀ ਓਪਨਿੰਗ''',
  'ur':
      '''مجبور کرنے والی شہ سے ٹیمپو ملتا ہے۔ چال سے پہلے بادشاہ کے ہر قانونی جواب کو جانچیں۔|کیسلنگ بادشاہ کی حفاظت بہتر کرتی ہے اور رخ کو کھیل میں لاتی ہے۔|مہرہ مارنے سے قوت کا توازن بدلتا ہے۔ جوابی مار اور درمیانی چالیں دوبارہ جانچیں۔|ایک خاموش چال۔ اس کا موازنہ مجبور کرنے والی شہ، مارنے کی چالوں اور براہ راست خطرات سے کریں۔|آپ نے انجن کا مضبوط ترین تسلسل تلاش کر کے پوزیشن پر قابو رکھا۔|اس سے حریف کو بڑا تدبیری موقع ملتا ہے۔|اس سے حریف کو واضح برتری ملتی ہے جس سے بچا جا سکتا تھا۔|چال کھیلنے کے قابل ہے، مگر زیادہ درست تسلسل چھوٹ گیا۔|{best} زیادہ مضبوط تھی؛ حریف کا فوری خطرہ {threat} ہے۔|پراعتماد، درست شطرنج|اچھے خیالات، مزید نکھار کی گنجائش|سیکھنے کے لیے مفید کھیل|ابھی ریکارڈ شدہ چالیں دستیاب نہیں۔|آغاز، درمیانی اور آخری کھیل کے فیصلوں میں {count} نصف چالوں کا جائزہ لیا گیا۔|جائزہ لی گئی {total} چالوں میں سے {count} بہترین یا شاندار تھیں۔|آپ نے {count} مجبور کرنے والی چالیں پہچان کر ٹھوس مسائل پیدا کیے۔|مرکز پر قابو اور مہروں کی ترقی آپ کی مضبوط ترین عادت تھی۔|آپ نے پوزیشن کھیلنے کے قابل رکھ کر گہری گنتی کی بنیاد رکھی۔|فیصلہ کن موڑ والی چال جاننے کے لیے مکمل کھیل کھیلیں۔|چال {count}|آغاز دستیاب نہیں|غیر درجہ بند آغاز|{best} زیادہ مضبوط تھی۔|سسلی دفاع|روئی لوپیز|اطالوی کھیل|فرانسیسی دفاع|کارو کان دفاع|کنگز انڈین دفاع|کوئینز گیمبٹ|نمزو/انڈین ترتیب|وزیر کے پیادے کا کھیل|بادشاہ کے پیادے کا کھیل|بادشاہ کے پیادے کا آغاز|وزیر کے پیادے کا آغاز|انگریزی آغاز|ریٹی آغاز''',
};

const _asianRows = <String, String>{
  'zh':
      '''强制性将军可以赢得一个先手。落子前检查对方王的每一种合法应对。|王车易位提高王的安全性，并让车参与战斗。|吃子会改变子力平衡。重新检查回吃和中间着。|这是一步安静着。将它与强制性将军、吃子及直接威胁比较。|你找到了引擎最强的后续变化，并保持了对局面的控制。|这给了对手重大的战术机会。|这让出了本可避免的明显优势。|这步棋可下，但错过了更精确的后续变化。|{best} 更强；对手的直接威胁是 {threat}。|自信而精确的棋局|想法不错，仍可打磨|值得学习的一局棋|尚无已记录的走棋。|已复盘开局、中局及残局决策中的 {count} 个半回合。|复盘的 {total} 步棋中，有 {count} 步为最佳或极佳。|你识别出 {count} 步强制着，给对手制造了具体难题。|你最好的习惯是控制中心并发展棋子。|你保持了可下的局面，并为更深入的计算奠定了基础。|完成一盘棋，即可查看具体的转折着。|第 {count} 步|开局不可用|未分类开局|{best} 更强。|西西里防御|西班牙开局|意大利开局|法兰西防御|卡罗康防御|古印度防御|后翼弃兵|尼姆佐／印度式布局|后兵开局|王兵对局|王兵开局|后兵开局|英国式开局|列蒂开局''',
  'ja':
      '''強制力のあるチェックはテンポを稼ぎます。指す前に、キングの合法な応手をすべて確認しましょう。|キャスリングはキングの安全性を高め、ルークを戦いに参加させます。|駒を取ると戦力の均衡が変わります。取り返す手や中間手を再確認しましょう。|静かな手です。強制力のあるチェック、駒取り、直接的な脅威と比べましょう。|エンジンの最強の継続手順を見つけ、局面の主導権を保ちました。|相手に大きな戦術的チャンスを与えます。|避けられたはずの明確な優位を相手に与えます。|指せる手ですが、より正確な継続手順を逃しています。|{best} のほうが強い手でした。相手の直近の脅威は {threat} です。|自信に満ちた正確なチェス|良い構想、さらに磨ける余地|学びの多い対局|記録された指し手はまだありません。|序盤、中盤、終盤の判断について {count} 半手を検討しました。|検討した {total} 手中、{count} 手が最善または素晴らしい手でした。|強制力のある手を {count} 手見つけ、具体的な難題を作りました。|中心の支配と駒の展開が最も良い習慣でした。|戦える局面を維持し、より深い読みの土台を築きました。|対局を最後まで指すと、転機となった手を確認できます。|指し手 {count}|定跡情報なし|未分類の序盤|{best} のほうが強い手でした。|シシリアン・ディフェンス|ルイ・ロペス|イタリアン・ゲーム|フレンチ・ディフェンス|カロ・カン・ディフェンス|キングズ・インディアン・ディフェンス|クイーンズ・ギャンビット|ニムゾ／インディアン型|クイーンズ・ポーン・ゲーム|キングズ・ポーン・ゲーム|キングズ・ポーン・オープニング|クイーンズ・ポーン・オープニング|イングリッシュ・オープニング|レティ・オープニング''',
  'ko':
      '''강제적인 체크는 템포를 얻습니다. 두기 전에 킹의 모든 합법적인 응수를 확인하세요.|캐슬링은 킹의 안전을 높이고 룩을 경기에 참여시킵니다.|기물을 잡으면 전력 균형이 바뀝니다. 되잡기와 중간 수를 다시 확인하세요.|조용한 수입니다. 강제적인 체크, 기물 잡기, 직접적인 위협과 비교하세요.|엔진의 가장 강한 후속 수순을 찾고 포지션의 주도권을 유지했습니다.|상대에게 큰 전술적 기회를 줍니다.|피할 수 있었던 명확한 우세를 상대에게 내줍니다.|둘 만한 수지만 더 정확한 후속 수순을 놓쳤습니다.|{best}이 더 강했습니다. 상대의 즉각적인 위협은 {threat}입니다.|자신감 있고 정확한 체스|더 다듬을 여지가 있는 좋은 구상|배울 점이 있는 경기|아직 기록된 수가 없습니다.|오프닝, 미들게임, 엔드게임의 판단에서 {count}개의 반수를 검토했습니다.|검토한 {total}수 중 {count}수가 최선 또는 훌륭한 수였습니다.|강제적인 수 {count}개를 알아보고 구체적인 문제를 만들었습니다.|중앙 통제와 기물 전개가 가장 좋은 습관이었습니다.|둘 만한 포지션을 유지하고 더 깊은 계산의 토대를 마련했습니다.|경기를 끝까지 두면 전환점이 된 수를 확인할 수 있습니다.|수 {count}|오프닝 정보 없음|미분류 오프닝|{best}이 더 강했습니다.|시실리안 디펜스|루이 로페즈|이탈리안 게임|프렌치 디펜스|카로칸 디펜스|킹스 인디언 디펜스|퀸스 갬빗|님조/인디언 배치|퀸스 폰 게임|킹스 폰 게임|킹스 폰 오프닝|퀸스 폰 오프닝|잉글리시 오프닝|레티 오프닝''',
  'id':
      '''Skak yang memaksa memperoleh tempo. Periksa setiap balasan raja yang sah sebelum melangkah.|Rokade meningkatkan keselamatan raja dan mengaktifkan benteng.|Penangkapan mengubah keseimbangan materi. Periksa lagi penangkapan balik dan langkah sela.|Langkah tenang. Bandingkan dengan skak memaksa, penangkapan, dan ancaman langsung.|Anda menemukan kelanjutan terkuat mesin dan mempertahankan kendali posisi.|Ini memberi lawan peluang taktis besar.|Ini memberikan keunggulan jelas kepada lawan yang sebenarnya bisa dihindari.|Langkah ini bisa dimainkan, tetapi melewatkan kelanjutan yang lebih akurat.|{best} lebih kuat; ancaman langsung lawan adalah {threat}.|Catur percaya diri dan akurat|Ide bagus yang masih bisa diasah|Partai yang berguna untuk belajar|Belum ada langkah tercatat yang tersedia.|{count} setengah langkah ditinjau pada keputusan pembukaan, tengah permainan, dan akhir permainan.|Dari {total} langkah yang ditinjau, {count} terbaik atau sangat bagus.|Anda mengenali {count} langkah memaksa dan menciptakan masalah nyata.|Kebiasaan terbaik Anda adalah mengendalikan pusat dan mengembangkan buah.|Anda mempertahankan posisi yang layak dimainkan dan membangun dasar perhitungan lebih dalam.|Mainkan partai lengkap untuk mengetahui langkah titik baliknya.|Langkah {count}|Pembukaan tidak tersedia|Pembukaan belum diklasifikasi|{best} lebih kuat.|Pertahanan Sisilia|Ruy Lopez|Permainan Italia|Pertahanan Prancis|Pertahanan Caro-Kann|Pertahanan India Raja|Gambit Menteri|Susunan Nimzo/India|Permainan Bidak Menteri|Permainan Bidak Raja|Pembukaan Bidak Raja|Pembukaan Bidak Menteri|Pembukaan Inggris|Pembukaan Réti''',
  'ms':
      '''Syah yang memaksa memperoleh tempo. Semak setiap balasan raja yang sah sebelum bergerak.|Rokade meningkatkan keselamatan raja dan mengaktifkan tir.|Tangkapan mengubah keseimbangan buah. Semak semula tangkapan balas dan langkah perantaraan.|Langkah tenang. Bandingkan dengan syah memaksa, tangkapan dan ancaman langsung.|Anda menemui sambungan terkuat enjin dan mengekalkan kawalan kedudukan.|Ini memberi lawan peluang taktikal yang besar.|Ini memberikan kelebihan jelas kepada lawan yang boleh dielakkan.|Langkah ini boleh dimainkan, tetapi terlepas sambungan yang lebih tepat.|{best} lebih kuat; ancaman segera lawan ialah {threat}.|Catur yakin dan tepat|Idea baik yang boleh dipertajam|Permainan yang berguna untuk belajar|Belum ada langkah direkodkan.|{count} separuh langkah disemak dalam keputusan pembukaan, pertengahan dan akhir permainan.|Daripada {total} langkah yang disemak, {count} terbaik atau sangat baik.|Anda mengenal pasti {count} langkah memaksa dan mewujudkan masalah nyata.|Tabiat terkuat anda ialah kawalan pusat dan pembangunan buah.|Anda mengekalkan kedudukan yang boleh dimainkan dan membina asas pengiraan lebih mendalam.|Mainkan satu permainan penuh untuk mengenal pasti langkah titik perubahan.|Langkah {count}|Pembukaan tidak tersedia|Pembukaan belum dikelaskan|{best} lebih kuat.|Pertahanan Sicily|Ruy Lopez|Permainan Itali|Pertahanan Perancis|Pertahanan Caro-Kann|Pertahanan India Raja|Gambit Menteri|Susunan Nimzo/India|Permainan Bidak Menteri|Permainan Bidak Raja|Pembukaan Bidak Raja|Pembukaan Bidak Menteri|Pembukaan Inggeris|Pembukaan Réti''',
  'th':
      '''การรุกที่บังคับให้ตอบโต้ช่วยได้จังหวะเดิน ตรวจสอบคำตอบที่ถูกกติกาของคิงทุกทางก่อนตัดสินใจ|การเข้าป้อมเพิ่มความปลอดภัยของคิงและนำเรือเข้าสู่เกม|การกินเปลี่ยนสมดุลกำลังหมาก ตรวจสอบการกินคืนและตาแทรกอีกครั้ง|เป็นตาเดินเงียบ เปรียบเทียบกับการรุกบังคับ การกิน และภัยคุกคามโดยตรง|คุณพบแนวเดินต่อที่แข็งแกร่งที่สุดของเอนจินและรักษาการควบคุมตำแหน่งไว้|ตานี้ให้โอกาสทางกลยุทธ์ครั้งใหญ่แก่คู่แข่ง|ตานี้ยอมให้คู่แข่งได้เปรียบอย่างชัดเจนซึ่งหลีกเลี่ยงได้|ตานี้ยังเล่นได้ แต่พลาดแนวเดินต่อที่แม่นยำกว่า|{best} แข็งแกร่งกว่า ภัยคุกคามทันทีของคู่แข่งคือ {threat}|หมากรุกที่มั่นใจและแม่นยำ|แนวคิดดีที่ยังพัฒนาได้|เกมที่มีประโยชน์ต่อการเรียนรู้|ยังไม่มีตาเดินที่บันทึกไว้|ทบทวน {count} ครึ่งตาในการตัดสินใจช่วงเปิดเกม กลางเกม และท้ายเกม|จาก {total} ตาที่ทบทวน มี {count} ตาที่ดีที่สุดหรือยอดเยี่ยม|คุณพบตาบังคับ {count} ตาและสร้างปัญหาที่เป็นรูปธรรม|นิสัยที่ดีที่สุดคือการควบคุมศูนย์กลางและพัฒนาหมาก|คุณรักษาตำแหน่งให้เล่นต่อได้และวางพื้นฐานสำหรับการคำนวณที่ลึกขึ้น|เล่นให้จบหนึ่งเกมเพื่อดูตาที่เป็นจุดเปลี่ยน|ตาที่ {count}|ไม่มีข้อมูลการเปิดเกม|การเปิดเกมที่ยังไม่จัดประเภท|{best} แข็งแกร่งกว่า|ซิซิเลียนดีเฟนส์|รุย โลเปซ|อิตาเลียนเกม|เฟรนช์ดีเฟนส์|คาโร-คานน์ดีเฟนส์|คิงส์อินเดียนดีเฟนส์|ควีนส์แกมบิต|รูปแบบนิมโซ/อินเดียน|เกมเบี้ยควีน|เกมเบี้ยคิง|การเปิดเกมเบี้ยคิง|การเปิดเกมเบี้ยควีน|อิงลิชโอเพนนิง|เรติโอเพนนิง''',
  'vi':
      '''Nước chiếu bắt buộc đáp trả giành một nhịp. Kiểm tra mọi cách đáp trả hợp lệ của vua trước khi quyết định.|Nhập thành giúp vua an toàn hơn và đưa xe vào cuộc.|Bắt quân làm thay đổi cân bằng lực lượng. Kiểm tra lại các nước bắt lại và nước xen giữa.|Một nước đi yên tĩnh. So sánh với các nước chiếu bắt buộc, bắt quân và đe dọa trực tiếp.|Bạn tìm được diễn biến mạnh nhất của máy và giữ quyền kiểm soát thế cờ.|Nước này trao cho đối thủ cơ hội chiến thuật lớn.|Nước này nhường lợi thế rõ ràng vốn có thể tránh được.|Nước này chơi được nhưng bỏ lỡ diễn biến chính xác hơn.|{best} mạnh hơn; đe dọa tức thời của đối thủ là {threat}.|Cờ vua tự tin, chính xác|Ý tưởng tốt còn có thể trau dồi|Một ván cờ đáng học hỏi|Chưa có nước đi nào được ghi lại.|Đã xem lại {count} nửa nước đi qua các quyết định ở khai cuộc, trung cuộc và tàn cuộc.|Trong {total} nước đã xem lại, {count} nước là tốt nhất hoặc rất hay.|Bạn nhận ra {count} nước đi bắt buộc đáp trả và tạo ra khó khăn cụ thể.|Thói quen tốt nhất là kiểm soát trung tâm và phát triển quân.|Bạn giữ thế cờ chơi được và tạo nền tảng tính toán sâu hơn.|Chơi trọn một ván để xác định nước đi bước ngoặt.|Nước {count}|Không có thông tin khai cuộc|Khai cuộc chưa phân loại|{best} mạnh hơn.|Phòng thủ Sicilia|Ruy Lopez|Ván cờ Ý|Phòng thủ Pháp|Phòng thủ Caro-Kann|Phòng thủ Ấn Độ vua|Gambit hậu|Thế trận Nimzo/Ấn Độ|Ván tốt hậu|Ván tốt vua|Khai cuộc tốt vua|Khai cuộc tốt hậu|Khai cuộc Anh|Khai cuộc Réti''',
};

const _otherRows = <String, String>{
  'ru':
      '''Форсирующий шах выигрывает темп. Перед ходом проверьте каждый допустимый ответ короля.|Рокировка повышает безопасность короля и вводит ладью в игру.|Взятие меняет материальное равновесие. Перепроверьте ответные взятия и промежуточные ходы.|Тихий ход. Сравните его с форсирующими шахами, взятиями и прямыми угрозами.|Вы нашли сильнейшее продолжение движка и сохранили контроль над позицией.|Это даёт сопернику большую тактическую возможность.|Это уступает явное преимущество, которого можно было избежать.|Ход допустим, но упускает более точное продолжение.|{best} было сильнее; непосредственная угроза соперника — {threat}.|Уверенная, точная игра|Хорошие идеи, которые можно отточить|Полезная для обучения партия|Записанных ходов пока нет.|Разобрано полуходов: {count}, с решениями в дебюте, миттельшпиле и эндшпиле.|Из {total} разобранных ходов {count} были лучшими или отличными.|Вы распознали форсирующие ходы ({count}) и создали конкретные трудности.|Вашей сильнейшей привычкой были контроль центра и развитие фигур.|Вы сохранили играбельную позицию и заложили основу для более глубокого расчёта.|Сыграйте полную партию, чтобы определить переломный ход.|Ход {count}|Дебют недоступен|Неклассифицированный дебют|{best} было сильнее.|Сицилианская защита|Испанская партия|Итальянская партия|Французская защита|Защита Каро-Канн|Староиндийская защита|Ферзевый гамбит|Нимцо/индийское построение|Игра ферзевых пешек|Игра королевских пешек|Дебют королевской пешки|Дебют ферзевой пешки|Английское начало|Дебют Рети''',
  'uk':
      '''Форсований шах виграє темп. Перед ходом перевірте кожну дозволену відповідь короля.|Рокіровка підвищує безпеку короля та вводить туру в гру.|Взяття змінює матеріальну рівновагу. Ще раз перевірте взяття у відповідь і проміжні ходи.|Тихий хід. Порівняйте його з форсованими шахами, взяттями та прямими загрозами.|Ви знайшли найсильніше продовження рушія та зберегли контроль над позицією.|Це дає супернику велику тактичну можливість.|Це віддає явну перевагу, якої можна було уникнути.|Хід прийнятний, але втрачає точніше продовження.|{best} було сильніше; безпосередня загроза суперника — {threat}.|Упевнена, точна гра|Хороші ідеї, які можна вдосконалити|Корисна для навчання партія|Записаних ходів поки немає.|Розібрано півходів: {count}, з рішеннями в дебюті, мітельшпілі та ендшпілі.|Із {total} розібраних ходів {count} були найкращими або чудовими.|Ви розпізнали форсовані ходи ({count}) і створили конкретні труднощі.|Вашою найсильнішою звичкою були контроль центру та розвиток фігур.|Ви зберегли придатну для гри позицію й заклали основу для глибшого розрахунку.|Зіграйте повну партію, щоб визначити переломний хід.|Хід {count}|Дебют недоступний|Некласифікований дебют|{best} було сильніше.|Сицилійський захист|Іспанська партія|Італійська партія|Французький захист|Захист Каро-Канн|Староіндійський захист|Ферзевий гамбіт|Німцо/індійська побудова|Гра ферзевих пішаків|Гра королівських пішаків|Дебют королівського пішака|Дебют ферзевого пішака|Англійський початок|Дебют Реті''',
  'tr':
      '''Zorlayıcı şah bir tempo kazandırır. Hamleden önce şahın her yasal yanıtını kontrol edin.|Rok, şah güvenliğini artırır ve kaleyi oyuna katar.|Taş almak maddi dengeyi değiştirir. Geri alışları ve ara hamleleri tekrar kontrol edin.|Sakin bir hamle. Zorlayıcı şahlar, alışlar ve doğrudan tehditlerle karşılaştırın.|Motorun en güçlü devam yolunu bulup konumun kontrolünü korudunuz.|Bu, rakibe büyük bir taktik fırsat verir.|Bu, önlenebilecek açık bir üstünlüğü rakibe verir.|Hamle oynanabilir, ancak daha doğru bir devam yolunu kaçırır.|{best} daha güçlüydü; rakibin hemen oluşturduğu tehdit {threat}.|Kendinden emin, doğru satranç|Geliştirilebilecek iyi fikirler|Öğretici bir oyun|Henüz kaydedilmiş hamle yok.|Açılış, oyun ortası ve oyun sonu kararlarında {count} yarım hamle incelendi.|İncelenen {total} hamlenin {count} tanesi en iyi veya harikaydı.|{count} zorlayıcı hamleyi fark ederek somut sorunlar oluşturdunuz.|En güçlü alışkanlığınız merkez kontrolü ve taş gelişimiydi.|Konumu oynanabilir tutup daha derin hesaplamaya temel oluşturdunuz.|Dönüm noktası olan hamleyi görmek için tam bir oyun oynayın.|Hamle {count}|Açılış mevcut değil|Sınıflandırılmamış açılış|{best} daha güçlüydü.|Sicilya Savunması|İspanyol Açılışı|İtalyan Oyunu|Fransız Savunması|Caro-Kann Savunması|Şah Hint Savunması|Vezir Gambiti|Nimzo/Hint düzeni|Vezir Piyonu Oyunu|Şah Piyonu Oyunu|Şah Piyonu Açılışı|Vezir Piyonu Açılışı|İngiliz Açılışı|Réti Açılışı''',
  'ar':
      '''الكش الإجباري يكسب نقلة زمنية. تحقّق من كل رد قانوني للملك قبل تنفيذ النقلة.|التبييت يحسّن أمان الملك ويُدخل الرخ إلى اللعب.|الأخذ يغيّر توازن القوة المادية. أعد فحص الأخذ المضاد والنقلات البينية.|نقلة هادئة. قارنها بالكشات الإجبارية والأخذ والتهديدات المباشرة.|وجدت أقوى تكملة للمحرك وحافظت على السيطرة على الوضع.|هذا يمنح الخصم فرصة تكتيكية كبيرة.|هذا يمنح الخصم أفضلية واضحة كان يمكن تجنبها.|النقلة قابلة للعب، لكنها تفوّت تكملة أدق.|كانت {best} أقوى؛ تهديد الخصم الفوري هو {threat}.|شطرنج واثق ودقيق|أفكار جيدة قابلة للصقل|مباراة مفيدة للتعلم|لا توجد نقلات مسجلة بعد.|تمت مراجعة {count} نصف نقلة عبر قرارات الافتتاح ووسط اللعب والنهاية.|من أصل {total} نقلة تمت مراجعتها، كانت {count} الأفضل أو ممتازة.|تعرّفت على {count} نقلة إجبارية وخلقت مشكلات ملموسة.|كانت أقوى عاداتك السيطرة على المركز وتطوير القطع.|حافظت على وضع قابل للعب وأسست لحساب أعمق.|العب مباراة كاملة لتحديد النقلة التي غيّرت مجرى اللعب.|النقلة {count}|الافتتاح غير متاح|افتتاح غير مصنف|كانت {best} أقوى.|الدفاع الصقلي|روي لوبيز|اللعب الإيطالي|الدفاع الفرنسي|دفاع كارو كان|دفاع الملك الهندي|غامبيت الوزير|تشكيل نيمزو/هندي|لعب بيدق الوزير|لعب بيدق الملك|افتتاح بيدق الملك|افتتاح بيدق الوزير|الافتتاح الإنجليزي|افتتاح ريتي''',
  'fa':
      '''کیش اجباری یک تمپو به دست می‌آورد. پیش از حرکت، تمام پاسخ‌های قانونی شاه را بررسی کنید.|قلعه‌رفتن امنیت شاه را بهتر کرده و رخ را وارد بازی می‌کند.|گرفتن مهره تعادل مادی را تغییر می‌دهد. پس‌گرفتن‌ها و حرکت‌های میانی را دوباره بررسی کنید.|حرکتی آرام است. آن را با کیش‌های اجباری، گرفتن‌ها و تهدیدهای مستقیم مقایسه کنید.|قوی‌ترین ادامهٔ موتور را یافتید و کنترل وضعیت را حفظ کردید.|این به حریف فرصت تاکتیکی بزرگی می‌دهد.|این برتری آشکاری به حریف می‌دهد که می‌شد از آن جلوگیری کرد.|حرکت قابل بازی است، اما ادامهٔ دقیق‌تری را از دست می‌دهد.|{best} قوی‌تر بود؛ تهدید فوری حریف {threat} است.|شطرنج مطمئن و دقیق|ایده‌های خوب با جای بهبود|بازی مفید برای یادگیری|هنوز حرکت ثبت‌شده‌ای در دسترس نیست.|{count} نیم‌حرکت در تصمیم‌های شروع، وسط و آخر بازی بررسی شد.|از {total} حرکت بررسی‌شده، {count} بهترین یا عالی بودند.|{count} حرکت اجباری را شناختید و مشکلات مشخصی ایجاد کردید.|قوی‌ترین عادت شما کنترل مرکز و گسترش مهره‌ها بود.|وضعیت را قابل بازی نگه داشتید و پایه‌ای برای محاسبهٔ عمیق‌تر ساختید.|یک بازی کامل انجام دهید تا حرکت نقطهٔ عطف مشخص شود.|حرکت {count}|شروع بازی در دسترس نیست|شروع بازی طبقه‌بندی‌نشده|{best} قوی‌تر بود.|دفاع سیسیلی|روی لوپز|بازی ایتالیایی|دفاع فرانسوی|دفاع کاروکان|دفاع هندی شاه|گامبی وزیر|آرایش نیمزو/هندی|بازی پیادهٔ وزیر|بازی پیادهٔ شاه|شروع پیادهٔ شاه|شروع پیادهٔ وزیر|شروع انگلیسی|شروع رتی''',
  'pl':
      '''Wymuszający szach zyskuje tempo. Przed ruchem sprawdź każdą legalną odpowiedź króla.|Roszada poprawia bezpieczeństwo króla i wprowadza wieżę do gry.|Bicie zmienia równowagę materialną. Ponownie sprawdź odbicia i ruchy pośrednie.|Spokojny ruch. Porównaj go z wymuszającymi szachami, biciami i bezpośrednimi groźbami.|Znalazłeś najsilniejszą kontynuację silnika i utrzymałeś kontrolę nad pozycją.|To daje przeciwnikowi dużą szansę taktyczną.|To oddaje wyraźną przewagę, której można było uniknąć.|Ruch nadaje się do gry, ale pomija dokładniejszą kontynuację.|{best} było silniejsze; bezpośrednia groźba przeciwnika to {threat}.|Pewne, dokładne szachy|Dobre pomysły do dopracowania|Pouczająca partia|Nie ma jeszcze zapisanych ruchów.|Przeanalizowano {count} półruchów z decyzjami w debiucie, grze środkowej i końcówce.|Spośród {total} przeanalizowanych ruchów {count} było najlepszych lub świetnych.|Rozpoznałeś ruchy wymuszające ({count}) i stworzyłeś konkretne problemy.|Twoim najlepszym nawykiem była kontrola centrum i rozwój figur.|Utrzymałeś grywalną pozycję i stworzyłeś podstawy do głębszego liczenia.|Rozegraj pełną partię, aby poznać przełomowy ruch.|Ruch {count}|Debiut niedostępny|Niesklasyfikowany debiut|{best} było silniejsze.|Obrona sycylijska|Partia hiszpańska|Partia włoska|Obrona francuska|Obrona Caro-Kann|Obrona królewsko-indyjska|Gambit hetmański|Ustawienie nimzo/indyjskie|Gra pionem hetmańskim|Gra pionem królewskim|Otwarcie pionem królewskim|Otwarcie pionem hetmańskim|Partia angielska|Debiut Rétiego''',
  'nl':
      '''Een dwingend schaak wint een tempo. Controleer vóór de zet elk legaal antwoord van de koning.|Rokeren verbetert de koningsveiligheid en brengt een toren in het spel.|Slaan verandert de materiaalbalans. Controleer terugslaan en tussenzetten opnieuw.|Een rustige zet. Vergelijk die met dwingende schaakzetten, slagzetten en directe dreigingen.|Je vond de sterkste voortzetting van de engine en behield controle over de stelling.|Dit geeft de tegenstander een grote tactische kans.|Dit geeft een duidelijk voordeel weg dat voorkomen kon worden.|De zet is speelbaar, maar mist een nauwkeurigere voortzetting.|{best} was sterker; de directe dreiging van de tegenstander is {threat}.|Zelfverzekerd, nauwkeurig schaken|Goede ideeën die nog scherper kunnen|Een leerzame partij|Er zijn nog geen opgeslagen zetten.|{count} halfzetten beoordeeld bij beslissingen in opening, middenspel en eindspel.|Van {total} beoordeelde zetten waren er {count} de beste of uitstekend.|Je herkende {count} dwingende zetten en creëerde concrete problemen.|Je sterkste gewoonte was centrumcontrole en stukontwikkeling.|Je hield de stelling speelbaar en legde een basis voor diepere berekening.|Speel een volledige partij om de kantelzet te zien.|Zet {count}|Opening niet beschikbaar|Niet-geclassificeerde opening|{best} was sterker.|Siciliaanse verdediging|Spaanse partij|Italiaanse partij|Franse verdediging|Caro-Kann-verdediging|Konings-Indische verdediging|Damegambiet|Nimzo/Indische opstelling|Damepionspel|Koningspionspel|Koningspionopening|Damepionopening|Engelse opening|Réti-opening''',
  'sv':
      '''En tvingande schack vinner ett tempo. Kontrollera varje lagligt kungssvar innan du bestämmer dig.|Rockad förbättrar kungens säkerhet och för in ett torn i spelet.|Ett slag ändrar materialbalansen. Kontrollera återslag och mellandrag igen.|Ett lugnt drag. Jämför med tvingande schackar, slag och direkta hot.|Du hittade motorns starkaste fortsättning och behöll kontrollen över ställningen.|Detta ger motståndaren en stor taktisk möjlighet.|Detta ger bort en tydlig fördel som kunde ha undvikits.|Draget är spelbart men missar en mer exakt fortsättning.|{best} var starkare; motståndarens omedelbara hot är {threat}.|Säkert, exakt schack|Bra idéer som kan vässas|Ett lärorikt parti|Det finns inga registrerade drag ännu.|{count} halvdrag granskade i beslut under öppning, mittspel och slutspel.|Av {total} granskade drag var {count} bäst eller utmärkta.|Du såg {count} tvingande drag och skapade konkreta problem.|Din starkaste vana var centrumkontroll och pjäsutveckling.|Du höll ställningen spelbar och lade grunden för djupare beräkning.|Spela ett helt parti för att se vilket drag som blev vändpunkten.|Drag {count}|Öppning saknas|Oklassificerad öppning|{best} var starkare.|Sicilianskt försvar|Spanskt parti|Italienskt parti|Franskt försvar|Caro-Kann-försvar|Kungsindiskt försvar|Damgambit|Nimzo/indisk uppställning|Dambondespel|Kungsbondespel|Kungsbondeöppning|Dambondeöppning|Engelsk öppning|Rétis öppning''',
  'el':
      '''Ένα εξαναγκαστικό σαχ κερδίζει τέμπο. Ελέγξτε κάθε νόμιμη απάντηση του βασιλιά πριν δεσμευτείτε.|Το ροκέ βελτιώνει την ασφάλεια του βασιλιά και βάζει έναν πύργο στο παιχνίδι.|Μια αιχμαλωσία αλλάζει την ισορροπία υλικού. Ελέγξτε ξανά τις ανακτήσεις και τις ενδιάμεσες κινήσεις.|Μια ήσυχη κίνηση. Συγκρίνετέ την με εξαναγκαστικά σαχ, αιχμαλωσίες και άμεσες απειλές.|Βρήκατε την ισχυρότερη συνέχεια της μηχανής και διατηρήσατε τον έλεγχο της θέσης.|Αυτό δίνει στον αντίπαλο μεγάλη τακτική ευκαιρία.|Αυτό παραχωρεί σαφές πλεονέκτημα που μπορούσε να αποφευχθεί.|Η κίνηση παίζεται, αλλά χάνει μια ακριβέστερη συνέχεια.|Το {best} ήταν ισχυρότερο· η άμεση απειλή του αντιπάλου είναι {threat}.|Σίγουρο, ακριβές σκάκι|Καλές ιδέες με περιθώριο βελτίωσης|Μια διδακτική παρτίδα|Δεν υπάρχουν ακόμη καταγεγραμμένες κινήσεις.|Εξετάστηκαν {count} ημικινήσεις σε αποφάσεις ανοίγματος, μέσου παιχνιδιού και φινάλε.|Από {total} κινήσεις που εξετάστηκαν, {count} ήταν οι καλύτερες ή εξαιρετικές.|Αναγνωρίσατε {count} εξαναγκαστικές κινήσεις και δημιουργήσατε συγκεκριμένα προβλήματα.|Η ισχυρότερη συνήθειά σας ήταν ο έλεγχος του κέντρου και η ανάπτυξη κομματιών.|Κρατήσατε τη θέση παικτή και βάλατε βάση για βαθύτερο υπολογισμό.|Παίξτε μια πλήρη παρτίδα για να εντοπιστεί η κρίσιμη κίνηση.|Κίνηση {count}|Το άνοιγμα δεν είναι διαθέσιμο|Μη ταξινομημένο άνοιγμα|Το {best} ήταν ισχυρότερο.|Σικελική άμυνα|Ισπανική παρτίδα|Ιταλική παρτίδα|Γαλλική άμυνα|Άμυνα Κάρο-Καν|Ινδική άμυνα του βασιλιά|Γκαμπί της βασίλισσας|Διάταξη Νίμτσο/Ινδική|Παιχνίδι πιονιού βασίλισσας|Παιχνίδι πιονιού βασιλιά|Άνοιγμα πιονιού βασιλιά|Άνοιγμα πιονιού βασίλισσας|Αγγλικό άνοιγμα|Άνοιγμα Ρέτι''',
  'he':
      '''שח כופה מרוויח טמפו. בדקו כל תגובה חוקית של המלך לפני ביצוע המסע.|הצרחה משפרת את בטיחות המלך ומכניסה צריח למשחק.|הכאה משנה את מאזן החומר. בדקו שוב הכאות חוזרות ומסעי ביניים.|מסע שקט. השוו אותו לשחים כופים, להכאות ולאיומים ישירים.|מצאתם את ההמשך החזק ביותר של המנוע ושמרתם על השליטה בעמדה.|המסע מעניק ליריב הזדמנות טקטית גדולה.|המסע מוותר על יתרון ברור שהיה אפשר למנוע.|המסע אפשרי למשחק, אך מחמיץ המשך מדויק יותר.|{best} היה חזק יותר; האיום המיידי של היריב הוא {threat}.|שחמט בטוח ומדויק|רעיונות טובים שאפשר לחדד|משחק מועיל ללמידה|עדיין אין מסעים מוקלטים.|נותחו {count} חצאי מסעים בהחלטות בפתיחה, במציעה ובסיום.|מתוך {total} מסעים שנותחו, {count} היו הטובים ביותר או מצוינים.|זיהיתם {count} מסעים כופים ויצרתם בעיות ממשיות.|ההרגל החזק ביותר שלכם היה שליטה במרכז ופיתוח כלים.|שמרתם על עמדה שניתן לשחק והנחתם בסיס לחישוב עמוק יותר.|שחקו משחק מלא כדי לזהות את המסע שהיה נקודת המפנה.|מסע {count}|הפתיחה אינה זמינה|פתיחה לא מסווגת|{best} היה חזק יותר.|הגנה סיציליאנית|פתיחה ספרדית|משחק איטלקי|הגנה צרפתית|הגנת קארו-קאן|הגנה הודית של המלך|גמביט המלכה|מבנה נימצו/הודי|משחק רגלי המלכה|משחק רגלי המלך|פתיחת רגלי המלך|פתיחת רגלי המלכה|פתיחה אנגלית|פתיחת רטי''',
  'sw':
      '''Shaha inayolazimisha jibu hupata tempo. Hakiki kila jibu halali la mfalme kabla ya kucheza.|Kubadilishana nafasi kwa mfalme na ngome huongeza usalama wa mfalme na kuleta ngome mchezoni.|Kukamata hubadilisha uwiano wa nguvu za kete. Kagua tena kukamata kwa kujibu na hatua za kati.|Hatua tulivu. Ilinganishe na shaha za kulazimisha, kukamata na vitisho vya moja kwa moja.|Umepata mwendelezo wenye nguvu zaidi wa injini na kudumisha udhibiti wa nafasi.|Hii inampa mpinzani nafasi kubwa ya mbinu.|Hii inatoa faida iliyo wazi ambayo ingeweza kuepukwa.|Hatua inaweza kuchezwa, lakini inakosa mwendelezo sahihi zaidi.|{best} ilikuwa na nguvu zaidi; tishio la haraka la mpinzani ni {threat}.|Chesi yenye kujiamini na usahihi|Mawazo mazuri yanayoweza kuboreshwa|Mchezo wenye manufaa ya kujifunza|Bado hakuna hatua zilizorekodiwa.|Hatua nusu {count} zimechambuliwa katika maamuzi ya ufunguzi, kati na mwisho wa mchezo.|Kati ya hatua {total} zilizochambuliwa, {count} zilikuwa bora zaidi au nzuri sana.|Umetambua hatua {count} za kulazimisha na kuunda matatizo halisi.|Tabia yako bora ilikuwa kudhibiti katikati na kuendeleza kete.|Umedumisha nafasi inayochezeka na kuweka msingi wa hesabu ya kina zaidi.|Cheza mchezo kamili ili kutambua hatua iliyogeuza mchezo.|Hatua {count}|Ufunguzi haupatikani|Ufunguzi usioainishwa|{best} ilikuwa na nguvu zaidi.|Ulinzi wa Sisilia|Ruy Lopez|Mchezo wa Italia|Ulinzi wa Ufaransa|Ulinzi wa Caro-Kann|Ulinzi wa Kihindi wa Mfalme|Gambiti ya Malkia|Mpangilio wa Nimzo/Kihindi|Mchezo wa Askari wa Malkia|Mchezo wa Askari wa Mfalme|Ufunguzi wa Askari wa Mfalme|Ufunguzi wa Askari wa Malkia|Ufunguzi wa Kiingereza|Ufunguzi wa Réti''',
};

const _rows = <String, String>{
  ..._indianRows,
  ..._asianRows,
  ..._otherRows,
  'en':
      '''A forcing check gains tempo. Verify every legal king reply before committing.|Castling improves king safety and connects a rook to the game.|A capture changes the material balance. Recheck recaptures and zwischenzugs.|A quiet move. Compare it with forcing checks, captures, and direct threats.|You found the engine's strongest continuation and kept control of the position.|This gives the opponent a major tactical opportunity.|This concedes a clear advantage that can be avoided.|The move is playable, but it misses a more accurate continuation.|{best} was stronger; the immediate opponent threat is {threat}.|Confident, accurate chess|Good ideas with room to sharpen|A useful game to learn from|No recorded moves are available yet.|{count} half-moves reviewed across opening, middlegame, and endgame decisions.|{count} of {total} reviewed moves were Best or Great.|You recognised {count} forcing moves and created concrete problems.|Your strongest habit was central control and piece development.|You kept the position playable and created a base for deeper calculation.|Play a complete game to unlock a move-level turning point.|Move {count}|Opening not available|Unclassified opening|{best} was stronger.|Sicilian Defence|Ruy Lopez|Italian Game|French Defence|Caro-Kann Defence|King's Indian Defence|Queen's Gambit|Nimzo/Indian setup|Queen's Pawn Game|King's Pawn Game|King's Pawn Opening|Queen's Pawn Opening|English Opening|Réti Opening''',
  'te':
      '''బలవంతపు చెక్ టెంపోను సాధిస్తుంది. ఆడే ముందు రాజు వేయగల ప్రతి చట్టబద్ధమైన సమాధానాన్ని తనిఖీ చేయండి.|క్యాస్లింగ్ రాజు భద్రతను మెరుగుపరిచి ఏనుగును ఆటలోకి తెస్తుంది.|కొట్టడం వల్ల బలగాల సమతుల్యత మారుతుంది. తిరిగి కొట్టే ఎత్తులను, మధ్యలో వచ్చే ఎత్తులను మళ్లీ తనిఖీ చేయండి.|ఇది నిశ్శబ్ద ఎత్తు. బలవంతపు చెక్‌లు, కొట్టే ఎత్తులు, ప్రత్యక్ష బెదిరింపులతో పోల్చండి.|ఇంజిన్ సూచించిన అత్యుత్తమ కొనసాగింపును కనుగొని స్థితిపై నియంత్రణను నిలుపుకున్నారు.|ఇది ప్రత్యర్థికి పెద్ద వ్యూహాత్మక అవకాశాన్ని ఇస్తుంది.|ఇది నివారించగల స్పష్టమైన ఆధిక్యాన్ని ప్రత్యర్థికి ఇస్తుంది.|ఈ ఎత్తు ఆడదగినదే, కానీ మరింత ఖచ్చితమైన కొనసాగింపును కోల్పోయింది.|{best} మరింత బలమైన ఎత్తు; ప్రత్యర్థి తక్షణ బెదిరింపు {threat}.|ఆత్మవిశ్వాసంతో ఖచ్చితమైన చెస్|మంచి ఆలోచనలు, మరింత మెరుగుపరచవచ్చు|నేర్చుకోవడానికి ఉపయోగకరమైన ఆట|ఇంకా నమోదు చేసిన ఎత్తులు అందుబాటులో లేవు.|ప్రారంభం, మధ్యగేమ్, ఎండ్‌గేమ్ నిర్ణయాలలో {count} అర్ధ-ఎత్తులను సమీక్షించాం.|సమీక్షించిన {total} ఎత్తులలో {count} ఉత్తమమైనవి లేదా చాలా మంచివి.|మీరు {count} బలవంతపు ఎత్తులను గుర్తించి స్పష్టమైన సమస్యలను సృష్టించారు.|కేంద్ర నియంత్రణ, పావుల అభివృద్ధి మీ అత్యుత్తమ అలవాట్లు.|స్థితిని ఆడదగినదిగా ఉంచి లోతైన లెక్కింపుకు పునాది వేశారు.|ఏ ఎత్తు ఆటను మలుపు తిప్పిందో తెలుసుకోవడానికి పూర్తి ఆట ఆడండి.|ఎత్తు {count}|ఓపెనింగ్ అందుబాటులో లేదు|వర్గీకరించని ఓపెనింగ్|{best} మరింత బలమైన ఎత్తు.|సిసిలియన్ రక్షణ|రూయ్ లోపెజ్|ఇటాలియన్ ఆట|ఫ్రెంచ్ రక్షణ|కారో-కాన్ రక్షణ|కింగ్స్ ఇండియన్ రక్షణ|క్వీన్స్ గాంబిట్|నిమ్జో/ఇండియన్ అమరిక|రాజమంత్రి పావు ఆట|రాజు పావు ఆట|రాజు పావు ఓపెనింగ్|రాజమంత్రి పావు ఓపెనింగ్|ఇంగ్లీష్ ఓపెనింగ్|రేటీ ఓపెనింగ్''',
  'hi':
      '''बाध्यकारी शह से टेम्पो मिलता है। चाल चलने से पहले राजा के हर वैध जवाब को जाँचें।|कैसलिंग राजा को सुरक्षित करती है और हाथी को खेल में सक्रिय करती है।|मारने से मोहरों के बल का संतुलन बदलता है। दोबारा मारने और बीच की चालों को फिर जाँचें।|एक शांत चाल। इसकी तुलना बाध्यकारी शह, मारने वाली चालों और सीधे खतरों से करें।|आपने इंजन का सबसे मजबूत क्रम खोजा और स्थिति पर नियंत्रण बनाए रखा।|इससे प्रतिद्वंद्वी को बड़ा सामरिक अवसर मिलता है।|इससे प्रतिद्वंद्वी को स्पष्ट बढ़त मिलती है जिसे टाला जा सकता था।|चाल खेलने योग्य है, लेकिन अधिक सटीक क्रम छूट गया।|{best} अधिक मजबूत था; प्रतिद्वंद्वी का तत्काल खतरा {threat} है।|आत्मविश्वासपूर्ण, सटीक शतरंज|अच्छे विचार, और निखार की गुंजाइश|सीखने के लिए उपयोगी खेल|अभी कोई दर्ज चाल उपलब्ध नहीं है।|ओपनिंग, मध्य खेल और अंतिम खेल के निर्णयों में {count} अर्ध-चालों की समीक्षा की गई।|समीक्षित {total} चालों में से {count} सर्वश्रेष्ठ या बेहतरीन थीं।|आपने {count} बाध्यकारी चालें पहचानीं और ठोस समस्याएँ पैदा कीं।|केंद्र नियंत्रण और मोहरों का विकास आपकी सबसे मजबूत आदत थी।|आपने स्थिति को खेलने योग्य रखा और गहरी गणना की नींव बनाई।|किस चाल पर खेल बदला, जानने के लिए पूरा खेल खेलें।|चाल {count}|ओपनिंग उपलब्ध नहीं|अवर्गीकृत ओपनिंग|{best} अधिक मजबूत था।|सिसिलियन रक्षा|रुय लोपेज़|इटालियन खेल|फ्रेंच रक्षा|कारो-कान रक्षा|किंग्स इंडियन रक्षा|क्वीन्स गैम्बिट|निम्ज़ो/इंडियन व्यवस्था|रानी के प्यादे का खेल|राजा के प्यादे का खेल|राजा के प्यादे की ओपनिंग|रानी के प्यादे की ओपनिंग|इंग्लिश ओपनिंग|रेटी ओपनिंग''',
  'es':
      '''Un jaque forzado gana un tiempo. Comprueba cada respuesta legal del rey antes de decidir.|El enroque mejora la seguridad del rey e incorpora una torre al juego.|Una captura cambia el equilibrio material. Revisa las recapturas y las jugadas intermedias.|Una jugada tranquila. Compárala con jaques forzados, capturas y amenazas directas.|Encontraste la continuación más fuerte del motor y mantuviste el control de la posición.|Esto da al rival una gran oportunidad táctica.|Esto concede una ventaja clara que se podía evitar.|La jugada es viable, pero pasa por alto una continuación más precisa.|{best} era más fuerte; la amenaza inmediata del rival es {threat}.|Ajedrez seguro y preciso|Buenas ideas con margen de mejora|Una partida útil para aprender|Todavía no hay jugadas registradas.|Se revisaron {count} medias jugadas en decisiones de apertura, medio juego y final.|De {total} jugadas revisadas, {count} fueron las mejores o excelentes.|Reconociste {count} jugadas forzadas y creaste problemas concretos.|Tu mejor hábito fue controlar el centro y desarrollar las piezas.|Mantuviste una posición viable y sentaste las bases para un cálculo más profundo.|Juega una partida completa para identificar la jugada decisiva.|Jugada {count}|Apertura no disponible|Apertura sin clasificar|{best} era más fuerte.|Defensa siciliana|Ruy López|Partida italiana|Defensa francesa|Defensa Caro-Kann|Defensa india de rey|Gambito de dama|Esquema Nimzo/indio|Partida de peón de dama|Partida de peón de rey|Apertura de peón de rey|Apertura de peón de dama|Apertura inglesa|Apertura Réti''',
  'fr':
      '''Un échec contraignant gagne un tempo. Vérifiez chaque réponse légale du roi avant de vous engager.|Le roque améliore la sécurité du roi et met une tour en jeu.|Une prise change l'équilibre matériel. Revérifiez les reprises et les coups intermédiaires.|Un coup calme. Comparez-le aux échecs contraignants, aux prises et aux menaces directes.|Vous avez trouvé la suite la plus forte du moteur et gardé le contrôle de la position.|Cela offre à l'adversaire une occasion tactique majeure.|Cela concède un avantage net qui pouvait être évité.|Le coup est jouable, mais manque une suite plus précise.|{best} était plus fort ; la menace immédiate adverse est {threat}.|Un jeu sûr et précis|De bonnes idées à affiner|Une partie instructive|Aucun coup enregistré n'est encore disponible.|{count} demi-coups analysés dans les décisions d'ouverture, de milieu de partie et de finale.|Sur {total} coups analysés, {count} étaient les meilleurs ou excellents.|Vous avez reconnu {count} coups contraignants et posé des problèmes concrets.|Votre meilleure habitude était le contrôle du centre et le développement des pièces.|Vous avez gardé une position jouable et posé les bases d'un calcul plus profond.|Jouez une partie complète pour identifier le coup charnière.|Coup {count}|Ouverture indisponible|Ouverture non classée|{best} était plus fort.|Défense sicilienne|Espagnole|Partie italienne|Défense française|Défense Caro-Kann|Défense est-indienne|Gambit dame|Structure nimzo/indienne|Partie du pion dame|Partie du pion roi|Ouverture du pion roi|Ouverture du pion dame|Ouverture anglaise|Ouverture Réti''',
  'de':
      '''Ein zwingendes Schach gewinnt ein Tempo. Prüfe vor dem Zug jede legale Antwort des Königs.|Die Rochade verbessert die Königssicherheit und bringt einen Turm ins Spiel.|Ein Schlagzug verändert das Materialgleichgewicht. Prüfe Rückschläge und Zwischenzüge erneut.|Ein ruhiger Zug. Vergleiche ihn mit zwingenden Schachs, Schlagzügen und direkten Drohungen.|Du hast die stärkste Fortsetzung der Engine gefunden und die Stellung unter Kontrolle gehalten.|Das gibt dem Gegner eine große taktische Chance.|Das gewährt einen klaren Vorteil, der vermeidbar wäre.|Der Zug ist spielbar, verpasst aber eine genauere Fortsetzung.|{best} war stärker; die unmittelbare gegnerische Drohung ist {threat}.|Sicheres, präzises Schach|Gute Ideen mit Verbesserungspotenzial|Eine lehrreiche Partie|Noch keine aufgezeichneten Züge verfügbar.|{count} Halbzüge mit Entscheidungen in Eröffnung, Mittelspiel und Endspiel analysiert.|Von {total} analysierten Zügen waren {count} die besten oder hervorragend.|Du hast {count} zwingende Züge erkannt und konkrete Probleme geschaffen.|Deine stärkste Gewohnheit war Zentrumskontrolle und Figurenentwicklung.|Du hast die Stellung spielbar gehalten und eine Grundlage für tiefere Berechnung geschaffen.|Spiele eine vollständige Partie, um den entscheidenden Wendepunkt zu ermitteln.|Zug {count}|Eröffnung nicht verfügbar|Nicht klassifizierte Eröffnung|{best} war stärker.|Sizilianische Verteidigung|Spanische Partie|Italienische Partie|Französische Verteidigung|Caro-Kann-Verteidigung|Königsindische Verteidigung|Damengambit|Nimzo/indischer Aufbau|Damenbauernspiel|Königsbauernspiel|Königsbauerneröffnung|Damenbauerneröffnung|Englische Eröffnung|Réti-Eröffnung''',
  'it':
      '''Uno scacco forzante guadagna un tempo. Verifica ogni risposta legale del re prima di impegnarti.|L'arrocco migliora la sicurezza del re e porta una torre in gioco.|Una cattura cambia l'equilibrio materiale. Ricontrolla ricatture e mosse intermedie.|Una mossa tranquilla. Confrontala con scacchi forzanti, catture e minacce dirette.|Hai trovato la continuazione più forte del motore e mantenuto il controllo della posizione.|Questo offre all'avversario una grande opportunità tattica.|Questo concede un chiaro vantaggio che si poteva evitare.|La mossa è giocabile, ma trascura una continuazione più precisa.|{best} era più forte; la minaccia immediata avversaria è {threat}.|Scacchi sicuri e precisi|Buone idee da affinare|Una partita utile per imparare|Non sono ancora disponibili mosse registrate.|Analizzate {count} semimosse nelle decisioni di apertura, mediogioco e finale.|Su {total} mosse analizzate, {count} erano le migliori o ottime.|Hai riconosciuto {count} mosse forzanti e creato problemi concreti.|La tua abitudine migliore era il controllo del centro e lo sviluppo dei pezzi.|Hai mantenuto la posizione giocabile e creato una base per calcoli più profondi.|Gioca una partita completa per individuare la mossa di svolta.|Mossa {count}|Apertura non disponibile|Apertura non classificata|{best} era più forte.|Difesa siciliana|Partita spagnola|Partita italiana|Difesa francese|Difesa Caro-Kann|Difesa est-indiana|Gambetto di donna|Impianto nimzo/indiano|Partita di pedone di donna|Partita di pedone di re|Apertura di pedone di re|Apertura di pedone di donna|Apertura inglese|Apertura Réti''',
  'pt':
      '''Um xeque forçante ganha um tempo. Verifique cada resposta legal do rei antes de decidir.|O roque melhora a segurança do rei e coloca uma torre em jogo.|Uma captura altera o equilíbrio material. Confira novamente as recapturas e os lances intermediários.|Um lance tranquilo. Compare-o com xeques forçantes, capturas e ameaças diretas.|Você encontrou a continuação mais forte do motor e manteve o controle da posição.|Isso dá ao adversário uma grande oportunidade tática.|Isso concede uma vantagem clara que poderia ser evitada.|O lance é jogável, mas deixa passar uma continuação mais precisa.|{best} era mais forte; a ameaça imediata do adversário é {threat}.|Xadrez confiante e preciso|Boas ideias com espaço para melhorar|Uma partida útil para aprender|Ainda não há lances registrados disponíveis.|Foram analisados {count} meios-lances em decisões de abertura, meio-jogo e final.|Dos {total} lances analisados, {count} foram os melhores ou ótimos.|Você reconheceu {count} lances forçantes e criou problemas concretos.|Seu melhor hábito foi o controle do centro e o desenvolvimento das peças.|Você manteve a posição jogável e criou uma base para cálculos mais profundos.|Jogue uma partida completa para identificar o lance decisivo.|Lance {count}|Abertura indisponível|Abertura não classificada|{best} era mais forte.|Defesa Siciliana|Ruy López|Partida Italiana|Defesa Francesa|Defesa Caro-Kann|Defesa Índia do Rei|Gambito da Dama|Estrutura Nimzo/Indiana|Partida do Peão da Dama|Partida do Peão do Rei|Abertura do Peão do Rei|Abertura do Peão da Dama|Abertura Inglesa|Abertura Réti''',
};
