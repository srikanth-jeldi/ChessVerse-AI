import 'app_language.dart';
import 'analysis_dashboard_localizations.dart';
import 'coach_localizations.dart';
import 'review_narrative_localizations.dart';

/// Bundled live-coach messages. Never translates notation or silently replaces
/// unknown prose with an unrelated generic explanation.
const liveCoachKeys = <String>[
  'select',
  'options',
  'noTarget',
  'blocked',
  'undo',
  'waiting',
  'thinking',
  'turn',
  'check',
  'promote',
  'nudge',
  'noMoves',
  'progress',
  'evaluation',
  'yourMove',
  'lastMove',
  'pieceHint',
  'analyze',
  'whyWeak',
  'analyzeMove',
  'training',
];

final Map<String, List<String>> liveCoachTranslations = {
  for (final entry in _rows.entries) entry.key: entry.value.split('|'),
};

const _sources = <String, String>{
  'Select a coin to see legal moves.': 'select',
  'Select a piece to see legal moves.': 'select',
  'Select a piece to begin': 'select',
  'Choose one of your coins first.': 'select',
  'That move is blocked. Pick a highlighted square.': 'blocked',
  'Waiting for your opponent to move.': 'waiting',
  'ChessVerseAI is calculating its reply.': 'thinking',
  'No legal moves found.': 'noMoves',
  'Step progress': 'progress',
  'Evaluation': 'evaluation',
  'Your move': 'yourMove',
  'Last move': 'lastMove',
  'Piece hint': 'pieceHint',
  'Analyze': 'analyze',
  'Why is this weak?': 'whyWeak',
  'Why weak?': 'whyWeak',
  'Analyze move': 'analyzeMove',
  'AI TRAINING • 3-LEVEL HINTS • GAME REVIEW': 'training',
};

final _options = RegExp(r'^([KQRBNP]) from ([a-h][1-8]) has (\d+) options?\.$');
final _noTarget =
    RegExp(r'^([KQRBNP]) has no legal target from ([a-h][1-8])\.$');
final _turn = RegExp(r'^(White|Black) to move\.$');
final _check = RegExp(r'^(White|Black) is in check\.$');
final _promote = RegExp(r'^Choose a promotion coin for ([a-h][1-8])\.$');
final _nudge = RegExp(
    r'^Need a nudge\? Blue lights suggest ([a-h][1-8]) → ([a-h][1-8])\. You can still choose any legal move\.$');

bool supportsLiveCoach(String value) =>
    _translateSheet(value, 'en') != null ||
    liveAnalysisSources.contains(value) ||
    _translateMini(value, 'en') != null ||
    _translateState(value, 'en') != null ||
    _translateDaily(value, 'en') != null ||
    _translateStatus(value, 'en') != null ||
    _translateHint(value, 'en') != null ||
    supportsReviewNarrative(value) ||
    _sources.containsKey(value) ||
    _narrativeSources.containsKey(value) ||
    _moveAction.hasMatch(value) ||
    _captureAction.hasMatch(value) ||
    value == 'Try again' ||
    (value.startsWith('Move undone. ') &&
        supportsLiveCoach(value.substring(13))) ||
    [_options, _noTarget, _turn, _check, _promote, _nudge]
        .any((p) => p.hasMatch(value));

String localizeLiveCoach(String value, String code) {
  final language = AppLanguageController.resolveCode(code);
  if (language == 'en') return value;
  final resultText = _translateResult(value, language);
  if (resultText != null) return resultText;
  final sheet = _translateSheet(value, language);
  if (sheet != null) return sheet;
  final analysisIndex = liveAnalysisSources.indexOf(value);
  if (analysisIndex >= 0) {
    return liveAnalysisTranslations[language]![analysisIndex];
  }
  if (value == 'Best move') return CoachLocalizations(language).text('best');
  if (value == 'Good move') return CoachLocalizations(language).text('good');
  const weakSuffix = ' Tap “Why is this weak?” to understand the safer plan.';
  if (value.endsWith(weakSuffix)) {
    return '${localizeLiveCoach(value.substring(0, value.length - weakSuffix.length), language)} ${_fill(liveSaferPlanTranslations[language]!, {
          'button': localizeLiveCoach('Why is this weak?', language)
        })}';
  }
  final mini = _translateMini(value, language);
  if (mini != null) return mini;
  final status = _translateStatus(value, language);
  if (status != null) return status;
  final daily = _translateDaily(value, language);
  if (daily != null) return daily;
  final state = _translateState(value, language);
  if (state != null) return state;
  final hint = _translateHint(value, language);
  if (hint != null) return hint;
  final reviewed = RegExp(
          r'^(Best|Great|Good|Playable|Inaccuracy|Mistake|Blunder|Move review) • (.+)$',
          dotAll: true)
      .firstMatch(value);
  if (reviewed != null) {
    final grade = reviewed[1] == 'Move review'
        ? CoachLocalizations(language).text('title')
        : CoachLocalizations(language).source(reviewed[1]!);
    return '$grade • ${localizeLiveCoach(localizeReviewNarrative(reviewed[2]!, language), language)}';
  }
  final narrative = localizeReviewNarrative(value, language);
  if (narrative != value) return narrative;
  String render(String key, [Map<String, String> args = const {}]) {
    var result = liveCoachTranslations[language]![liveCoachKeys.indexOf(key)];
    for (final arg in args.entries) {
      result = result.replaceAll('{${arg.key}}', arg.value);
    }
    return result;
  }

  if (value == 'Try again') return CoachLocalizations(language).text('retry');
  if (_sources.containsKey(value)) return render(_sources[value]!);
  if (_narrativeSources.containsKey(value)) {
    return _narrative(language, _narrativeSources[value]!);
  }
  if (value.startsWith('Move undone. ')) {
    return '${render('undo')} ${localizeLiveCoach(value.substring(13), language)}';
  }
  var match = _options.firstMatch(value);
  if (match != null) {
    return render('options',
        {'piece': match[1]!, 'square': match[2]!, 'count': match[3]!});
  }
  match = _noTarget.firstMatch(value);
  if (match != null) {
    return render('noTarget', {'piece': match[1]!, 'square': match[2]!});
  }
  match = _turn.firstMatch(value);
  if (match != null) {
    return render(
        'turn', {'side': CoachLocalizations(language).source(match[1]!)});
  }
  match = _check.firstMatch(value);
  if (match != null) {
    return render(
        'check', {'side': CoachLocalizations(language).source(match[1]!)});
  }
  match = _promote.firstMatch(value);
  if (match != null) return render('promote', {'square': match[1]!});
  match = _nudge.firstMatch(value);
  if (match != null) {
    return render('nudge', {'from': match[1]!, 'to': match[2]!});
  }
  match = _moveAction.firstMatch(value);
  if (match != null) {
    return _fill(_narrative(language, 'moved'), {
      'piece': _piece(match[1]!, language),
      'from': match[2]!,
      'to': match[3]!
    });
  }
  match = _captureAction.firstMatch(value);
  if (match != null) {
    return _fill(_narrative(language, 'captured'), {
      'piece': _piece(match[1]!, language),
      'target': _piece(match[2]!, language),
      'to': match[3]!
    });
  }
  // Local move reports concatenate complete sentences. Translate each exact
  // sentence without dropping unrecognised details or corrupting decimals.
  // Keep this pair together: a single template expresses both sentences.
  const forcingPair =
      'This is a forcing check. Now calculate every legal king escape, capture, and blocking move.';
  if (value.contains(forcingPair)) {
    return value
        .split(forcingPair)
        .map((s) => localizeLiveCoach(s.trim(), language))
        .join(' ${_narrative(language, 'forcingCheck')} ')
        .trim();
  }
  final discovered = RegExp(
          r'Discovered check: moving the \w+ opened the \w+ attack from [a-h][1-8] onto the king at [a-h][1-8]\. The opponent must answer that revealed check\.')
      .firstMatch(value);
  if (discovered != null) {
    return [
      localizeLiveCoach(value.substring(0, discovered.start).trim(), language),
      _translateHint(discovered[0]!, language)!,
      localizeLiveCoach(value.substring(discovered.end).trim(), language)
    ].where((s) => s.isNotEmpty).join(' ');
  }
  final sentences = value.split(RegExp(r'(?<=\.) (?=[A-Z])'));
  if (sentences.length > 1) {
    return sentences.map((s) => localizeLiveCoach(s, language)).join(' ');
  }
  return value;
}

String _fill(String value, Map<String, String> parameters) {
  for (final p in parameters.entries) {
    value = value.replaceAll('{${p.key}}', p.value);
  }
  return value;
}

String _narrative(String language, String key) =>
    liveNarrativeTranslations[language]![liveNarrativeKeys.indexOf(key)];
String _piece(String name, String language) =>
    liveNarrativeKeys.take(7).contains(name.toLowerCase())
        ? _narrative(language, name.toLowerCase())
        : name;
final _moveAction = RegExp(
    r'^(Pawn|Knight|Bishop|Rook|Queen|King|Piece) moved from ([a-h][1-8]) to ([a-h][1-8])\.$');
final _captureAction = RegExp(
    r'^(Pawn|Knight|Bishop|Rook|Queen|King|Piece) captured (?:a |the )(pawn|knight|bishop|rook|queen|king|piece) on ([a-h][1-8])\.$');
const liveNarrativeKeys = [
  'pawn',
  'knight',
  'bishop',
  'rook',
  'queen',
  'king',
  'piece',
  'moved',
  'captured',
  'amazing',
  'superb',
  'goodStep',
  'kingSafety',
  'average',
  'pawnCentre',
  'pawnStructure',
  'knightPurpose',
  'bishopPurpose',
  'rookPurpose',
  'queenPurpose',
  'kingPurpose',
  'compare',
  'forcingGain',
  'forcingCheck',
  'captureSafety',
  'centreSpace',
  'nextThreat'
];
final Map<String, List<String>> liveNarrativeTranslations = {
  for (final e in _narrativeRows.entries) e.key: e.value.split('|')
};
const _narrativeSources = <String, String>{
  'Amazing step - check with material gain.': 'amazing',
  'Superb step - strong chess idea.': 'superb',
  'Good step - useful improvement.': 'goodStep',
  'Not good step - king safety first.': 'kingSafety',
  'Average step - playable, but look for more pressure.': 'average',
  'The pawn claims central space and opens lines for your pieces.':
      'pawnCentre',
  'The pawn changes the structure; check the squares it now protects.':
      'pawnStructure',
  'The knight attacks in an L-shape; inspect its new forks and protected squares.':
      'knightPurpose',
  'The bishop opens a diagonal; trace it until the first blocker.':
      'bishopPurpose',
  'The rook works on ranks and files; look for an open file or king pressure.':
      'rookPurpose',
  'The queen creates threats in several directions; verify it cannot be chased.':
      'queenPurpose',
  'The king move changes king safety; recheck every enemy check on the new square.':
      'kingPurpose',
  'Compare the checks, captures, and threats created by the move.': 'compare',
  'Strong forcing move: it wins material and checks the king, so the opponent must respond to the check.':
      'forcingGain',
  'This is a forcing check.': 'forcingCheck',
  'Now calculate every legal king escape, capture, and blocking move.':
      'forcingCheck',
  'This is a forcing check. Now calculate every legal king escape, capture, and blocking move.':
      'forcingCheck',
  'Before the next move, compare the traded piece values and check whether the capturing piece is protected.':
      'captureSafety',
  'Central control gives your pieces more space and mobility.': 'centreSpace',
  'Next, look for a check, capture, or direct threat.': 'nextThreat',
};

const _narrativeRows = <String, String>{
  'en':
      '''Pawn|Knight|Bishop|Rook|Queen|King|Piece|{piece} moved from {from} to {to}.|{piece} captured {target} on {to}.|Amazing step - check with material gain.|Superb step - strong chess idea.|Good step - useful improvement.|Not good step - king safety first.|Average step - playable, but look for more pressure.|The pawn claims central space and opens lines for your pieces.|The pawn changes the structure; check the squares it now protects.|The knight attacks in an L-shape; inspect its new forks and protected squares.|The bishop opens a diagonal; trace it until the first blocker.|The rook works on ranks and files; look for an open file or king pressure.|The queen creates threats in several directions; verify it cannot be chased.|The king move changes king safety; recheck every enemy check on the new square.|Compare the checks, captures, and threats created by the move.|Strong forcing move: it wins material and checks the king, so the opponent must respond to the check.|This is a forcing check. Now calculate every legal king escape, capture, and blocking move.|Before the next move, compare the traded piece values and check whether the capturing piece is protected.|Central control gives your pieces more space and mobility.|Next, look for a check, capture, or direct threat.''',
  'te':
      '''సైనికుడు|గుర్రం|ఏనుగు|శకటం|రాణి|రాజు|పావు|{piece}: {from} నుండి {to}కు కదిలింది.|{piece}: {to}లోని {target}ను పట్టుకుంది.|అద్భుతమైన ఎత్తు — పావును గెలుస్తూ చెక్ ఇచ్చారు.|అత్యుత్తమ ఎత్తు — బలమైన చదరంగ ఆలోచన.|మంచి ఎత్తు — ఉపయోగకరమైన మెరుగుదల.|మంచి ఎత్తు కాదు — రాజు భద్రత ముందుగా.|సగటు ఎత్తు — ఆడవచ్చు, కానీ మరింత ఒత్తిడి కోసం చూడండి.|సైనికుడు కేంద్రంలో స్థలాన్ని ఆక్రమించి మీ పావులకు మార్గాలను తెరుస్తాడు.|సైనికుడు నిర్మాణాన్ని మారుస్తాడు; ఇప్పుడు రక్షించే గడులను చూడండి.|గుర్రం L ఆకారంలో దాడి చేస్తుంది; కొత్త ద్వంద్వదాడులు, రక్షిత గడులను పరిశీలించండి.|ఏనుగు వికర్ణాన్ని తెరుస్తుంది; మొదటి అడ్డంకి వరకు పరిశీలించండి.|శకటం వరుసలు, నిలువు వరుసలలో పనిచేస్తుంది; తెరిచిన నిలువు వరుస లేదా రాజుపై ఒత్తిడి కోసం చూడండి.|రాణి పలు దిశల్లో ముప్పులు సృష్టిస్తుంది; దాన్ని తరిమివేయలేరని నిర్ధారించండి.|రాజు కదలిక భద్రతను మారుస్తుంది; కొత్త గడిపై ప్రత్యర్థి ఇచ్చే ప్రతి చెక్‌ను పరిశీలించండి.|ఈ ఎత్తు సృష్టించిన చెక్‌లు, పట్టుకోవడాలు, ముప్పులను పోల్చండి.|బలమైన బలవంతపు ఎత్తు: పావును గెలుస్తూ చెక్ ఇస్తుంది, కాబట్టి ప్రత్యర్థి చెక్‌కు స్పందించాలి.|ఇది బలవంతపు చెక్. రాజు తప్పించుకోవడం, పట్టుకోవడం, అడ్డుకోవడం వంటి అన్ని చట్టబద్ధమైన సమాధానాలను లెక్కించండి.|తదుపరి ఎత్తుకు ముందు మార్పిడి పావుల విలువలను పోల్చి పట్టుకున్న పావుకు రక్షణ ఉందో చూడండి.|కేంద్ర నియంత్రణ మీ పావులకు మరింత స్థలం, కదలిక ఇస్తుంది.|తరువాత చెక్, పట్టుకోవడం లేదా నేరుగా ముప్పు కోసం చూడండి.''',
  'hi':
      '''प्यादा|घोड़ा|ऊँट|हाथी|वज़ीर|राजा|मोहरा|{piece}: {from} से {to} गया।|{piece} ने {to} पर {target} मारा।|अद्भुत चाल — मोहरा जीतते हुए शह।|शानदार चाल — मजबूत शतरंज विचार।|अच्छी चाल — उपयोगी सुधार।|अच्छी चाल नहीं — राजा की सुरक्षा पहले।|औसत चाल — खेलने योग्य, पर अधिक दबाव खोजें।|प्यादा केंद्र में जगह लेता है और आपके मोहरों के लिए रास्ते खोलता है।|प्यादा संरचना बदलता है; अब जिन खानों की रक्षा करता है उन्हें देखें।|घोड़ा L आकार में हमला करता है; नए दोहरे हमले और सुरक्षित खाने देखें।|ऊँट विकर्ण खोलता है; पहले अवरोध तक देखें।|हाथी पंक्तियों और फ़ाइलों पर चलता है; खुली फ़ाइल या राजा पर दबाव खोजें।|वज़ीर कई दिशाओं में खतरे बनाता है; जाँचें कि उसे खदेड़ा न जा सके।|राजा की चाल सुरक्षा बदलती है; नए खाने पर दुश्मन की हर शह जाँचें।|इस चाल से बनी शह, मारने के मौके और खतरों की तुलना करें।|मजबूत बाध्यकारी चाल: मोहरा जीतती है और शह देती है, इसलिए प्रतिद्वंद्वी को शह का जवाब देना होगा।|यह बाध्यकारी शह है। राजा के हर वैध बचाव, मारने और रोकने की चाल की गणना करें।|अगली चाल से पहले बदले गए मोहरों के मूल्य और मारने वाले मोहरे की सुरक्षा जाँचें।|केंद्र पर नियंत्रण मोहरों को अधिक जगह और गतिशीलता देता है।|अब शह, मोहरा मारने या सीधे खतरे की तलाश करें।''',
  'ta':
      '''சிப்பாய்|குதிரை|யானை|கோட்டை|ராணி|ராஜா|காய்|{piece}: {from} இலிருந்து {to} சென்றது.|{piece}, {to} இல் {target} ஐப் பிடித்தது.|அற்புத நகர்வு — காயைப் பெற்று செக்.|மிகச்சிறந்த நகர்வு — வலுவான சதுரங்க யோசனை.|நல்ல நகர்வு — பயனுள்ள முன்னேற்றம்.|நல்ல நகர்வு அல்ல — ராஜாவின் பாதுகாப்பு முதலில்.|சராசரி நகர்வு — ஆடலாம், ஆனால் அதிக அழுத்தத்தைத் தேடுங்கள்.|சிப்பாய் மைய இடத்தைப் பிடித்து உங்கள் காய்களுக்கு வழிகளைத் திறக்கிறது.|சிப்பாய் கட்டமைப்பை மாற்றுகிறது; இப்போது பாதுகாக்கும் கட்டங்களைப் பாருங்கள்.|குதிரை L வடிவில் தாக்குகிறது; புதிய இரட்டைத் தாக்குதல்களையும் பாதுகாக்கும் கட்டங்களையும் பாருங்கள்.|யானை மூலைவிட்டத்தைத் திறக்கிறது; முதல் தடுப்புவரை பாருங்கள்.|கோட்டை வரிசைகளில் செயல்படுகிறது; திறந்த செங்குத்து வரிசை அல்லது ராஜா மீதான அழுத்தத்தைத் தேடுங்கள்.|ராணி பல திசைகளில் அச்சுறுத்துகிறது; அதை விரட்ட முடியாதா எனச் சரிபாருங்கள்.|ராஜாவின் நகர்வு பாதுகாப்பை மாற்றுகிறது; புதிய கட்டத்தில் எதிரியின் எல்லா செக்குகளையும் பாருங்கள்.|இந்த நகர்வு உருவாக்கும் செக்குகள், பிடிப்புகள், அச்சுறுத்தல்களை ஒப்பிடுங்கள்.|வலுவான கட்டாய நகர்வு: காயை வென்று செக் தருவதால் எதிரி செக்கிற்கு பதிலளிக்க வேண்டும்.|இது கட்டாய செக். ராஜா தப்புதல், பிடித்தல், தடுத்தல் ஆகிய எல்லாச் சட்டபூர்வ பதில்களையும் கணக்கிடுங்கள்.|அடுத்த நகர்வுக்கு முன் பரிமாறிய காய்களின் மதிப்பையும் பிடித்த காயின் பாதுகாப்பையும் பாருங்கள்.|மையக் கட்டுப்பாடு காய்களுக்கு அதிக இடமும் இயக்கமும் தருகிறது.|அடுத்து செக், பிடிப்பு அல்லது நேரடி அச்சுறுத்தலைத் தேடுங்கள்.''',
  'kn':
      '''ಸೈನಿಕ|ಕುದುರೆ|ಒಂಟೆ|ಆನೆ|ರಾಣಿ|ರಾಜ|ಕಾಯಿ|{piece}: {from} ಇಂದ {to} ಗೆ ಚಲಿಸಿತು.|{piece}, {to} ನಲ್ಲಿ {target} ಅನ್ನು ಹಿಡಿಯಿತು.|ಅದ್ಭುತ ನಡೆ — ಕಾಯಿ ಲಾಭದೊಂದಿಗೆ ಚೆಕ್.|ಅತ್ಯುತ್ತಮ ನಡೆ — ಬಲವಾದ ಚದುರಂಗ ಯೋಚನೆ.|ಒಳ್ಳೆಯ ನಡೆ — ಉಪಯುಕ್ತ ಸುಧಾರಣೆ.|ಒಳ್ಳೆಯ ನಡೆಯಲ್ಲ — ರಾಜನ ಸುರಕ್ಷತೆ ಮೊದಲು.|ಸರಾಸರಿ ನಡೆ — ಆಡಬಹುದು, ಆದರೆ ಹೆಚ್ಚಿನ ಒತ್ತಡ ಹುಡುಕಿ.|ಸೈನಿಕ ಕೇಂದ್ರದ ಜಾಗ ಪಡೆದು ನಿಮ್ಮ ಕಾಯಿಗಳಿಗೆ ದಾರಿಗಳನ್ನು ತೆರೆಯುತ್ತದೆ.|ಸೈನಿಕ ರಚನೆ ಬದಲಿಸುತ್ತದೆ; ಈಗ ರಕ್ಷಿಸುವ ಚೌಕಗಳನ್ನು ನೋಡಿ.|ಕುದುರೆ L ಆಕಾರದಲ್ಲಿ ದಾಳಿ ಮಾಡುತ್ತದೆ; ಹೊಸ ಜೋಡಿದಾಳಿಗಳು ಮತ್ತು ರಕ್ಷಿತ ಚೌಕಗಳನ್ನು ನೋಡಿ.|ಒಂಟೆ ಕರ್ಣದ ದಾರಿ ತೆರೆಯುತ್ತದೆ; ಮೊದಲ ಅಡ್ಡಿಯವರೆಗೆ ನೋಡಿ.|ಆನೆ ಅಡ್ಡ ಮತ್ತು ನೇರ ಸಾಲುಗಳಲ್ಲಿ ಕೆಲಸ ಮಾಡುತ್ತದೆ; ತೆರೆದ ಸಾಲು ಅಥವಾ ರಾಜನ ಮೇಲೆ ಒತ್ತಡ ಹುಡುಕಿ.|ರಾಣಿ ಹಲವು ದಿಕ್ಕುಗಳಲ್ಲಿ ಬೆದರಿಕೆ ಸೃಷ್ಟಿಸುತ್ತದೆ; ಅದನ್ನು ಓಡಿಸಲು ಸಾಧ್ಯವಿಲ್ಲವೇ ಪರಿಶೀಲಿಸಿ.|ರಾಜನ ನಡೆ ಸುರಕ್ಷತೆ ಬದಲಿಸುತ್ತದೆ; ಹೊಸ ಚೌಕದಲ್ಲಿ ಎದುರಾಳಿಯ ಪ್ರತಿಯೊಂದು ಚೆಕ್ ಪರಿಶೀಲಿಸಿ.|ನಡೆ ಸೃಷ್ಟಿಸಿದ ಚೆಕ್‌ಗಳು, ಸೆರೆಗಳು ಮತ್ತು ಬೆದರಿಕೆಗಳನ್ನು ಹೋಲಿಸಿ.|ಬಲವಾದ ಬಲವಂತದ ನಡೆ: ಕಾಯಿ ಗೆದ್ದು ಚೆಕ್ ನೀಡುತ್ತದೆ, ಆದ್ದರಿಂದ ಎದುರಾಳಿ ಚೆಕ್‌ಗೆ ಉತ್ತರಿಸಬೇಕು.|ಇದು ಬಲವಂತದ ಚೆಕ್. ರಾಜನ ತಪ್ಪಿಸಿಕೊಳ್ಳುವಿಕೆ, ಸೆರೆ ಮತ್ತು ತಡೆಯುವ ಎಲ್ಲ ಕಾನೂನುಬದ್ಧ ನಡೆಗಳನ್ನು ಲೆಕ್ಕಿಸಿ.|ಮುಂದಿನ ನಡೆಗೂ ಮೊದಲು ವಿನಿಮಯದ ಕಾಯಿಗಳ ಮೌಲ್ಯ ಮತ್ತು ಹಿಡಿದ ಕಾಯಿಯ ರಕ್ಷಣೆ ಪರಿಶೀಲಿಸಿ.|ಕೇಂದ್ರ ನಿಯಂತ್ರಣ ಕಾಯಿಗಳಿಗೆ ಹೆಚ್ಚು ಜಾಗ ಮತ್ತು ಚಲನೆ ನೀಡುತ್ತದೆ.|ಮುಂದೆ ಚೆಕ್, ಸೆರೆ ಅಥವಾ ನೇರ ಬೆದರಿಕೆ ಹುಡುಕಿ.''',
  'ml':
      '''കാലാൾ|കുതിര|ആന|തേര്|മന്ത്രി|രാജാവ്|കരു|{piece}: {from} ൽ നിന്ന് {to} ലേക്ക് നീങ്ങി.|{piece}, {to} ലെ {target} പിടിച്ചു.|അതിശയകരമായ നീക്കം — കരു നേട്ടത്തോടെ ചെക്ക്.|മികച്ച നീക്കം — ശക്തമായ ചെസ് ആശയം.|നല്ല നീക്കം — ഉപകാരപ്രദമായ പുരോഗതി.|നല്ല നീക്കമല്ല — രാജാവിന്റെ സുരക്ഷ ആദ്യം.|ശരാശരി നീക്കം — കളിക്കാം, കൂടുതൽ സമ്മർദം കണ്ടെത്തുക.|കാലാൾ മധ്യത്തിലെ ഇടം നേടി കരുക്കൾക്ക് വഴികൾ തുറക്കുന്നു.|കാലാൾ ഘടന മാറ്റുന്നു; ഇപ്പോൾ സംരക്ഷിക്കുന്ന കളങ്ങൾ പരിശോധിക്കുക.|കുതിര L രൂപത്തിൽ ആക്രമിക്കുന്നു; പുതിയ ഇരട്ടാക്രമണങ്ങളും സംരക്ഷിത കളങ്ങളും നോക്കുക.|ആന വികർണം തുറക്കുന്നു; ആദ്യ തടസ്സം വരെ പിന്തുടരുക.|തേര് നിരകളിൽ പ്രവർത്തിക്കുന്നു; തുറന്ന നിരയോ രാജാവിന് സമ്മർദമോ കണ്ടെത്തുക.|മന്ത്രി പല ദിശകളിൽ ഭീഷണികൾ സൃഷ്ടിക്കുന്നു; അതിനെ ഓടിക്കാനാവില്ലെന്ന് ഉറപ്പാക്കുക.|രാജാവിന്റെ നീക്കം സുരക്ഷ മാറ്റുന്നു; പുതിയ കളത്തിലെ എല്ലാ എതിരാളി ചെക്കുകളും പരിശോധിക്കുക.|നീക്കം സൃഷ്ടിക്കുന്ന ചെക്കുകളും പിടിത്തങ്ങളും ഭീഷണികളും താരതമ്യം ചെയ്യുക.|ശക്തമായ നിർബന്ധിത നീക്കം: കരു നേടി ചെക്ക് നൽകുന്നതിനാൽ എതിരാളി ചെക്കിന് മറുപടി നൽകണം.|ഇത് നിർബന്ധിത ചെക്കാണ്. രാജാവിന്റെ രക്ഷപ്പെടലും പിടിത്തവും തടയലും ഉൾപ്പെടെ എല്ലാ നിയമാനുസൃത മറുപടികളും കണക്കാക്കുക.|അടുത്ത നീക്കത്തിന് മുമ്പ് കൈമാറിയ കരുക്കളുടെ മൂല്യവും പിടിച്ച കരുവിന്റെ സംരക്ഷണവും പരിശോധിക്കുക.|മധ്യനിയന്ത്രണം കരുക്കൾക്ക് കൂടുതൽ ഇടവും ചലനവും നൽകുന്നു.|അടുത്തതായി ചെക്കോ പിടിത്തമോ നേരിട്ടുള്ള ഭീഷണിയോ കണ്ടെത്തുക.''',
  'mr':
      '''प्यादा|घोडा|उंट|हत्ती|वजीर|राजा|मोहरा|{piece}: {from} वरून {to} वर गेला.|{piece} ने {to} वर {target} मारला.|अप्रतिम चाल — मोहरा मिळवत शह.|उत्कृष्ट चाल — मजबूत बुद्धिबळ कल्पना.|चांगली चाल — उपयुक्त सुधारणा.|चांगली चाल नाही — राजाची सुरक्षितता आधी.|सरासरी चाल — खेळण्यायोग्य, पण अधिक दबाव शोधा.|प्यादा केंद्रातील जागा घेतो आणि मोहर्‍यांसाठी मार्ग उघडतो.|प्यादा रचना बदलतो; आता रक्षण होणारी घरे तपासा.|घोडा L आकारात हल्ला करतो; नवीन दुहेरी हल्ले आणि संरक्षित घरे तपासा.|उंट कर्ण उघडतो; पहिल्या अडथळ्यापर्यंत पाहा.|हत्ती आडव्या व उभ्या रेषांवर काम करतो; मोकळी रेषा किंवा राजावर दबाव शोधा.|वजीर अनेक दिशांना धोके निर्माण करतो; त्याला हुसकावता येणार नाही याची खात्री करा.|राजाची चाल सुरक्षितता बदलते; नव्या घरावर प्रत्येक विरोधी शह तपासा.|या चालीतील शह, मारण्याच्या संधी आणि धमक्यांची तुलना करा.|जबरदस्त सक्तीची चाल: मोहरा मिळतो व शह मिळतो, त्यामुळे विरोधकाला शहचे उत्तर द्यावे लागते.|हा सक्तीचा शह आहे. राजाची सुटका, मारणे आणि अडवणे यांचे सर्व वैध पर्याय मोजा.|पुढच्या चालीपूर्वी बदललेल्या मोहर्‍यांचे मूल्य आणि मारणार्‍या मोहर्‍याचे संरक्षण तपासा.|केंद्रावरील नियंत्रण मोहर्‍यांना अधिक जागा आणि हालचाल देते.|पुढे शह, मारणे किंवा थेट धमकी शोधा.''',
  'bn':
      '''বোড়ে|ঘোড়া|গজ|নৌকা|মন্ত্রী|রাজা|ঘুঁটি|{piece}: {from} থেকে {to} গেল।|{piece}, {to}-এ {target} ধরেছে।|অসাধারণ চাল — ঘুঁটি জিতে কিস্তি।|দুর্দান্ত চাল — শক্তিশালী দাবার ভাবনা।|ভালো চাল — উপকারী উন্নতি।|ভালো চাল নয় — রাজার নিরাপত্তা আগে।|গড় চাল — খেলা যায়, তবে আরও চাপ খুঁজুন।|বোড়ে কেন্দ্রের জায়গা নেয় এবং ঘুঁটির পথ খোলে।|বোড়ে কাঠামো বদলায়; এখন যে ঘরগুলি রক্ষা করে দেখুন।|ঘোড়া L আকারে আক্রমণ করে; নতুন দ্বৈত আক্রমণ ও সুরক্ষিত ঘর দেখুন।|গজ কর্ণ খোলে; প্রথম বাধা পর্যন্ত দেখুন।|নৌকা সারি ও কলামে কাজ করে; খোলা কলাম বা রাজার ওপর চাপ খুঁজুন।|মন্ত্রী বিভিন্ন দিকে হুমকি তৈরি করে; তাকে তাড়ানো যাবে কি না যাচাই করুন।|রাজার চাল নিরাপত্তা বদলায়; নতুন ঘরে শত্রুর প্রতিটি কিস্তি যাচাই করুন।|চালটি তৈরি করা কিস্তি, ধরার সুযোগ ও হুমকি তুলনা করুন।|শক্তিশালী বাধ্যকারী চাল: ঘুঁটি জেতে ও কিস্তি দেয়, তাই প্রতিপক্ষকে কিস্তির উত্তর দিতে হবে।|এটি বাধ্যকারী কিস্তি। রাজার পালানো, ধরা ও আটকানোর সব বৈধ চাল গণনা করুন।|পরের চালের আগে বদলানো ঘুঁটির মূল্য ও ধরা ঘুঁটির নিরাপত্তা যাচাই করুন।|কেন্দ্রের নিয়ন্ত্রণ ঘুঁটিকে বেশি জায়গা ও চলাচল দেয়।|এবার কিস্তি, ধরা বা সরাসরি হুমকি খুঁজুন।''',
  'gu':
      '''પ્યાદું|ઘોડો|ઊંટ|હાથી|વજીર|રાજા|મહોરું|{piece}: {from} થી {to} ગયું.|{piece} એ {to} પર {target} માર્યું.|અદ્ભુત ચાલ — મહોરું જીતીને શાહ.|શાનદાર ચાલ — મજબૂત શતરંજ વિચાર.|સારી ચાલ — ઉપયોગી સુધારો.|સારી ચાલ નથી — રાજાની સુરક્ષા પ્રથમ.|સરેરાશ ચાલ — રમી શકાય, પણ વધુ દબાણ શોધો.|પ્યાદું કેન્દ્રમાં જગ્યા લે છે અને મહોરાં માટે માર્ગ ખોલે છે.|પ્યાદું રચના બદલે છે; હવે સુરક્ષિત ઘરો તપાસો.|ઘોડો L આકારમાં હુમલો કરે છે; નવા બેવડા હુમલા અને સુરક્ષિત ઘરો જુઓ.|ઊંટ કર્ણ ખોલે છે; પ્રથમ અવરોધ સુધી જુઓ.|હાથી આડી અને ઊભી હરોળમાં કામ કરે છે; ખુલ્લી હરોળ કે રાજા પર દબાણ શોધો.|વજીર અનેક દિશામાં ખતરા બનાવે છે; તેને ભગાડી ન શકાય તે તપાસો.|રાજાની ચાલ સુરક્ષા બદલે છે; નવા ઘર પર વિરોધીની દરેક શાહ તપાસો.|આ ચાલથી બનેલી શાહ, મારવાની તકો અને ખતરાઓની તુલના કરો.|મજબૂત ફરજિયાત ચાલ: મહોરું જીતે અને શાહ આપે, તેથી વિરોધીને શાહનો જવાબ આપવો પડે.|આ ફરજિયાત શાહ છે. રાજાના બચાવ, મારવા અને રોકવાની બધી કાયદેસર ચાલ ગણો.|આગલી ચાલ પહેલાં બદલેલા મહોરાંનું મૂલ્ય અને મારનાર મહોરાની સુરક્ષા તપાસો.|કેન્દ્રનું નિયંત્રણ મહોરાંને વધુ જગ્યા અને ગતિ આપે છે.|હવે શાહ, મારવું કે સીધો ખતરો શોધો.''',
  'pa':
      '''ਪਿਆਦਾ|ਘੋੜਾ|ਊਠ|ਹਾਥੀ|ਵਜ਼ੀਰ|ਰਾਜਾ|ਮੋਹਰਾ|{piece}: {from} ਤੋਂ {to} ਗਿਆ।|{piece} ਨੇ {to} ਉੱਤੇ {target} ਮਾਰਿਆ।|ਕਮਾਲ ਦੀ ਚਾਲ — ਮੋਹਰਾ ਜਿੱਤ ਕੇ ਸ਼ਹ।|ਸ਼ਾਨਦਾਰ ਚਾਲ — ਮਜ਼ਬੂਤ ਸ਼ਤਰੰਜ ਵਿਚਾਰ।|ਵਧੀਆ ਚਾਲ — ਲਾਭਦਾਇਕ ਸੁਧਾਰ।|ਚੰਗੀ ਚਾਲ ਨਹੀਂ — ਰਾਜੇ ਦੀ ਸੁਰੱਖਿਆ ਪਹਿਲਾਂ।|ਔਸਤ ਚਾਲ — ਖੇਡਣ ਯੋਗ, ਪਰ ਹੋਰ ਦਬਾਅ ਲੱਭੋ।|ਪਿਆਦਾ ਕੇਂਦਰ ਵਿੱਚ ਥਾਂ ਲੈਂਦਾ ਅਤੇ ਮੋਹਰਿਆਂ ਲਈ ਰਾਹ ਖੋਲ੍ਹਦਾ ਹੈ।|ਪਿਆਦਾ ਬਣਤਰ ਬਦਲਦਾ ਹੈ; ਹੁਣ ਸੁਰੱਖਿਅਤ ਖਾਨੇ ਵੇਖੋ।|ਘੋੜਾ L ਆਕਾਰ ਵਿੱਚ ਹਮਲਾ ਕਰਦਾ ਹੈ; ਨਵੇਂ ਦੋਹਰੇ ਹਮਲੇ ਅਤੇ ਸੁਰੱਖਿਅਤ ਖਾਨੇ ਵੇਖੋ।|ਊਠ ਤਿਰਛਾ ਰਾਹ ਖੋਲ੍ਹਦਾ ਹੈ; ਪਹਿਲੀ ਰੁਕਾਵਟ ਤੱਕ ਵੇਖੋ।|ਹਾਥੀ ਕਤਾਰਾਂ ਵਿੱਚ ਕੰਮ ਕਰਦਾ ਹੈ; ਖੁੱਲ੍ਹੀ ਕਤਾਰ ਜਾਂ ਰਾਜੇ ਉੱਤੇ ਦਬਾਅ ਲੱਭੋ।|ਵਜ਼ੀਰ ਕਈ ਦਿਸ਼ਾਵਾਂ ਵਿੱਚ ਖ਼ਤਰੇ ਬਣਾਉਂਦਾ ਹੈ; ਜਾਂਚੋ ਕਿ ਉਸ ਨੂੰ ਭਜਾਇਆ ਨਾ ਜਾ ਸਕੇ।|ਰਾਜੇ ਦੀ ਚਾਲ ਸੁਰੱਖਿਆ ਬਦਲਦੀ ਹੈ; ਨਵੇਂ ਖਾਨੇ ਉੱਤੇ ਹਰ ਵਿਰੋਧੀ ਸ਼ਹ ਜਾਂਚੋ।|ਇਸ ਚਾਲ ਦੀ ਸ਼ਹ, ਮਾਰਨ ਦੇ ਮੌਕੇ ਅਤੇ ਖ਼ਤਰਿਆਂ ਦੀ ਤੁਲਨਾ ਕਰੋ।|ਮਜ਼ਬੂਤ ਮਜਬੂਰ ਕਰਨ ਵਾਲੀ ਚਾਲ: ਮੋਹਰਾ ਜਿੱਤ ਕੇ ਸ਼ਹ ਦਿੰਦੀ ਹੈ, ਇਸ ਲਈ ਵਿਰੋਧੀ ਨੂੰ ਸ਼ਹ ਦਾ ਜਵਾਬ ਦੇਣਾ ਪਵੇਗਾ।|ਇਹ ਮਜਬੂਰ ਕਰਨ ਵਾਲੀ ਸ਼ਹ ਹੈ। ਰਾਜੇ ਦੇ ਬਚਾਅ, ਮਾਰਨ ਅਤੇ ਰੋਕਣ ਦੀ ਹਰ ਜਾਇਜ਼ ਚਾਲ ਗਿਣੋ।|ਅਗਲੀ ਚਾਲ ਤੋਂ ਪਹਿਲਾਂ ਬਦਲੇ ਮੋਹਰਿਆਂ ਦੀ ਕੀਮਤ ਅਤੇ ਮਾਰਨ ਵਾਲੇ ਮੋਹਰੇ ਦੀ ਰੱਖਿਆ ਜਾਂਚੋ।|ਕੇਂਦਰ ਦਾ ਕਾਬੂ ਮੋਹਰਿਆਂ ਨੂੰ ਵੱਧ ਥਾਂ ਅਤੇ ਗਤੀ ਦਿੰਦਾ ਹੈ।|ਹੁਣ ਸ਼ਹ, ਮਾਰਨ ਜਾਂ ਸਿੱਧਾ ਖ਼ਤਰਾ ਲੱਭੋ।''',
  'ur':
      '''پیادہ|گھوڑا|فیل|رخ|وزیر|بادشاہ|مہرہ|{piece}: {from} سے {to} گیا۔|{piece} نے {to} پر {target} مارا۔|حیرت انگیز چال — مہرہ جیت کر شہ۔|شاندار چال — مضبوط شطرنج خیال۔|اچھی چال — مفید بہتری۔|اچھی چال نہیں — بادشاہ کی حفاظت پہلے۔|اوسط چال — قابل کھیل، مگر زیادہ دباؤ تلاش کریں۔|پیادہ مرکز میں جگہ لیتا اور مہروں کے راستے کھولتا ہے۔|پیادہ ساخت بدلتا ہے؛ اب محفوظ خانوں کو دیکھیں۔|گھوڑا L کی شکل میں حملہ کرتا ہے؛ نئے دوہرے حملے اور محفوظ خانے دیکھیں۔|فیل ترچھا راستہ کھولتا ہے؛ پہلی رکاوٹ تک دیکھیں۔|رخ قطاروں اور کالموں پر کام کرتا ہے؛ کھلا کالم یا بادشاہ پر دباؤ تلاش کریں۔|وزیر کئی سمتوں میں خطرے بناتا ہے؛ جانچیں کہ اسے بھگایا نہ جا سکے۔|بادشاہ کی چال حفاظت بدلتی ہے؛ نئے خانے پر دشمن کی ہر شہ جانچیں۔|اس چال کی شہ، مارنے کے مواقع اور خطرات کا موازنہ کریں۔|مضبوط جبری چال: مہرہ جیت کر شہ دیتی ہے، لہٰذا حریف کو شہ کا جواب دینا ہوگا۔|یہ جبری شہ ہے۔ بادشاہ کے ہر جائز بچاؤ، مارنے اور روکنے کی چال کا حساب کریں۔|اگلی چال سے پہلے بدلے مہروں کی قیمت اور مارنے والے مہرے کی حفاظت جانچیں۔|مرکز کا کنٹرول مہروں کو زیادہ جگہ اور حرکت دیتا ہے۔|اب شہ، مارنے یا براہ راست خطرے کی تلاش کریں۔''',
  'ar':
      '''بيدق|حصان|فيل|رخ|وزير|ملك|قطعة|انتقلت القطعة {piece} من {from} إلى {to}.|أخذت القطعة {piece} القطعة {target} في {to}.|نقلة مذهلة — كش مع ربح مادي.|نقلة رائعة — فكرة شطرنج قوية.|نقلة جيدة — تحسين مفيد.|نقلة غير جيدة — سلامة الملك أولاً.|نقلة متوسطة — قابلة للعب، لكن ابحث عن ضغط أكبر.|يسيطر البيدق على مساحة في المركز ويفتح خطوطًا لقطعك.|يغيّر البيدق البنية؛ افحص المربعات التي يحميها الآن.|يهاجم الحصان بشكل L؛ افحص الشوكات الجديدة والمربعات المحمية.|يفتح الفيل قطرًا؛ تتبعه حتى أول عائق.|يعمل الرخ على الصفوف والأعمدة؛ ابحث عن عمود مفتوح أو ضغط على الملك.|يصنع الوزير تهديدات في اتجاهات متعددة؛ تحقق أنه لا يمكن مطاردته.|تغيّر نقلة الملك سلامته؛ أعد فحص كل كش للعدو على المربع الجديد.|قارن الكش والأخذ والتهديدات الناتجة عن النقلة.|نقلة إجبارية قوية: تربح مادة وتكش الملك، لذا يجب على الخصم الرد على الكش.|هذا كش إجباري. احسب كل هروب قانوني للملك وأخذ وحجب.|قبل النقلة التالية قارن قيم القطع المتبادلة وتحقق من حماية القطعة الآخذة.|السيطرة على المركز تمنح قطعك مساحة وحركة أكبر.|ابحث الآن عن كش أو أخذ أو تهديد مباشر.''',
  'es':
      '''Peón|Caballo|Alfil|Torre|Dama|Rey|Pieza|{piece} se movió de {from} a {to}.|{piece} capturó {target} en {to}.|Paso asombroso: jaque con ganancia material.|Paso excelente: una idea fuerte.|Buen paso: mejora útil.|Mal paso: primero la seguridad del rey.|Paso normal: jugable, pero busca más presión.|El peón gana espacio central y abre líneas para tus piezas.|El peón cambia la estructura; revisa las casillas que ahora protege.|El caballo ataca en L; examina sus nuevas horquillas y casillas protegidas.|El alfil abre una diagonal; síguela hasta el primer obstáculo.|La torre actúa por filas y columnas; busca una columna abierta o presión sobre el rey.|La dama crea amenazas en varias direcciones; verifica que no puedan perseguirla.|La jugada del rey cambia su seguridad; revisa todos los jaques enemigos en la nueva casilla.|Compara los jaques, capturas y amenazas creados por la jugada.|Jugada forzante fuerte: gana material y da jaque, por lo que el rival debe responder al jaque.|Es un jaque forzante. Calcula todas las escapadas legales del rey, capturas y bloqueos.|Antes de la siguiente jugada, compara los valores intercambiados y verifica que la pieza capturadora esté protegida.|El control central da más espacio y movilidad a tus piezas.|Ahora busca un jaque, una captura o una amenaza directa.''',
  'fr':
      '''Pion|Cavalier|Fou|Tour|Dame|Roi|Pièce|{piece} est allé de {from} à {to}.|{piece} a capturé {target} en {to}.|Coup remarquable : échec avec gain matériel.|Excellent coup : une idée forte.|Bon coup : amélioration utile.|Mauvais coup : la sécurité du roi d’abord.|Coup moyen : jouable, mais cherchez plus de pression.|Le pion gagne de l’espace central et ouvre des lignes pour vos pièces.|Le pion modifie la structure ; vérifiez les cases qu’il protège maintenant.|Le cavalier attaque en L ; examinez ses nouvelles fourchettes et cases protégées.|Le fou ouvre une diagonale ; suivez-la jusqu’au premier obstacle.|La tour agit sur les rangées et colonnes ; cherchez une colonne ouverte ou une pression sur le roi.|La dame menace dans plusieurs directions ; vérifiez qu’elle ne peut pas être chassée.|Le coup du roi modifie sa sécurité ; revérifiez tous les échecs ennemis sur la nouvelle case.|Comparez les échecs, captures et menaces créés par ce coup.|Fort coup forçant : il gagne du matériel et donne échec, donc l’adversaire doit répondre à l’échec.|C’est un échec forçant. Calculez toutes les fuites légales du roi, captures et interpositions.|Avant le prochain coup, comparez les valeurs échangées et vérifiez la protection de la pièce qui capture.|Le contrôle central donne plus d’espace et de mobilité à vos pièces.|Cherchez ensuite un échec, une capture ou une menace directe.''',
  'de':
      '''Bauer|Springer|Läufer|Turm|Dame|König|Figur|{piece} zog von {from} nach {to}.|{piece} schlug {target} auf {to}.|Erstaunlicher Zug: Schach mit Materialgewinn.|Hervorragender Zug: starke Schachidee.|Guter Zug: nützliche Verbesserung.|Kein guter Zug: Königssicherheit zuerst.|Durchschnittlicher Zug: spielbar, aber suche mehr Druck.|Der Bauer gewinnt Raum im Zentrum und öffnet Linien für deine Figuren.|Der Bauer verändert die Struktur; prüfe die nun gedeckten Felder.|Der Springer greift L-förmig an; prüfe neue Gabeln und gedeckte Felder.|Der Läufer öffnet eine Diagonale; verfolge sie bis zum ersten Hindernis.|Der Turm wirkt auf Reihen und Linien; suche eine offene Linie oder Königsdruck.|Die Dame droht in mehreren Richtungen; prüfe, ob sie vertrieben werden kann.|Der Königszug verändert die Sicherheit; prüfe alle gegnerischen Schachs auf dem neuen Feld.|Vergleiche die Schachs, Schläge und Drohungen dieses Zuges.|Starker forcierender Zug: Er gewinnt Material und bietet Schach, weshalb der Gegner das Schach abwehren muss.|Dies ist ein forcierendes Schach. Berechne alle legalen Königsfluchten, Schläge und Zwischenzüge zum Blockieren.|Vergleiche vor dem nächsten Zug die getauschten Figurenwerte und prüfe die Deckung der schlagenden Figur.|Zentrumskontrolle gibt deinen Figuren mehr Raum und Beweglichkeit.|Suche als Nächstes ein Schach, einen Schlag oder eine direkte Drohung.''',
  'it':
      '''Pedone|Cavallo|Alfiere|Torre|Donna|Re|Pezzo|{piece} si è mosso da {from} a {to}.|{piece} ha catturato {target} in {to}.|Mossa sorprendente: scacco con guadagno materiale.|Mossa eccellente: idea forte.|Buona mossa: miglioramento utile.|Mossa non buona: prima la sicurezza del re.|Mossa media: giocabile, ma cerca più pressione.|Il pedone conquista spazio centrale e apre linee per i tuoi pezzi.|Il pedone cambia la struttura; controlla le case che ora protegge.|Il cavallo attacca a L; esamina nuove forchette e case protette.|L’alfiere apre una diagonale; seguila fino al primo ostacolo.|La torre agisce su traverse e colonne; cerca una colonna aperta o pressione sul re.|La donna crea minacce in più direzioni; verifica che non possa essere scacciata.|La mossa del re cambia la sicurezza; ricontrolla ogni scacco nemico sulla nuova casa.|Confronta scacchi, catture e minacce creati dalla mossa.|Forte mossa forzante: guadagna materiale e dà scacco, quindi l’avversario deve rispondere allo scacco.|È uno scacco forzante. Calcola tutte le fughe legali del re, catture e interposizioni.|Prima della prossima mossa confronta i valori scambiati e verifica che il pezzo catturante sia protetto.|Il controllo centrale dà più spazio e mobilità ai pezzi.|Ora cerca uno scacco, una cattura o una minaccia diretta.''',
  'pt':
      '''Peão|Cavalo|Bispo|Torre|Dama|Rei|Peça|{piece} moveu-se de {from} para {to}.|{piece} capturou {target} em {to}.|Lance incrível: xeque com ganho material.|Lance excelente: ideia forte.|Bom lance: melhoria útil.|Lance ruim: segurança do rei primeiro.|Lance médio: jogável, mas procure mais pressão.|O peão conquista espaço central e abre linhas para as peças.|O peão muda a estrutura; verifique as casas que agora protege.|O cavalo ataca em L; examine os novos garfos e casas protegidas.|O bispo abre uma diagonal; siga-a até ao primeiro bloqueio.|A torre atua em filas e colunas; procure uma coluna aberta ou pressão sobre o rei.|A dama cria ameaças em várias direções; verifique que não possa ser perseguida.|O lance do rei altera a segurança; reveja todos os xeques inimigos na nova casa.|Compare xeques, capturas e ameaças criados pelo lance.|Lance forçante forte: ganha material e dá xeque, por isso o adversário deve responder ao xeque.|É um xeque forçante. Calcule todas as fugas legais do rei, capturas e bloqueios.|Antes do próximo lance compare os valores trocados e verifique a proteção da peça que captura.|O controlo central dá mais espaço e mobilidade às peças.|Agora procure um xeque, uma captura ou uma ameaça direta.''',
  'ru':
      '''Пешка|Конь|Слон|Ладья|Ферзь|Король|Фигура|{piece} переместилась с {from} на {to}.|{piece} взяла {target} на {to}.|Прекрасный ход — шах с выигрышем материала.|Отличный ход — сильная шахматная идея.|Хороший ход — полезное улучшение.|Неудачный ход — безопасность короля прежде всего.|Средний ход — допустим, но ищите больше давления.|Пешка занимает пространство в центре и открывает линии для фигур.|Пешка меняет структуру; проверьте поля, которые она теперь защищает.|Конь атакует буквой Г; проверьте новые вилки и защищённые поля.|Слон открывает диагональ; проследите её до первого препятствия.|Ладья действует по горизонталям и вертикалям; ищите открытую линию или давление на короля.|Ферзь создаёт угрозы в разных направлениях; убедитесь, что его нельзя прогнать.|Ход короля меняет его безопасность; проверьте все шахи соперника на новом поле.|Сравните шахи, взятия и угрозы, созданные ходом.|Сильный форсирующий ход: выигрывает материал и даёт шах, поэтому соперник обязан защититься от шаха.|Это форсирующий шах. Рассчитайте все допустимые отходы короля, взятия и перекрытия.|Перед следующим ходом сравните ценность разменянных фигур и проверьте защиту берущей фигуры.|Контроль центра даёт фигурам больше пространства и подвижности.|Теперь ищите шах, взятие или прямую угрозу.''',
  'uk':
      '''Пішак|Кінь|Слон|Тура|Ферзь|Король|Фігура|{piece} перемістилася з {from} на {to}.|{piece} взяла {target} на {to}.|Чудовий хід — шах із виграшем матеріалу.|Відмінний хід — сильна шахова ідея.|Добрий хід — корисне покращення.|Недобрий хід — безпека короля передусім.|Середній хід — можливий, але шукайте більший тиск.|Пішак займає простір у центрі та відкриває лінії для фігур.|Пішак змінює структуру; перевірте поля, які тепер захищає.|Кінь атакує літерою Г; перевірте нові вилки та захищені поля.|Слон відкриває діагональ; простежте до першої перешкоди.|Тура діє по горизонталях і вертикалях; шукайте відкриту лінію або тиск на короля.|Ферзь створює загрози в різних напрямках; перевірте, чи його не можна прогнати.|Хід короля змінює безпеку; перевірте всі шахи суперника на новому полі.|Порівняйте шахи, взяття та загрози цього ходу.|Сильний форсований хід: виграє матеріал і дає шах, тому суперник має відповісти на шах.|Це форсований шах. Розрахуйте всі законні відступи короля, взяття та перекриття.|Перед наступним ходом порівняйте цінність обмінених фігур і захист фігури, що бере.|Контроль центру дає фігурам більше простору та рухливості.|Тепер шукайте шах, взяття або пряму загрозу.''',
  'tr':
      '''Piyon|At|Fil|Kale|Vezir|Şah|Taş|{piece}, {from} karesinden {to} karesine gitti.|{piece}, {to} karesindeki {target} taşını aldı.|Harika hamle — materyal kazancıyla şah.|Mükemmel hamle — güçlü satranç fikri.|İyi hamle — yararlı gelişme.|İyi değil — önce şah güvenliği.|Ortalama hamle — oynanabilir, ama daha çok baskı ara.|Piyon merkezde alan kazanır ve taşların için hatlar açar.|Piyon yapıyı değiştirir; artık koruduğu kareleri kontrol et.|At L biçiminde saldırır; yeni çatalları ve korunan kareleri incele.|Fil bir çapraz açar; ilk engele kadar izle.|Kale yatay ve dikeylerde çalışır; açık hat veya şaha baskı ara.|Vezir birçok yönde tehdit yaratır; kovalanamayacağını doğrula.|Şah hamlesi güvenliği değiştirir; yeni karedeki tüm rakip şahlarını kontrol et.|Hamlenin oluşturduğu şahları, alışları ve tehditleri karşılaştır.|Güçlü zorlayıcı hamle: materyal kazanır ve şah çeker, bu yüzden rakip şahı yanıtlamalıdır.|Bu zorlayıcı bir şahtır. Tüm yasal şah kaçışlarını, alışları ve engellemeleri hesapla.|Sonraki hamleden önce değişilen taş değerlerini ve alan taşın korunduğunu kontrol et.|Merkez kontrolü taşlarına daha çok alan ve hareketlilik verir.|Şimdi şah, alış veya doğrudan tehdit ara.''',
  'fa':
      '''پیاده|اسب|فیل|رخ|وزیر|شاه|مهره|{piece} از {from} به {to} رفت.|{piece} مهره {target} را در {to} گرفت.|حرکت شگفت‌انگیز — کیش همراه با برتری مهره.|حرکت عالی — ایده قوی شطرنج.|حرکت خوب — بهبود مفید.|حرکت خوبی نیست — اول امنیت شاه.|حرکت متوسط — قابل بازی، ولی فشار بیشتری پیدا کنید.|پیاده فضای مرکز را می‌گیرد و خط‌ها را برای مهره‌ها باز می‌کند.|پیاده ساختار را تغییر می‌دهد؛ خانه‌هایی را که اکنون محافظت می‌کند بررسی کنید.|اسب به شکل L حمله می‌کند؛ چنگال‌های تازه و خانه‌های محافظت‌شده را بررسی کنید.|فیل قطر را باز می‌کند؛ تا اولین مانع دنبال کنید.|رخ در ردیف و ستون کار می‌کند؛ ستون باز یا فشار بر شاه را جست‌وجو کنید.|وزیر در چند جهت تهدید می‌سازد؛ مطمئن شوید نمی‌توان آن را راند.|حرکت شاه امنیت را تغییر می‌دهد؛ هر کیش دشمن روی خانه تازه را بررسی کنید.|کیش‌ها، گرفتن‌ها و تهدیدهای ایجادشده را مقایسه کنید.|حرکت اجباری قوی: مهره می‌برد و کیش می‌دهد، پس حریف باید پاسخ کیش را بدهد.|این کیش اجباری است. تمام فرارهای مجاز شاه، گرفتن‌ها و سدکردن‌ها را حساب کنید.|پیش از حرکت بعد ارزش مهره‌های تعویض‌شده و حفاظت مهره گیرنده را بررسی کنید.|کنترل مرکز به مهره‌ها فضای بیشتر و تحرک می‌دهد.|اکنون دنبال کیش، گرفتن یا تهدید مستقیم باشید.''',
  'zh':
      '''兵|马|象|车|后|王|棋子|{piece}从{from}走到{to}。|{piece}在{to}吃掉了{target}。|精彩的一步——得子并将军。|出色的一步——有力的棋路。|好棋——有效改善局面。|这步不好——王的安全第一。|一般的着法——可行，但应寻找更多压力。|兵占据中心空间，为其他棋子打开线路。|兵改变了结构；检查它现在保护的格子。|马以L形攻击；检查新的捉双和受保护的格子。|象打开斜线；沿线检查到第一个阻挡棋子。|车沿横线和直线行动；寻找开放线或对王施压。|后在多个方向制造威胁；确认它不会被赶走。|王的移动改变安全状况；检查新位置上对手所有将军手段。|比较这步棋产生的将军、吃子和威胁。|有力的强制着法：得子并将军，因此对手必须应将。|这是强制将军。计算王的所有合法逃路、吃子和垫子应对。|下一步前，比较交换棋子的价值，并检查吃子方是否受保护。|控制中心让棋子拥有更多空间和机动性。|接下来寻找将军、吃子或直接威胁。''',
  'ja':
      '''ポーン|ナイト|ビショップ|ルーク|クイーン|キング|駒|{piece}が{from}から{to}へ移動しました。|{piece}が{to}で{target}を取りました。|見事な手 — 駒得を伴うチェック。|素晴らしい手 — 強いチェスの構想。|良い手 — 有益な改善。|良くない手 — キングの安全を優先。|普通の手 — 指せますが、さらに圧力を探しましょう。|ポーンが中央のスペースを取り、駒のためのラインを開きます。|ポーンが構造を変えます。新しく守るマスを確認しましょう。|ナイトはL字型に攻撃します。新たなフォークと守るマスを確認しましょう。|ビショップが対角線を開きます。最初の障害物までたどりましょう。|ルークは縦横に働きます。開いたファイルやキングへの圧力を探しましょう。|クイーンが複数方向に脅威を作ります。追い払われないか確認しましょう。|キングの移動で安全性が変わります。新しいマスへの敵の全チェックを再確認しましょう。|この手で生まれるチェック、捕獲、脅威を比較しましょう。|強い強制手です。駒を得てチェックするので、相手はチェックに応じる必要があります。|これは強制的なチェックです。キングの全ての合法な逃げ道、捕獲、合駒を計算しましょう。|次の手の前に交換した駒の価値を比べ、取った駒が守られているか確認しましょう。|中央の支配は駒に空間と機動力を与えます。|次にチェック、捕獲、直接の脅威を探しましょう。''',
  'ko':
      '''폰|나이트|비숍|룩|퀸|킹|기물|{piece}: {from}에서 {to}(으)로 이동했습니다.|{piece}: {to}에서 {target}을 잡았습니다.|놀라운 수 — 기물을 얻으면서 체크.|훌륭한 수 — 강력한 체스 아이디어.|좋은 수 — 유용한 개선.|좋지 않은 수 — 킹의 안전이 먼저입니다.|평범한 수 — 둘 수 있지만 더 많은 압박을 찾으세요.|폰이 중앙 공간을 차지하고 기물들의 길을 엽니다.|폰이 구조를 바꿉니다. 이제 보호하는 칸을 확인하세요.|나이트는 L자로 공격합니다. 새로운 포크와 보호하는 칸을 살피세요.|비숍이 대각선을 엽니다. 첫 장애물까지 살피세요.|룩은 가로세로로 움직입니다. 열린 파일이나 킹에 대한 압박을 찾으세요.|퀸이 여러 방향에 위협을 만듭니다. 쫓겨나지 않는지 확인하세요.|킹의 이동은 안전을 바꿉니다. 새 칸에서 상대의 모든 체크를 다시 확인하세요.|이 수가 만드는 체크, 잡기, 위협을 비교하세요.|강력한 강제 수입니다. 기물을 얻으며 체크하므로 상대는 체크에 대응해야 합니다.|강제 체크입니다. 킹의 모든 합법적 탈출, 잡기, 막는 수를 계산하세요.|다음 수 전에 교환한 기물의 가치를 비교하고 잡은 기물이 보호되는지 확인하세요.|중앙 장악은 기물에 더 많은 공간과 기동성을 줍니다.|이제 체크, 잡기 또는 직접적인 위협을 찾으세요.''',
  'id':
      '''Pion|Kuda|Gajah|Benteng|Menteri|Raja|Buah|{piece} bergerak dari {from} ke {to}.|{piece} menangkap {target} di {to}.|Langkah menakjubkan — skak dengan keuntungan materi.|Langkah hebat — ide catur kuat.|Langkah bagus — perbaikan berguna.|Kurang baik — utamakan keamanan raja.|Langkah biasa — dapat dimainkan, tetapi cari tekanan lebih.|Pion merebut ruang pusat dan membuka jalur bagi buah Anda.|Pion mengubah struktur; periksa petak yang kini dilindunginya.|Kuda menyerang berbentuk L; periksa garpu baru dan petak terlindungi.|Gajah membuka diagonal; telusuri hingga penghalang pertama.|Benteng bekerja pada baris dan lajur; cari lajur terbuka atau tekanan pada raja.|Menteri membuat ancaman berbagai arah; pastikan tidak bisa diusir.|Langkah raja mengubah keamanan; periksa kembali semua skak musuh pada petak baru.|Bandingkan skak, tangkapan, dan ancaman dari langkah ini.|Langkah memaksa yang kuat: menang materi dan memberi skak, sehingga lawan harus menjawab skak.|Ini skak memaksa. Hitung semua pelarian raja, tangkapan, dan penutupan legal.|Sebelum langkah berikut, bandingkan nilai buah yang ditukar dan periksa perlindungan buah penangkap.|Kendali pusat memberi buah ruang dan mobilitas lebih.|Selanjutnya cari skak, tangkapan, atau ancaman langsung.''',
  'ms':
      '''Bidak|Kuda|Gajah|Benteng|Permaisuri|Raja|Buah|{piece} bergerak dari {from} ke {to}.|{piece} menangkap {target} di {to}.|Gerakan menakjubkan — syah dengan keuntungan buah.|Gerakan hebat — idea catur kuat.|Gerakan bagus — penambahbaikan berguna.|Tidak bagus — keselamatan raja dahulu.|Gerakan sederhana — boleh dimainkan, tetapi cari tekanan lebih.|Bidak menguasai ruang tengah dan membuka laluan untuk buah anda.|Bidak mengubah struktur; periksa petak yang kini dilindunginya.|Kuda menyerang berbentuk L; periksa serangan bercabang baharu dan petak dilindungi.|Gajah membuka pepenjuru; jejak hingga penghalang pertama.|Benteng bekerja pada baris dan lajur; cari lajur terbuka atau tekanan pada raja.|Permaisuri mengancam dalam pelbagai arah; pastikan ia tidak boleh dihalau.|Gerakan raja mengubah keselamatan; semak semua syah musuh di petak baharu.|Bandingkan syah, tangkapan dan ancaman yang terhasil.|Gerakan memaksa yang kuat: memenangi buah dan memberi syah, maka lawan mesti menjawab syah.|Ini syah memaksa. Kira semua jalan lari raja, tangkapan dan sekatan sah.|Sebelum gerakan seterusnya, bandingkan nilai buah ditukar dan perlindungan buah penangkap.|Kawalan tengah memberi buah lebih ruang dan pergerakan.|Seterusnya cari syah, tangkapan atau ancaman langsung.''',
  'th':
      '''เบี้ย|ม้า|บิชอป|เรือ|ควีน|คิง|ตัวหมาก|{piece} เดินจาก {from} ไป {to}|{piece} จับ {target} ที่ {to}|ตาที่ยอดเยี่ยม — รุกพร้อมได้ตัวหมาก|ตาที่ยอดเยี่ยม — แนวคิดหมากรุกที่แข็งแกร่ง|ตาที่ดี — ปรับปรุงอย่างมีประโยชน์|ตาที่ไม่ดี — ความปลอดภัยคิงมาก่อน|ตาปานกลาง — เล่นได้ แต่หาความกดดันเพิ่ม|เบี้ยยึดพื้นที่กลางกระดานและเปิดแนวให้ตัวหมาก|เบี้ยเปลี่ยนโครงสร้าง ตรวจช่องที่มันป้องกันอยู่ตอนนี้|ม้าโจมตีเป็นรูป L ตรวจการโจมตีสองเป้าใหม่และช่องที่ป้องกัน|บิชอปเปิดแนวทแยง ไล่ดูจนถึงตัวขวางแรก|เรือทำงานตามแนวนอนและแนวตั้ง หาแนวเปิดหรือแรงกดดันต่อคิง|ควีนสร้างภัยหลายทิศ ตรวจว่าจะไม่ถูกไล่|การเดินคิงเปลี่ยนความปลอดภัย ตรวจทุกการรุกของคู่ต่อสู้ที่ช่องใหม่|เปรียบเทียบการรุก การจับ และภัยที่เกิดจากตานี้|ตาบังคับที่แข็งแกร่ง ได้ตัวหมากและรุกคิง คู่ต่อสู้จึงต้องแก้รุก|นี่คือการรุกบังคับ คำนวณการหนีคิง การจับ และการบังที่ถูกกติกาทั้งหมด|ก่อนตาถัดไป เปรียบเทียบค่าตัวที่แลกและตรวจว่าตัวที่จับมีการป้องกัน|การคุมกลางกระดานเพิ่มพื้นที่และความคล่องตัวของหมาก|ต่อไปหาการรุก การจับ หรือภัยโดยตรง''',
  'vi':
      '''Tốt|Mã|Tượng|Xe|Hậu|Vua|Quân|{piece} đi từ {from} đến {to}.|{piece} bắt {target} ở {to}.|Nước tuyệt vời — chiếu và thắng quân.|Nước xuất sắc — ý tưởng mạnh.|Nước tốt — cải thiện hữu ích.|Nước không tốt — an toàn vua trước tiên.|Nước trung bình — chơi được, nhưng hãy tìm thêm áp lực.|Tốt chiếm không gian trung tâm và mở đường cho quân.|Tốt đổi cấu trúc; kiểm tra các ô nó đang bảo vệ.|Mã tấn công hình chữ L; xem đòn đôi mới và các ô được bảo vệ.|Tượng mở đường chéo; theo đến vật cản đầu tiên.|Xe hoạt động theo hàng và cột; tìm cột mở hoặc áp lực lên vua.|Hậu tạo đe dọa nhiều hướng; kiểm tra nó không bị đuổi.|Nước vua thay đổi an toàn; kiểm tra mọi nước chiếu của địch ở ô mới.|So sánh các nước chiếu, bắt quân và đe dọa tạo ra.|Nước cưỡng bức mạnh: thắng quân và chiếu vua, nên đối thủ phải đáp lại chiếu.|Đây là chiếu cưỡng bức. Tính mọi cách vua thoát, bắt và chắn hợp lệ.|Trước nước tiếp, so giá trị quân trao đổi và kiểm tra quân bắt có được bảo vệ không.|Kiểm soát trung tâm cho quân thêm không gian và cơ động.|Tiếp theo tìm chiếu, bắt quân hoặc đe dọa trực tiếp.''',
  'pl':
      '''Pion|Skoczek|Goniec|Wieża|Hetman|Król|Figura|{piece} przesunęła się z {from} na {to}.|{piece} zbiła {target} na {to}.|Świetny ruch — szach z zyskiem materiału.|Znakomity ruch — silna idea szachowa.|Dobry ruch — przydatna poprawa.|Niedobry ruch — bezpieczeństwo króla najpierw.|Przeciętny ruch — grywalny, ale szukaj większego nacisku.|Pion zajmuje centrum i otwiera linie dla figur.|Pion zmienia strukturę; sprawdź pola, które teraz chroni.|Skoczek atakuje w kształcie L; sprawdź nowe widełki i bronione pola.|Goniec otwiera przekątną; prześledź ją do pierwszej przeszkody.|Wieża działa w rzędach i kolumnach; szukaj otwartej linii lub nacisku na króla.|Hetman tworzy groźby w wielu kierunkach; sprawdź, czy nie można go przepędzić.|Ruch króla zmienia bezpieczeństwo; sprawdź wszystkie szachy wroga na nowym polu.|Porównaj szachy, bicia i groźby tworzone przez ruch.|Silny ruch wymuszający: zyskuje materiał i daje szacha, więc przeciwnik musi odpowiedzieć na szacha.|To wymuszający szach. Oblicz wszystkie legalne ucieczki króla, bicia i zasłony.|Przed następnym ruchem porównaj wartości wymienionych figur i sprawdź ochronę bijącej figury.|Kontrola centrum daje figurom więcej przestrzeni i mobilności.|Teraz szukaj szacha, bicia lub bezpośredniej groźby.''',
  'nl':
      '''Pion|Paard|Loper|Toren|Dame|Koning|Stuk|{piece} ging van {from} naar {to}.|{piece} sloeg {target} op {to}.|Geweldige zet — schaak met materiaalwinst.|Uitstekende zet — sterk schaakidee.|Goede zet — nuttige verbetering.|Geen goede zet — koningsveiligheid eerst.|Gemiddelde zet — speelbaar, maar zoek meer druk.|De pion wint centrumruimte en opent lijnen voor je stukken.|De pion verandert de structuur; bekijk welke velden hij nu dekt.|Het paard valt in L-vorm aan; bekijk nieuwe vorken en gedekte velden.|De loper opent een diagonaal; volg die tot de eerste blokkade.|De toren werkt op rijen en lijnen; zoek een open lijn of druk op de koning.|De dame dreigt in meerdere richtingen; controleer dat ze niet verjaagd kan worden.|De koningszet verandert de veiligheid; controleer alle vijandelijke schaakzetten op het nieuwe veld.|Vergelijk de schaakzetten, slagen en dreigingen van deze zet.|Sterke dwingende zet: wint materiaal en geeft schaak, dus de tegenstander moet het schaak beantwoorden.|Dit is een dwingend schaak. Bereken alle legale vluchtvelden, slagen en blokkades.|Vergelijk vóór de volgende zet de geruilde waarden en controleer de dekking van het slaande stuk.|Centrumcontrole geeft je stukken meer ruimte en mobiliteit.|Zoek nu schaak, een slag of een directe dreiging.''',
  'sv':
      '''Bonde|Springare|Löpare|Torn|Dam|Kung|Pjäs|{piece} flyttade från {from} till {to}.|{piece} slog {target} på {to}.|Fantastiskt drag — schack med materialvinst.|Utmärkt drag — stark schackidé.|Bra drag — nyttig förbättring.|Inte bra — kungens säkerhet först.|Medelmåttigt drag — spelbart, men sök mer press.|Bonden tar central terräng och öppnar linjer för pjäserna.|Bonden ändrar strukturen; kontrollera rutorna den nu skyddar.|Springaren angriper i L-form; granska nya gafflar och skyddade rutor.|Löparen öppnar en diagonal; följ den till första hindret.|Tornet verkar på rader och linjer; sök en öppen linje eller press mot kungen.|Damen skapar hot i flera riktningar; kontrollera att den inte kan jagas bort.|Kungsdraget ändrar säkerheten; granska alla fiendeschack på den nya rutan.|Jämför schackar, slag och hot som draget skapar.|Starkt tvingande drag: vinner material och schackar, så motståndaren måste besvara schacken.|Det är en tvingande schack. Beräkna alla lagliga kungsflykter, slag och blockeringar.|Jämför utbytta pjäsers värden och kontrollera att den slående pjäsen är skyddad före nästa drag.|Centrumkontroll ger pjäserna mer utrymme och rörlighet.|Sök nu en schack, ett slag eller ett direkt hot.''',
  'el':
      '''Πιόνι|Ίππος|Αξιωματικός|Πύργος|Βασίλισσα|Βασιλιάς|Κομμάτι|{piece}: μετακινήθηκε από {from} στο {to}.|{piece}: έπιασε {target} στο {to}.|Εκπληκτική κίνηση — σαχ με κέρδος υλικού.|Εξαιρετική κίνηση — ισχυρή σκακιστική ιδέα.|Καλή κίνηση — χρήσιμη βελτίωση.|Όχι καλή κίνηση — πρώτα η ασφάλεια του βασιλιά.|Μέτρια κίνηση — παίζεται, αλλά αναζητήστε περισσότερη πίεση.|Το πιόνι κερδίζει χώρο στο κέντρο και ανοίγει γραμμές για τα κομμάτια.|Το πιόνι αλλάζει τη δομή· ελέγξτε τα τετράγωνα που τώρα προστατεύει.|Ο ίππος επιτίθεται σε σχήμα L· εξετάστε νέα πιρούνια και προστατευμένα τετράγωνα.|Ο αξιωματικός ανοίγει διαγώνιο· ακολουθήστε την μέχρι το πρώτο εμπόδιο.|Ο πύργος δρα σε γραμμές και στήλες· αναζητήστε ανοιχτή στήλη ή πίεση στον βασιλιά.|Η βασίλισσα απειλεί σε πολλές κατευθύνσεις· ελέγξτε ότι δεν μπορεί να εκδιωχθεί.|Η κίνηση του βασιλιά αλλάζει την ασφάλεια· ελέγξτε κάθε εχθρικό σαχ στο νέο τετράγωνο.|Συγκρίνετε τα σαχ, τα χτυπήματα και τις απειλές της κίνησης.|Ισχυρή αναγκαστική κίνηση: κερδίζει υλικό και δίνει σαχ, οπότε ο αντίπαλος πρέπει να απαντήσει στο σαχ.|Αυτό είναι αναγκαστικό σαχ. Υπολογίστε κάθε νόμιμη διαφυγή, χτύπημα και παρεμβολή.|Πριν την επόμενη κίνηση συγκρίνετε τις αξίες ανταλλαγής και ελέγξτε την προστασία του κομματιού που έπιασε.|Ο έλεγχος του κέντρου δίνει περισσότερο χώρο και κινητικότητα.|Τώρα αναζητήστε σαχ, χτύπημα ή άμεση απειλή.''',
  'he':
      '''רגלי|פרש|רץ|צריח|מלכה|מלך|כלי|{piece} עבר מ־{from} ל־{to}.|{piece} הכה {target} ב־{to}.|מסע מדהים — שח עם רווח חומרי.|מסע מצוין — רעיון שחמט חזק.|מסע טוב — שיפור מועיל.|מסע לא טוב — בטיחות המלך תחילה.|מסע ממוצע — אפשרי, אך חפשו יותר לחץ.|הרגלי תופס מרחב במרכז ופותח קווים לכלים.|הרגלי משנה את המבנה; בדקו את המשבצות שהוא מגן עליהן כעת.|הפרש תוקף בצורת L; בדקו מזלגות חדשים ומשבצות מוגנות.|הרץ פותח אלכסון; עקבו עד לחוסם הראשון.|הצריח פועל בשורות וטורים; חפשו טור פתוח או לחץ על המלך.|המלכה יוצרת איומים בכמה כיוונים; ודאו שאי אפשר לגרש אותה.|מסע המלך משנה את בטיחותו; בדקו כל שח של היריב במשבצת החדשה.|השוו את השחים, ההכאות והאיומים שהמסע יוצר.|מסע כפוי חזק: זוכה בחומר ונותן שח, לכן היריב חייב לענות לשח.|זהו שח כפוי. חשבו כל בריחת מלך חוקית, הכאה וחסימה.|לפני המסע הבא השוו את ערכי הכלים שהוחלפו ובדקו שהכלי המכה מוגן.|שליטה במרכז נותנת לכלים יותר מרחב וניידות.|כעת חפשו שח, הכאה או איום ישיר.''',
  'sw':
      '''Askari|Farasi|Askofu|Ngome|Malkia|Mfalme|Kete|{piece} imetoka {from} kwenda {to}.|{piece} imekamata {target} kwenye {to}.|Hatua ya ajabu — shaha pamoja na faida ya kete.|Hatua bora — wazo imara la sataranji.|Hatua nzuri — uboreshaji muhimu.|Si hatua nzuri — usalama wa mfalme kwanza.|Hatua ya wastani — inachezeka, lakini tafuta shinikizo zaidi.|Askari anachukua nafasi ya katikati na kufungua njia za kete zako.|Askari anabadilisha muundo; kagua visanduku anavyolinda sasa.|Farasi anashambulia kwa umbo la L; kagua mashambulizi mapya mawili na visanduku salama.|Askofu anafungua ulalo; ufuate hadi kizuizi cha kwanza.|Ngome hufanya kazi kwenye safu; tafuta safu wazi au shinikizo kwa mfalme.|Malkia anatishia pande nyingi; hakikisha hawezi kufukuzwa.|Hatua ya mfalme hubadilisha usalama; kagua kila shaha ya adui kwenye kisanduku kipya.|Linganisha shaha, ukamataji na vitisho vya hatua hii.|Hatua yenye kulazimisha: inapata kete na kutoa shaha, hivyo mpinzani lazima ajibu shaha.|Hii ni shaha ya kulazimisha. Hesabu njia zote halali za mfalme kutoroka, kukamata na kuzuia.|Kabla ya hatua inayofuata linganisha thamani za kete zilizobadilishwa na ulinzi wa kete iliyokamata.|Udhibiti wa katikati huwapa kete nafasi na uwezo zaidi wa kusonga.|Sasa tafuta shaha, ukamataji au tishio la moja kwa moja.''',
};

const liveHintKeys = [
  'simple1',
  'advanced1',
  'simple2',
  'advanced2',
  'simple3',
  'advanced3',
  'kingSide',
  'queenSide',
  'discovered',
  'castle',
  'mate',
  'wins',
  'stalemate'
];
final Map<String, List<String>> liveHintTranslations = {
  for (final e in _hintRows.entries) e.key: e.value.split('|')
};
String? _translateHint(String value, String code) {
  String t(String key, [Map<String, String> args = const {}]) =>
      _fill(liveHintTranslations[code]![liveHintKeys.indexOf(key)], args);
  var m = RegExp(r'^Hint 1/3 • Start with the (\w+) on ([a-h][1-8])\.$')
      .firstMatch(value);
  if (m != null) {
    return t('simple1', {'piece': _piece(m[1]!, code), 'from': m[2]!});
  }
  m = RegExp(
          r'^Piece hint 1/3 • Candidate: (\w+) on ([a-h][1-8])\. Check its forcing options\.$')
      .firstMatch(value);
  if (m != null) {
    return t('advanced1', {'piece': _piece(m[1]!, code), 'from': m[2]!});
  }
  m = RegExp(
          r'^(Hint 2/3 • Move that|Direction hint 2/3 • Improve the) (\w+) toward the (king|queen) side(?: and challenge the centre)?\.$')
      .firstMatch(value);
  if (m != null) {
    return t(m[1]!.startsWith('Hint') ? 'simple2' : 'advanced2', {
      'piece': _piece(m[2]!, code),
      'direction': t(m[3] == 'king' ? 'kingSide' : 'queenSide')
    });
  }
  m = RegExp(
          r'^(Hint 3/3 • Try|Exact move 3/3 • Calculate) ([a-h][1-8]) → ([a-h][1-8])\. (.*)$',
          dotAll: true)
      .firstMatch(value);
  if (m != null) {
    return t(m[1]!.startsWith('Hint') ? 'simple3' : 'advanced3', {
      'from': m[2]!,
      'to': m[3]!,
      'explanation': localizeLiveCoach(m[4]!, code)
    });
  }
  m = RegExp(
          r'^Discovered check: moving the (\w+) opened the (\w+) attack from ([a-h][1-8]) onto the king at ([a-h][1-8])\. The opponent must answer that revealed check\.$')
      .firstMatch(value);
  if (m != null) {
    return t('discovered', {
      'piece': _piece(m[1]!, code),
      'attacker': _piece(m[2]!, code),
      'from': m[3]!,
      'king': m[4]!
    });
  }
  m = RegExp(r'^(White|Black) castles (king|queen) side\.$').firstMatch(value);
  if (m != null) {
    return t('castle', {
      'side': CoachLocalizations(code).source(m[1]!),
      'direction': t(m[2] == 'king' ? 'kingSide' : 'queenSide')
    });
  }
  if (value == 'Checkmate' || value == 'Checkmate.') return t('mate');
  m = RegExp(r'^(White|Black) wins\.?$').firstMatch(value);
  if (m != null) {
    return t('wins', {'side': CoachLocalizations(code).source(m[1]!)});
  }
  m = RegExp(r'^Stalemate\. No legal move for (White|Black)\.$')
      .firstMatch(value);
  if (m != null) {
    return t('stalemate', {'side': CoachLocalizations(code).source(m[1]!)});
  }
  return null;
}

const _hintRows = <String, String>{
  'en':
      '''Hint 1/3 • Start with the {piece} on {from}.|Piece hint 1/3 • Candidate: {piece} on {from}. Check its forcing options.|Hint 2/3 • Move that {piece} {direction}.|Direction hint 2/3 • Improve the {piece} {direction} and challenge the centre.|Hint 3/3 • Try {from} → {to}. {explanation}|Exact move 3/3 • Calculate {from} → {to}. {explanation}|toward the king side|toward the queen side|Discovered check: moving the {piece} opened the {attacker} attack from {from} onto the king at {king}. The opponent must answer that revealed check.|{side} castles {direction}.|Checkmate.|{side} wins.|Stalemate. No legal move for {side}.''',
  'te':
      '''సూచన 1/3 • {from}లోని {piece}తో ప్రారంభించండి.|పావు సూచన 1/3 • అవకాశం: {from}లోని {piece}. బలవంతపు ఎత్తులను పరిశీలించండి.|సూచన 2/3 • {piece}ను {direction} కదపండి.|దిశ సూచన 2/3 • {piece}ను {direction} మెరుగుపరచి కేంద్రానికి పోటీ ఇవ్వండి.|సూచన 3/3 • {from} → {to} ప్రయత్నించండి. {explanation}|ఖచ్చితమైన ఎత్తు 3/3 • {from} → {to} లెక్కించండి. {explanation}|రాజు వైపు|రాణి వైపు|వెలికితీసిన చెక్: {piece} కదలడం వల్ల {from}లోని {attacker}, {king}లోని రాజుపై దాడి తెరుచుకుంది. ప్రత్యర్థి ఈ చెక్‌కు సమాధానం ఇవ్వాలి.|{side}: {direction} క్యాస్లింగ్.|చెక్‌మేట్.|{side} గెలిచారు.|స్టేల్‌మేట్. {side}కు చట్టబద్ధమైన ఎత్తు లేదు.''',
  'hi':
      '''संकेत 1/3 • {from} पर {piece} से शुरू करें।|मोहरे का संकेत 1/3 • विकल्प: {from} पर {piece}। इसकी बाध्यकारी चालें देखें।|संकेत 2/3 • {piece} को {direction} चलाएँ।|दिशा संकेत 2/3 • {piece} को {direction} बेहतर करें और केंद्र को चुनौती दें।|संकेत 3/3 • {from} → {to} आज़माएँ। {explanation}|सटीक चाल 3/3 • {from} → {to} की गणना करें। {explanation}|राजा की ओर|वज़ीर की ओर|खुली शह: {piece} के हटने से {from} के {attacker} का हमला {king} के राजा पर खुला। प्रतिद्वंद्वी को इस शह का उत्तर देना होगा।|{side}: {direction} कैसलिंग।|शह-मात।|{side} जीते।|गतिरोध। {side} की कोई वैध चाल नहीं।''',
  'ta':
      '''குறிப்பு 1/3 • {from} இல் உள்ள {piece} உடன் தொடங்குங்கள்.|காய் குறிப்பு 1/3 • வாய்ப்பு: {from} இல் {piece}. அதன் கட்டாய நகர்வுகளைப் பாருங்கள்.|குறிப்பு 2/3 • {piece} ஐ {direction} நகர்த்துங்கள்.|திசைக் குறிப்பு 2/3 • {piece} ஐ {direction} மேம்படுத்தி மையத்துக்குப் போட்டியிடுங்கள்.|குறிப்பு 3/3 • {from} → {to} முயலுங்கள். {explanation}|சரியான நகர்வு 3/3 • {from} → {to} கணக்கிடுங்கள். {explanation}|ராஜா பக்கம்|ராணி பக்கம்|திறந்த செக்: {piece} நகர்ந்ததால் {from} இல் உள்ள {attacker} இன் தாக்குதல் {king} இல் உள்ள ராஜாவுக்குத் திறந்தது. எதிரி இந்த செக்கிற்குப் பதிலளிக்க வேண்டும்.|{side}: {direction} காஸ்லிங்.|செக்மேட்.|{side} வெற்றி.|ஸ்டேல்மேட். {side} க்கு சட்டபூர்வ நகர்வு இல்லை.''',
  'kn':
      '''ಸುಳಿವು 1/3 • {from} ನಲ್ಲಿರುವ {piece} ನಿಂದ ಪ್ರಾರಂಭಿಸಿ.|ಕಾಯಿ ಸುಳಿವು 1/3 • ಆಯ್ಕೆ: {from} ನಲ್ಲಿರುವ {piece}. ಬಲವಂತದ ನಡೆಗಳನ್ನು ನೋಡಿ.|ಸುಳಿವು 2/3 • {piece} ಅನ್ನು {direction} ಚಲಿಸಿ.|ದಿಕ್ಕಿನ ಸುಳಿವು 2/3 • {piece} ಅನ್ನು {direction} ಸುಧಾರಿಸಿ ಕೇಂದ್ರಕ್ಕೆ ಸ್ಪರ್ಧಿಸಿ.|ಸುಳಿವು 3/3 • {from} → {to} ಪ್ರಯತ್ನಿಸಿ. {explanation}|ನಿಖರ ನಡೆ 3/3 • {from} → {to} ಲೆಕ್ಕಿಸಿ. {explanation}|ರಾಜನ ಕಡೆಗೆ|ರಾಣಿಯ ಕಡೆಗೆ|ತೆರೆದ ಚೆಕ್: {piece} ಚಲಿಸಿದ್ದರಿಂದ {from} ನಲ್ಲಿನ {attacker} ದಾಳಿ {king} ನಲ್ಲಿನ ರಾಜನ ಮೇಲೆ ತೆರೆಯಿತು. ಎದುರಾಳಿ ಈ ಚೆಕ್‌ಗೆ ಉತ್ತರಿಸಬೇಕು.|{side}: {direction} ಕ್ಯಾಸ್ಲಿಂಗ್.|ಚೆಕ್‌ಮೇಟ್.|{side} ಗೆದ್ದರು.|ಸ್ಟೇಲ್‌ಮೇಟ್. {side} ಗೆ ಕಾನೂನುಬದ್ಧ ನಡೆಯಿಲ್ಲ.''',
  'ml':
      '''സൂചന 1/3 • {from} ലെ {piece} ഉപയോഗിച്ച് തുടങ്ങുക.|കരു സൂചന 1/3 • സാധ്യത: {from} ലെ {piece}. നിർബന്ധിത നീക്കങ്ങൾ പരിശോധിക്കുക.|സൂചന 2/3 • {piece} നെ {direction} നീക്കുക.|ദിശാ സൂചന 2/3 • {piece} നെ {direction} മെച്ചപ്പെടുത്തി മധ്യത്തിനായി പോരാടുക.|സൂചന 3/3 • {from} → {to} പരീക്ഷിക്കുക. {explanation}|കൃത്യ നീക്കം 3/3 • {from} → {to} കണക്കാക്കുക. {explanation}|രാജാവിന്റെ വശത്തേക്ക്|മന്ത്രിയുടെ വശത്തേക്ക്|തുറന്ന ചെക്ക്: {piece} നീങ്ങിയപ്പോൾ {from} ലെ {attacker} ന്റെ ആക്രമണം {king} ലെ രാജാവിനുനേരെ തുറന്നു. എതിരാളി ഈ ചെക്കിന് മറുപടി നൽകണം.|{side}: {direction} കാസ്ലിങ്.|ചെക്ക്മേറ്റ്.|{side} ജയിച്ചു.|സ്റ്റേൽമേറ്റ്. {side} ന് നിയമാനുസൃത നീക്കമില്ല.''',
  'mr':
      '''संकेत 1/3 • {from} वरील {piece} पासून सुरू करा.|मोहऱ्याचा संकेत 1/3 • पर्याय: {from} वरील {piece}. सक्तीच्या चाली तपासा.|संकेत 2/3 • {piece} ला {direction} हलवा.|दिशा संकेत 2/3 • {piece} ला {direction} सुधारून केंद्राला आव्हान द्या.|संकेत 3/3 • {from} → {to} करून पाहा. {explanation}|अचूक चाल 3/3 • {from} → {to} मोजा. {explanation}|राजाच्या बाजूला|वजीराच्या बाजूला|उघडा शह: {piece} हलल्यामुळे {from} वरील {attacker} चा हल्ला {king} वरील राजावर खुला झाला. विरोधकाने या शहला उत्तर द्यावे.|{side}: {direction} कॅसलिंग.|शह-मात.|{side} जिंकले.|कोंडी. {side} साठी वैध चाल नाही.''',
  'bn':
      '''ইঙ্গিত 1/3 • {from}-এর {piece} দিয়ে শুরু করুন।|ঘুঁটির ইঙ্গিত 1/3 • বিকল্প: {from}-এর {piece}। বাধ্যকারী চালগুলি দেখুন।|ইঙ্গিত 2/3 • {piece} কে {direction} চালান।|দিকের ইঙ্গিত 2/3 • {piece} কে {direction} উন্নত করে কেন্দ্রকে চ্যালেঞ্জ করুন।|ইঙ্গিত 3/3 • {from} → {to} চেষ্টা করুন। {explanation}|সঠিক চাল 3/3 • {from} → {to} গণনা করুন। {explanation}|রাজার দিকে|মন্ত্রীর দিকে|উন্মুক্ত কিস্তি: {piece} সরায় {from}-এর {attacker}-এর আক্রমণ {king}-এর রাজার দিকে খুলেছে। প্রতিপক্ষকে এই কিস্তির উত্তর দিতে হবে।|{side}: {direction} ক্যাসলিং।|কিস্তিমাত।|{side} জয়ী।|অচলাবস্থা। {side}-এর বৈধ চাল নেই।''',
  'gu':
      '''સંકેત 1/3 • {from} પરના {piece} થી શરૂ કરો.|મહોરાનો સંકેત 1/3 • વિકલ્પ: {from} પર {piece}. ફરજિયાત ચાલ તપાસો.|સંકેત 2/3 • {piece} ને {direction} ખસેડો.|દિશા સંકેત 2/3 • {piece} ને {direction} સુધારી કેન્દ્રને પડકારો.|સંકેત 3/3 • {from} → {to} અજમાવો. {explanation}|ચોક્કસ ચાલ 3/3 • {from} → {to} ગણો. {explanation}|રાજાની તરફ|વજીરની તરફ|ખુલ્લી શાહ: {piece} ખસતાં {from} પરના {attacker} નો હુમલો {king} ના રાજા તરફ ખુલ્યો. વિરોધીએ આ શાહનો જવાબ આપવો પડશે.|{side}: {direction} કેસલિંગ.|શાહમાત.|{side} જીત્યા.|ગતિરોધ. {side} ની કાયદેસર ચાલ નથી.''',
  'pa':
      '''ਸੰਕੇਤ 1/3 • {from} ਦੇ {piece} ਨਾਲ ਸ਼ੁਰੂ ਕਰੋ।|ਮੋਹਰੇ ਦਾ ਸੰਕੇਤ 1/3 • ਵਿਕਲਪ: {from} ਉੱਤੇ {piece}। ਮਜਬੂਰ ਕਰਨ ਵਾਲੀਆਂ ਚਾਲਾਂ ਵੇਖੋ।|ਸੰਕੇਤ 2/3 • {piece} ਨੂੰ {direction} ਚਲਾਓ।|ਦਿਸ਼ਾ ਸੰਕੇਤ 2/3 • {piece} ਨੂੰ {direction} ਸੁਧਾਰ ਕੇ ਕੇਂਦਰ ਨੂੰ ਚੁਣੌਤੀ ਦਿਓ।|ਸੰਕੇਤ 3/3 • {from} → {to} ਅਜ਼ਮਾਓ। {explanation}|ਸਹੀ ਚਾਲ 3/3 • {from} → {to} ਗਿਣੋ। {explanation}|ਰਾਜੇ ਵੱਲ|ਵਜ਼ੀਰ ਵੱਲ|ਖੁੱਲ੍ਹੀ ਸ਼ਹ: {piece} ਦੇ ਹਟਣ ਨਾਲ {from} ਦੇ {attacker} ਦਾ ਹਮਲਾ {king} ਦੇ ਰਾਜੇ ਉੱਤੇ ਖੁੱਲ੍ਹਿਆ। ਵਿਰੋਧੀ ਨੂੰ ਇਸ ਸ਼ਹ ਦਾ ਜਵਾਬ ਦੇਣਾ ਪਵੇਗਾ।|{side}: {direction} ਕੈਸਲਿੰਗ।|ਸ਼ਹ-ਮਾਤ।|{side} ਜਿੱਤੇ।|ਖੜੋਤ। {side} ਲਈ ਜਾਇਜ਼ ਚਾਲ ਨਹੀਂ।''',
  'ur':
      '''اشارہ 1/3 • {from} پر {piece} سے شروع کریں۔|مہرے کا اشارہ 1/3 • انتخاب: {from} پر {piece}۔ جبری چالیں دیکھیں۔|اشارہ 2/3 • {piece} کو {direction} چلیں۔|سمت کا اشارہ 2/3 • {piece} کو {direction} بہتر کریں اور مرکز کو چیلنج کریں۔|اشارہ 3/3 • {from} → {to} آزمائیں۔ {explanation}|درست چال 3/3 • {from} → {to} حساب کریں۔ {explanation}|بادشاہ کی طرف|وزیر کی طرف|کھلی شہ: {piece} ہٹنے سے {from} کے {attacker} کا حملہ {king} کے بادشاہ پر کھلا۔ حریف کو اس شہ کا جواب دینا ہوگا۔|{side}: {direction} کیسلنگ۔|شہ مات۔|{side} جیتے۔|بندش۔ {side} کی کوئی جائز چال نہیں۔''',
  'ar':
      '''تلميح 1/3 • ابدأ بالقطعة {piece} على {from}.|تلميح القطعة 1/3 • مرشح: {piece} على {from}. افحص خياراتها الإجبارية.|تلميح 2/3 • حرّك {piece} {direction}.|تلميح الاتجاه 2/3 • حسّن {piece} {direction} ونافس على المركز.|تلميح 3/3 • جرّب {from} → {to}. {explanation}|النقلة الدقيقة 3/3 • احسب {from} → {to}. {explanation}|نحو جناح الملك|نحو جناح الوزير|كش مكتشف: تحريك {piece} فتح هجوم {attacker} من {from} على الملك في {king}. يجب على الخصم الرد على هذا الكش.|{side}: تبييت {direction}.|كش مات.|فاز {side}.|تعادل بالخنق. لا نقلة قانونية لـ{side}.''',
  'es':
      '''Pista 1/3 • Empieza con {piece} en {from}.|Pista de pieza 1/3 • Candidata: {piece} en {from}. Revisa sus opciones forzantes.|Pista 2/3 • Mueve {piece} {direction}.|Pista de dirección 2/3 • Mejora {piece} {direction} y disputa el centro.|Pista 3/3 • Prueba {from} → {to}. {explanation}|Jugada exacta 3/3 • Calcula {from} → {to}. {explanation}|hacia el flanco de rey|hacia el flanco de dama|Jaque descubierto: mover {piece} abrió el ataque de {attacker} desde {from} al rey en {king}. El rival debe responder al jaque descubierto.|{side} enrocan {direction}.|Jaque mate.|Ganan {side}.|Ahogado. No hay jugada legal para {side}.''',
  'fr':
      '''Indice 1/3 • Commencez avec {piece} en {from}.|Indice de pièce 1/3 • Candidate : {piece} en {from}. Vérifiez ses options forçantes.|Indice 2/3 • Déplacez {piece} {direction}.|Indice de direction 2/3 • Améliorez {piece} {direction} et disputez le centre.|Indice 3/3 • Essayez {from} → {to}. {explanation}|Coup exact 3/3 • Calculez {from} → {to}. {explanation}|vers l’aile roi|vers l’aile dame|Échec à la découverte : déplacer {piece} a ouvert l’attaque de {attacker} depuis {from} sur le roi en {king}. L’adversaire doit répondre à cet échec.|{side} roquent {direction}.|Échec et mat.|{side} gagnent.|Pat. Aucun coup légal pour {side}.''',
  'de':
      '''Hinweis 1/3 • Beginne mit {piece} auf {from}.|Figurenhinweis 1/3 • Kandidat: {piece} auf {from}. Prüfe forcierende Möglichkeiten.|Hinweis 2/3 • Ziehe {piece} {direction}.|Richtungshinweis 2/3 • Verbessere {piece} {direction} und kämpfe ums Zentrum.|Hinweis 3/3 • Versuche {from} → {to}. {explanation}|Genauer Zug 3/3 • Berechne {from} → {to}. {explanation}|zum Königsflügel|zum Damenflügel|Abzugsschach: Der Zug mit {piece} öffnete den Angriff von {attacker} auf {from} gegen den König auf {king}. Der Gegner muss dieses Schach abwehren.|{side} rochiert {direction}.|Schachmatt.|{side} gewinnt.|Patt. Kein legaler Zug für {side}.''',
  'it':
      '''Indizio 1/3 • Inizia con {piece} in {from}.|Indizio sul pezzo 1/3 • Candidato: {piece} in {from}. Controlla le opzioni forzanti.|Indizio 2/3 • Muovi {piece} {direction}.|Indizio direzionale 2/3 • Migliora {piece} {direction} e contesta il centro.|Indizio 3/3 • Prova {from} → {to}. {explanation}|Mossa esatta 3/3 • Calcola {from} → {to}. {explanation}|verso il lato di re|verso il lato di donna|Scacco di scoperta: muovere {piece} ha aperto l’attacco di {attacker} da {from} al re in {king}. L’avversario deve rispondere allo scacco.|{side} arrocca {direction}.|Scacco matto.|Vince {side}.|Stallo. Nessuna mossa legale per {side}.''',
  'pt':
      '''Dica 1/3 • Comece com {piece} em {from}.|Dica de peça 1/3 • Candidata: {piece} em {from}. Verifique as opções forçantes.|Dica 2/3 • Mova {piece} {direction}.|Dica de direção 2/3 • Melhore {piece} {direction} e dispute o centro.|Dica 3/3 • Tente {from} → {to}. {explanation}|Lance exato 3/3 • Calcule {from} → {to}. {explanation}|para o flanco do rei|para o flanco da dama|Xeque descoberto: mover {piece} abriu o ataque de {attacker} de {from} ao rei em {king}. O adversário deve responder a esse xeque.|{side} faz roque {direction}.|Xeque-mate.|{side} vence.|Afogamento. Nenhum lance legal para {side}.''',
  'ru':
      '''Подсказка 1/3 • Начните с {piece} на {from}.|Подсказка фигуры 1/3 • Кандидат: {piece} на {from}. Проверьте форсирующие возможности.|Подсказка 2/3 • Переместите {piece} {direction}.|Подсказка направления 2/3 • Улучшите {piece} {direction} и боритесь за центр.|Подсказка 3/3 • Попробуйте {from} → {to}. {explanation}|Точный ход 3/3 • Рассчитайте {from} → {to}. {explanation}|к королевскому флангу|к ферзевому флангу|Вскрытый шах: ход {piece} открыл атаку {attacker} с {from} на короля на {king}. Соперник обязан ответить на этот шах.|{side}: рокировка {direction}.|Мат.|{side} выигрывают.|Пат. У стороны {side} нет допустимого хода.''',
  'uk':
      '''Підказка 1/3 • Почніть з {piece} на {from}.|Підказка фігури 1/3 • Кандидат: {piece} на {from}. Перевірте форсовані можливості.|Підказка 2/3 • Перемістіть {piece} {direction}.|Підказка напрямку 2/3 • Покращте {piece} {direction} і боріться за центр.|Підказка 3/3 • Спробуйте {from} → {to}. {explanation}|Точний хід 3/3 • Розрахуйте {from} → {to}. {explanation}|до королівського флангу|до ферзевого флангу|Відкритий шах: хід {piece} відкрив атаку {attacker} з {from} на короля на {king}. Суперник має відповісти на цей шах.|{side}: рокіровка {direction}.|Мат.|{side} перемагають.|Пат. У сторони {side} немає допустимого ходу.''',
  'tr':
      '''İpucu 1/3 • {from} üzerindeki {piece} ile başla.|Taş ipucu 1/3 • Aday: {from} üzerinde {piece}. Zorlayıcı seçeneklerini kontrol et.|İpucu 2/3 • {piece} taşını {direction} ilerlet.|Yön ipucu 2/3 • {piece} taşını {direction} geliştir ve merkezi zorla.|İpucu 3/3 • {from} → {to} dene. {explanation}|Kesin hamle 3/3 • {from} → {to} hesapla. {explanation}|şah kanadına doğru|vezir kanadına doğru|Açmaz şahı: {piece} hareketi {from} üzerindeki {attacker} saldırısını {king} üzerindeki şaha açtı. Rakip bu açılan şahı yanıtlamalı.|{side}: {direction} rok.|Şah mat.|{side} kazandı.|Pat. {side} için yasal hamle yok.''',
  'fa':
      '''راهنمایی 1/3 • با {piece} در {from} شروع کنید.|راهنمای مهره 1/3 • گزینه: {piece} در {from}. حرکت‌های اجباری را بررسی کنید.|راهنمایی 2/3 • {piece} را {direction} حرکت دهید.|راهنمای جهت 2/3 • {piece} را {direction} بهتر کرده و برای مرکز بجنگید.|راهنمایی 3/3 • {from} → {to} را امتحان کنید. {explanation}|حرکت دقیق 3/3 • {from} → {to} را حساب کنید. {explanation}|به سوی جناح شاه|به سوی جناح وزیر|کیش برخاست: حرکت {piece} حمله {attacker} از {from} به شاه در {king} را باز کرد. حریف باید این کیش آشکارشده را پاسخ دهد.|{side}: قلعه {direction}.|کیش‌ومات.|{side} برنده شد.|پات. برای {side} حرکت مجازی نیست.''',
  'zh':
      '''提示1/3 • 从{from}的{piece}开始。|棋子提示1/3 • 候选：{from}的{piece}。检查它的强制着法。|提示2/3 • 将{piece}走向{direction}。|方向提示2/3 • 向{direction}改善{piece}的位置并争夺中心。|提示3/3 • 试试{from} → {to}。{explanation}|精确着法3/3 • 计算{from} → {to}。{explanation}|王翼|后翼|闪将：移动{piece}使{from}的{attacker}对{king}的王打开攻击。对手必须应对这个闪将。|{side}向{direction}王车易位。|将死。|{side}获胜。|逼和。{side}没有合法着法。''',
  'ja':
      '''ヒント1/3 • {from}の{piece}から始めましょう。|駒のヒント1/3 • 候補：{from}の{piece}。強制的な手を確認しましょう。|ヒント2/3 • {piece}を{direction}動かしましょう。|方向ヒント2/3 • {piece}を{direction}改善して中央を争いましょう。|ヒント3/3 • {from} → {to}を試しましょう。{explanation}|正確な手3/3 • {from} → {to}を計算しましょう。{explanation}|キング側へ|クイーン側へ|ディスカバードチェック：{piece}を動かすと、{from}の{attacker}から{king}のキングへの攻撃が開きました。相手はこのチェックに応じなければなりません。|{side}が{direction}キャスリングしました。|チェックメイト。|{side}の勝ち。|ステイルメイト。{side}に合法手がありません。''',
  'ko':
      '''힌트 1/3 • {from}의 {piece}부터 시작하세요.|기물 힌트 1/3 • 후보: {from}의 {piece}. 강제적인 선택지를 확인하세요.|힌트 2/3 • {piece}을 {direction} 이동하세요.|방향 힌트 2/3 • {piece}을 {direction} 개선하고 중앙을 다투세요.|힌트 3/3 • {from} → {to}를 시도하세요. {explanation}|정확한 수 3/3 • {from} → {to}를 계산하세요. {explanation}|킹 쪽으로|퀸 쪽으로|디스커버드 체크: {piece}을 옮겨 {from}의 {attacker}이 {king}의 킹을 공격하게 되었습니다. 상대는 이 체크에 대응해야 합니다.|{side}: {direction} 캐슬링.|체크메이트.|{side} 승리.|스테일메이트. {side}에 합법적인 수가 없습니다.''',
  'id':
      '''Petunjuk 1/3 • Mulai dengan {piece} di {from}.|Petunjuk buah 1/3 • Kandidat: {piece} di {from}. Periksa pilihan memaksanya.|Petunjuk 2/3 • Gerakkan {piece} {direction}.|Petunjuk arah 2/3 • Perbaiki {piece} {direction} dan perebutkan pusat.|Petunjuk 3/3 • Coba {from} → {to}. {explanation}|Langkah tepat 3/3 • Hitung {from} → {to}. {explanation}|ke sisi raja|ke sisi menteri|Skak terbuka: memindahkan {piece} membuka serangan {attacker} dari {from} ke raja di {king}. Lawan harus menjawab skak terbuka itu.|{side} rokade {direction}.|Skakmat.|{side} menang.|Pat. Tidak ada langkah legal untuk {side}.''',
  'ms':
      '''Petunjuk 1/3 • Mulakan dengan {piece} di {from}.|Petunjuk buah 1/3 • Calon: {piece} di {from}. Semak pilihan memaksanya.|Petunjuk 2/3 • Gerakkan {piece} {direction}.|Petunjuk arah 2/3 • Perbaiki {piece} {direction} dan rebut tengah.|Petunjuk 3/3 • Cuba {from} → {to}. {explanation}|Gerakan tepat 3/3 • Kira {from} → {to}. {explanation}|ke sayap raja|ke sayap permaisuri|Syah terbuka: menggerakkan {piece} membuka serangan {attacker} dari {from} ke raja di {king}. Lawan mesti menjawab syah itu.|{side} berkubu {direction}.|Syahmat.|{side} menang.|Buntu. Tiada gerakan sah untuk {side}.''',
  'th':
      '''คำใบ้ 1/3 • เริ่มจาก {piece} ที่ {from}|คำใบ้ตัวหมาก 1/3 • ตัวเลือก: {piece} ที่ {from} ตรวจทางเลือกบังคับ|คำใบ้ 2/3 • เดิน {piece} {direction}|คำใบ้ทิศทาง 2/3 • ปรับปรุง {piece} {direction} และแย่งกลางกระดาน|คำใบ้ 3/3 • ลอง {from} → {to} {explanation}|ตาที่แน่นอน 3/3 • คำนวณ {from} → {to} {explanation}|ไปทางปีกคิง|ไปทางปีกควีน|เปิดรุก: การย้าย {piece} เปิดการโจมตีของ {attacker} จาก {from} ไปยังคิงที่ {king} คู่ต่อสู้ต้องตอบการรุกที่เปิดนี้|{side} เข้าป้อม {direction}|รุกฆาต|{side} ชนะ|อับ ไม่เหลือตาเดินที่ถูกกติกาสำหรับ {side}''',
  'vi':
      '''Gợi ý 1/3 • Bắt đầu với {piece} ở {from}.|Gợi ý quân 1/3 • Ứng viên: {piece} ở {from}. Kiểm tra nước cưỡng bức.|Gợi ý 2/3 • Đi {piece} {direction}.|Gợi ý hướng 2/3 • Cải thiện {piece} {direction} và tranh trung tâm.|Gợi ý 3/3 • Thử {from} → {to}. {explanation}|Nước chính xác 3/3 • Tính {from} → {to}. {explanation}|về cánh vua|về cánh hậu|Chiếu mở: đi {piece} mở đòn của {attacker} từ {from} đến vua ở {king}. Đối thủ phải đáp lại chiếu mở đó.|{side} nhập thành {direction}.|Chiếu hết.|{side} thắng.|Hòa hết nước. {side} không có nước hợp lệ.''',
  'pl':
      '''Wskazówka 1/3 • Zacznij od {piece} na {from}.|Wskazówka figury 1/3 • Kandydat: {piece} na {from}. Sprawdź wymuszające możliwości.|Wskazówka 2/3 • Przesuń {piece} {direction}.|Wskazówka kierunku 2/3 • Popraw {piece} {direction} i walcz o centrum.|Wskazówka 3/3 • Spróbuj {from} → {to}. {explanation}|Dokładny ruch 3/3 • Oblicz {from} → {to}. {explanation}|w stronę skrzydła królewskiego|w stronę skrzydła hetmańskiego|Szach z odsłony: ruch {piece} otworzył atak {attacker} z {from} na króla na {king}. Przeciwnik musi odpowiedzieć na ten szach.|{side}: roszada {direction}.|Mat.|{side} wygrywają.|Pat. Brak legalnego ruchu dla {side}.''',
  'nl':
      '''Hint 1/3 • Begin met {piece} op {from}.|Stukhint 1/3 • Kandidaat: {piece} op {from}. Controleer dwingende opties.|Hint 2/3 • Verplaats {piece} {direction}.|Richtingshint 2/3 • Verbeter {piece} {direction} en betwist het centrum.|Hint 3/3 • Probeer {from} → {to}. {explanation}|Exacte zet 3/3 • Bereken {from} → {to}. {explanation}|naar de koningsvleugel|naar de damevleugel|Aftrekschaak: het verplaatsen van {piece} opende de aanval van {attacker} vanaf {from} op de koning op {king}. De tegenstander moet dit schaak beantwoorden.|{side} rokeert {direction}.|Schaakmat.|{side} wint.|Pat. Geen legale zet voor {side}.''',
  'sv':
      '''Ledtråd 1/3 • Börja med {piece} på {from}.|Pjäsledtråd 1/3 • Kandidat: {piece} på {from}. Kontrollera tvingande möjligheter.|Ledtråd 2/3 • Flytta {piece} {direction}.|Riktningsledtråd 2/3 • Förbättra {piece} {direction} och utmana centrum.|Ledtråd 3/3 • Prova {from} → {to}. {explanation}|Exakt drag 3/3 • Beräkna {from} → {to}. {explanation}|mot kungsflygeln|mot damflygeln|Avdragsschack: flytten av {piece} öppnade attacken från {attacker} på {from} mot kungen på {king}. Motståndaren måste besvara denna schack.|{side} rockerar {direction}.|Schackmatt.|{side} vinner.|Patt. Inget lagligt drag för {side}.''',
  'el':
      '''Υπόδειξη 1/3 • Ξεκινήστε με {piece} στο {from}.|Υπόδειξη κομματιού 1/3 • Υποψήφιο: {piece} στο {from}. Ελέγξτε αναγκαστικές επιλογές.|Υπόδειξη 2/3 • Μετακινήστε {piece} {direction}.|Υπόδειξη κατεύθυνσης 2/3 • Βελτιώστε {piece} {direction} και διεκδικήστε το κέντρο.|Υπόδειξη 3/3 • Δοκιμάστε {from} → {to}. {explanation}|Ακριβής κίνηση 3/3 • Υπολογίστε {from} → {to}. {explanation}|προς την πτέρυγα βασιλιά|προς την πτέρυγα βασίλισσας|Σαχ από αποκάλυψη: η κίνηση του {piece} άνοιξε την επίθεση του {attacker} από {from} στον βασιλιά στο {king}. Ο αντίπαλος πρέπει να απαντήσει σε αυτό το σαχ.|{side}: ροκέ {direction}.|Σαχ ματ.|Νίκη για {side}.|Πατ. Καμία νόμιμη κίνηση για {side}.''',
  'he':
      '''רמז 1/3 • התחילו עם {piece} ב־{from}.|רמז לכלי 1/3 • מועמד: {piece} ב־{from}. בדקו אפשרויות כפויות.|רמז 2/3 • הזיזו {piece} {direction}.|רמז כיוון 2/3 • שפרו את {piece} {direction} והתחרו על המרכז.|רמז 3/3 • נסו {from} → {to}. {explanation}|מסע מדויק 3/3 • חשבו {from} → {to}. {explanation}|לכיוון אגף המלך|לכיוון אגף המלכה|שח נגלה: הזזת {piece} פתחה התקפת {attacker} מ־{from} על המלך ב־{king}. היריב חייב לענות לשח הנגלה.|{side}: הצרחה {direction}.|מט.|{side} מנצח.|פט. אין מסע חוקי עבור {side}.''',
  'sw':
      '''Kidokezo 1/3 • Anza na {piece} kwenye {from}.|Kidokezo cha kete 1/3 • Chaguo: {piece} kwenye {from}. Kagua hatua zake za kulazimisha.|Kidokezo 2/3 • Sogeza {piece} {direction}.|Kidokezo cha mwelekeo 2/3 • Boresha {piece} {direction} na pigania katikati.|Kidokezo 3/3 • Jaribu {from} → {to}. {explanation}|Hatua kamili 3/3 • Hesabu {from} → {to}. {explanation}|kuelekea upande wa mfalme|kuelekea upande wa malkia|Shaha iliyofunguliwa: kusogeza {piece} kumefungua shambulio la {attacker} kutoka {from} kwa mfalme kwenye {king}. Mpinzani lazima ajibu shaha hiyo.|{side}: kaslingi {direction}.|Mati.|{side} ameshinda.|Mkwamo. Hakuna hatua halali kwa {side}.''',
};

const liveStateKeys = [
  'yourTurn',
  'aiTurn',
  'player',
  'coach',
  'daily',
  'puzzles',
  'local',
  'online',
  'sync',
  'mateGoal',
  'outplay',
  'liveOpponent',
  'disabled',
  'calculating',
  'welcome',
  'complete',
  'puzzleComplete',
  'newDaily',
  'waiting',
  'draw'
];
final Map<String, List<String>> liveStateTranslations = {
  for (final e in _stateRows.entries) e.key: e.value.split('|')
};
const _stateSources = <String, String>{
  'YOUR TURN': 'yourTurn',
  'Your turn.': 'yourTurn',
  'AI TURN': 'aiTurn',
  'AI Coach ✦': 'coach',
  'AI Coach': 'coach',
  'DAILY CHALLENGE': 'daily',
  'PUZZLE ACADEMY': 'puzzles',
  'PUZZLE TRAINING': 'puzzles',
  'LOCAL MATCH': 'local',
  'ONLINE BATTLE': 'online',
  'Sync': 'sync',
  'Outplay your opponent': 'outplay',
  'Play a live opponent': 'liveOpponent',
  'Turn Coach on in Game controls for live move explanations.': 'disabled',
  'Turn Coach on from Game controls to receive move-by-move explanations.':
      'disabled',
  'Stockfish is finding your best plan…': 'calculating',
  'Running Stockfish position analysis…': 'calculating',
  'AI review in progress…': 'calculating',
  'Puzzle defense is replying...': 'calculating',
  'Challenge complete': 'complete',
  'Puzzle complete': 'puzzleComplete',
  'Puzzle complete.': 'puzzleComplete',
  'Daily challenge complete.': 'complete',
  'A new Daily Checkmate is ready.': 'newDaily',
  'Waiting for an online opponent.': 'waiting',
  'Draw': 'draw',
};
String? _translateState(String value, String code) {
  String t(String key, [Map<String, String> p = const {}]) =>
      _fill(liveStateTranslations[code]![liveStateKeys.indexOf(key)], p);
  final key = _stateSources[value];
  if (key != null) return t(key);
  var m = RegExp(r'^PLAYER ([12]) • (WHITE|BLACK)$').firstMatch(value);
  if (m != null) {
    return '${t('player', {
          'count': m[1]!
        })} • ${CoachLocalizations(code).text(m[2]!.toLowerCase())}';
  }
  m = RegExp(r'^Checkmate in (\d+)$').firstMatch(value);
  if (m != null) return t('mateGoal', {'count': m[1]!});
  m = RegExp(r'^Welcome (.+)\. Your game is ready\.$').firstMatch(value);
  if (m != null) return t('welcome', {'name': m[1]!});
  m = RegExp(r'^(.+) AI is calculating\.\.\.$').firstMatch(value);
  if (m != null) return '${m[1]} • ${t('calculating')}';
  return null;
}

const _stateRows = <String, String>{
  'en':
      '''Your turn|AI turn|Player {count}|AI Coach|Daily challenge|Puzzle training|Local match|Online battle|Sync|Checkmate in {count}|Outplay your opponent|Play a live opponent|Turn Coach on in Game controls for move-by-move explanations.|Calculating…|Welcome {name}. Your game is ready.|Challenge complete.|Puzzle complete.|A new Daily Checkmate is ready.|Waiting for an online opponent.|Draw''',
  'te':
      '''మీ వంతు|AI వంతు|ఆటగాడు {count}|AI కోచ్|రోజువారీ సవాలు|పజిల్ శిక్షణ|స్థానిక మ్యాచ్|ఆన్‌లైన్ పోరు|సమకాలీకరణ|{count} ఎత్తుల్లో చెక్‌మేట్|ప్రత్యర్థిని మించి ఆడండి|ప్రత్యక్ష ప్రత్యర్థితో ఆడండి|ప్రతి ఎత్తుకు వివరణ కోసం గేమ్ నియంత్రణల్లో కోచ్‌ను ఆన్ చేయండి.|లెక్కిస్తోంది…|స్వాగతం {name}. మీ ఆట సిద్ధంగా ఉంది.|సవాలు పూర్తయింది.|పజిల్ పూర్తయింది.|కొత్త రోజువారీ చెక్‌మేట్ సిద్ధంగా ఉంది.|ఆన్‌లైన్ ప్రత్యర్థి కోసం వేచి ఉంది.|డ్రా''',
  'hi':
      '''आपकी बारी|AI की बारी|खिलाड़ी {count}|AI कोच|दैनिक चुनौती|पहेली प्रशिक्षण|स्थानीय मैच|ऑनलाइन मुकाबला|समन्वय|{count} चालों में मात|प्रतिद्वंद्वी से बेहतर खेलें|लाइव प्रतिद्वंद्वी से खेलें|हर चाल की व्याख्या के लिए गेम नियंत्रण में कोच चालू करें।|गणना जारी…|स्वागत है {name}। आपका खेल तैयार है।|चुनौती पूरी।|पहेली पूरी।|नई दैनिक मात चुनौती तैयार है।|ऑनलाइन प्रतिद्वंद्वी की प्रतीक्षा है।|ड्रॉ''',
  'ta':
      '''உங்கள் முறை|AI முறை|வீரர் {count}|AI பயிற்சியாளர்|தினசரி சவால்|புதிர் பயிற்சி|உள்ளூர் ஆட்டம்|இணையப் போட்டி|ஒத்திசைவு|{count} நகர்வுகளில் செக்மேட்|எதிரியைவிடச் சிறப்பாக ஆடுங்கள்|நேரடி எதிரியுடன் ஆடுங்கள்|ஒவ்வொரு நகர்வின் விளக்கத்திற்கும் ஆட்டக் கட்டுப்பாடுகளில் பயிற்சியாளரை இயக்குங்கள்.|கணக்கிடுகிறது…|வரவேற்கிறோம் {name}. உங்கள் ஆட்டம் தயார்.|சவால் முடிந்தது.|புதிர் முடிந்தது.|புதிய தினசரி செக்மேட் தயார்.|இணைய எதிரிக்காகக் காத்திருக்கிறது.|சமநிலை''',
  'kn':
      '''ನಿಮ್ಮ ಸರದಿ|AI ಸರದಿ|ಆಟಗಾರ {count}|AI ತರಬೇತುದಾರ|ದೈನಂದಿನ ಸವಾಲು|ಒಗಟು ತರಬೇತಿ|ಸ್ಥಳೀಯ ಪಂದ್ಯ|ಆನ್‌ಲೈನ್ ಪಂದ್ಯ|ಸಿಂಕ್|{count} ನಡೆಗಳಲ್ಲಿ ಚೆಕ್‌ಮೇಟ್|ಎದುರಾಳಿಗಿಂತ ಉತ್ತಮವಾಗಿ ಆಡಿ|ನೇರ ಎದುರಾಳಿಯೊಂದಿಗೆ ಆಡಿ|ಪ್ರತಿ ನಡೆಯ ವಿವರಣೆಗಾಗಿ ಆಟದ ನಿಯಂತ್ರಣಗಳಲ್ಲಿ ತರಬೇತುದಾರನನ್ನು ಆನ್ ಮಾಡಿ.|ಲೆಕ್ಕಿಸುತ್ತಿದೆ…|ಸ್ವಾಗತ {name}. ನಿಮ್ಮ ಆಟ ಸಿದ್ಧವಾಗಿದೆ.|ಸವಾಲು ಪೂರ್ಣ.|ಒಗಟು ಪೂರ್ಣ.|ಹೊಸ ದೈನಂದಿನ ಚೆಕ್‌ಮೇಟ್ ಸಿದ್ಧವಾಗಿದೆ.|ಆನ್‌ಲೈನ್ ಎದುರಾಳಿಗಾಗಿ ಕಾಯುತ್ತಿದೆ.|ಡ್ರಾ''',
  'ml':
      '''നിങ്ങളുടെ ഊഴം|AI ഊഴം|കളിക്കാരൻ {count}|AI പരിശീലകൻ|ദൈനംദിന വെല്ലുവിളി|പസിൽ പരിശീലനം|പ്രാദേശിക മത്സരം|ഓൺലൈൻ മത്സരം|സമന്വയം|{count} നീക്കങ്ങളിൽ ചെക്ക്മേറ്റ്|എതിരാളിയേക്കാൾ നന്നായി കളിക്കുക|തത്സമയ എതിരാളിയുമായി കളിക്കുക|ഓരോ നീക്കത്തിന്റെയും വിശദീകരണത്തിന് കളി നിയന്ത്രണങ്ങളിൽ പരിശീലകനെ ഓണാക്കുക.|കണക്കാക്കുന്നു…|സ്വാഗതം {name}. നിങ്ങളുടെ കളി തയ്യാറാണ്.|വെല്ലുവിളി പൂർത്തിയായി.|പസിൽ പൂർത്തിയായി.|പുതിയ ദൈനംദിന ചെക്ക്മേറ്റ് തയ്യാർ.|ഓൺലൈൻ എതിരാളിക്കായി കാത്തിരിക്കുന്നു.|സമനില''',
  'mr':
      '''तुमची पाळी|AI ची पाळी|खेळाडू {count}|AI प्रशिक्षक|दैनिक आव्हान|कोडे प्रशिक्षण|स्थानिक सामना|ऑनलाइन लढत|समक्रमण|{count} चालींत मात|प्रतिस्पर्ध्यापेक्षा चांगले खेळा|थेट प्रतिस्पर्ध्याशी खेळा|प्रत्येक चालीच्या स्पष्टीकरणासाठी खेळ नियंत्रणात प्रशिक्षक सुरू करा.|गणना सुरू…|स्वागत {name}. तुमचा खेळ तयार आहे.|आव्हान पूर्ण.|कोडे पूर्ण.|नवीन दैनिक मात आव्हान तयार आहे.|ऑनलाइन प्रतिस्पर्ध्याची वाट पाहत आहे.|बरोबरी''',
  'bn':
      '''আপনার পালা|AI-এর পালা|খেলোয়াড় {count}|AI প্রশিক্ষক|দৈনিক চ্যালেঞ্জ|ধাঁধা প্রশিক্ষণ|স্থানীয় ম্যাচ|অনলাইন লড়াই|সমন্বয়|{count} চালে মাত|প্রতিপক্ষের চেয়ে ভালো খেলুন|সরাসরি প্রতিপক্ষের সঙ্গে খেলুন|প্রতি চালের ব্যাখ্যা পেতে খেলার নিয়ন্ত্রণে প্রশিক্ষক চালু করুন।|গণনা চলছে…|স্বাগতম {name}। আপনার খেলা প্রস্তুত।|চ্যালেঞ্জ সম্পূর্ণ।|ধাঁধা সম্পূর্ণ।|নতুন দৈনিক মাত প্রস্তুত।|অনলাইন প্রতিপক্ষের অপেক্ষায়।|ড্র''',
  'gu':
      '''તમારો વારો|AI નો વારો|ખેલાડી {count}|AI કોચ|દૈનિક પડકાર|કોયડા તાલીમ|સ્થાનિક મેચ|ઓનલાઇન મુકાબલો|સમન્વય|{count} ચાલમાં માત|વિરોધી કરતાં વધુ સારું રમો|જીવંત વિરોધી સાથે રમો|દરેક ચાલની સમજ માટે રમતના નિયંત્રણોમાં કોચ ચાલુ કરો.|ગણતરી ચાલુ…|સ્વાગત {name}. તમારી રમત તૈયાર છે.|પડકાર પૂર્ણ.|કોયડો પૂર્ણ.|નવો દૈનિક માત પડકાર તૈયાર છે.|ઓનલાઇન વિરોધીની રાહ જોવાય છે.|ડ્રો''',
  'pa':
      '''ਤੁਹਾਡੀ ਵਾਰੀ|AI ਦੀ ਵਾਰੀ|ਖਿਡਾਰੀ {count}|AI ਕੋਚ|ਰੋਜ਼ਾਨਾ ਚੁਣੌਤੀ|ਬੁਝਾਰਤ ਸਿਖਲਾਈ|ਸਥਾਨਕ ਮੈਚ|ਆਨਲਾਈਨ ਮੁਕਾਬਲਾ|ਸਮਕਾਲੀਕਰਨ|{count} ਚਾਲਾਂ ਵਿੱਚ ਮਾਤ|ਵਿਰੋਧੀ ਤੋਂ ਵਧੀਆ ਖੇਡੋ|ਲਾਈਵ ਵਿਰੋਧੀ ਨਾਲ ਖੇਡੋ|ਹਰ ਚਾਲ ਦੀ ਵਿਆਖਿਆ ਲਈ ਖੇਡ ਕੰਟਰੋਲਾਂ ਵਿੱਚ ਕੋਚ ਚਾਲੂ ਕਰੋ।|ਗਣਨਾ ਜਾਰੀ…|ਜੀ ਆਇਆਂ ਨੂੰ {name}। ਤੁਹਾਡੀ ਖੇਡ ਤਿਆਰ ਹੈ।|ਚੁਣੌਤੀ ਪੂਰੀ।|ਬੁਝਾਰਤ ਪੂਰੀ।|ਨਵੀਂ ਰੋਜ਼ਾਨਾ ਮਾਤ ਤਿਆਰ ਹੈ।|ਆਨਲਾਈਨ ਵਿਰੋਧੀ ਦੀ ਉਡੀਕ ਹੈ।|ਬਰਾਬਰੀ''',
  'ur':
      '''آپ کی باری|AI کی باری|کھلاڑی {count}|AI کوچ|روزانہ چیلنج|پہیلی کی تربیت|مقامی میچ|آن لائن مقابلہ|ہم آہنگی|{count} چالوں میں مات|حریف سے بہتر کھیلیں|براہ راست حریف سے کھیلیں|ہر چال کی وضاحت کے لیے کھیل کے کنٹرول میں کوچ آن کریں۔|حساب جاری…|خوش آمدید {name}۔ آپ کا کھیل تیار ہے۔|چیلنج مکمل۔|پہیلی مکمل۔|نیا روزانہ مات چیلنج تیار ہے۔|آن لائن حریف کا انتظار ہے۔|برابری''',
  'ar':
      '''دورك|دور AI|اللاعب {count}|مدرب AI|التحدي اليومي|تدريب الألغاز|مباراة محلية|مواجهة عبر الإنترنت|مزامنة|مات خلال {count} نقلات|تفوق على خصمك|العب ضد خصم مباشر|شغّل المدرب في عناصر تحكم اللعبة لشرح كل نقلة.|جارٍ الحساب…|مرحبًا {name}. لعبتك جاهزة.|اكتمل التحدي.|اكتمل اللغز.|تحدي مات يومي جديد جاهز.|في انتظار خصم عبر الإنترنت.|تعادل''',
  'es':
      '''Tu turno|Turno de IA|Jugador {count}|Entrenador IA|Desafío diario|Entrenamiento de problemas|Partida local|Batalla en línea|Sincronizar|Mate en {count}|Supera a tu rival|Juega contra un rival en vivo|Activa el entrenador en los controles para explicaciones de cada jugada.|Calculando…|Bienvenido, {name}. Tu partida está lista.|Desafío completado.|Problema completado.|Hay un nuevo mate diario disponible.|Esperando un rival en línea.|Tablas''',
  'fr':
      '''Votre tour|Tour de l’IA|Joueur {count}|Coach IA|Défi quotidien|Entraînement aux problèmes|Partie locale|Duel en ligne|Synchroniser|Mat en {count}|Surpassez votre adversaire|Jouez contre un adversaire en direct|Activez le coach dans les commandes pour des explications à chaque coup.|Calcul en cours…|Bienvenue {name}. Votre partie est prête.|Défi terminé.|Problème terminé.|Un nouveau mat quotidien est prêt.|En attente d’un adversaire en ligne.|Nulle''',
  'de':
      '''Du bist am Zug|KI am Zug|Spieler {count}|KI-Trainer|Tagesaufgabe|Aufgabentraining|Lokale Partie|Online-Duell|Synchronisieren|Matt in {count}|Überspiele deinen Gegner|Spiele gegen einen Live-Gegner|Aktiviere den Trainer in der Spielsteuerung für Erklärungen zu jedem Zug.|Berechnung läuft…|Willkommen {name}. Deine Partie ist bereit.|Aufgabe abgeschlossen.|Rätsel abgeschlossen.|Eine neue tägliche Mattaufgabe ist bereit.|Warte auf einen Online-Gegner.|Remis''',
  'it':
      '''Il tuo turno|Turno IA|Giocatore {count}|Allenatore IA|Sfida giornaliera|Allenamento problemi|Partita locale|Sfida online|Sincronizza|Matto in {count}|Supera il tuo avversario|Gioca contro un avversario dal vivo|Attiva l’allenatore nei comandi per spiegazioni di ogni mossa.|Calcolo in corso…|Benvenuto {name}. La partita è pronta.|Sfida completata.|Problema completato.|Un nuovo matto giornaliero è pronto.|In attesa di un avversario online.|Patta''',
  'pt':
      '''A sua vez|Vez da IA|Jogador {count}|Treinador IA|Desafio diário|Treino de problemas|Partida local|Batalha online|Sincronizar|Mate em {count}|Supere o adversário|Jogue contra um adversário ao vivo|Ative o treinador nos controlos para explicações de cada lance.|A calcular…|Bem-vindo {name}. A partida está pronta.|Desafio concluído.|Problema concluído.|Um novo mate diário está pronto.|A aguardar adversário online.|Empate''',
  'ru':
      '''Ваш ход|Ход ИИ|Игрок {count}|ИИ-тренер|Ежедневное задание|Тренировка задач|Локальная партия|Онлайн-поединок|Синхронизация|Мат в {count}|Переиграйте соперника|Играйте с живым соперником|Включите тренера в управлении игрой для объяснения каждого хода.|Вычисление…|Добро пожаловать, {name}. Партия готова.|Задание выполнено.|Задача решена.|Готово новое ежедневное задание на мат.|Ожидание онлайн-соперника.|Ничья''',
  'uk':
      '''Ваш хід|Хід ШІ|Гравець {count}|ШІ-тренер|Щоденне завдання|Тренування задач|Локальна партія|Онлайн-поєдинок|Синхронізація|Мат за {count}|Переграйте суперника|Грайте з живим суперником|Увімкніть тренера в керуванні грою для пояснення кожного ходу.|Обчислення…|Вітаємо, {name}. Партія готова.|Завдання виконано.|Задачу розв’язано.|Готове нове щоденне завдання на мат.|Очікування онлайн-суперника.|Нічия''',
  'tr':
      '''Senin sıran|Yapay zekâ sırası|Oyuncu {count}|Yapay zekâ koçu|Günlük görev|Bulmaca eğitimi|Yerel maç|Çevrimiçi mücadele|Eşitle|{count} hamlede mat|Rakibini geride bırak|Canlı rakiple oyna|Her hamlenin açıklaması için oyun kontrollerinden koçu aç.|Hesaplanıyor…|Hoş geldin {name}. Oyunun hazır.|Görev tamamlandı.|Bulmaca tamamlandı.|Yeni günlük mat görevi hazır.|Çevrimiçi rakip bekleniyor.|Berabere''',
  'fa':
      '''نوبت شما|نوبت هوش مصنوعی|بازیکن {count}|مربی هوش مصنوعی|چالش روزانه|تمرین معما|بازی محلی|نبرد آنلاین|همگام‌سازی|مات در {count}|از حریف بهتر بازی کنید|با حریف زنده بازی کنید|مربی را در کنترل‌های بازی روشن کنید تا هر حرکت توضیح داده شود.|در حال محاسبه…|خوش آمدید {name}. بازی آماده است.|چالش کامل شد.|معما حل شد.|مات روزانه تازه آماده است.|در انتظار حریف آنلاین.|مساوی''',
  'zh':
      '''轮到你|AI回合|玩家{count}|AI教练|每日挑战|习题训练|本地对局|在线对战|同步|{count}步杀|胜过对手|与真人对手对弈|在游戏控制中开启教练，获取逐步讲解。|计算中…|欢迎{name}。棋局已准备好。|挑战完成。|习题完成。|新的每日杀王挑战已就绪。|等待在线对手。|和棋''',
  'ja':
      '''あなたの手番|AIの手番|プレイヤー{count}|AIコーチ|毎日の挑戦|問題トレーニング|ローカル対局|オンライン対戦|同期|{count}手でメイト|相手を上回ろう|リアルタイムで対戦|ゲーム操作でコーチを有効にすると各手の説明が表示されます。|計算中…|ようこそ{name}。対局の準備ができました。|挑戦達成。|問題クリア。|新しい毎日のメイト問題が用意されました。|オンラインの相手を待っています。|引き分け''',
  'ko':
      '''내 차례|AI 차례|플레이어 {count}|AI 코치|일일 도전|퍼즐 훈련|로컬 대국|온라인 대결|동기화|{count}수 메이트|상대를 능가하세요|실시간 상대와 플레이|각 수의 설명을 보려면 게임 설정에서 코치를 켜세요.|계산 중…|환영합니다 {name}. 대국이 준비되었습니다.|도전 완료.|퍼즐 완료.|새 일일 메이트가 준비되었습니다.|온라인 상대를 기다립니다.|무승부''',
  'id':
      '''Giliran Anda|Giliran AI|Pemain {count}|Pelatih AI|Tantangan harian|Latihan teka-teki|Pertandingan lokal|Pertarungan online|Sinkronkan|Mat dalam {count}|Ungguli lawan Anda|Main dengan lawan langsung|Aktifkan pelatih di kontrol permainan untuk penjelasan setiap langkah.|Menghitung…|Selamat datang {name}. Permainan Anda siap.|Tantangan selesai.|Teka-teki selesai.|Mat harian baru siap.|Menunggu lawan online.|Remis''',
  'ms':
      '''Giliran anda|Giliran AI|Pemain {count}|Jurulatih AI|Cabaran harian|Latihan teka-teki|Perlawanan tempatan|Pertarungan dalam talian|Segerakkan|Mat dalam {count}|Atasi lawan anda|Main dengan lawan langsung|Hidupkan jurulatih dalam kawalan permainan untuk penerangan setiap gerakan.|Mengira…|Selamat datang {name}. Permainan anda sedia.|Cabaran selesai.|Teka-teki selesai.|Mat harian baharu sedia.|Menunggu lawan dalam talian.|Seri''',
  'th':
      '''ตาคุณ|ตาของ AI|ผู้เล่น {count}|โค้ช AI|ความท้าทายประจำวัน|ฝึกปริศนา|เล่นในเครื่อง|ต่อสู้ออนไลน์|ซิงค์|รุกฆาตใน {count} ตา|เล่นให้เหนือกว่าคู่ต่อสู้|เล่นกับคู่ต่อสู้แบบสด|เปิดโค้ชในส่วนควบคุมเกมเพื่อดูคำอธิบายทุกตา|กำลังคำนวณ…|ยินดีต้อนรับ {name} เกมพร้อมแล้ว|ผ่านความท้าทายแล้ว|แก้ปริศนาสำเร็จ|โจทย์รุกฆาตประจำวันใหม่พร้อมแล้ว|กำลังรอคู่ต่อสู้ออนไลน์|เสมอ''',
  'vi':
      '''Lượt của bạn|Lượt AI|Người chơi {count}|Huấn luyện viên AI|Thử thách hằng ngày|Luyện câu đố|Ván cục bộ|Đấu trực tuyến|Đồng bộ|Chiếu hết trong {count}|Chơi hay hơn đối thủ|Đấu với đối thủ trực tiếp|Bật huấn luyện viên trong điều khiển trò chơi để giải thích từng nước.|Đang tính…|Chào {name}. Ván đấu đã sẵn sàng.|Hoàn thành thử thách.|Hoàn thành câu đố.|Bài chiếu hết hằng ngày mới đã sẵn sàng.|Đang chờ đối thủ trực tuyến.|Hòa''',
  'pl':
      '''Twój ruch|Ruch AI|Gracz {count}|Trener AI|Codzienne wyzwanie|Trening zadań|Partia lokalna|Pojedynek online|Synchronizuj|Mat w {count}|Przechytrz przeciwnika|Graj z żywym przeciwnikiem|Włącz trenera w ustawieniach gry, by uzyskać wyjaśnienia każdego ruchu.|Obliczanie…|Witaj {name}. Partia jest gotowa.|Wyzwanie ukończone.|Zadanie ukończone.|Nowe codzienne zadanie matowe jest gotowe.|Oczekiwanie na przeciwnika online.|Remis''',
  'nl':
      '''Jouw beurt|Beurt van AI|Speler {count}|AI-coach|Dagelijkse uitdaging|Puzzeltraining|Lokale partij|Online duel|Synchroniseren|Mat in {count}|Overtref je tegenstander|Speel tegen een live tegenstander|Zet de coach aan in de spelbediening voor uitleg bij elke zet.|Berekenen…|Welkom {name}. Je partij is klaar.|Uitdaging voltooid.|Puzzel voltooid.|Een nieuwe dagelijkse matopgave is klaar.|Wachten op een online tegenstander.|Remise''',
  'sv':
      '''Din tur|AI:s tur|Spelare {count}|AI-tränare|Dagens utmaning|Problemträning|Lokalt parti|Onlineduell|Synkronisera|Matt i {count}|Överlista motståndaren|Spela mot en livemotståndare|Slå på tränaren i spelkontrollerna för förklaringar drag för drag.|Beräknar…|Välkommen {name}. Ditt parti är klart.|Utmaningen klar.|Problemet klart.|En ny daglig mattuppgift är klar.|Väntar på en onlinemotståndare.|Remi''',
  'el':
      '''Σειρά σας|Σειρά AI|Παίκτης {count}|Προπονητής AI|Καθημερινή πρόκληση|Εξάσκηση προβλημάτων|Τοπική παρτίδα|Διαδικτυακή μάχη|Συγχρονισμός|Ματ σε {count}|Ξεπεράστε τον αντίπαλο|Παίξτε με ζωντανό αντίπαλο|Ενεργοποιήστε τον προπονητή στα χειριστήρια για εξηγήσεις κάθε κίνησης.|Υπολογισμός…|Καλώς ήρθατε {name}. Η παρτίδα είναι έτοιμη.|Η πρόκληση ολοκληρώθηκε.|Το πρόβλημα ολοκληρώθηκε.|Νέο καθημερινό ματ είναι έτοιμο.|Αναμονή διαδικτυακού αντιπάλου.|Ισοπαλία''',
  'he':
      '''התור שלכם|תור AI|שחקן {count}|מאמן AI|אתגר יומי|אימון חידות|משחק מקומי|קרב מקוון|סנכרון|מט ב־{count}|גברו על היריב|שחקו מול יריב חי|הפעילו את המאמן בבקרות המשחק כדי לקבל הסבר לכל מסע.|מחשב…|ברוכים הבאים {name}. המשחק מוכן.|האתגר הושלם.|החידה הושלמה.|חידת מט יומית חדשה מוכנה.|ממתין ליריב מקוון.|תיקו''',
  'sw':
      '''Zamu yako|Zamu ya AI|Mchezaji {count}|Kocha wa AI|Changamoto ya kila siku|Mazoezi ya mafumbo|Mechi ya hapa|Pambano mtandaoni|Sawazisha|Mati katika {count}|Mshinde mpinzani kwa ustadi|Cheza na mpinzani wa moja kwa moja|Washa kocha kwenye vidhibiti vya mchezo kwa maelezo ya kila hatua.|Inahesabu…|Karibu {name}. Mchezo wako uko tayari.|Changamoto imekamilika.|Fumbo limekamilika.|Mati mpya ya kila siku iko tayari.|Inasubiri mpinzani mtandaoni.|Sare''',
};

const liveDailyKeys = [
  'invalid',
  'guest',
  'remaining',
  'unlock',
  'dailyDone',
  'puzzleDone',
  'puzzleSolved',
  'legalWhite',
  'notTactic',
  'limit',
  'noMate',
  'dailyAvailable',
  'puzzleRetry',
  'staleRetry',
  'staleObjective',
  'leaves'
];
final Map<String, List<String>> liveDailyTranslations = {
  for (final e in _dailyRows.entries) e.key: e.value.split('|')
};
String? _translateDaily(String value, String code) {
  String t(String key, [Map<String, String> p = const {}]) =>
      _fill(liveDailyTranslations[code]![liveDailyKeys.indexOf(key)], p);
  const sources = {
    'Invalid board detected and safely reset. Kings cannot be captured.':
        'invalid',
    'An invalid board was detected and safely reset. No king can be captured.':
        'invalid',
    'Guest Player mode is ready. Create an account later to save progress.':
        'guest',
    'That is a legal chess move, but not the tactic. Tap Try again and look for checks, captures, and threats.':
        'notTactic',
    'The move limit ended before checkmate. This is not a loss. Review the board, find the forcing checks first, then try again.':
        'limit',
    'Your daily attempt is still available.': 'dailyAvailable',
    'Try this puzzle again whenever you are ready.': 'puzzleRetry',
    'Stalemate avoids checkmate. Try again.': 'staleRetry',
    'Stalemate is not the checkmate objective. Try the forcing line again.':
        'staleObjective',
    'That move leaves the puzzle solution. Find the forcing line and try again.':
        'leaves',
  };
  if (sources.containsKey(value)) return t(sources[value]!);
  var m =
      RegExp(r'^(\d+) move\(s\) remain\. Find checkmate\.$').firstMatch(value);
  if (m != null) return t('remaining', {'count': m[1]!});
  m = RegExp(
          r'^Daily Checkmate complete\. Next challenge unlocks in (\d+) hours? (\d+) minutes? (\d+) seconds?\.$')
      .firstMatch(value);
  if (m != null) {
    return t('unlock', {'hours': m[1]!, 'minutes': m[2]!, 'seconds': m[3]!});
  }
  m = RegExp(r'^Brilliant! Today.s (.+) challenge is complete\. (.*)$',
          dotAll: true)
      .firstMatch(value);
  if (m != null) {
    return '${t('dailyDone', {
          'difficulty': localizeLiveCoach(m[1]!, code)
        })} ${localizeLiveCoach(m[2]!, code)}';
  }
  m = RegExp(r'^Brilliant! (.+) complete — no daily waiting limit\.$')
      .firstMatch(value);
  if (m != null) return t('puzzleDone', {'title': m[1]!});
  m = RegExp(r'^(.+) solved\. Continue with the next puzzle anytime\.$')
      .firstMatch(value);
  if (m != null) return t('puzzleSolved', {'title': m[1]!});
  m = RegExp(r'^Move any legal white coin\. Checkmate in (\d+) moves\.$')
      .firstMatch(value);
  if (m != null) return t('legalWhite', {'count': m[1]!});
  m = RegExp(r'^(.+): checkmate in (\d+) moves\.$').firstMatch(value);
  if (m != null) {
    return '${m[1]}: ${localizeLiveCoach('Checkmate in ${m[2]}', code)}';
  }
  m = RegExp(r'^No checkmate within (\d+) moves\.(.*)$').firstMatch(value);
  if (m != null) {
    return '${t('noMate', {
          'count': m[1]!
        })} ${localizeLiveCoach(m[2]!.trim(), code)}'
        .trim();
  }
  return null;
}

const _dailyRows = <String, String>{
  'en':
      '''Invalid board detected and safely reset. Kings cannot be captured.|Guest Player mode is ready. Create an account later to save progress.|{count} moves remain. Find checkmate.|Daily Checkmate complete. Next challenge unlocks in {hours} hours {minutes} minutes {seconds} seconds.|Brilliant! Today’s {difficulty} challenge is complete.|Brilliant! {title} complete — no daily waiting limit.|{title} solved. Continue with the next puzzle anytime.|Move any legal white piece. Checkmate in {count} moves.|That is a legal chess move, but not the tactic. Tap Try again and look for checks, captures, and threats.|The move limit ended before checkmate. This is not a loss. Review the board, find the forcing checks first, then try again.|No checkmate within {count} moves.|Your daily attempt is still available.|Try this puzzle again whenever you are ready.|Stalemate avoids checkmate. Try again.|Stalemate is not the checkmate objective. Try the forcing line again.|That move leaves the puzzle solution. Find the forcing line and try again.''',
  'te':
      '''చెల్లని బోర్డును గుర్తించి సురక్షితంగా రీసెట్ చేశాం. రాజులను పట్టుకోలేరు.|అతిథి ఆటగాడి మోడ్ సిద్ధం. పురోగతి సేవ్ చేయడానికి తరువాత ఖాతా సృష్టించండి.|ఇంకా {count} ఎత్తులు ఉన్నాయి. చెక్‌మేట్ కనుగొనండి.|రోజువారీ చెక్‌మేట్ పూర్తయింది. తదుపరి సవాలు {hours} గంటలు {minutes} నిమిషాలు {seconds} సెకన్లలో తెరుచుకుంటుంది.|అద్భుతం! నేటి {difficulty} సవాలు పూర్తయింది.|అద్భుతం! {title} పూర్తయింది — రోజువారీ నిరీక్షణ పరిమితి లేదు.|{title} పరిష్కరించారు. తదుపరి పజిల్‌ను ఎప్పుడైనా కొనసాగించండి.|తెల్ల పావుతో ఏ చట్టబద్ధమైన ఎత్తైనా ఆడండి. {count} ఎత్తుల్లో చెక్‌మేట్ చేయండి.|ఇది చట్టబద్ధమైన ఎత్తే కానీ ఈ వ్యూహం కాదు. మళ్లీ ప్రయత్నించి చెక్‌లు, పట్టుకోవడాలు, ముప్పులను చూడండి.|చెక్‌మేట్‌కు ముందు ఎత్తుల పరిమితి ముగిసింది. ఇది ఓటమి కాదు. బోర్డును సమీక్షించి బలవంతపు చెక్‌లను మొదట కనుగొని మళ్లీ ప్రయత్నించండి.|{count} ఎత్తుల్లో చెక్‌మేట్ కాలేదు.|మీ రోజువారీ ప్రయత్నం ఇంకా అందుబాటులో ఉంది.|సిద్ధమైనప్పుడు ఈ పజిల్‌ను మళ్లీ ప్రయత్నించండి.|స్టేల్‌మేట్ వల్ల చెక్‌మేట్ జరగదు. మళ్లీ ప్రయత్నించండి.|స్టేల్‌మేట్ చెక్‌మేట్ లక్ష్యం కాదు. బలవంతపు వరుసను మళ్లీ ప్రయత్నించండి.|ఆ ఎత్తు పజిల్ పరిష్కారాన్ని విడిచిపెడుతుంది. బలవంతపు వరుస కనుగొని మళ్లీ ప్రయత్నించండి.''',
  'hi':
      '''अवैध बोर्ड मिला और सुरक्षित रीसेट किया गया। राजा को मारा नहीं जा सकता।|अतिथि मोड तैयार है। प्रगति सहेजने के लिए बाद में खाता बनाएँ।|{count} चालें बची हैं। मात खोजें।|दैनिक मात पूरी। अगली चुनौती {hours} घंटे {minutes} मिनट {seconds} सेकंड में खुलेगी।|शानदार! आज की {difficulty} चुनौती पूरी।|शानदार! {title} पूरी — रोज़ प्रतीक्षा की सीमा नहीं।|{title} हल हुई। अगली पहेली कभी भी शुरू करें।|सफेद की कोई वैध चाल चलें। {count} चालों में मात करें।|यह वैध चाल है लेकिन सही रणनीतिक समाधान नहीं। फिर कोशिश करें और शह, मारने के मौके व खतरे देखें।|मात से पहले चाल सीमा खत्म हुई। यह हार नहीं है। बोर्ड देखें, पहले बाध्यकारी शह खोजें, फिर कोशिश करें।|{count} चालों में मात नहीं हुई।|आपका दैनिक प्रयास अभी उपलब्ध है।|तैयार होने पर पहेली फिर आज़माएँ।|गतिरोध से मात नहीं होती। फिर कोशिश करें।|गतिरोध मात का लक्ष्य नहीं है। बाध्यकारी क्रम फिर आज़माएँ।|यह चाल पहेली के समाधान से हटती है। बाध्यकारी क्रम खोजकर फिर कोशिश करें।''',
  'ta':
      '''தவறான பலகை கண்டறியப்பட்டு பாதுகாப்பாக மீட்டமைக்கப்பட்டது. ராஜாவைப் பிடிக்க முடியாது.|விருந்தினர் முறை தயார். முன்னேற்றத்தைச் சேமிக்கப் பின்னர் கணக்கு உருவாக்குங்கள்.|{count} நகர்வுகள் மீதம். செக்மேட் கண்டுபிடியுங்கள்.|தினசரி செக்மேட் முடிந்தது. அடுத்த சவால் {hours} மணி {minutes} நிமிடம் {seconds} விநாடியில் திறக்கும்.|அற்புதம்! இன்றைய {difficulty} சவால் முடிந்தது.|அற்புதம்! {title} முடிந்தது — தினசரி காத்திருப்பு வரம்பில்லை.|{title} தீர்க்கப்பட்டது. அடுத்த புதிரை எப்போதும் தொடரலாம்.|வெள்ளையின் எந்தச் சட்டபூர்வ நகர்வையும் ஆடுங்கள். {count} நகர்வுகளில் செக்மேட் செய்யுங்கள்.|இது சட்டபூர்வ நகர்வு; ஆனால் இந்தத் தந்திரம் அல்ல. மீண்டும் முயன்று செக், பிடிப்பு, அச்சுறுத்தலைத் தேடுங்கள்.|செக்மேட்டுக்கு முன் நகர்வு வரம்பு முடிந்தது. இது தோல்வியல்ல. பலகையை ஆய்ந்து கட்டாய செக்குகளை முதலில் கண்டுபிடித்து மீண்டும் முயலுங்கள்.|{count} நகர்வுகளில் செக்மேட் இல்லை.|உங்கள் தினசரி முயற்சி இன்னும் கிடைக்கிறது.|தயாரானதும் இந்தப் புதிரை மீண்டும் முயலுங்கள்.|ஸ்டேல்மேட் செக்மேட்டைத் தவிர்க்கிறது. மீண்டும் முயலுங்கள்.|ஸ்டேல்மேட் செக்மேட் இலக்கு அல்ல. கட்டாய வரிசையை மீண்டும் முயலுங்கள்.|அந்த நகர்வு புதிர் தீர்விலிருந்து விலகுகிறது. கட்டாய வரிசையைக் கண்டறிந்து மீண்டும் முயலுங்கள்.''',
  'kn':
      '''ಅಮಾನ್ಯ ಬೋರ್ಡನ್ನು ಗುರುತಿಸಿ ಸುರಕ್ಷಿತವಾಗಿ ಮರುಹೊಂದಿಸಲಾಗಿದೆ. ರಾಜರನ್ನು ಹಿಡಿಯಲಾಗುವುದಿಲ್ಲ.|ಅತಿಥಿ ಮೋಡ್ ಸಿದ್ಧ. ಪ್ರಗತಿ ಉಳಿಸಲು ನಂತರ ಖಾತೆ ರಚಿಸಿ.|{count} ನಡೆಗಳು ಉಳಿದಿವೆ. ಚೆಕ್‌ಮೇಟ್ ಹುಡುಕಿ.|ದೈನಂದಿನ ಚೆಕ್‌ಮೇಟ್ ಪೂರ್ಣ. ಮುಂದಿನ ಸವಾಲು {hours} ಗಂಟೆ {minutes} ನಿಮಿಷ {seconds} ಸೆಕೆಂಡುಗಳಲ್ಲಿ ತೆರೆಯುತ್ತದೆ.|ಅದ್ಭುತ! ಇಂದಿನ {difficulty} ಸವಾಲು ಪೂರ್ಣ.|ಅದ್ಭುತ! {title} ಪೂರ್ಣ — ದೈನಂದಿನ ಕಾಯುವ ಮಿತಿಯಿಲ್ಲ.|{title} ಪರಿಹರಿಸಲಾಗಿದೆ. ಮುಂದಿನ ಒಗಟನ್ನು ಯಾವಾಗ ಬೇಕಾದರೂ ಮುಂದುವರಿಸಿ.|ಬಿಳಿಯ ಯಾವುದೇ ಕಾನೂನುಬದ್ಧ ನಡೆ ಆಡಿ. {count} ನಡೆಗಳಲ್ಲಿ ಚೆಕ್‌ಮೇಟ್ ಮಾಡಿ.|ಇದು ಕಾನೂನುಬದ್ಧ ನಡೆ, ಆದರೆ ತಂತ್ರವಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ ಚೆಕ್, ಸೆರೆ, ಬೆದರಿಕೆ ಹುಡುಕಿ.|ಚೆಕ್‌ಮೇಟ್‌ಗೆ ಮೊದಲು ನಡೆಯ ಮಿತಿ ಮುಗಿದಿದೆ. ಇದು ಸೋಲಲ್ಲ. ಬೋರ್ಡನ್ನು ಪರಿಶೀಲಿಸಿ ಮೊದಲು ಬಲವಂತದ ಚೆಕ್ ಹುಡುಕಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.|{count} ನಡೆಗಳಲ್ಲಿ ಚೆಕ್‌ಮೇಟ್ ಆಗಿಲ್ಲ.|ನಿಮ್ಮ ದೈನಂದಿನ ಪ್ರಯತ್ನ ಇನ್ನೂ ಲಭ್ಯವಿದೆ.|ಸಿದ್ಧವಾದಾಗ ಈ ಒಗಟನ್ನು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.|ಸ್ಟೇಲ್‌ಮೇಟ್ ಚೆಕ್‌ಮೇಟ್ ತಪ್ಪಿಸುತ್ತದೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.|ಸ್ಟೇಲ್‌ಮೇಟ್ ಚೆಕ್‌ಮೇಟ್ ಗುರಿಯಲ್ಲ. ಬಲವಂತದ ಸಾಲನ್ನು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.|ಆ ನಡೆ ಒಗಟಿನ ಪರಿಹಾರದಿಂದ ದೂರ ಹೋಗುತ್ತದೆ. ಬಲವಂತದ ಸಾಲು ಕಂಡು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.''',
  'ml':
      '''അസാധുവായ ബോർഡ് കണ്ടെത്തി സുരക്ഷിതമായി പുനഃസജ്ജമാക്കി. രാജാവിനെ പിടിക്കാനാവില്ല.|അതിഥി മോഡ് തയ്യാർ. പുരോഗതി സൂക്ഷിക്കാൻ പിന്നീട് അക്കൗണ്ട് ഉണ്ടാക്കുക.|{count} നീക്കങ്ങൾ ബാക്കി. ചെക്ക്മേറ്റ് കണ്ടെത്തുക.|ദൈനംദിന ചെക്ക്മേറ്റ് പൂർത്തി. അടുത്ത വെല്ലുവിളി {hours} മണിക്കൂർ {minutes} മിനിറ്റ് {seconds} സെക്കൻഡിൽ തുറക്കും.|ഗംഭീരം! ഇന്നത്തെ {difficulty} വെല്ലുവിളി പൂർത്തി.|ഗംഭീരം! {title} പൂർത്തി — ദിവസേന കാത്തിരിപ്പ് പരിധിയില്ല.|{title} പരിഹരിച്ചു. അടുത്ത പസിൽ എപ്പോൾ വേണമെങ്കിലും തുടരുക.|വെള്ളയുടെ ഏത് നിയമാനുസൃത നീക്കവും കളിക്കുക. {count} നീക്കങ്ങളിൽ ചെക്ക്മേറ്റ് ചെയ്യുക.|ഇത് നിയമാനുസൃത നീക്കമാണ്, പക്ഷേ തന്ത്രമല്ല. വീണ്ടും ശ്രമിച്ച് ചെക്ക്, പിടിത്തം, ഭീഷണി നോക്കുക.|ചെക്ക്മേറ്റിന് മുമ്പ് നീക്കപരിധി കഴിഞ്ഞു. ഇത് തോൽവിയല്ല. ബോർഡ് പരിശോധിച്ച് നിർബന്ധിത ചെക്കുകൾ ആദ്യം കണ്ടെത്തി വീണ്ടും ശ്രമിക്കുക.|{count} നീക്കങ്ങളിൽ ചെക്ക്മേറ്റ് ആയില്ല.|നിങ്ങളുടെ ദൈനംദിന ശ്രമം ഇപ്പോഴും ലഭ്യമാണ്.|തയ്യാറാകുമ്പോൾ ഈ പസിൽ വീണ്ടും ശ്രമിക്കുക.|സ്റ്റേൽമേറ്റ് ചെക്ക്മേറ്റ് ഒഴിവാക്കുന്നു. വീണ്ടും ശ്രമിക്കുക.|സ്റ്റേൽമേറ്റ് ചെക്ക്മേറ്റ് ലക്ഷ്യമല്ല. നിർബന്ധിത ക്രമം വീണ്ടും ശ്രമിക്കുക.|ആ നീക്കം പസിൽ പരിഹാരത്തിൽനിന്ന് മാറുന്നു. നിർബന്ധിത ക്രമം കണ്ടെത്തി വീണ്ടും ശ്രമിക്കുക.''',
  'mr':
      '''अवैध पट सापडला आणि सुरक्षित रीसेट केला. राजाला मारता येत नाही.|अतिथी मोड तयार. प्रगती जतन करण्यासाठी नंतर खाते उघडा.|{count} चाली शिल्लक. मात शोधा.|दैनिक मात पूर्ण. पुढील आव्हान {hours} तास {minutes} मिनिटे {seconds} सेकंदांत उघडेल.|उत्कृष्ट! आजचे {difficulty} आव्हान पूर्ण.|उत्कृष्ट! {title} पूर्ण — दैनिक प्रतीक्षा मर्यादा नाही.|{title} सुटले. पुढील कोडे केव्हाही सुरू करा.|पांढऱ्याची कोणतीही वैध चाल खेळा. {count} चालींत मात करा.|ही वैध चाल आहे, पण अपेक्षित डावपेच नाही. पुन्हा प्रयत्न करून शह, मारण्याच्या संधी आणि धोके पाहा.|मात होण्यापूर्वी चालींची मर्यादा संपली. हा पराभव नाही. पट पाहा, आधी सक्तीचे शह शोधा व पुन्हा प्रयत्न करा.|{count} चालींत मात झाली नाही.|दैनिक प्रयत्न अजून उपलब्ध आहे.|तयार झाल्यावर हे कोडे पुन्हा सोडवा.|कोंडीमुळे मात टळते. पुन्हा प्रयत्न करा.|कोंडी हे मातचे ध्येय नाही. सक्तीचा क्रम पुन्हा खेळा.|ही चाल कोड्याच्या उत्तरापासून दूर जाते. सक्तीचा क्रम शोधा व पुन्हा प्रयत्न करा.''',
  'bn':
      '''অবৈধ বোর্ড পাওয়া গেছে এবং নিরাপদে রিসেট করা হয়েছে। রাজাকে ধরা যায় না।|অতিথি মোড প্রস্তুত। অগ্রগতি রাখতে পরে অ্যাকাউন্ট করুন।|{count} চাল বাকি। মাত খুঁজুন।|দৈনিক মাত সম্পূর্ণ। পরের চ্যালেঞ্জ {hours} ঘণ্টা {minutes} মিনিট {seconds} সেকেন্ডে খুলবে।|অসাধারণ! আজকের {difficulty} চ্যালেঞ্জ সম্পূর্ণ।|অসাধারণ! {title} সম্পূর্ণ — দৈনিক অপেক্ষার সীমা নেই।|{title} সমাধান হয়েছে। পরের ধাঁধা যেকোনো সময় করুন।|সাদার যেকোনো বৈধ চাল খেলুন। {count} চালে মাত করুন।|এটি বৈধ চাল, কিন্তু কৌশলটি নয়। আবার চেষ্টা করে কিস্তি, ধরা ও হুমকি দেখুন।|মাতের আগে চালের সীমা শেষ। এটি হার নয়। বোর্ড দেখুন, আগে বাধ্যকারী কিস্তি খুঁজে আবার চেষ্টা করুন।|{count} চালে মাত হয়নি।|আপনার দৈনিক চেষ্টা এখনও আছে।|প্রস্তুত হলে এই ধাঁধা আবার চেষ্টা করুন।|অচলাবস্থা মাত এড়ায়। আবার চেষ্টা করুন।|অচলাবস্থা মাতের লক্ষ্য নয়। বাধ্যকারী ক্রম আবার চেষ্টা করুন।|এই চাল ধাঁধার সমাধান থেকে সরে যায়। বাধ্যকারী ক্রম খুঁজে আবার চেষ্টা করুন।''',
  'gu':
      '''અમાન્ય બોર્ડ મળ્યું અને સુરક્ષિત રીસેટ કર્યું. રાજાને મારી શકાય નહીં.|અતિથિ મોડ તૈયાર. પ્રગતિ સાચવવા પછી ખાતું બનાવો.|{count} ચાલ બાકી. માત શોધો.|દૈનિક માત પૂર્ણ. આગળનો પડકાર {hours} કલાક {minutes} મિનિટ {seconds} સેકન્ડમાં ખુલશે.|અદ્ભુત! આજનો {difficulty} પડકાર પૂર્ણ.|અદ્ભુત! {title} પૂર્ણ — દૈનિક રાહની મર્યાદા નથી.|{title} ઉકેલાયું. આગળનો કોયડો ગમે ત્યારે કરો.|સફેદની કોઈપણ કાયદેસર ચાલ રમો. {count} ચાલમાં માત કરો.|આ કાયદેસર ચાલ છે, પણ તે યુક્તિ નથી. ફરી પ્રયત્ન કરી શાહ, મારવું અને ખતરા જુઓ.|માત પહેલાં ચાલની મર્યાદા પૂરી થઈ. આ હાર નથી. બોર્ડ જુઓ, ફરજિયાત શાહ પહેલાં શોધી ફરી પ્રયત્ન કરો.|{count} ચાલમાં માત ન થઈ.|તમારો દૈનિક પ્રયત્ન હજુ ઉપલબ્ધ છે.|તૈયાર થાઓ ત્યારે આ કોયડો ફરી અજમાવો.|ગતિરોધ માત ટાળે છે. ફરી પ્રયત્ન કરો.|ગતિરોધ માતનું લક્ષ્ય નથી. ફરજિયાત ક્રમ ફરી અજમાવો.|આ ચાલ કોયડાના ઉકેલથી દૂર જાય છે. ફરજિયાત ક્રમ શોધી ફરી પ્રયત્ન કરો.''',
  'pa':
      '''ਗਲਤ ਬੋਰਡ ਮਿਲਿਆ ਤੇ ਸੁਰੱਖਿਅਤ ਰੀਸੈੱਟ ਕੀਤਾ। ਰਾਜੇ ਨੂੰ ਮਾਰਿਆ ਨਹੀਂ ਜਾ ਸਕਦਾ।|ਮਹਿਮਾਨ ਮੋਡ ਤਿਆਰ। ਤਰੱਕੀ ਸੰਭਾਲਣ ਲਈ ਬਾਅਦ ਵਿੱਚ ਖਾਤਾ ਬਣਾਓ।|{count} ਚਾਲਾਂ ਬਾਕੀ। ਮਾਤ ਲੱਭੋ।|ਰੋਜ਼ਾਨਾ ਮਾਤ ਪੂਰੀ। ਅਗਲੀ ਚੁਣੌਤੀ {hours} ਘੰਟੇ {minutes} ਮਿੰਟ {seconds} ਸਕਿੰਟ ਵਿੱਚ ਖੁੱਲ੍ਹੇਗੀ।|ਸ਼ਾਨਦਾਰ! ਅੱਜ ਦੀ {difficulty} ਚੁਣੌਤੀ ਪੂਰੀ।|ਸ਼ਾਨਦਾਰ! {title} ਪੂਰੀ — ਰੋਜ਼ਾਨਾ ਉਡੀਕ ਦੀ ਹੱਦ ਨਹੀਂ।|{title} ਹੱਲ ਹੋਈ। ਅਗਲੀ ਬੁਝਾਰਤ ਕਦੇ ਵੀ ਕਰੋ।|ਚਿੱਟੇ ਦੀ ਕੋਈ ਜਾਇਜ਼ ਚਾਲ ਖੇਡੋ। {count} ਚਾਲਾਂ ਵਿੱਚ ਮਾਤ ਕਰੋ।|ਇਹ ਜਾਇਜ਼ ਚਾਲ ਹੈ ਪਰ ਸਹੀ ਦਾਅ ਨਹੀਂ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰਕੇ ਸ਼ਹ, ਮਾਰਨ ਅਤੇ ਖ਼ਤਰੇ ਲੱਭੋ।|ਮਾਤ ਤੋਂ ਪਹਿਲਾਂ ਚਾਲਾਂ ਦੀ ਹੱਦ ਮੁੱਕੀ। ਇਹ ਹਾਰ ਨਹੀਂ। ਬੋਰਡ ਵੇਖੋ, ਪਹਿਲਾਂ ਮਜਬੂਰ ਕਰਨ ਵਾਲੀ ਸ਼ਹ ਲੱਭੋ ਅਤੇ ਫਿਰ ਕੋਸ਼ਿਸ਼ ਕਰੋ।|{count} ਚਾਲਾਂ ਵਿੱਚ ਮਾਤ ਨਹੀਂ ਹੋਈ।|ਤੁਹਾਡਾ ਰੋਜ਼ਾਨਾ ਯਤਨ ਹਾਲੇ ਬਾਕੀ ਹੈ।|ਤਿਆਰ ਹੋਣ ਉੱਤੇ ਇਹ ਬੁਝਾਰਤ ਫਿਰ ਕਰੋ।|ਖੜੋਤ ਮਾਤ ਤੋਂ ਬਚਾਉਂਦੀ ਹੈ। ਫਿਰ ਕੋਸ਼ਿਸ਼ ਕਰੋ।|ਖੜੋਤ ਮਾਤ ਦਾ ਟੀਚਾ ਨਹੀਂ। ਮਜਬੂਰ ਕਰਨ ਵਾਲਾ ਕ੍ਰਮ ਫਿਰ ਖੇਡੋ।|ਇਹ ਚਾਲ ਬੁਝਾਰਤ ਦੇ ਹੱਲ ਤੋਂ ਹਟਦੀ ਹੈ। ਸਹੀ ਮਜਬੂਰ ਕਰਨ ਵਾਲਾ ਕ੍ਰਮ ਲੱਭ ਕੇ ਫਿਰ ਕੋਸ਼ਿਸ਼ ਕਰੋ।''',
  'ur':
      '''غلط بورڈ ملا اور محفوظ طریقے سے ری سیٹ کیا گیا۔ بادشاہ کو نہیں مارا جا سکتا۔|مہمان موڈ تیار ہے۔ پیش رفت محفوظ کرنے کے لیے بعد میں اکاؤنٹ بنائیں۔|{count} چالیں باقی ہیں۔ مات تلاش کریں۔|روزانہ مات مکمل۔ اگلا چیلنج {hours} گھنٹے {minutes} منٹ {seconds} سیکنڈ میں کھلے گا۔|شاندار! آج کا {difficulty} چیلنج مکمل۔|شاندار! {title} مکمل — روزانہ انتظار کی حد نہیں۔|{title} حل ہوگئی۔ اگلی پہیلی کبھی بھی جاری رکھیں۔|سفید کی کوئی جائز چال کھیلیں۔ {count} چالوں میں مات کریں۔|یہ جائز چال ہے مگر مطلوبہ ترکیب نہیں۔ دوبارہ کوشش کرکے شہ، مارنے اور خطرات دیکھیں۔|مات سے پہلے چالوں کی حد ختم ہوئی۔ یہ ہار نہیں۔ بورڈ دیکھیں، پہلے جبری شہ تلاش کریں اور پھر کوشش کریں۔|{count} چالوں میں مات نہیں ہوئی۔|آپ کی روزانہ کوشش ابھی دستیاب ہے۔|تیار ہوں تو یہ پہیلی پھر آزمائیں۔|بندش مات سے بچاتی ہے۔ دوبارہ کوشش کریں۔|بندش مات کا مقصد نہیں۔ جبری ترتیب پھر آزمائیں۔|یہ چال پہیلی کے حل سے ہٹتی ہے۔ جبری ترتیب تلاش کرکے پھر کوشش کریں۔''',
  'ar':
      '''اكتُشفت لوحة غير صالحة وأُعيدت بأمان. لا يمكن أخذ الملوك.|وضع الضيف جاهز. أنشئ حسابًا لاحقًا لحفظ التقدم.|بقيت {count} نقلات. اعثر على المات.|اكتمل المات اليومي. يفتح التحدي التالي خلال {hours} ساعة و{minutes} دقيقة و{seconds} ثانية.|رائع! اكتمل تحدي اليوم {difficulty}.|رائع! اكتمل {title} — لا انتظار يومي.|تم حل {title}. تابع اللغز التالي في أي وقت.|العب أي نقلة قانونية للأبيض. حقق المات خلال {count} نقلات.|هذه نقلة قانونية لكنها ليست الحل التكتيكي. أعد المحاولة وابحث عن الكش والأخذ والتهديدات.|انتهى حد النقلات قبل المات. ليست خسارة. راجع اللوحة وابحث عن الكش الإجباري أولاً ثم أعد المحاولة.|لم يتحقق المات خلال {count} نقلات.|محاولتك اليومية لا تزال متاحة.|أعد هذا اللغز عندما تكون مستعدًا.|الخنق يتجنب المات. أعد المحاولة.|الخنق ليس هدف المات. جرّب التسلسل الإجباري مجددًا.|تخرج هذه النقلة عن حل اللغز. اعثر على التسلسل الإجباري وأعد المحاولة.''',
  'es':
      '''Tablero inválido detectado y restablecido con seguridad. Los reyes no se capturan.|Modo invitado listo. Crea una cuenta después para guardar el progreso.|Quedan {count} jugadas. Encuentra el mate.|Mate diario completado. El próximo desafío se abre en {hours} horas {minutes} minutos {seconds} segundos.|¡Genial! El desafío {difficulty} de hoy está completado.|¡Genial! {title} completado, sin espera diaria.|{title} resuelto. Continúa con el siguiente problema cuando quieras.|Juega cualquier movimiento legal blanco. Da mate en {count} jugadas.|Es una jugada legal, pero no la táctica. Reintenta y busca jaques, capturas y amenazas.|Se acabó el límite antes del mate. No es una derrota. Revisa el tablero, busca primero jaques forzantes y reintenta.|No hubo mate en {count} jugadas.|Tu intento diario sigue disponible.|Reintenta este problema cuando estés listo.|El ahogado evita el mate. Reintenta.|El ahogado no cumple el objetivo de mate. Reintenta la línea forzante.|La jugada se aparta de la solución. Encuentra la línea forzante y reintenta.''',
  'fr':
      '''Échiquier invalide détecté et réinitialisé sans risque. Les rois ne peuvent pas être capturés.|Mode invité prêt. Créez un compte plus tard pour sauvegarder la progression.|Il reste {count} coups. Trouvez le mat.|Mat quotidien terminé. Prochain défi dans {hours} heures {minutes} minutes {seconds} secondes.|Bravo ! Le défi {difficulty} d’aujourd’hui est terminé.|Bravo ! {title} terminé, sans attente quotidienne.|{title} résolu. Passez au prochain problème quand vous voulez.|Jouez un coup blanc légal. Matez en {count} coups.|Ce coup est légal, mais ce n’est pas la tactique. Réessayez et cherchez échecs, captures et menaces.|La limite est atteinte avant le mat. Ce n’est pas une défaite. Examinez l’échiquier, trouvez d’abord les échecs forçants, puis réessayez.|Pas de mat en {count} coups.|Votre tentative quotidienne reste disponible.|Réessayez ce problème quand vous serez prêt.|Le pat évite le mat. Réessayez.|Le pat n’est pas l’objectif de mat. Réessayez la ligne forçante.|Ce coup quitte la solution. Trouvez la ligne forçante et réessayez.''',
  'de':
      '''Ungültiges Brett erkannt und sicher zurückgesetzt. Könige können nicht geschlagen werden.|Gastmodus bereit. Erstelle später ein Konto, um Fortschritt zu speichern.|Noch {count} Züge. Finde das Matt.|Tagesmatt abgeschlossen. Nächste Aufgabe in {hours} Stunden {minutes} Minuten {seconds} Sekunden.|Großartig! Die heutige Aufgabe {difficulty} ist abgeschlossen.|Großartig! {title} abgeschlossen — keine tägliche Wartezeit.|{title} gelöst. Fahre jederzeit mit der nächsten Aufgabe fort.|Spiele einen legalen weißen Zug. Matt in {count} Zügen.|Das ist legal, aber nicht die Taktik. Versuche erneut und suche Schachs, Schläge und Drohungen.|Zuglimit vor dem Matt erreicht. Das ist keine Niederlage. Prüfe das Brett, finde zuerst forcierende Schachs und versuche erneut.|Kein Matt innerhalb von {count} Zügen.|Dein täglicher Versuch ist weiterhin verfügbar.|Versuche diese Aufgabe erneut, wenn du bereit bist.|Patt vermeidet Matt. Versuche erneut.|Patt erfüllt das Mattziel nicht. Versuche die forcierende Variante erneut.|Der Zug verlässt die Lösung. Finde die forcierende Variante und versuche erneut.''',
  'it':
      '''Scacchiera non valida rilevata e ripristinata in sicurezza. I re non si catturano.|Modalità ospite pronta. Crea un account più tardi per salvare i progressi.|Restano {count} mosse. Trova il matto.|Matto giornaliero completato. Prossima sfida tra {hours} ore {minutes} minuti {seconds} secondi.|Bravo! Sfida {difficulty} di oggi completata.|Bravo! {title} completato, senza attesa giornaliera.|{title} risolto. Continua con il prossimo problema quando vuoi.|Gioca una mossa bianca legale. Matto in {count} mosse.|È una mossa legale, ma non la tattica. Riprova e cerca scacchi, catture e minacce.|Limite raggiunto prima del matto. Non è una sconfitta. Rivedi la scacchiera, cerca prima scacchi forzanti e riprova.|Nessun matto entro {count} mosse.|Il tentativo giornaliero è ancora disponibile.|Riprova questo problema quando sei pronto.|Lo stallo evita il matto. Riprova.|Lo stallo non è l’obiettivo di matto. Riprova la linea forzante.|La mossa esce dalla soluzione. Trova la linea forzante e riprova.''',
  'pt':
      '''Tabuleiro inválido detetado e reposto em segurança. Reis não podem ser capturados.|Modo convidado pronto. Crie uma conta depois para guardar o progresso.|Restam {count} lances. Encontre o mate.|Mate diário concluído. Próximo desafio em {hours} horas {minutes} minutos {seconds} segundos.|Excelente! Desafio {difficulty} de hoje concluído.|Excelente! {title} concluído, sem espera diária.|{title} resolvido. Continue com o próximo problema quando quiser.|Jogue qualquer lance branco legal. Mate em {count} lances.|É um lance legal, mas não a tática. Tente novamente e procure xeques, capturas e ameaças.|O limite terminou antes do mate. Não é derrota. Reveja o tabuleiro, encontre primeiro xeques forçantes e tente novamente.|Nenhum mate em {count} lances.|A tentativa diária continua disponível.|Tente este problema de novo quando estiver pronto.|O afogamento evita o mate. Tente novamente.|O afogamento não é o objetivo de mate. Repita a linha forçante.|O lance sai da solução. Encontre a linha forçante e tente novamente.''',
  'ru':
      '''Обнаружена неверная доска, выполнен безопасный сброс. Королей нельзя брать.|Гостевой режим готов. Создайте аккаунт позже, чтобы сохранять прогресс.|Осталось ходов: {count}. Найдите мат.|Ежедневный мат решён. Следующее задание через {hours} ч {minutes} мин {seconds} с.|Отлично! Сегодняшнее задание {difficulty} выполнено.|Отлично! {title} выполнено — без ежедневного ожидания.|{title} решено. Продолжайте со следующей задачей в любое время.|Сделайте любой допустимый ход белых. Мат в {count} ходов.|Это допустимый ход, но не нужная тактика. Повторите и ищите шахи, взятия и угрозы.|Лимит ходов закончился до мата. Это не поражение. Проверьте доску, сначала найдите форсирующие шахи и повторите.|Нет мата за {count} ходов.|Ваша ежедневная попытка ещё доступна.|Повторите задачу, когда будете готовы.|Пат избегает мата. Повторите.|Пат не выполняет цель поставить мат. Повторите форсирующий вариант.|Ход уводит от решения. Найдите форсирующий вариант и повторите.''',
  'uk':
      '''Виявлено неправильну дошку, безпечно скинуто. Королів не можна брати.|Гостьовий режим готовий. Створіть обліковий запис пізніше для збереження прогресу.|Залишилося ходів: {count}. Знайдіть мат.|Щоденний мат завершено. Наступне завдання через {hours} год {minutes} хв {seconds} с.|Чудово! Сьогоднішнє завдання {difficulty} виконано.|Чудово! {title} виконано — без щоденного очікування.|{title} розв’язано. Продовжуйте наступну задачу будь-коли.|Зробіть будь-який допустимий хід білих. Мат за {count} ходів.|Це допустимий хід, але не потрібна тактика. Повторіть і шукайте шахи, взяття та загрози.|Ліміт ходів закінчився до мату. Це не поразка. Перевірте дошку, знайдіть спершу форсовані шахи та повторіть.|Немає мату за {count} ходів.|Ваша щоденна спроба ще доступна.|Повторіть задачу, коли будете готові.|Пат уникає мату. Повторіть.|Пат не виконує мету поставити мат. Повторіть форсований варіант.|Хід відходить від розв’язку. Знайдіть форсований варіант і повторіть.''',
  'tr':
      '''Geçersiz tahta bulundu ve güvenle sıfırlandı. Şahlar alınamaz.|Misafir modu hazır. İlerlemeyi kaydetmek için sonra hesap oluştur.|{count} hamle kaldı. Matı bul.|Günlük mat tamamlandı. Sonraki görev {hours} saat {minutes} dakika {seconds} saniye sonra açılır.|Harika! Bugünün {difficulty} görevi tamamlandı.|Harika! {title} tamamlandı — günlük bekleme yok.|{title} çözüldü. Sonraki bulmacaya istediğin zaman geç.|Beyazın herhangi bir yasal hamlesini oyna. {count} hamlede mat et.|Yasal bir hamle ama taktik bu değil. Tekrar dene; şah, alış ve tehdit ara.|Mattan önce hamle sınırı bitti. Bu yenilgi değil. Tahtayı incele, önce zorlayıcı şahları bul, tekrar dene.|{count} hamlede mat yok.|Günlük denemen hâlâ kullanılabilir.|Hazır olduğunda bulmacayı tekrar dene.|Pat matı önler. Tekrar dene.|Pat, mat hedefi değildir. Zorlayıcı varyantı tekrar dene.|Hamle çözümden uzaklaşıyor. Zorlayıcı varyantı bul ve tekrar dene.''',
  'fa':
      '''صفحه نامعتبر شناسایی و ایمن بازنشانی شد. شاه‌ها قابل گرفتن نیستند.|حالت مهمان آماده است. بعداً برای ذخیره پیشرفت حساب بسازید.|{count} حرکت مانده است. مات را پیدا کنید.|مات روزانه کامل شد. چالش بعدی در {hours} ساعت {minutes} دقیقه {seconds} ثانیه باز می‌شود.|عالی! چالش {difficulty} امروز کامل شد.|عالی! {title} کامل شد؛ بدون انتظار روزانه.|{title} حل شد. هر وقت خواستید معمای بعدی را ادامه دهید.|هر حرکت مجاز سفید را بازی کنید. در {count} حرکت مات کنید.|این حرکت مجاز است ولی تاکتیک موردنظر نیست. دوباره تلاش کنید و کیش، گرفتن و تهدید را ببینید.|حد حرکت پیش از مات تمام شد. این شکست نیست. صفحه را بررسی کنید، اول کیش‌های اجباری را بیابید و دوباره تلاش کنید.|در {count} حرکت مات نشد.|تلاش روزانه شما هنوز در دسترس است.|هر وقت آماده بودید دوباره معما را امتحان کنید.|پات مانع مات می‌شود. دوباره تلاش کنید.|پات هدف مات نیست. مسیر اجباری را دوباره امتحان کنید.|این حرکت از حل معما خارج می‌شود. مسیر اجباری را یافته و دوباره تلاش کنید.''',
  'zh':
      '''检测到无效棋盘并已安全重置。王不能被吃掉。|访客模式已就绪。稍后创建账户可保存进度。|还剩{count}步。寻找将死。|每日杀王已完成。下一挑战在{hours}小时{minutes}分钟{seconds}秒后解锁。|精彩！今天的{difficulty}挑战已完成。|精彩！{title}完成——没有每日等待限制。|{title}已解答。随时继续下一题。|走白方任意合法着法。在{count}步内将死。|这是合法着法，但不是本题战术。重试并寻找将军、吃子和威胁。|将死前已用完步数。这不是输棋。检查棋盘，先寻找强制将军，再重试。|{count}步内未将死。|你的每日尝试仍可使用。|准备好后随时重试此题。|逼和避免将死。请重试。|逼和不是将死目标。请重试强制变化。|这步偏离了题目解法。找到强制变化再重试。''',
  'ja':
      '''無効な盤面を検出し、安全にリセットしました。キングは捕獲できません。|ゲストモードの準備完了。進歩を保存するには後でアカウントを作成してください。|残り{count}手。メイトを見つけましょう。|毎日のメイト達成。次の挑戦は{hours}時間{minutes}分{seconds}秒後に解放されます。|素晴らしい！今日の{difficulty}の挑戦を達成しました。|素晴らしい！{title}を達成。毎日の待ち時間はありません。|{title}を解きました。いつでも次の問題に進めます。|白の合法手を指してください。{count}手でメイトしましょう。|合法手ですが、この戦術ではありません。再挑戦してチェック、捕獲、脅威を探しましょう。|メイト前に手数制限に達しました。負けではありません。盤面を見直し、強制的なチェックを先に探して再挑戦しましょう。|{count}手以内にメイトできませんでした。|毎日の挑戦はまだ利用できます。|準備ができたらこの問題を再挑戦してください。|ステイルメイトはメイトを回避します。再挑戦しましょう。|ステイルメイトはメイトの目標を達成しません。強制手順を再挑戦しましょう。|この手は解答から外れます。強制手順を見つけて再挑戦しましょう。''',
  'ko':
      '''잘못된 보드를 감지해 안전하게 초기화했습니다. 킹은 잡을 수 없습니다.|게스트 모드가 준비되었습니다. 진행을 저장하려면 나중에 계정을 만드세요.|{count}수 남았습니다. 메이트를 찾으세요.|일일 메이트 완료. 다음 도전은 {hours}시간 {minutes}분 {seconds}초 뒤 열립니다.|훌륭합니다! 오늘의 {difficulty} 도전 완료.|훌륭합니다! {title} 완료 — 매일 기다릴 필요가 없습니다.|{title} 해결. 언제든 다음 퍼즐을 계속하세요.|백의 합법적인 수를 두세요. {count}수 안에 메이트하세요.|합법적인 수지만 이 전술은 아닙니다. 다시 시도하고 체크, 잡기, 위협을 찾으세요.|메이트 전에 수 제한이 끝났습니다. 패배가 아닙니다. 보드를 검토하고 강제 체크부터 찾아 다시 시도하세요.|{count}수 안에 메이트하지 못했습니다.|일일 시도는 아직 가능합니다.|준비되면 이 퍼즐을 다시 시도하세요.|스테일메이트는 메이트를 피합니다. 다시 시도하세요.|스테일메이트는 메이트 목표가 아닙니다. 강제 수순을 다시 시도하세요.|이 수는 퍼즐 해법에서 벗어납니다. 강제 수순을 찾아 다시 시도하세요.''',
  'id':
      '''Papan tidak valid ditemukan dan diatur ulang dengan aman. Raja tidak dapat ditangkap.|Mode tamu siap. Buat akun nanti untuk menyimpan kemajuan.|Tersisa {count} langkah. Temukan mat.|Mat harian selesai. Tantangan berikut terbuka dalam {hours} jam {minutes} menit {seconds} detik.|Hebat! Tantangan {difficulty} hari ini selesai.|Hebat! {title} selesai — tanpa batas tunggu harian.|{title} terpecahkan. Lanjutkan teka-teki berikut kapan saja.|Mainkan langkah putih legal. Mat dalam {count} langkah.|Itu langkah legal, tetapi bukan taktiknya. Coba lagi dan cari skak, tangkapan, serta ancaman.|Batas langkah berakhir sebelum mat. Ini bukan kekalahan. Tinjau papan, cari skak memaksa dahulu, lalu coba lagi.|Tidak ada mat dalam {count} langkah.|Percobaan harian Anda masih tersedia.|Coba teka-teki ini lagi saat siap.|Pat menghindari mat. Coba lagi.|Pat bukan tujuan mat. Coba jalur memaksa lagi.|Langkah itu keluar dari solusi. Temukan jalur memaksa dan coba lagi.''',
  'ms':
      '''Papan tidak sah dikesan dan ditetapkan semula dengan selamat. Raja tidak boleh ditangkap.|Mod tetamu sedia. Cipta akaun kemudian untuk menyimpan kemajuan.|Tinggal {count} gerakan. Cari mat.|Mat harian selesai. Cabaran seterusnya dibuka dalam {hours} jam {minutes} minit {seconds} saat.|Hebat! Cabaran {difficulty} hari ini selesai.|Hebat! {title} selesai — tiada had menunggu harian.|{title} diselesaikan. Teruskan teka-teki berikut bila-bila masa.|Mainkan gerakan putih yang sah. Mat dalam {count} gerakan.|Itu gerakan sah, tetapi bukan taktiknya. Cuba lagi dan cari syah, tangkapan dan ancaman.|Had gerakan tamat sebelum mat. Ini bukan kekalahan. Semak papan, cari syah memaksa dahulu, kemudian cuba lagi.|Tiada mat dalam {count} gerakan.|Cubaan harian anda masih tersedia.|Cuba teka-teki ini semula apabila sedia.|Buntu mengelakkan mat. Cuba lagi.|Buntu bukan mat yang disasarkan. Cuba turutan memaksa lagi.|Gerakan itu keluar daripada penyelesaian. Cari turutan memaksa dan cuba lagi.''',
  'th':
      '''พบบอร์ดไม่ถูกต้องและรีเซ็ตอย่างปลอดภัย คิงไม่สามารถถูกจับได้|โหมดผู้เยี่ยมชมพร้อม สร้างบัญชีภายหลังเพื่อบันทึกความคืบหน้า|เหลือ {count} ตา หารุกฆาต|รุกฆาตประจำวันสำเร็จ โจทย์ถัดไปเปิดใน {hours} ชั่วโมง {minutes} นาที {seconds} วินาที|ยอดเยี่ยม! ผ่านโจทย์ {difficulty} วันนี้แล้ว|ยอดเยี่ยม! {title} สำเร็จ — ไม่มีข้อจำกัดรอรายวัน|แก้ {title} แล้ว ไปโจทย์ถัดไปได้ทุกเมื่อ|เดินตาถูกกติกาของขาว รุกฆาตใน {count} ตา|ตานี้ถูกกติกาแต่ไม่ใช่กลยุทธ์คำตอบ ลองใหม่แล้วหาการรุก การจับ และภัย|ครบจำนวนตาก่อนรุกฆาต นี่ไม่ใช่แพ้ ทบทวนกระดาน หาการรุกบังคับก่อนแล้วลองใหม่|ไม่รุกฆาตภายใน {count} ตา|คุณยังลองโจทย์ประจำวันได้|ลองโจทย์นี้ใหม่เมื่อพร้อม|อับหลีกเลี่ยงรุกฆาต ลองใหม่|อับไม่ใช่เป้าหมายรุกฆาต ลองแนวบังคับใหม่|ตานี้ออกจากคำตอบโจทย์ หาแนวบังคับแล้วลองใหม่''',
  'vi':
      '''Phát hiện bàn cờ không hợp lệ và đặt lại an toàn. Không thể bắt vua.|Chế độ khách sẵn sàng. Tạo tài khoản sau để lưu tiến độ.|Còn {count} nước. Tìm chiếu hết.|Hoàn thành chiếu hết hằng ngày. Thử thách tiếp mở sau {hours} giờ {minutes} phút {seconds} giây.|Tuyệt! Hoàn thành thử thách {difficulty} hôm nay.|Tuyệt! Hoàn thành {title} — không cần đợi hằng ngày.|Đã giải {title}. Tiếp câu đố sau bất cứ lúc nào.|Đi một nước trắng hợp lệ. Chiếu hết trong {count} nước.|Đây là nước hợp lệ nhưng không đúng chiến thuật. Thử lại, tìm chiếu, bắt và đe dọa.|Hết giới hạn nước trước khi chiếu hết. Đây không phải thua. Xem bàn cờ, tìm chiếu cưỡng bức trước rồi thử lại.|Không chiếu hết trong {count} nước.|Lượt thử hằng ngày của bạn vẫn còn.|Thử câu đố lại khi sẵn sàng.|Hết nước tránh chiếu hết. Thử lại.|Hòa hết nước không phải mục tiêu chiếu hết. Thử lại biến cưỡng bức.|Nước này rời khỏi lời giải. Tìm biến cưỡng bức rồi thử lại.''',
  'pl':
      '''Wykryto nieprawidłową szachownicę i bezpiecznie ją zresetowano. Królów nie można zbijać.|Tryb gościa gotowy. Utwórz konto później, by zapisać postępy.|Pozostało {count} ruchów. Znajdź mata.|Codzienny mat ukończony. Następne wyzwanie za {hours} godz. {minutes} min {seconds} sek.|Świetnie! Dzisiejsze wyzwanie {difficulty} ukończone.|Świetnie! {title} ukończone — bez codziennego czekania.|{title} rozwiązane. Kontynuuj następne zadanie w dowolnym momencie.|Zagraj legalny ruch białych. Mat w {count} ruchach.|To legalny ruch, ale nie ta taktyka. Spróbuj ponownie i szukaj szachów, bić i gróźb.|Limit ruchów skończył się przed matem. To nie porażka. Sprawdź planszę, znajdź najpierw wymuszające szachy i spróbuj ponownie.|Brak mata w {count} ruchach.|Twoja dzienna próba jest nadal dostępna.|Spróbuj ponownie, gdy będziesz gotowy.|Pat unika mata. Spróbuj ponownie.|Pat nie jest celem matowym. Powtórz wymuszający wariant.|Ruch odchodzi od rozwiązania. Znajdź wymuszający wariant i spróbuj ponownie.''',
  'nl':
      '''Ongeldig bord gevonden en veilig hersteld. Koningen kunnen niet geslagen worden.|Gastmodus gereed. Maak later een account om voortgang op te slaan.|Nog {count} zetten. Vind mat.|Dagelijks mat voltooid. Volgende uitdaging over {hours} uur {minutes} minuten {seconds} seconden.|Geweldig! De uitdaging {difficulty} van vandaag is voltooid.|Geweldig! {title} voltooid — geen dagelijkse wachttijd.|{title} opgelost. Ga verder met de volgende puzzel wanneer je wilt.|Speel een legale witte zet. Mat in {count} zetten.|Dat is legaal, maar niet de tactiek. Probeer opnieuw en zoek schaak, slagen en dreigingen.|Zetlimiet bereikt vóór mat. Dit is geen verlies. Bekijk het bord, zoek eerst dwingende schaakzetten en probeer opnieuw.|Geen mat binnen {count} zetten.|Je dagelijkse poging is nog beschikbaar.|Probeer deze puzzel opnieuw wanneer je klaar bent.|Pat vermijdt mat. Probeer opnieuw.|Pat is niet het matdoel. Probeer de dwingende variant opnieuw.|De zet verlaat de oplossing. Vind de dwingende variant en probeer opnieuw.''',
  'sv':
      '''Ogiltigt bräde upptäckt och säkert återställt. Kungar kan inte slås.|Gästläget är klart. Skapa konto senare för att spara framsteg.|{count} drag återstår. Hitta matt.|Dagens matt klar. Nästa utmaning öppnas om {hours} timmar {minutes} minuter {seconds} sekunder.|Utmärkt! Dagens utmaning {difficulty} är klar.|Utmärkt! {title} klar — ingen daglig väntetid.|{title} löst. Fortsätt med nästa problem när du vill.|Spela ett lagligt vitt drag. Matt i {count} drag.|Det är ett lagligt drag, men inte taktiken. Försök igen och sök schackar, slag och hot.|Draggränsen tog slut före matt. Det är inte en förlust. Granska brädet, hitta tvingande schackar först och försök igen.|Ingen matt inom {count} drag.|Ditt dagliga försök är fortfarande tillgängligt.|Försök med problemet igen när du är redo.|Patt undviker matt. Försök igen.|Patt är inte mattmålet. Försök den tvingande varianten igen.|Draget lämnar lösningen. Hitta den tvingande varianten och försök igen.''',
  'el':
      '''Εντοπίστηκε άκυρη σκακιέρα και επαναφέρθηκε με ασφάλεια. Οι βασιλιάδες δεν αιχμαλωτίζονται.|Η λειτουργία επισκέπτη είναι έτοιμη. Δημιουργήστε λογαριασμό αργότερα για αποθήκευση προόδου.|Απομένουν {count} κινήσεις. Βρείτε ματ.|Το καθημερινό ματ ολοκληρώθηκε. Επόμενη πρόκληση σε {hours} ώρες {minutes} λεπτά {seconds} δευτερόλεπτα.|Μπράβο! Η σημερινή πρόκληση {difficulty} ολοκληρώθηκε.|Μπράβο! Το {title} ολοκληρώθηκε — χωρίς καθημερινή αναμονή.|Το {title} λύθηκε. Συνεχίστε με το επόμενο πρόβλημα όποτε θέλετε.|Παίξτε νόμιμη κίνηση λευκών. Ματ σε {count} κινήσεις.|Είναι νόμιμη κίνηση, αλλά όχι η τακτική. Ξαναδοκιμάστε και ψάξτε σαχ, χτυπήματα και απειλές.|Το όριο τελείωσε πριν το ματ. Δεν είναι ήττα. Δείτε τη σκακιέρα, βρείτε πρώτα αναγκαστικά σαχ και ξαναδοκιμάστε.|Δεν έγινε ματ σε {count} κινήσεις.|Η καθημερινή σας προσπάθεια παραμένει διαθέσιμη.|Ξαναδοκιμάστε το πρόβλημα όταν είστε έτοιμοι.|Το πατ αποφεύγει το ματ. Ξαναδοκιμάστε.|Το πατ δεν είναι ο στόχος ματ. Ξαναδοκιμάστε την αναγκαστική γραμμή.|Η κίνηση βγαίνει από τη λύση. Βρείτε την αναγκαστική γραμμή και ξαναδοκιμάστε.''',
  'he':
      '''לוח לא תקין זוהה ואופס בבטחה. אי אפשר להכות מלכים.|מצב אורח מוכן. צרו חשבון מאוחר יותר לשמירת התקדמות.|נותרו {count} מסעים. מצאו מט.|המט היומי הושלם. האתגר הבא ייפתח בעוד {hours} שעות {minutes} דקות {seconds} שניות.|מצוין! אתגר {difficulty} של היום הושלם.|מצוין! {title} הושלם — ללא המתנה יומית.|{title} נפתר. המשיכו לחידה הבאה בכל עת.|שחקו מסע לבן חוקי. מט ב־{count} מסעים.|זה מסע חוקי, אבל לא הטקטיקה. נסו שוב וחפשו שח, הכאות ואיומים.|מגבלת המסעים הסתיימה לפני מט. זה לא הפסד. בדקו את הלוח, מצאו תחילה שח כפוי ונסו שוב.|לא הושג מט ב־{count} מסעים.|הניסיון היומי שלכם עדיין זמין.|נסו את החידה שוב כשתהיו מוכנים.|פט נמנע ממט. נסו שוב.|פט אינו מטרת המט. נסו שוב את ההמשך הכפוי.|המסע סוטה מהפתרון. מצאו את ההמשך הכפוי ונסו שוב.''',
  'sw':
      '''Bodi batili imegunduliwa na kuwekwa upya salama. Wafalme hawawezi kukamatwa.|Hali ya mgeni iko tayari. Fungua akaunti baadaye kuhifadhi maendeleo.|Hatua {count} zimebaki. Tafuta mati.|Mati ya kila siku imekamilika. Changamoto inayofuata itafunguka baada ya saa {hours} dakika {minutes} sekunde {seconds}.|Hongera! Changamoto ya leo ya {difficulty} imekamilika.|Hongera! {title} imekamilika — hakuna kusubiri kila siku.|{title} imetatuliwa. Endelea na fumbo linalofuata wakati wowote.|Cheza hatua yoyote halali ya nyeupe. Mati katika hatua {count}.|Hiyo ni hatua halali lakini si mbinu hiyo. Jaribu tena ukitafuta shaha, ukamataji na vitisho.|Kikomo kimefika kabla ya mati. Huu si ushinde. Kagua bodi, tafuta kwanza shaha za kulazimisha, kisha jaribu tena.|Hakuna mati ndani ya hatua {count}.|Jaribio lako la kila siku bado linapatikana.|Jaribu fumbo hili tena ukiwa tayari.|Mkwamo huepuka mati. Jaribu tena.|Mkwamo si lengo la mati. Jaribu mfululizo wa kulazimisha tena.|Hatua hiyo inaondoka kwenye suluhisho. Tafuta mfululizo wa kulazimisha na ujaribu tena.''',
};

const liveStatusKeys = [
  'recommends',
  'promoted',
  'room',
  'left',
  'reconnect',
  'drawSent',
  'drawOffer',
  'chooseOnline',
  'sending',
  'rematch',
  'finalOnline',
  'recovery',
  'rejected',
  'mateIn',
  'defendMate',
  'balanced',
  'advantage',
  'sideToMove',
  'defendingSide'
];
final Map<String, List<String>> liveStatusTranslations = {
  for (final e in _statusRows.entries) e.key: e.value.split('|')
};
String? _translateStatus(String value, String code) {
  String t(String key, [Map<String, String> p = const {}]) =>
      _fill(liveStatusTranslations[code]![liveStatusKeys.indexOf(key)], p);
  const sources = {
    'Opponent connection lost. Waiting for reconnect...': 'reconnect',
    'Draw offer sent. Waiting for your opponent.': 'drawSent',
    'Your opponent offered a draw.': 'drawOffer',
    'Choose how you want to start your next online match.': 'chooseOnline',
    'Rematch requested. Waiting for your opponent...': 'rematch',
    'Online moves are final. Syncing the authoritative match...': 'finalOnline',
    'The position is approximately balanced.': 'balanced',
  };
  if (sources.containsKey(value)) return t(sources[value]!);
  if (value == 'Analysis complete. No legal move is available.' ||
      value == 'ChessVerseAI has no legal move.' ||
      value == 'Black has no legal reply.') {
    return '${localizeLiveCoach('Analyze', code)}: ${localizeLiveCoach('No legal moves found.', code)}';
  }
  if (value == 'AI reply recovered. Calculating again...') {
    return '${t('recovery', {
          'error': ''
        })} ${localizeLiveCoach('Running Stockfish position analysis…', code)}';
  }
  var m = RegExp(r'^Coach recommends (.+) for (White|Black)\.$',
          caseSensitive: false)
      .firstMatch(value);
  if (m != null) {
    return t('recommends', {
      'move': m[1]!,
      'side': CoachLocalizations(code).text(m[2]!.toLowerCase())
    });
  }
  m = RegExp(r'^Pawn promoted to ([QRBN]) on ([a-h][1-8])\.$')
      .firstMatch(value);
  if (m != null) return t('promoted', {'piece': m[1]!, 'square': m[2]!});
  m = RegExp(r'^Room (.+): waiting for your opponent\.$').firstMatch(value);
  if (m != null) return t('room', {'room': m[1]!});
  m = RegExp(r'^Opponent left\. You win in (\d+)s if they do not reconnect\.$')
      .firstMatch(value);
  if (m != null) return t('left', {'seconds': m[1]!});
  m = RegExp(r'^Your turn \((white|black)\)\.$', caseSensitive: false)
      .firstMatch(value);
  if (m != null) {
    return '${localizeLiveCoach('YOUR TURN', code)} (${CoachLocalizations(code).text(m[1]!.toLowerCase())}).';
  }
  m = RegExp(r'^Waiting for (white|black) to move\.$', caseSensitive: false)
      .firstMatch(value);
  if (m != null) {
    return '${localizeLiveCoach('Waiting for your opponent to move.', code)} (${CoachLocalizations(code).text(m[1]!.toLowerCase())})';
  }
  m = RegExp(r'^Sending (.+) to your opponent\.\.\.$').firstMatch(value);
  if (m != null) return t('sending', {'move': m[1]!});
  m = RegExp(r'^(?:Rematch reconnect pending|Reconnect pending): (.*)$',
          dotAll: true)
      .firstMatch(value);
  if (m != null) return t('recovery', {'error': m[1]!});
  m = RegExp(r'^Move not accepted: (.*)$', dotAll: true).firstMatch(value);
  if (m != null) return t('rejected', {'error': m[1]!});
  m = RegExp(r'^There is a forced checkmate in (\d+)\.$').firstMatch(value);
  if (m != null) return t('mateIn', {'count': m[1]!});
  m = RegExp(r'^You must defend against checkmate in (\d+)\.$')
      .firstMatch(value);
  if (m != null) return t('defendMate', {'count': m[1]!});
  m = RegExp(
          r'^Stockfish estimates a ([\d.]+) pawn advantage for (the side to move|the defending side)\.$')
      .firstMatch(value);
  if (m != null) {
    return t('advantage', {
      'count': m[1]!,
      'side': t(m[2] == 'the side to move' ? 'sideToMove' : 'defendingSide')
    });
  }
  return null;
}

const _statusRows = <String, String>{
  'en':
      '''Coach recommends {move} for {side}.|Pawn promoted to {piece} on {square}.|Room {room}: waiting for your opponent.|Opponent left. You win in {seconds}s if they do not reconnect.|Opponent connection lost. Waiting for reconnect...|Draw offer sent. Waiting for your opponent.|Your opponent offered a draw.|Choose how you want to start your next online match.|Sending {move} to your opponent...|Rematch requested. Waiting for your opponent...|Online moves are final. Syncing the authoritative match...|Reconnect pending: {error}|Move not accepted: {error}|There is a forced checkmate in {count}.|You must defend against checkmate in {count}.|The position is approximately balanced.|Stockfish estimates a {count} pawn advantage for {side}.|the side to move|the defending side''',
  'te':
      '''కోచ్ {side}కు {move} సూచిస్తున్నారు.|{square}లో సైనికుడు {piece}గా ప్రమోట్ అయ్యాడు.|గది {room}: ప్రత్యర్థి కోసం వేచి ఉంది.|ప్రత్యర్థి వెళ్లిపోయారు. తిరిగి కనెక్ట్ కాకపోతే {seconds} సెకన్లలో మీరు గెలుస్తారు.|ప్రత్యర్థి కనెక్షన్ పోయింది. తిరిగి కనెక్ట్ కోసం వేచి ఉంది…|డ్రా ప్రతిపాదన పంపారు. ప్రత్యర్థి కోసం వేచి ఉంది.|ప్రత్యర్థి డ్రా ప్రతిపాదించారు.|మీ తదుపరి ఆన్‌లైన్ మ్యాచ్‌ను ఎలా ప్రారంభించాలో ఎంచుకోండి.|ప్రత్యర్థికి {move} పంపుతోంది…|రీమ్యాచ్ కోరారు. ప్రత్యర్థి కోసం వేచి ఉంది…|ఆన్‌లైన్ ఎత్తులు తుది నిర్ణయం. సర్వర్ మ్యాచ్‌తో సమకాలీకరిస్తోంది…|మళ్లీ కనెక్షన్ పెండింగ్: {error}|ఎత్తు అంగీకరించలేదు: {error}|{count}లో బలవంతపు చెక్‌మేట్ ఉంది.|{count}లో చెక్‌మేట్‌ను మీరు అడ్డుకోవాలి.|స్థితి దాదాపు సమంగా ఉంది.|Stockfish ప్రకారం {side}కు {count} సైనికుల విలువ ఆధిక్యం.|ఆడవలసిన పక్షం|రక్షిస్తున్న పక్షం''',
  'hi':
      '''कोच {side} के लिए {move} सुझाते हैं।|{square} पर प्यादा {piece} बना।|कमरा {room}: प्रतिद्वंद्वी की प्रतीक्षा है।|प्रतिद्वंद्वी चला गया। दोबारा न जुड़ा तो {seconds} सेकंड में आप जीतेंगे।|प्रतिद्वंद्वी का कनेक्शन टूटा। फिर जुड़ने की प्रतीक्षा…|ड्रॉ प्रस्ताव भेजा। प्रतिद्वंद्वी की प्रतीक्षा है।|प्रतिद्वंद्वी ने ड्रॉ प्रस्तावित किया।|अगला ऑनलाइन मैच कैसे शुरू करना है चुनें।|प्रतिद्वंद्वी को {move} भेज रहे हैं…|दोबारा मैच का अनुरोध भेजा। प्रतिद्वंद्वी की प्रतीक्षा…|ऑनलाइन चालें अंतिम हैं। आधिकारिक मैच समन्वय हो रहा है…|दोबारा जुड़ना बाकी: {error}|चाल स्वीकार नहीं हुई: {error}|{count} में बाध्यकारी मात है।|आपको {count} में मात से बचाव करना होगा।|स्थिति लगभग बराबर है।|Stockfish के अनुसार {side} को {count} प्यादों का लाभ है।|चाल वाला पक्ष|बचाव वाला पक्ष''',
  'ta':
      '''பயிற்சியாளர் {side} க்கு {move} பரிந்துரைக்கிறார்.|{square} இல் சிப்பாய் {piece} ஆனது.|அறை {room}: எதிரிக்காகக் காத்திருக்கிறது.|எதிரி விலகினார். மீண்டும் இணையாவிட்டால் {seconds} விநாடியில் வெல்வீர்கள்.|எதிரியின் இணைப்பு துண்டித்தது. மீண்டும் இணைவதற்குக் காத்திருக்கிறது…|சமநிலை முன்மொழிவு அனுப்பப்பட்டது. எதிரிக்காகக் காத்திருக்கிறது.|எதிரி சமநிலை முன்மொழிந்தார்.|அடுத்த இணைய ஆட்டத்தை எப்படித் தொடங்குவது எனத் தேர்ந்தெடுக்கவும்.|எதிரிக்கு {move} அனுப்புகிறது…|மறுஆட்டம் கோரப்பட்டது. எதிரிக்காகக் காத்திருக்கிறது…|இணைய நகர்வுகள் இறுதியானவை. அதிகாரப்பூர்வ ஆட்டத்தை ஒத்திசைக்கிறது…|மீண்டும் இணைப்பு நிலுவை: {error}|நகர்வு ஏற்கப்படவில்லை: {error}|{count} இல் கட்டாய செக்மேட் உள்ளது.|{count} இல் செக்மேட்டைத் தடுக்க வேண்டும்.|நிலை ஏறத்தாழச் சமமாக உள்ளது.|Stockfish படி {side} க்கு {count} சிப்பாய் மதிப்பு முன்னிலை.|நகர வேண்டிய தரப்பு|தற்காப்பு தரப்பு''',
  'kn':
      '''ತರಬೇತುದಾರರು {side} ಗೆ {move} ಸೂಚಿಸುತ್ತಾರೆ.|{square} ನಲ್ಲಿ ಸೈನಿಕ {piece} ಆಗಿ ಬಡ್ತಿ ಪಡೆದಿದೆ.|ಕೊಠಡಿ {room}: ಎದುರಾಳಿಗಾಗಿ ಕಾಯುತ್ತಿದೆ.|ಎದುರಾಳಿ ಹೊರಹೋದರು. ಮರುಸಂಪರ್ಕವಾಗದಿದ್ದರೆ {seconds} ಸೆಕೆಂಡುಗಳಲ್ಲಿ ಗೆಲ್ಲುತ್ತೀರಿ.|ಎದುರಾಳಿಯ ಸಂಪರ್ಕ ಕಡಿತವಾಯಿತು. ಮರುಸಂಪರ್ಕಕ್ಕಾಗಿ ಕಾಯುತ್ತಿದೆ…|ಡ್ರಾ ಪ್ರಸ್ತಾವನೆ ಕಳುಹಿಸಲಾಗಿದೆ. ಎದುರಾಳಿಗಾಗಿ ಕಾಯುತ್ತಿದೆ.|ಎದುರಾಳಿ ಡ್ರಾ ಪ್ರಸ್ತಾಪಿಸಿದರು.|ಮುಂದಿನ ಆನ್‌ಲೈನ್ ಪಂದ್ಯ ಹೇಗೆ ಪ್ರಾರಂಭಿಸಬೇಕೆಂದು ಆಯ್ಕೆಮಾಡಿ.|ಎದುರಾಳಿಗೆ {move} ಕಳುಹಿಸುತ್ತಿದೆ…|ಮರುಪಂದ್ಯ ಕೋರಲಾಗಿದೆ. ಎದುರಾಳಿಗಾಗಿ ಕಾಯುತ್ತಿದೆ…|ಆನ್‌ಲೈನ್ ನಡೆಗಳು ಅಂತಿಮ. ಅಧಿಕೃತ ಪಂದ್ಯ ಸಿಂಕ್ ಆಗುತ್ತಿದೆ…|ಮರುಸಂಪರ್ಕ ಬಾಕಿ: {error}|ನಡೆ ಒಪ್ಪಿಕೊಳ್ಳಲಿಲ್ಲ: {error}|{count} ನಲ್ಲಿ ಬಲವಂತದ ಚೆಕ್‌ಮೇಟ್ ಇದೆ.|{count} ನಲ್ಲಿ ಚೆಕ್‌ಮೇಟ್ ವಿರುದ್ಧ ರಕ್ಷಿಸಬೇಕು.|ಸ್ಥಿತಿ ಸುಮಾರು ಸಮವಾಗಿದೆ.|Stockfish ಪ್ರಕಾರ {side} ಗೆ {count} ಸೈನಿಕ ಮೌಲ್ಯದ ಮುನ್ನಡೆ.|ನಡೆಯುವ ಪಕ್ಷ|ರಕ್ಷಿಸುವ ಪಕ್ಷ''',
  'ml':
      '''പരിശീലകൻ {side} ന് {move} നിർദേശിക്കുന്നു.|{square} ൽ കാലാൾ {piece} ആയി ഉയർന്നു.|മുറി {room}: എതിരാളിക്കായി കാത്തിരിക്കുന്നു.|എതിരാളി വിട്ടുപോയി. വീണ്ടും ബന്ധിപ്പിച്ചില്ലെങ്കിൽ {seconds} സെക്കൻഡിൽ ജയിക്കും.|എതിരാളിയുടെ ബന്ധം നഷ്ടപ്പെട്ടു. വീണ്ടും ബന്ധിപ്പിക്കാൻ കാത്തിരിക്കുന്നു…|സമനില നിർദേശം അയച്ചു. എതിരാളിക്കായി കാത്തിരിക്കുന്നു.|എതിരാളി സമനില നിർദേശിച്ചു.|അടുത്ത ഓൺലൈൻ മത്സരം എങ്ങനെ തുടങ്ങണമെന്ന് തിരഞ്ഞെടുക്കുക.|എതിരാളിക്ക് {move} അയയ്ക്കുന്നു…|വീണ്ടും മത്സരിക്കാൻ അഭ്യർഥിച്ചു. എതിരാളിക്കായി കാത്തിരിക്കുന്നു…|ഓൺലൈൻ നീക്കങ്ങൾ അന്തിമമാണ്. ഔദ്യോഗിക മത്സരം സമന്വയിപ്പിക്കുന്നു…|പുനഃബന്ധം ബാക്കി: {error}|നീക്കം അംഗീകരിച്ചില്ല: {error}|{count} ൽ നിർബന്ധിത ചെക്ക്മേറ്റ് ഉണ്ട്.|{count} ൽ ചെക്ക്മേറ്റിനെ പ്രതിരോധിക്കണം.|സ്ഥിതി ഏകദേശം സമമാണ്.|Stockfish പ്രകാരം {side} ന് {count} കാലാൾ മൂല്യത്തിന്റെ മുൻതൂക്കം.|നീക്കാനുള്ള പക്ഷം|പ്രതിരോധിക്കുന്ന പക്ഷം''',
  'mr':
      '''प्रशिक्षक {side} साठी {move} सुचवतात.|{square} वर प्याद्याची {piece} म्हणून बढती झाली.|खोली {room}: प्रतिस्पर्ध्याची प्रतीक्षा.|प्रतिस्पर्धी गेला. पुन्हा न जोडल्यास {seconds} सेकंदांत जिंकाल.|प्रतिस्पर्ध्याचे कनेक्शन तुटले. पुन्हा जोडण्याची वाट पाहत आहे…|बरोबरी प्रस्ताव पाठवला. प्रतिस्पर्ध्याची प्रतीक्षा.|प्रतिस्पर्ध्याने बरोबरी सुचवली.|पुढील ऑनलाइन सामना कसा सुरू करायचा ते निवडा.|प्रतिस्पर्ध्याला {move} पाठवत आहे…|पुन्हा सामन्याची विनंती. प्रतिस्पर्ध्याची प्रतीक्षा…|ऑनलाइन चाली अंतिम आहेत. अधिकृत सामना समक्रमित करत आहे…|पुन्हा जोडणे बाकी: {error}|चाल स्वीकारली नाही: {error}|{count} मध्ये सक्तीची मात आहे.|{count} मध्ये मात होण्यापासून बचाव करा.|स्थिती साधारण समतोल आहे.|Stockfish नुसार {side} कडे {count} प्याद्यांचे मूल्य अधिक आहे.|चालीचा पक्ष|बचाव करणारा पक्ष''',
  'bn':
      '''প্রশিক্ষক {side}-এর জন্য {move} সুপারিশ করেন।|{square}-এ বোড়ে {piece} হয়েছে।|ঘর {room}: প্রতিপক্ষের অপেক্ষায়।|প্রতিপক্ষ চলে গেছে। না ফিরলে {seconds} সেকেন্ডে আপনি জিতবেন।|প্রতিপক্ষের সংযোগ বিচ্ছিন্ন। পুনরায় সংযোগের অপেক্ষায়…|ড্র প্রস্তাব পাঠানো হয়েছে। প্রতিপক্ষের অপেক্ষায়।|প্রতিপক্ষ ড্র প্রস্তাব করেছে।|পরের অনলাইন ম্যাচ কীভাবে শুরু করবেন বেছে নিন।|প্রতিপক্ষকে {move} পাঠানো হচ্ছে…|পুনরায় ম্যাচের অনুরোধ। প্রতিপক্ষের অপেক্ষায়…|অনলাইন চাল চূড়ান্ত। আনুষ্ঠানিক ম্যাচ সমন্বয় হচ্ছে…|পুনরায় সংযোগ বাকি: {error}|চাল গ্রহণ হয়নি: {error}|{count}-এ বাধ্যকারী মাত আছে।|{count}-এ মাত ঠেকাতে হবে।|অবস্থান মোটামুটি সমান।|Stockfish মতে {side}-এর {count} বোড়ের সুবিধা।|চাল দেওয়ার পক্ষ|রক্ষাকারী পক্ষ''',
  'gu':
      '''કોચ {side} માટે {move} સૂચવે છે.|{square} પર પ્યાદું {piece} બન્યું.|રૂમ {room}: વિરોધીની રાહ જોવાય છે.|વિરોધી ગયા. ફરી ન જોડાય તો {seconds} સેકન્ડમાં તમે જીતશો.|વિરોધીનું જોડાણ તૂટ્યું. ફરી જોડાવાની રાહ…|ડ્રો પ્રસ્તાવ મોકલ્યો. વિરોધીની રાહ છે.|વિરોધીએ ડ્રો પ્રસ્તાવ આપ્યો.|આગલી ઓનલાઇન મેચ કેવી રીતે શરૂ કરવી તે પસંદ કરો.|વિરોધીને {move} મોકલી રહ્યા છીએ…|ફરી મેચની વિનંતી કરી. વિરોધીની રાહ…|ઓનલાઇન ચાલ અંતિમ છે. સત્તાવાર મેચ સમન્વય થાય છે…|ફરી જોડાણ બાકી: {error}|ચાલ સ્વીકારાઈ નહીં: {error}|{count} માં ફરજિયાત માત છે.|{count} માં માત સામે બચાવ કરવો પડશે.|સ્થિતિ આશરે સમાન છે.|Stockfish મુજબ {side} ને {count} પ્યાદાંનો લાભ છે.|ચાલ કરતો પક્ષ|બચાવ કરતો પક્ષ''',
  'pa':
      '''ਕੋਚ {side} ਲਈ {move} ਸੁਝਾਉਂਦਾ ਹੈ।|{square} ਉੱਤੇ ਪਿਆਦਾ {piece} ਬਣਿਆ।|ਕਮਰਾ {room}: ਵਿਰੋਧੀ ਦੀ ਉਡੀਕ।|ਵਿਰੋਧੀ ਚਲਾ ਗਿਆ। ਮੁੜ ਨਾ ਜੁੜਿਆ ਤਾਂ {seconds} ਸਕਿੰਟ ਵਿੱਚ ਜਿੱਤੋਗੇ।|ਵਿਰੋਧੀ ਦਾ ਸੰਪਰਕ ਟੁੱਟਿਆ। ਮੁੜ ਜੁੜਨ ਦੀ ਉਡੀਕ…|ਬਰਾਬਰੀ ਦਾ ਸੁਝਾਅ ਭੇਜਿਆ। ਵਿਰੋਧੀ ਦੀ ਉਡੀਕ।|ਵਿਰੋਧੀ ਨੇ ਬਰਾਬਰੀ ਪੇਸ਼ ਕੀਤੀ।|ਅਗਲਾ ਆਨਲਾਈਨ ਮੈਚ ਕਿਵੇਂ ਸ਼ੁਰੂ ਕਰਨਾ ਹੈ ਚੁਣੋ।|ਵਿਰੋਧੀ ਨੂੰ {move} ਭੇਜਿਆ ਜਾ ਰਿਹਾ ਹੈ…|ਮੁੜ ਮੈਚ ਦੀ ਬੇਨਤੀ। ਵਿਰੋਧੀ ਦੀ ਉਡੀਕ…|ਆਨਲਾਈਨ ਚਾਲਾਂ ਅੰਤਿਮ ਹਨ। ਅਧਿਕਾਰਤ ਮੈਚ ਸਮਕਾਲੀ ਹੋ ਰਿਹਾ ਹੈ…|ਮੁੜ ਜੁੜਨਾ ਬਾਕੀ: {error}|ਚਾਲ ਮਨਜ਼ੂਰ ਨਹੀਂ: {error}|{count} ਵਿੱਚ ਮਜਬੂਰ ਮਾਤ ਹੈ।|{count} ਵਿੱਚ ਮਾਤ ਤੋਂ ਬਚਾਅ ਕਰਨਾ ਪਵੇਗਾ।|ਸਥਿਤੀ ਲਗਭਗ ਬਰਾਬਰ ਹੈ।|Stockfish ਮੁਤਾਬਕ {side} ਨੂੰ {count} ਪਿਆਦਿਆਂ ਦਾ ਲਾਭ ਹੈ।|ਚਾਲ ਵਾਲਾ ਪੱਖ|ਬਚਾਅ ਵਾਲਾ ਪੱਖ''',
  'ur':
      '''کوچ {side} کے لیے {move} تجویز کرتا ہے۔|{square} پر پیادہ {piece} بن گیا۔|کمرہ {room}: حریف کا انتظار۔|حریف چلا گیا۔ دوبارہ نہ جڑا تو {seconds} سیکنڈ میں آپ جیتیں گے۔|حریف کا رابطہ ٹوٹ گیا۔ دوبارہ جڑنے کا انتظار…|برابری کی پیشکش بھیجی۔ حریف کا انتظار۔|حریف نے برابری کی پیشکش کی۔|اگلا آن لائن میچ کیسے شروع کرنا ہے منتخب کریں۔|حریف کو {move} بھیج رہے ہیں…|دوبارہ میچ کی درخواست۔ حریف کا انتظار…|آن لائن چالیں حتمی ہیں۔ سرکاری میچ ہم آہنگ ہو رہا ہے…|دوبارہ رابطہ باقی: {error}|چال قبول نہیں ہوئی: {error}|{count} میں جبری مات ہے۔|آپ کو {count} میں مات سے بچنا ہوگا۔|پوزیشن تقریباً برابر ہے۔|Stockfish کے مطابق {side} کو {count} پیادوں کا فائدہ ہے۔|چال والا فریق|دفاع کرنے والا فریق''',
  'ar':
      '''يقترح المدرب {move} لصالح {side}.|ترقّى البيدق إلى {piece} في {square}.|الغرفة {room}: في انتظار خصمك.|غادر الخصم. تفوز خلال {seconds} ثانية إن لم يعد الاتصال.|فُقد اتصال الخصم. انتظار إعادة الاتصال…|أُرسل عرض التعادل. في انتظار خصمك.|عرض خصمك التعادل.|اختر طريقة بدء مباراتك التالية عبر الإنترنت.|إرسال {move} إلى خصمك…|طُلبت إعادة المباراة. في انتظار الخصم…|النقلات عبر الإنترنت نهائية. مزامنة المباراة المعتمدة…|إعادة الاتصال معلّقة: {error}|لم تُقبل النقلة: {error}|يوجد مات إجباري خلال {count}.|يجب الدفاع ضد المات خلال {count}.|الوضع متوازن تقريبًا.|يقدّر Stockfish أفضلية {count} بيدق لصالح {side}.|الطرف الذي عليه الدور|الطرف المدافع''',
  'es':
      '''El entrenador recomienda {move} para {side}.|Peón promocionado a {piece} en {square}.|Sala {room}: esperando a tu rival.|El rival salió. Ganas en {seconds}s si no se reconecta.|Conexión del rival perdida. Esperando reconexión…|Oferta de tablas enviada. Esperando al rival.|Tu rival ofreció tablas.|Elige cómo iniciar tu próxima partida en línea.|Enviando {move} a tu rival…|Revancha solicitada. Esperando al rival…|Las jugadas en línea son definitivas. Sincronizando la partida oficial…|Reconexión pendiente: {error}|Jugada no aceptada: {error}|Hay un mate forzado en {count}.|Debes defenderte de un mate en {count}.|La posición está aproximadamente igualada.|Stockfish estima una ventaja de {count} peones para {side}.|el bando al turno|el bando defensor''',
  'fr':
      '''Le coach recommande {move} pour {side}.|Pion promu en {piece} sur {square}.|Salle {room} : en attente de votre adversaire.|L’adversaire est parti. Vous gagnez dans {seconds}s s’il ne se reconnecte pas.|Connexion adverse perdue. En attente de reconnexion…|Proposition de nulle envoyée. En attente de l’adversaire.|Votre adversaire propose la nulle.|Choisissez comment commencer votre prochaine partie en ligne.|Envoi de {move} à votre adversaire…|Revanche demandée. En attente de l’adversaire…|Les coups en ligne sont définitifs. Synchronisation de la partie officielle…|Reconnexion en attente : {error}|Coup refusé : {error}|Il y a un mat forcé en {count}.|Vous devez défendre contre un mat en {count}.|La position est à peu près équilibrée.|Stockfish estime un avantage de {count} pions pour {side}.|le camp au trait|le camp défenseur''',
  'de':
      '''Der Trainer empfiehlt {move} für {side}.|Bauer auf {square} in {piece} umgewandelt.|Raum {room}: Warte auf deinen Gegner.|Gegner gegangen. Du gewinnst in {seconds}s, falls er sich nicht erneut verbindet.|Gegnerverbindung verloren. Warte auf Wiederverbindung…|Remisangebot gesendet. Warte auf den Gegner.|Dein Gegner bietet Remis an.|Wähle den Start deiner nächsten Online-Partie.|Sende {move} an deinen Gegner…|Revanche angefragt. Warte auf den Gegner…|Online-Züge sind endgültig. Offizielle Partie wird synchronisiert…|Wiederverbindung ausstehend: {error}|Zug nicht angenommen: {error}|Es gibt ein erzwungenes Matt in {count}.|Du musst ein Matt in {count} abwehren.|Die Stellung ist ungefähr ausgeglichen.|Stockfish schätzt {count} Bauerneinheiten Vorteil für {side}.|die Seite am Zug|die verteidigende Seite''',
  'it':
      '''Il coach consiglia {move} per {side}.|Pedone promosso a {piece} in {square}.|Stanza {room}: in attesa dell’avversario.|L’avversario è uscito. Vinci tra {seconds}s se non si riconnette.|Connessione avversaria persa. In attesa di riconnessione…|Offerta di patta inviata. In attesa dell’avversario.|L’avversario ha offerto patta.|Scegli come iniziare la prossima partita online.|Invio di {move} all’avversario…|Rivincita richiesta. In attesa dell’avversario…|Le mosse online sono definitive. Sincronizzazione della partita ufficiale…|Riconnessione in sospeso: {error}|Mossa non accettata: {error}|C’è un matto forzato in {count}.|Devi difenderti dal matto in {count}.|La posizione è circa equilibrata.|Stockfish stima un vantaggio di {count} pedoni per {side}.|il lato al tratto|il lato in difesa''',
  'pt':
      '''O treinador recomenda {move} para {side}.|Peão promovido a {piece} em {square}.|Sala {room}: à espera do adversário.|O adversário saiu. Ganha em {seconds}s se ele não se reconectar.|Ligação do adversário perdida. À espera de reconexão…|Oferta de empate enviada. À espera do adversário.|O adversário ofereceu empate.|Escolha como iniciar a próxima partida online.|A enviar {move} ao adversário…|Revanche pedida. À espera do adversário…|Os lances online são definitivos. A sincronizar a partida oficial…|Reconexão pendente: {error}|Lance não aceite: {error}|Há mate forçado em {count}.|Deve defender-se de mate em {count}.|A posição está aproximadamente equilibrada.|Stockfish estima vantagem de {count} peões para {side}.|o lado a jogar|o lado defensor''',
  'ru':
      '''Тренер рекомендует {move} для стороны {side}.|Пешка превратилась в {piece} на {square}.|Комната {room}: ожидание соперника.|Соперник вышел. Вы выиграете через {seconds} с, если он не вернётся.|Связь с соперником потеряна. Ожидание подключения…|Предложение ничьей отправлено. Ожидание соперника.|Соперник предложил ничью.|Выберите способ начать следующую онлайн-партию.|Отправка {move} сопернику…|Реванш запрошен. Ожидание соперника…|Онлайн-ходы окончательны. Синхронизация с официальной партией…|Ожидание подключения: {error}|Ход не принят: {error}|Есть форсированный мат в {count}.|Нужно защититься от мата в {count}.|Позиция примерно равная.|Stockfish оценивает преимущество в {count} пешки у стороны: {side}.|сторона, которой ходить|защищающаяся сторона''',
  'uk':
      '''Тренер рекомендує {move} для сторони {side}.|Пішак перетворився на {piece} на {square}.|Кімната {room}: очікування суперника.|Суперник вийшов. Ви виграєте через {seconds} с, якщо він не повернеться.|Зв’язок із суперником втрачено. Очікування підключення…|Пропозицію нічиєї надіслано. Очікування суперника.|Суперник запропонував нічию.|Виберіть спосіб почати наступну онлайн-партію.|Надсилання {move} супернику…|Реванш запрошено. Очікування суперника…|Онлайн-ходи остаточні. Синхронізація офіційної партії…|Очікування підключення: {error}|Хід не прийнято: {error}|Є форсований мат за {count}.|Потрібно захиститися від мату за {count}.|Позиція приблизно рівна.|Stockfish оцінює перевагу в {count} пішака для сторони: {side}.|сторона, якій ходити|сторона, що захищається''',
  'tr':
      '''Koç {side} için {move} öneriyor.|Piyon {square} karesinde {piece} oldu.|Oda {room}: rakibiniz bekleniyor.|Rakip ayrıldı. Yeniden bağlanmazsa {seconds} saniyede kazanırsın.|Rakip bağlantısı koptu. Yeniden bağlanması bekleniyor…|Beraberlik teklifi gönderildi. Rakip bekleniyor.|Rakibin beraberlik teklif etti.|Sonraki çevrimiçi maçı nasıl başlatacağını seç.|Rakibe {move} gönderiliyor…|Rövanş istendi. Rakip bekleniyor…|Çevrimiçi hamleler kesindir. Resmî maç eşitleniyor…|Yeniden bağlantı bekleniyor: {error}|Hamle kabul edilmedi: {error}|{count} içinde zorunlu mat var.|{count} içinde mata karşı savunmalısın.|Konum yaklaşık dengeli.|Stockfish {side} için {count} piyon üstünlüğü hesaplıyor.|hamle sırası olan taraf|savunan taraf''',
  'fa':
      '''مربی {move} را برای {side} پیشنهاد می‌کند.|پیاده در {square} به {piece} ارتقا یافت.|اتاق {room}: در انتظار حریف.|حریف خارج شد. اگر برنگردد در {seconds} ثانیه می‌برید.|اتصال حریف قطع شد. در انتظار اتصال مجدد…|پیشنهاد تساوی ارسال شد. در انتظار حریف.|حریف پیشنهاد تساوی داد.|روش شروع بازی آنلاین بعدی را انتخاب کنید.|ارسال {move} به حریف…|درخواست بازی مجدد ارسال شد. در انتظار حریف…|حرکت‌های آنلاین نهایی‌اند. همگام‌سازی بازی رسمی…|اتصال مجدد در انتظار: {error}|حرکت پذیرفته نشد: {error}|مات اجباری در {count} وجود دارد.|باید در برابر مات در {count} دفاع کنید.|وضعیت تقریباً برابر است.|Stockfish برتری {count} پیاده برای {side} برآورد می‌کند.|طرفی که نوبت اوست|طرف مدافع''',
  'zh':
      '''教练建议{side}走{move}。|兵在{square}升变为{piece}。|房间{room}：等待对手。|对手已离开。如未重连，你将在{seconds}秒后获胜。|对手连接中断。等待重连…|已发送和棋提议。等待对手。|对手提出和棋。|选择如何开始下一盘在线对局。|正在向对手发送{move}…|已请求再战。等待对手…|在线着法不可撤回。正在同步权威对局…|等待重连：{error}|着法未接受：{error}|存在{count}步强制将死。|你必须防守{count}步将死。|局面大致均衡。|Stockfish估计{side}有{count}兵优势。|行棋方|防守方''',
  'ja':
      '''コーチは{side}に{move}を勧めます。|ポーンが{square}で{piece}に昇格しました。|ルーム{room}：相手を待っています。|相手が離れました。再接続しなければ{seconds}秒後に勝ちます。|相手の接続が切れました。再接続を待っています…|引き分けを提案しました。相手を待っています。|相手が引き分けを提案しました。|次のオンライン対局の始め方を選んでください。|相手に{move}を送信中…|再戦を申し込みました。相手を待っています…|オンラインの手は確定です。正式な対局を同期中…|再接続待ち：{error}|着手が拒否されました：{error}|{count}手の強制メイトがあります。|{count}手のメイトを防ぐ必要があります。|局面はおおむね互角です。|Stockfishは{side}に{count}ポーン分の優勢と評価しています。|手番の側|守る側''',
  'ko':
      '''코치가 {side}에 {move}를 추천합니다.|폰이 {square}에서 {piece}로 승격했습니다.|방 {room}: 상대를 기다립니다.|상대가 나갔습니다. 다시 연결하지 않으면 {seconds}초 후 승리합니다.|상대 연결이 끊겼습니다. 재연결 대기 중…|무승부 제안을 보냈습니다. 상대를 기다립니다.|상대가 무승부를 제안했습니다.|다음 온라인 대국을 시작할 방법을 선택하세요.|상대에게 {move} 전송 중…|재대결을 요청했습니다. 상대 대기 중…|온라인 수는 확정됩니다. 공식 대국 동기화 중…|재연결 대기: {error}|수 거절됨: {error}|{count}수 강제 메이트가 있습니다.|{count}수 메이트를 막아야 합니다.|포지션은 거의 균형입니다.|Stockfish는 {side}에 {count}폰 우세로 평가합니다.|둘 차례인 쪽|수비하는 쪽''',
  'id':
      '''Pelatih menyarankan {move} untuk {side}.|Pion dipromosikan menjadi {piece} di {square}.|Ruang {room}: menunggu lawan.|Lawan pergi. Anda menang dalam {seconds} detik jika tidak terhubung kembali.|Koneksi lawan terputus. Menunggu sambungan ulang…|Tawaran remis dikirim. Menunggu lawan.|Lawan menawarkan remis.|Pilih cara memulai pertandingan online berikut.|Mengirim {move} kepada lawan…|Tanding ulang diminta. Menunggu lawan…|Langkah online bersifat final. Menyinkronkan pertandingan resmi…|Sambungan ulang tertunda: {error}|Langkah ditolak: {error}|Ada mat paksa dalam {count}.|Anda harus bertahan dari mat dalam {count}.|Posisi kira-kira seimbang.|Stockfish memperkirakan keuntungan {count} pion untuk {side}.|pihak yang akan melangkah|pihak bertahan''',
  'ms':
      '''Jurulatih mencadangkan {move} untuk {side}.|Bidak dinaikkan menjadi {piece} di {square}.|Bilik {room}: menunggu lawan.|Lawan keluar. Anda menang dalam {seconds} saat jika tidak menyambung semula.|Sambungan lawan terputus. Menunggu sambungan semula…|Tawaran seri dihantar. Menunggu lawan.|Lawan menawarkan seri.|Pilih cara memulakan perlawanan dalam talian seterusnya.|Menghantar {move} kepada lawan…|Perlawanan semula diminta. Menunggu lawan…|Gerakan dalam talian adalah muktamad. Menyegerakkan perlawanan rasmi…|Sambungan semula tertunda: {error}|Gerakan tidak diterima: {error}|Terdapat mat paksa dalam {count}.|Anda mesti bertahan daripada mat dalam {count}.|Kedudukan lebih kurang seimbang.|Stockfish menganggarkan kelebihan {count} bidak untuk {side}.|pihak yang bergerak|pihak bertahan''',
  'th':
      '''โค้ชแนะนำ {move} สำหรับ {side}|เบี้ยเลื่อนขั้นเป็น {piece} ที่ {square}|ห้อง {room}: รอคู่ต่อสู้|คู่ต่อสู้ออกแล้ว คุณจะชนะใน {seconds} วินาทีถ้าเขาไม่เชื่อมต่อใหม่|คู่ต่อสู้ขาดการเชื่อมต่อ กำลังรอเชื่อมต่อใหม่…|ส่งข้อเสนอเสมอแล้ว รอคู่ต่อสู้|คู่ต่อสู้เสนอเสมอ|เลือกวิธีเริ่มเกมออนไลน์ถัดไป|กำลังส่ง {move} ให้คู่ต่อสู้…|ขอแข่งใหม่แล้ว กำลังรอคู่ต่อสู้…|ตาออนไลน์ถือเป็นที่สิ้นสุด กำลังซิงค์เกมทางการ…|รอเชื่อมต่อใหม่: {error}|ไม่รับตาเดิน: {error}|มีรุกฆาตบังคับใน {count}|คุณต้องป้องกันรุกฆาตใน {count}|ตำแหน่งใกล้เคียงสมดุล|Stockfish ประเมินว่า {side} ได้เปรียบ {count} เบี้ย|ฝ่ายที่มีตาเดิน|ฝ่ายตั้งรับ''',
  'vi':
      '''Huấn luyện viên đề xuất {move} cho {side}.|Tốt phong thành {piece} tại {square}.|Phòng {room}: chờ đối thủ.|Đối thủ rời đi. Bạn thắng sau {seconds} giây nếu họ không kết nối lại.|Mất kết nối đối thủ. Đang chờ kết nối lại…|Đã gửi đề nghị hòa. Đang chờ đối thủ.|Đối thủ đề nghị hòa.|Chọn cách bắt đầu ván trực tuyến tiếp theo.|Đang gửi {move} cho đối thủ…|Đã yêu cầu đấu lại. Chờ đối thủ…|Nước trực tuyến là cuối cùng. Đang đồng bộ ván chính thức…|Chờ kết nối lại: {error}|Nước không được chấp nhận: {error}|Có chiếu hết cưỡng bức trong {count}.|Bạn phải chống chiếu hết trong {count}.|Vị trí gần cân bằng.|Stockfish ước tính {side} hơn {count} tốt.|bên đến lượt|bên phòng thủ''',
  'pl':
      '''Trener zaleca {move} dla {side}.|Pion promowany na {piece} na {square}.|Pokój {room}: oczekiwanie na przeciwnika.|Przeciwnik wyszedł. Wygrasz za {seconds}s, jeśli nie wróci.|Połączenie przeciwnika utracone. Oczekiwanie na ponowne połączenie…|Oferta remisu wysłana. Oczekiwanie na przeciwnika.|Przeciwnik zaoferował remis.|Wybierz sposób rozpoczęcia następnej partii online.|Wysyłanie {move} przeciwnikowi…|Poproszono o rewanż. Oczekiwanie na przeciwnika…|Ruchy online są ostateczne. Synchronizacja oficjalnej partii…|Ponowne połączenie oczekuje: {error}|Ruch odrzucony: {error}|Jest wymuszony mat w {count}.|Musisz bronić się przed matem w {count}.|Pozycja jest mniej więcej równa.|Stockfish ocenia przewagę {count} piona dla strony: {side}.|strona na ruchu|strona broniąca''',
  'nl':
      '''De coach beveelt {move} aan voor {side}.|Pion gepromoveerd tot {piece} op {square}.|Kamer {room}: wacht op je tegenstander.|Tegenstander weg. Je wint over {seconds}s als die niet terugkomt.|Verbinding met tegenstander weg. Wachten op herstel…|Remiseaanbod verzonden. Wachten op tegenstander.|Je tegenstander bood remise aan.|Kies hoe je de volgende online partij wilt beginnen.|{move} naar je tegenstander verzenden…|Revanche aangevraagd. Wachten op tegenstander…|Online zetten zijn definitief. Officiële partij synchroniseren…|Herverbinding wacht: {error}|Zet niet geaccepteerd: {error}|Er is geforceerd mat in {count}.|Je moet mat in {count} verdedigen.|De stelling is ongeveer in evenwicht.|Stockfish schat {count} pion voordeel voor {side}.|de partij aan zet|de verdedigende partij''',
  'sv':
      '''Tränaren rekommenderar {move} för {side}.|Bonden promoverades till {piece} på {square}.|Rum {room}: väntar på motståndaren.|Motståndaren lämnade. Du vinner om {seconds}s om de inte återansluter.|Motståndarens anslutning förlorad. Väntar på återanslutning…|Remianbud skickat. Väntar på motståndaren.|Motståndaren erbjöd remi.|Välj hur nästa onlineparti ska starta.|Skickar {move} till motståndaren…|Revansch begärd. Väntar på motståndaren…|Onlinedrag är slutgiltiga. Synkroniserar det officiella partiet…|Återanslutning väntar: {error}|Draget accepterades inte: {error}|Det finns forcerad matt i {count}.|Du måste försvara dig mot matt i {count}.|Ställningen är ungefär jämn.|Stockfish uppskattar {count} bönders fördel för {side}.|sidan vid draget|den försvarande sidan''',
  'el':
      '''Ο προπονητής προτείνει {move} για {side}.|Το πιόνι προήχθη σε {piece} στο {square}.|Δωμάτιο {room}: αναμονή αντιπάλου.|Ο αντίπαλος έφυγε. Κερδίζετε σε {seconds} δευτ. αν δεν επανασυνδεθεί.|Χάθηκε η σύνδεση αντιπάλου. Αναμονή επανασύνδεσης…|Στάλθηκε πρόταση ισοπαλίας. Αναμονή αντιπάλου.|Ο αντίπαλος πρότεινε ισοπαλία.|Επιλέξτε πώς θα αρχίσετε την επόμενη διαδικτυακή παρτίδα.|Αποστολή {move} στον αντίπαλο…|Ζητήθηκε ρεβάνς. Αναμονή αντιπάλου…|Οι διαδικτυακές κινήσεις είναι οριστικές. Συγχρονισμός επίσημης παρτίδας…|Εκκρεμεί επανασύνδεση: {error}|Η κίνηση απορρίφθηκε: {error}|Υπάρχει αναγκαστικό ματ σε {count}.|Πρέπει να αμυνθείτε κατά ματ σε {count}.|Η θέση είναι περίπου ισορροπημένη.|Το Stockfish εκτιμά πλεονέκτημα {count} πιονιών για {side}.|την πλευρά που παίζει|την αμυνόμενη πλευρά''',
  'he':
      '''המאמן ממליץ על {move} עבור {side}.|הרגלי הוכתר ל־{piece} ב־{square}.|חדר {room}: ממתין ליריב.|היריב עזב. תנצחו בעוד {seconds} שניות אם לא יתחבר מחדש.|החיבור ליריב אבד. ממתין לחיבור מחדש…|הצעת תיקו נשלחה. ממתין ליריב.|היריב הציע תיקו.|בחרו כיצד להתחיל את המשחק המקוון הבא.|שולח {move} ליריב…|נשלחה בקשת משחק חוזר. ממתין ליריב…|המסעים המקוונים סופיים. מסנכרן את המשחק הרשמי…|חיבור מחדש ממתין: {error}|המסע לא התקבל: {error}|יש מט כפוי ב־{count}.|עליכם להתגונן ממט ב־{count}.|העמדה מאוזנת בקירוב.|Stockfish מעריך יתרון של {count} רגלים עבור {side}.|הצד שבתור|הצד המגן''',
  'sw':
      '''Kocha anapendekeza {move} kwa {side}.|Askari amepandishwa kuwa {piece} kwenye {square}.|Chumba {room}: inasubiri mpinzani.|Mpinzani ameondoka. Utashinda baada ya sekunde {seconds} asipounganika tena.|Muunganisho wa mpinzani umepotea. Inasubiri kuunganishwa tena…|Ofa ya sare imetumwa. Inasubiri mpinzani.|Mpinzani amependekeza sare.|Chagua jinsi ya kuanza mechi inayofuata mtandaoni.|Inatuma {move} kwa mpinzani…|Mechi ya marudiano imeombwa. Inasubiri mpinzani…|Hatua za mtandaoni ni za mwisho. Inasawazisha mechi rasmi…|Kuunganisha tena kunasubiri: {error}|Hatua haijakubaliwa: {error}|Kuna mati ya lazima katika {count}.|Lazima ujilinde dhidi ya mati katika {count}.|Nafasi ina usawa takriban.|Stockfish inakadiria faida ya askari {count} kwa {side}.|upande wenye zamu|upande unaojilinda''',
};

const liveMiniKeys = [
  'easy',
  'medium',
  'hard',
  'undo',
  'noUndo',
  'stalemate',
  'offline',
  'movesTo',
  'recovered'
];
final Map<String, List<String>> liveMiniTranslations = {
  for (final e in _miniRows.entries) e.key: e.value.split('|')
};
String? _translateMini(String value, String code) {
  String t(String key, [Map<String, String> p = const {}]) =>
      _fill(liveMiniTranslations[code]![liveMiniKeys.indexOf(key)], p);
  const source = {
    'easy': 'easy',
    'medium': 'medium',
    'hard': 'hard',
    'Undo move': 'undo',
    'Undo is unavailable in online games': 'noUndo',
    'Stalemate': 'stalemate',
    'Offline AI': 'offline',
    'AI reply recovered. Calculating again...': 'recovered'
  };
  if (source.containsKey(value)) return t(source[value]!);
  if (value == 'DRAW') return localizeLiveCoach('Draw', code);
  if (value == 'Puzzle Academy') {
    return localizeLiveCoach('PUZZLE ACADEMY', code);
  }
  var m = RegExp(r'^(easy|medium|hard) - mate in (\d+)$').firstMatch(value);
  if (m != null) {
    return '${t(m[1]!)} • ${localizeLiveCoach('Checkmate in ${m[2]}', code)}';
  }
  m = RegExp(r'^(Stockfish|Offline AI): ([KQRBNP]) moves to ([a-h][1-8])\.$')
      .firstMatch(value);
  if (m != null) {
    return '${m[1] == 'Offline AI' ? t('offline') : m[1]}: ${t('movesTo', {
          'piece': m[2]!,
          'square': m[3]!
        })}';
  }
  m = RegExp(
          r'^(Stockfish|Offline AI): ([KQRBNP]) captures ([KQRBNP]) on ([a-h][1-8])\.$')
      .firstMatch(value);
  if (m != null) {
    return '${m[1] == 'Offline AI' ? t('offline') : m[1]}: ${_fill(_narrative(code, 'captured'), {
          'piece': m[2]!,
          'target': m[3]!,
          'to': m[4]!
        })}';
  }
  return null;
}

const _miniRows = <String, String>{
  'en':
      '''Easy|Medium|Hard|Undo move|Undo is unavailable in online games|Stalemate|Offline AI|{piece} moves to {square}.|AI reply recovered. Calculating again…''',
  'te':
      '''సులభం|మధ్యస్థం|కష్టం|ఎత్తు వెనక్కి|ఆన్‌లైన్ ఆటల్లో ఎత్తు వెనక్కి తీసుకోలేరు|స్టేల్‌మేట్|ఆఫ్‌లైన్ AI|{piece} {square}కు కదిలింది.|AI సమాధానం పునరుద్ధరించబడింది. మళ్లీ లెక్కిస్తోంది…''',
  'hi':
      '''आसान|मध्यम|कठिन|चाल वापस लें|ऑनलाइन खेलों में चाल वापस नहीं ले सकते|गतिरोध|ऑफलाइन AI|{piece}, {square} पर गया।|AI उत्तर बहाल हुआ। फिर गणना जारी…''',
  'ta':
      '''எளிது|நடுத்தரம்|கடினம்|நகர்வை மீளெடு|இணைய ஆட்டங்களில் நகர்வை மீளெடுக்க முடியாது|ஸ்டேல்மேட்|இணையமில்லா AI|{piece}, {square} செல்கிறது.|AI பதில் மீண்டது. மீண்டும் கணக்கிடுகிறது…''',
  'kn':
      '''ಸುಲಭ|ಮಧ್ಯಮ|ಕಠಿಣ|ನಡೆ ಹಿಂದಕ್ಕೆ|ಆನ್‌ಲೈನ್ ಆಟಗಳಲ್ಲಿ ನಡೆ ಹಿಂದಕ್ಕೆ ಸಾಧ್ಯವಿಲ್ಲ|ಸ್ಟೇಲ್‌ಮೇಟ್|ಆಫ್‌ಲೈನ್ AI|{piece} {square} ಗೆ ಚಲಿಸುತ್ತದೆ.|AI ಉತ್ತರ ಮರುಸ್ಥಾಪಿತ. ಮತ್ತೆ ಲೆಕ್ಕಿಸುತ್ತಿದೆ…''',
  'ml':
      '''എളുപ്പം|ഇടത്തരം|കഠിനം|നീക്കം പിൻവലിക്കുക|ഓൺലൈൻ കളികളിൽ നീക്കം പിൻവലിക്കാനാവില്ല|സ്റ്റേൽമേറ്റ്|ഓഫ്‌ലൈൻ AI|{piece} {square} ലേക്ക് നീങ്ങുന്നു.|AI മറുപടി വീണ്ടെടുത്തു. വീണ്ടും കണക്കാക്കുന്നു…''',
  'mr':
      '''सोपे|मध्यम|कठीण|चाल मागे घ्या|ऑनलाइन खेळात चाल मागे घेता येत नाही|कोंडी|ऑफलाइन AI|{piece} {square} वर जातो.|AI उत्तर पुन्हा मिळाले. गणना पुन्हा सुरू…''',
  'bn':
      '''সহজ|মাঝারি|কঠিন|চাল ফেরান|অনলাইন খেলায় চাল ফেরানো যায় না|অচলাবস্থা|অফলাইন AI|{piece} {square}-এ যায়।|AI উত্তর ফিরে এসেছে। আবার গণনা চলছে…''',
  'gu':
      '''સરળ|મધ્યમ|કઠિન|ચાલ પાછી લો|ઓનલાઇન રમતમાં ચાલ પાછી લઈ શકાતી નથી|ગતિરોધ|ઓફલાઇન AI|{piece} {square} પર જાય છે.|AI જવાબ પાછો મળ્યો. ફરી ગણતરી ચાલુ…''',
  'pa':
      '''ਸੌਖਾ|ਦਰਮਿਆਨਾ|ਔਖਾ|ਚਾਲ ਵਾਪਸ ਲਓ|ਆਨਲਾਈਨ ਖੇਡ ਵਿੱਚ ਚਾਲ ਵਾਪਸ ਨਹੀਂ ਲੈ ਸਕਦੇ|ਖੜੋਤ|ਆਫਲਾਈਨ AI|{piece} {square} ਉੱਤੇ ਜਾਂਦਾ ਹੈ।|AI ਜਵਾਬ ਬਹਾਲ ਹੋਇਆ। ਫਿਰ ਗਣਨਾ ਜਾਰੀ…''',
  'ur':
      '''آسان|درمیانہ|مشکل|چال واپس لیں|آن لائن کھیل میں چال واپس نہیں لے سکتے|بندش|آف لائن AI|{piece} {square} پر جاتا ہے۔|AI جواب بحال ہوا۔ دوبارہ حساب جاری…''',
  'ar':
      '''سهل|متوسط|صعب|تراجع عن النقلة|التراجع غير متاح في اللعب عبر الإنترنت|خنق|AI دون اتصال|ينتقل {piece} إلى {square}.|استُعيد رد AI. جارٍ الحساب مجددًا…''',
  'es':
      '''Fácil|Medio|Difícil|Deshacer jugada|No se puede deshacer en partidas en línea|Ahogado|IA sin conexión|{piece} va a {square}.|Respuesta de IA recuperada. Calculando de nuevo…''',
  'fr':
      '''Facile|Moyen|Difficile|Annuler le coup|L’annulation est indisponible en ligne|Pat|IA hors ligne|{piece} va en {square}.|Réponse IA rétablie. Nouveau calcul…''',
  'de':
      '''Leicht|Mittel|Schwer|Zug zurücknehmen|Zurücknehmen ist online nicht verfügbar|Patt|Offline-KI|{piece} zieht nach {square}.|KI-Antwort wiederhergestellt. Neue Berechnung…''',
  'it':
      '''Facile|Medio|Difficile|Annulla mossa|Non si può annullare nelle partite online|Stallo|IA offline|{piece} va in {square}.|Risposta IA recuperata. Nuovo calcolo…''',
  'pt':
      '''Fácil|Médio|Difícil|Desfazer lance|Não se pode desfazer em partidas online|Afogamento|IA offline|{piece} vai para {square}.|Resposta da IA recuperada. A calcular novamente…''',
  'ru':
      '''Легко|Средне|Сложно|Отменить ход|В онлайн-партиях нельзя отменять ходы|Пат|Офлайн-ИИ|{piece} идёт на {square}.|Ответ ИИ восстановлен. Новый расчёт…''',
  'uk':
      '''Легко|Середньо|Складно|Скасувати хід|В онлайн-партіях не можна скасовувати ходи|Пат|Офлайн-ШІ|{piece} іде на {square}.|Відповідь ШІ відновлено. Новий розрахунок…''',
  'tr':
      '''Kolay|Orta|Zor|Hamleyi geri al|Çevrimiçi oyunlarda geri alma yok|Pat|Çevrimdışı yapay zekâ|{piece} {square} karesine gider.|Yapay zekâ yanıtı kurtarıldı. Tekrar hesaplanıyor…''',
  'fa':
      '''آسان|متوسط|سخت|برگرداندن حرکت|برگرداندن حرکت در بازی آنلاین ممکن نیست|پات|هوش مصنوعی آفلاین|{piece} به {square} می‌رود.|پاسخ هوش مصنوعی بازیابی شد. محاسبه دوباره…''',
  'zh': '''简单|中等|困难|悔棋|在线对局不能悔棋|逼和|离线AI|{piece}走到{square}。|AI应答已恢复。重新计算中…''',
  'ja':
      '''簡単|中級|難しい|手を戻す|オンライン対局では手を戻せません|ステイルメイト|オフラインAI|{piece}が{square}へ進みます。|AI応答が復旧しました。再計算中…''',
  'ko':
      '''쉬움|보통|어려움|수 되돌리기|온라인 대국에서는 되돌릴 수 없습니다|스테일메이트|오프라인 AI|{piece}이 {square}(으)로 이동합니다.|AI 응답 복구 완료. 다시 계산 중…''',
  'id':
      '''Mudah|Sedang|Sulit|Batalkan langkah|Pembatalan tidak tersedia dalam permainan online|Pat|AI luring|{piece} ke {square}.|Balasan AI pulih. Menghitung lagi…''',
  'ms':
      '''Mudah|Sederhana|Sukar|Batalkan gerakan|Pembatalan tidak tersedia dalam permainan dalam talian|Buntu|AI luar talian|{piece} ke {square}.|Balasan AI pulih. Mengira semula…''',
  'th':
      '''ง่าย|ปานกลาง|ยาก|ย้อนตาเดิน|ย้อนตาในเกมออนไลน์ไม่ได้|อับ|AI ออฟไลน์|{piece} ไป {square}|กู้คืนคำตอบ AI แล้ว กำลังคำนวณใหม่…''',
  'vi':
      '''Dễ|Trung bình|Khó|Hoàn tác nước|Không thể hoàn tác trong ván trực tuyến|Hòa hết nước|AI ngoại tuyến|{piece} đến {square}.|Đã khôi phục đáp án AI. Đang tính lại…''',
  'pl':
      '''Łatwy|Średni|Trudny|Cofnij ruch|Cofanie jest niedostępne w grze online|Pat|AI offline|{piece} idzie na {square}.|Odpowiedź AI przywrócona. Ponowne obliczanie…''',
  'nl':
      '''Makkelijk|Gemiddeld|Moeilijk|Zet terugnemen|Terugnemen is online niet beschikbaar|Pat|Offline-AI|{piece} gaat naar {square}.|AI-antwoord hersteld. Opnieuw berekenen…''',
  'sv':
      '''Lätt|Medel|Svårt|Ångra drag|Ångra är inte tillgängligt online|Patt|Offline-AI|{piece} går till {square}.|AI-svar återställt. Beräknar igen…''',
  'el':
      '''Εύκολο|Μέτριο|Δύσκολο|Αναίρεση κίνησης|Η αναίρεση δεν είναι διαθέσιμη διαδικτυακά|Πατ|AI εκτός σύνδεσης|{piece} πηγαίνει στο {square}.|Η απάντηση AI αποκαταστάθηκε. Νέος υπολογισμός…''',
  'he':
      '''קל|בינוני|קשה|בטל מסע|אי אפשר לבטל מסעים במשחק מקוון|פט|AI לא מקוון|{piece} עובר ל־{square}.|תגובת AI שוחזרה. מחשב שוב…''',
  'sw':
      '''Rahisi|Wastani|Ngumu|Rudisha hatua|Kurudisha hakupatikani kwenye michezo ya mtandaoni|Mkwamo|AI bila mtandao|{piece} inaenda {square}.|Jibu la AI limerudishwa. Inahesabu tena…''',
};

const liveSaferPlanTranslations = <String, String>{
  'en': 'Tap “{button}” to understand the safer plan.',
  'te': 'మరింత సురక్షితమైన ప్రణాళికను అర్థం చేసుకోవడానికి “{button}” నొక్కండి.',
  'hi': 'सुरक्षित योजना समझने के लिए “{button}” दबाएँ।',
  'ta': 'பாதுகாப்பான திட்டத்தைப் புரிந்துகொள்ள “{button}” தட்டவும்.',
  'kn': 'ಸುರಕ್ಷಿತ ಯೋಜನೆ ತಿಳಿಯಲು “{button}” ಒತ್ತಿ.',
  'ml': 'സുരക്ഷിത പദ്ധതി മനസ്സിലാക്കാൻ “{button}” അമർത്തുക.',
  'mr': 'सुरक्षित योजना समजण्यासाठी “{button}” दाबा.',
  'bn': 'নিরাপদ পরিকল্পনা বুঝতে “{button}” চাপুন।',
  'gu': 'સુરક્ષિત યોજના સમજવા “{button}” દબાવો.',
  'pa': 'ਸੁਰੱਖਿਅਤ ਯੋਜਨਾ ਸਮਝਣ ਲਈ “{button}” ਦਬਾਓ।',
  'ur': 'محفوظ منصوبہ سمجھنے کے لیے “{button}” دبائیں۔',
  'ar': 'اضغط «{button}» لفهم الخطة الأكثر أمانًا.',
  'es': 'Pulsa «{button}» para entender el plan más seguro.',
  'fr': 'Touchez « {button} » pour comprendre le plan plus sûr.',
  'de': 'Tippe auf „{button}“, um den sichereren Plan zu verstehen.',
  'it': 'Tocca «{button}» per capire il piano più sicuro.',
  'pt': 'Toque em «{button}» para entender o plano mais seguro.',
  'ru': 'Нажмите «{button}», чтобы понять более безопасный план.',
  'uk': 'Натисніть «{button}», щоб зрозуміти безпечніший план.',
  'tr': 'Daha güvenli planı anlamak için “{button}” seçeneğine dokun.',
  'fa': 'برای درک برنامه امن‌تر روی «{button}» بزنید.',
  'zh': '点击“{button}”了解更安全的计划。',
  'ja': 'より安全な計画を理解するには「{button}」をタップしてください。',
  'ko': '더 안전한 계획을 이해하려면 “{button}”을 누르세요.',
  'id': 'Ketuk “{button}” untuk memahami rencana lebih aman.',
  'ms': 'Ketik “{button}” untuk memahami pelan lebih selamat.',
  'th': 'แตะ “{button}” เพื่อเข้าใจแผนที่ปลอดภัยกว่า',
  'vi': 'Nhấn “{button}” để hiểu kế hoạch an toàn hơn.',
  'pl': 'Dotknij „{button}”, aby zrozumieć bezpieczniejszy plan.',
  'nl': 'Tik op ‘{button}’ om het veiligere plan te begrijpen.',
  'sv': 'Tryck på ”{button}” för att förstå den säkrare planen.',
  'el': 'Πατήστε «{button}» για να κατανοήσετε το ασφαλέστερο σχέδιο.',
  'he': 'לחצו על ״{button}״ כדי להבין את התוכנית הבטוחה יותר.',
  'sw': 'Gusa “{button}” kuelewa mpango salama zaidi.',
};

const liveAnalysisSources = [
  'No legal move is available in this position.',
  'This move creates a strong tactical threat or wins material.',
  'This is a healthy move: it improves the position and keeps pressure.',
  'Playable, but keep looking for forcing checks, captures, or threats.',
  'Safe but quiet. A sharper move may exist if you calculate forcing lines.',
  'Ordinary move',
  'Quiet move',
  'No move',
];
final Map<String, List<String>> liveAnalysisTranslations = {
  for (final e in _analysisRows.entries) e.key: e.value.split('|')
};
const _analysisRows = <String, String>{
  'en':
      '''No legal move is available in this position.|This move creates a strong tactical threat or wins material.|This is a healthy move: it improves the position and keeps pressure.|Playable, but keep looking for forcing checks, captures, or threats.|Safe but quiet. A sharper move may exist if you calculate forcing lines.|Ordinary move|Quiet move|No move''',
  'te':
      '''ఈ స్థితిలో చట్టబద్ధమైన ఎత్తు లేదు.|ఈ ఎత్తు బలమైన వ్యూహాత్మక ముప్పును సృష్టిస్తుంది లేదా పావుల లాభం ఇస్తుంది.|ఇది మంచి ఎత్తు: స్థితిని మెరుగుపరచి ఒత్తిడిని కొనసాగిస్తుంది.|ఆడదగినది, కానీ బలవంతపు చెక్‌లు, పట్టుకోవడాలు లేదా ముప్పుల కోసం వెతకండి.|సురక్షితమైనా నిశ్శబ్ద ఎత్తు. బలవంతపు వరుసలను లెక్కిస్తే మరింత పదునైన ఎత్తు ఉండవచ్చు.|సాధారణ ఎత్తు|నిశ్శబ్ద ఎత్తు|ఎత్తు లేదు''',
  'hi':
      '''इस स्थिति में कोई वैध चाल उपलब्ध नहीं है।|यह चाल मजबूत सामरिक खतरा बनाती है या मोहरा जीतती है।|यह स्वस्थ चाल है: स्थिति सुधारती है और दबाव बनाए रखती है।|खेलने योग्य, लेकिन बाध्यकारी शह, मारने के मौके या खतरे खोजते रहें।|सुरक्षित लेकिन शांत। बाध्यकारी क्रम की गणना से अधिक तेज चाल मिल सकती है।|साधारण चाल|शांत चाल|कोई चाल नहीं''',
  'ta':
      '''இந்த நிலையில் சட்டபூர்வ நகர்வு இல்லை.|இந்த நகர்வு வலுவான தந்திர அச்சுறுத்தலை உருவாக்குகிறது அல்லது காயை வெல்கிறது.|இது நல்ல நகர்வு: நிலையை மேம்படுத்தி அழுத்தத்தைத் தொடர்கிறது.|ஆடத்தக்கது, ஆனால் கட்டாய செக், பிடிப்பு அல்லது அச்சுறுத்தலைத் தொடர்ந்து தேடுங்கள்.|பாதுகாப்பான ஆனால் அமைதியான நகர்வு. கட்டாய வரிசைகளை கணக்கிட்டால் கூர்மையான நகர்வு இருக்கலாம்.|சாதாரண நகர்வு|அமைதியான நகர்வு|நகர்வு இல்லை''',
  'kn':
      '''ಈ ಸ್ಥಿತಿಯಲ್ಲಿ ಕಾನೂನುಬದ್ಧ ನಡೆಯಿಲ್ಲ.|ಈ ನಡೆ ಬಲವಾದ ತಂತ್ರದ ಬೆದರಿಕೆ ಸೃಷ್ಟಿಸುತ್ತದೆ ಅಥವಾ ಕಾಯಿ ಗೆಲ್ಲುತ್ತದೆ.|ಇದು ಉತ್ತಮ ನಡೆ: ಸ್ಥಿತಿಯನ್ನು ಸುಧಾರಿಸಿ ಒತ್ತಡ ಉಳಿಸುತ್ತದೆ.|ಆಡಬಹುದು, ಆದರೆ ಬಲವಂತದ ಚೆಕ್, ಸೆರೆ ಅಥವಾ ಬೆದರಿಕೆಗಳನ್ನು ಹುಡುಕುತ್ತಿರಿ.|ಸುರಕ್ಷಿತ ಆದರೆ ಶಾಂತ ನಡೆ. ಬಲವಂತದ ಸಾಲುಗಳನ್ನು ಲೆಕ್ಕಿಸಿದರೆ ತೀಕ್ಷ್ಣ ನಡೆ ಇರಬಹುದು.|ಸಾಮಾನ್ಯ ನಡೆ|ಶಾಂತ ನಡೆ|ನಡೆಯಿಲ್ಲ''',
  'ml':
      '''ഈ നിലയിൽ നിയമാനുസൃത നീക്കമില്ല.|ഈ നീക്കം ശക്തമായ തന്ത്രഭീഷണി സൃഷ്ടിക്കുന്നു അല്ലെങ്കിൽ കരു നേടുന്നു.|ഇത് നല്ല നീക്കമാണ്: സ്ഥിതി മെച്ചപ്പെടുത്തുകയും സമ്മർദം നിലനിർത്തുകയും ചെയ്യുന്നു.|കളിക്കാവുന്നതാണ്, പക്ഷേ നിർബന്ധിത ചെക്ക്, പിടിത്തം, ഭീഷണി എന്നിവ അന്വേഷിക്കുക.|സുരക്ഷിതമെങ്കിലും ശാന്തമാണ്. നിർബന്ധിത ക്രമങ്ങൾ കണക്കാക്കിയാൽ കൂടുതൽ മൂർച്ചയുള്ള നീക്കം ഉണ്ടാകാം.|സാധാരണ നീക്കം|ശാന്തമായ നീക്കം|നീക്കമില്ല''',
  'mr':
      '''या स्थितीत वैध चाल उपलब्ध नाही.|ही चाल मजबूत डावपेचाचा धोका निर्माण करते किंवा मोहरा जिंकते.|ही उपयुक्त चाल आहे: स्थिती सुधारते आणि दबाव ठेवते.|खेळण्यायोग्य, पण सक्तीचे शह, मारण्याच्या संधी किंवा धोके शोधत राहा.|सुरक्षित पण शांत. सक्तीचे क्रम मोजल्यास अधिक तीक्ष्ण चाल सापडू शकते.|सामान्य चाल|शांत चाल|चाल नाही''',
  'bn':
      '''এই অবস্থানে কোনো বৈধ চাল নেই।|এই চাল শক্তিশালী কৌশলগত হুমকি তৈরি করে বা ঘুঁটি জেতে।|এটি ভালো চাল: অবস্থান উন্নত করে ও চাপ রাখে।|খেলা যায়, কিন্তু বাধ্যকারী কিস্তি, ধরা বা হুমকি খুঁজতে থাকুন।|নিরাপদ কিন্তু শান্ত। বাধ্যকারী ক্রম হিসাব করলে আরও ধারালো চাল পেতে পারেন।|সাধারণ চাল|শান্ত চাল|চাল নেই''',
  'gu':
      '''આ સ્થિતિમાં કાયદેસર ચાલ ઉપલબ્ધ નથી.|આ ચાલ મજબૂત વ્યૂહાત્મક ખતરો બનાવે અથવા મહોરું જીતે છે.|આ સારી ચાલ છે: સ્થિતિ સુધારે અને દબાણ રાખે છે.|રમી શકાય, પણ ફરજિયાત શાહ, મારવું કે ખતરા શોધતા રહો.|સુરક્ષિત પણ શાંત. ફરજિયાત ક્રમ ગણો તો વધુ તીવ્ર ચાલ હોઈ શકે.|સામાન્ય ચાલ|શાંત ચાલ|ચાલ નથી''',
  'pa':
      '''ਇਸ ਸਥਿਤੀ ਵਿੱਚ ਕੋਈ ਜਾਇਜ਼ ਚਾਲ ਨਹੀਂ।|ਇਹ ਚਾਲ ਮਜ਼ਬੂਤ ਦਾਅ ਦਾ ਖ਼ਤਰਾ ਬਣਾਉਂਦੀ ਜਾਂ ਮੋਹਰਾ ਜਿੱਤਦੀ ਹੈ।|ਇਹ ਚੰਗੀ ਚਾਲ ਹੈ: ਸਥਿਤੀ ਸੁਧਾਰਦੀ ਅਤੇ ਦਬਾਅ ਰੱਖਦੀ ਹੈ।|ਖੇਡਣ ਯੋਗ, ਪਰ ਮਜਬੂਰ ਕਰਨ ਵਾਲੀ ਸ਼ਹ, ਮਾਰਨ ਜਾਂ ਖ਼ਤਰੇ ਲੱਭਦੇ ਰਹੋ।|ਸੁਰੱਖਿਅਤ ਪਰ ਸ਼ਾਂਤ। ਮਜਬੂਰ ਕ੍ਰਮ ਗਿਣਣ ਨਾਲ ਹੋਰ ਤਿੱਖੀ ਚਾਲ ਮਿਲ ਸਕਦੀ ਹੈ।|ਆਮ ਚਾਲ|ਸ਼ਾਂਤ ਚਾਲ|ਚਾਲ ਨਹੀਂ''',
  'ur':
      '''اس پوزیشن میں کوئی جائز چال نہیں۔|یہ چال مضبوط حربی خطرہ بناتی ہے یا مہرہ جیتتی ہے۔|یہ اچھی چال ہے: پوزیشن بہتر کرکے دباؤ برقرار رکھتی ہے۔|قابل کھیل، مگر جبری شہ، مارنے یا خطرات تلاش کرتے رہیں۔|محفوظ مگر خاموش۔ جبری ترتیب کا حساب کرنے سے زیادہ تیز چال مل سکتی ہے۔|عام چال|خاموش چال|چال نہیں''',
  'ar':
      '''لا توجد نقلة قانونية في هذا الوضع.|تخلق هذه النقلة تهديدًا تكتيكيًا قويًا أو تربح مادة.|هذه نقلة سليمة: تحسّن الوضع وتُبقي الضغط.|قابلة للعب، لكن واصل البحث عن كش أو أخذ أو تهديد إجباري.|آمنة لكنها هادئة. قد تجد نقلة أشد إذا حسبت التسلسلات الإجبارية.|نقلة عادية|نقلة هادئة|لا نقلة''',
  'es':
      '''No hay jugada legal en esta posición.|Esta jugada crea una fuerte amenaza táctica o gana material.|Es una jugada sana: mejora la posición y mantiene la presión.|Jugable, pero sigue buscando jaques, capturas o amenazas forzantes.|Segura pero tranquila. Puede haber algo más incisivo si calculas líneas forzantes.|Jugada normal|Jugada tranquila|Sin jugada''',
  'fr':
      '''Aucun coup légal n’est disponible dans cette position.|Ce coup crée une forte menace tactique ou gagne du matériel.|C’est un coup sain : il améliore la position et maintient la pression.|Jouable, mais cherchez encore des échecs, captures ou menaces forçants.|Sûr mais calme. Un coup plus tranchant peut exister en calculant les lignes forçantes.|Coup ordinaire|Coup calme|Aucun coup''',
  'de':
      '''In dieser Stellung gibt es keinen legalen Zug.|Dieser Zug erzeugt eine starke taktische Drohung oder gewinnt Material.|Ein gesunder Zug: Er verbessert die Stellung und hält den Druck.|Spielbar, aber suche weiter nach forcierenden Schachs, Schlägen oder Drohungen.|Sicher, aber ruhig. Berechne forcierende Varianten; vielleicht gibt es einen schärferen Zug.|Gewöhnlicher Zug|Ruhiger Zug|Kein Zug''',
  'it':
      '''Nessuna mossa legale è disponibile in questa posizione.|Questa mossa crea una forte minaccia tattica o guadagna materiale.|È una mossa sana: migliora la posizione e mantiene la pressione.|Giocabile, ma continua a cercare scacchi, catture o minacce forzanti.|Sicura ma tranquilla. Calcolando linee forzanti potresti trovare una mossa più incisiva.|Mossa ordinaria|Mossa tranquilla|Nessuna mossa''',
  'pt':
      '''Não há lance legal disponível nesta posição.|Este lance cria uma forte ameaça tática ou ganha material.|É um lance saudável: melhora a posição e mantém a pressão.|Jogável, mas continue a procurar xeques, capturas ou ameaças forçantes.|Seguro mas calmo. Pode haver lance mais incisivo se calcular linhas forçantes.|Lance normal|Lance calmo|Sem lance''',
  'ru':
      '''В этой позиции нет допустимого хода.|Этот ход создаёт сильную тактическую угрозу или выигрывает материал.|Это здоровый ход: улучшает позицию и сохраняет давление.|Ход допустим, но продолжайте искать форсирующие шахи, взятия и угрозы.|Безопасно, но спокойно. При расчёте форсирующих вариантов может найтись более острый ход.|Обычный ход|Тихий ход|Нет хода''',
  'uk':
      '''У цій позиції немає допустимого ходу.|Цей хід створює сильну тактичну загрозу або виграє матеріал.|Це здоровий хід: покращує позицію та зберігає тиск.|Хід можливий, але шукайте далі форсовані шахи, взяття та загрози.|Безпечно, але спокійно. Розрахунок форсованих варіантів може знайти гостріший хід.|Звичайний хід|Тихий хід|Немає ходу''',
  'tr':
      '''Bu konumda yasal hamle yok.|Bu hamle güçlü taktik tehdit oluşturur veya materyal kazanır.|Sağlıklı hamle: konumu geliştirir ve baskıyı sürdürür.|Oynanabilir, ama zorlayıcı şahları, alışları ve tehditleri aramayı sürdür.|Güvenli ama sessiz. Zorlayıcı varyantları hesaplarsan daha keskin bir hamle bulunabilir.|Sıradan hamle|Sessiz hamle|Hamle yok''',
  'fa':
      '''در این وضعیت حرکت مجازی وجود ندارد.|این حرکت تهدید تاکتیکی قوی می‌سازد یا مهره می‌برد.|این حرکت سالم است: وضعیت را بهتر کرده و فشار را حفظ می‌کند.|قابل بازی است، اما کیش‌ها، گرفتن‌ها و تهدیدهای اجباری را بجویید.|امن اما آرام. با محاسبه مسیرهای اجباری شاید حرکت تندتری پیدا شود.|حرکت معمولی|حرکت آرام|بدون حرکت''',
  'zh':
      '''此局面没有合法着法。|这步制造强烈战术威胁或赢得子力。|这是稳健的一步：改善局面并保持压力。|可行，但继续寻找强制将军、吃子或威胁。|安全但平静。计算强制变化后，可能找到更犀利的着法。|普通着法|安静着法|无着法''',
  'ja':
      '''この局面に合法手はありません。|この手は強い戦術的脅威を作るか駒得します。|健全な手です。局面を改善して圧力を保ちます。|指せますが、強制的なチェック、捕獲、脅威を引き続き探しましょう。|安全ですが静かな手です。強制手順を計算すれば、より鋭い手があるかもしれません。|普通の手|静かな手|手がありません''',
  'ko':
      '''이 포지션에는 합법적인 수가 없습니다.|이 수는 강한 전술 위협을 만들거나 기물을 얻습니다.|건전한 수입니다. 포지션을 개선하고 압박을 유지합니다.|둘 수 있지만 강제 체크, 잡기, 위협을 계속 찾으세요.|안전하지만 조용합니다. 강제 수순을 계산하면 더 날카로운 수가 있을 수 있습니다.|평범한 수|조용한 수|수 없음''',
  'id':
      '''Tidak ada langkah legal dalam posisi ini.|Langkah ini menciptakan ancaman taktis kuat atau menang materi.|Ini langkah sehat: memperbaiki posisi dan menjaga tekanan.|Dapat dimainkan, tetapi terus cari skak, tangkapan, atau ancaman memaksa.|Aman tetapi tenang. Langkah lebih tajam mungkin ada jika menghitung jalur memaksa.|Langkah biasa|Langkah tenang|Tidak ada langkah''',
  'ms':
      '''Tiada gerakan sah dalam kedudukan ini.|Gerakan ini menghasilkan ancaman taktikal kuat atau memenangi buah.|Ini gerakan sihat: memperbaiki kedudukan dan mengekalkan tekanan.|Boleh dimainkan, tetapi terus cari syah, tangkapan atau ancaman memaksa.|Selamat tetapi tenang. Gerakan lebih tajam mungkin ada jika mengira turutan memaksa.|Gerakan biasa|Gerakan tenang|Tiada gerakan''',
  'th':
      '''ตำแหน่งนี้ไม่มีตาเดินที่ถูกกติกา|ตานี้สร้างภัยทางกลยุทธ์ที่รุนแรงหรือได้ตัวหมาก|ตานี้ดี ปรับปรุงตำแหน่งและรักษาความกดดัน|เล่นได้ แต่หาการรุก การจับ หรือภัยบังคับต่อไป|ปลอดภัยแต่เงียบ อาจมีตาที่เฉียบคมกว่าหากคำนวณแนวบังคับ|ตาธรรมดา|ตาเงียบ|ไม่มีตาเดิน''',
  'vi':
      '''Vị trí này không có nước đi hợp lệ.|Nước này tạo đe dọa chiến thuật mạnh hoặc thắng quân.|Đây là nước lành mạnh: cải thiện vị trí và giữ áp lực.|Chơi được, nhưng tiếp tục tìm chiếu, bắt hoặc đe dọa cưỡng bức.|An toàn nhưng yên tĩnh. Có thể có nước sắc hơn nếu tính các biến cưỡng bức.|Nước thường|Nước yên tĩnh|Không có nước''',
  'pl':
      '''W tej pozycji nie ma legalnego ruchu.|Ten ruch tworzy silną groźbę taktyczną lub zyskuje materiał.|To zdrowy ruch: poprawia pozycję i utrzymuje nacisk.|Grywalny, ale szukaj dalej wymuszających szachów, bić i gróźb.|Bezpieczny, ale cichy. Obliczenie wymuszających wariantów może ujawnić ostrzejszy ruch.|Zwykły ruch|Cichy ruch|Brak ruchu''',
  'nl':
      '''Er is geen legale zet in deze stelling.|Deze zet maakt een sterke tactische dreiging of wint materiaal.|Dit is een gezonde zet: verbetert de stelling en houdt druk.|Speelbaar, maar blijf zoeken naar dwingende schaakzetten, slagen of dreigingen.|Veilig maar rustig. Een scherpere zet kan bestaan als je dwingende varianten berekent.|Gewone zet|Rustige zet|Geen zet''',
  'sv':
      '''Det finns inget lagligt drag i denna ställning.|Draget skapar ett starkt taktiskt hot eller vinner material.|Ett sunt drag: det förbättrar ställningen och behåller pressen.|Spelbart, men fortsätt leta efter tvingande schackar, slag eller hot.|Säkert men lugnt. Ett skarpare drag kan finnas om du beräknar tvingande varianter.|Vanligt drag|Lugnt drag|Inget drag''',
  'el':
      '''Δεν υπάρχει νόμιμη κίνηση σε αυτή τη θέση.|Η κίνηση δημιουργεί ισχυρή τακτική απειλή ή κερδίζει υλικό.|Είναι υγιής κίνηση: βελτιώνει τη θέση και διατηρεί την πίεση.|Παίζεται, αλλά συνεχίστε να ψάχνετε αναγκαστικά σαχ, χτυπήματα ή απειλές.|Ασφαλής αλλά ήσυχη. Ίσως υπάρχει οξύτερη κίνηση αν υπολογίσετε αναγκαστικές γραμμές.|Συνηθισμένη κίνηση|Ήσυχη κίνηση|Καμία κίνηση''',
  'he':
      '''אין מסע חוקי בעמדה הזאת.|המסע יוצר איום טקטי חזק או זוכה בחומר.|זהו מסע בריא: משפר את העמדה ושומר על הלחץ.|אפשרי, אך המשיכו לחפש שח, הכאות או איומים כפויים.|בטוח אך שקט. ייתכן מסע חד יותר אם תחשבו המשכים כפויים.|מסע רגיל|מסע שקט|אין מסע''',
  'sw':
      '''Hakuna hatua halali katika nafasi hii.|Hatua hii huunda tishio kubwa la mbinu au hupata kete.|Hii ni hatua nzuri: huboresha nafasi na kudumisha shinikizo.|Inachezeka, lakini endelea kutafuta shaha, ukamataji au vitisho vya kulazimisha.|Salama lakini tulivu. Hatua kali zaidi huenda ipo ukihesabu mifululizo ya kulazimisha.|Hatua ya kawaida|Hatua tulivu|Hakuna hatua''',
};

const liveSheetKeys = ['equal', 'legal', 'captures', 'check', 'safe', 'close'];
final Map<String, List<String>> liveSheetTranslations = {
  for (final e in _sheetRows.entries) e.key: e.value.split('|')
};
String? _translateSheet(String value, String code) {
  String t(String key) =>
      liveSheetTranslations[code]![liveSheetKeys.indexOf(key)];
  const source = {
    'Equal': 'equal',
    'Immediate captures': 'captures',
    'In check': 'check',
    'Safe': 'safe',
    'Close analysis': 'close'
  };
  if (source.containsKey(value)) return t(source[value]!);
  if (value == 'AI Agent Coach') return localizeLiveCoach('AI Coach', code);
  if (value == 'No legal move') return localizeLiveCoach('No move', code);
  if (value == 'King safety') return analysisDashboardText('kingSafety', code);
  if (value == 'Recommended') {
    return CoachLocalizations(code).text('recommended');
  }
  if (value == 'Move quality') {
    return CoachLocalizations(code).text('moveQuality');
  }
  final m = RegExp(r'^(White|Black) legal moves$').firstMatch(value);
  if (m != null) {
    return '${CoachLocalizations(code).source(m[1]!)} • ${t('legal')}';
  }
  return null;
}

const _sheetRows = <String, String>{
  'en': 'Equal|Legal moves|Immediate captures|In check|Safe|Close analysis',
  'te':
      'సమానం|చట్టబద్ధమైన ఎత్తులు|తక్షణ పట్టుకోవడాలు|చెక్‌లో ఉంది|సురక్షితం|విశ్లేషణ మూసివేయండి',
  'hi': 'बराबर|वैध चालें|तुरंत मारने के मौके|शह में|सुरक्षित|विश्लेषण बंद करें',
  'ta':
      'சமம்|சட்டபூர்வ நகர்வுகள்|உடனடி பிடிப்புகள்|செக்கில்|பாதுகாப்பு|பகுப்பாய்வை மூடு',
  'kn':
      'ಸಮ|ಕಾನೂನುಬದ್ಧ ನಡೆಗಳು|ತಕ್ಷಣದ ಸೆರೆಗಳು|ಚೆಕ್‌ನಲ್ಲಿ|ಸುರಕ್ಷಿತ|ವಿಶ್ಲೇಷಣೆ ಮುಚ್ಚಿ',
  'ml':
      'സമം|നിയമാനുസൃത നീക്കങ്ങൾ|ഉടൻ പിടിക്കാവുന്നവ|ചെക്കിൽ|സുരക്ഷിതം|വിശകലനം അടയ്ക്കുക',
  'mr':
      'समान|वैध चाली|तत्काळ मारण्याच्या संधी|शहमध्ये|सुरक्षित|विश्लेषण बंद करा',
  'bn': 'সমান|বৈধ চাল|তাৎক্ষণিক ধরার সুযোগ|কিস্তিতে|নিরাপদ|বিশ্লেষণ বন্ধ করুন',
  'gu':
      'સમાન|કાયદેસર ચાલો|તાત્કાલિક મારવાની તક|શાહમાં|સુરક્ષિત|વિશ્લેષણ બંધ કરો',
  'pa':
      'ਬਰਾਬਰ|ਜਾਇਜ਼ ਚਾਲਾਂ|ਤੁਰੰਤ ਮਾਰਨ ਦੇ ਮੌਕੇ|ਸ਼ਹ ਵਿੱਚ|ਸੁਰੱਖਿਅਤ|ਵਿਸ਼ਲੇਸ਼ਣ ਬੰਦ ਕਰੋ',
  'ur': 'برابر|جائز چالیں|فوری مارنے کے مواقع|شہ میں|محفوظ|تجزیہ بند کریں',
  'ar': 'متعادل|نقلات قانونية|أخذ فوري|في كش|آمن|إغلاق التحليل',
  'es':
      'Igualado|Jugadas legales|Capturas inmediatas|En jaque|Seguro|Cerrar análisis',
  'fr': 'Égal|Coups légaux|Captures immédiates|En échec|Sûr|Fermer l’analyse',
  'de':
      'Ausgeglichen|Legale Züge|Sofortige Schläge|Im Schach|Sicher|Analyse schließen',
  'it':
      'Pari|Mosse legali|Catture immediate|Sotto scacco|Sicuro|Chiudi analisi',
  'pt': 'Igual|Lances legais|Capturas imediatas|Em xeque|Seguro|Fechar análise',
  'ru':
      'Равенство|Допустимые ходы|Немедленные взятия|Под шахом|Безопасно|Закрыть анализ',
  'uk':
      'Рівність|Допустимі ходи|Негайні взяття|Під шахом|Безпечно|Закрити аналіз',
  'tr': 'Eşit|Yasal hamleler|Anlık alışlar|Şah altında|Güvenli|Analizi kapat',
  'fa': 'برابر|حرکت‌های مجاز|گرفتن‌های فوری|در کیش|امن|بستن تحلیل',
  'zh': '均势|合法着法|立即吃子|被将军|安全|关闭分析',
  'ja': '互角|合法手|即座の捕獲|チェック中|安全|分析を閉じる',
  'ko': '동등|합법적인 수|즉시 잡기|체크 상태|안전|분석 닫기',
  'id':
      'Seimbang|Langkah legal|Tangkapan langsung|Dalam skak|Aman|Tutup analisis',
  'ms':
      'Seimbang|Gerakan sah|Tangkapan segera|Dalam syah|Selamat|Tutup analisis',
  'th': 'เท่ากัน|ตาเดินถูกกติกา|จับได้ทันที|ถูกรุก|ปลอดภัย|ปิดการวิเคราะห์',
  'vi': 'Cân bằng|Nước hợp lệ|Bắt ngay|Bị chiếu|An toàn|Đóng phân tích',
  'pl':
      'Równo|Legalne ruchy|Natychmiastowe bicia|W szachu|Bezpiecznie|Zamknij analizę',
  'nl': 'Gelijk|Legale zetten|Directe slagen|Schaak|Veilig|Analyse sluiten',
  'sv': 'Lika|Lagliga drag|Omedelbara slag|I schack|Säker|Stäng analys',
  'el':
      'Ισορροπία|Νόμιμες κινήσεις|Άμεσα χτυπήματα|Σε σαχ|Ασφαλής|Κλείσιμο ανάλυσης',
  'he': 'שוויון|מסעים חוקיים|הכאות מיידיות|בשח|בטוח|סגור ניתוח',
  'sw':
      'Sawa|Hatua halali|Ukamataji wa haraka|Katika shaha|Salama|Funga uchanganuzi',
};

const liveResultKeys = [
  'resign',
  'timeout',
  'agreed',
  'left',
  'both',
  'complete',
  'missed',
  'refund',
  'prize',
  'entry'
];
final Map<String, List<String>> liveResultTranslations = {
  for (final e in _resultRows.entries) e.key: e.value.split('|')
};
String? _translateResult(String value, String code) {
  String t(String key, [Map<String, String> p = const {}]) =>
      _fill(liveResultTranslations[code]![liveResultKeys.indexOf(key)], p);
  const sources = {
    'Match ended by resignation': 'resign',
    'Match ended on time': 'timeout',
    'Draw agreed': 'agreed',
    'Opponent left the match': 'left',
    'Both players disconnected': 'both',
    'Online match complete': 'complete',
    'Game complete': 'complete',
    'Challenge missed': 'missed'
  };
  final stripped =
      value.endsWith('.') ? value.substring(0, value.length - 1) : value;
  if (sources.containsKey(stripped)) return t(sources[stripped]!);
  var m = RegExp(r'^(\d+) coins refunded$').firstMatch(value);
  if (m != null) return t('refund', {'count': m[1]!});
  m = RegExp(r'^Prize \+(\d+) coins$').firstMatch(value);
  if (m != null) return t('prize', {'count': m[1]!});
  m = RegExp(r'^Entry -(\d+) coins$').firstMatch(value);
  if (m != null) return t('entry', {'count': m[1]!});
  if (RegExp(r'^(?:1-0|0-1|1/2-1/2)? • ').hasMatch(value)) {
    return value
        .split(' • ')
        .map((part) => localizeLiveCoach(part, code))
        .join(' • ');
  }
  return null;
}

const _resultRows = <String, String>{
  'en':
      'Match ended by resignation|Match ended on time|Draw agreed|Opponent left the match|Both players disconnected|Game complete|Challenge missed|{count} coins refunded|Prize +{count} coins|Entry -{count} coins',
  'te':
      'రాజీనామాతో మ్యాచ్ ముగిసింది|సమయం ముగిసి మ్యాచ్ ముగిసింది|డ్రా అంగీకరించారు|ప్రత్యర్థి మ్యాచ్ విడిచారు|ఇద్దరి కనెక్షన్ పోయింది|ఆట పూర్తయింది|సవాలు సాధించలేదు|{count} నాణేలు తిరిగి ఇచ్చారు|బహుమతి +{count} నాణేలు|ప్రవేశం -{count} నాణేలు',
  'hi':
      'इस्तीफे से मैच समाप्त|समय समाप्त होने से मैच खत्म|ड्रॉ स्वीकार|प्रतिद्वंद्वी मैच छोड़ गया|दोनों खिलाड़ियों का कनेक्शन टूटा|खेल पूरा|चुनौती अधूरी|{count} सिक्के लौटाए|इनाम +{count} सिक्के|प्रवेश -{count} सिक्के',
  'ta':
      'விலகலால் ஆட்டம் முடிந்தது|நேரம் முடிந்து ஆட்டம் முடிந்தது|சமநிலை ஏற்கப்பட்டது|எதிரி ஆட்டத்தை விட்டார்|இருவரின் இணைப்பும் துண்டித்தது|ஆட்டம் முடிந்தது|சவால் நிறைவேறவில்லை|{count} நாணயங்கள் திருப்பப்பட்டன|பரிசு +{count} நாணயங்கள்|நுழைவு -{count} நாணயங்கள்',
  'kn':
      'ರಾಜೀನಾಮೆಯಿಂದ ಪಂದ್ಯ ಮುಗಿದಿದೆ|ಸಮಯ ಮುಗಿದು ಪಂದ್ಯ ಅಂತ್ಯ|ಡ್ರಾ ಒಪ್ಪಲಾಗಿದೆ|ಎದುರಾಳಿ ಪಂದ್ಯ ಬಿಟ್ಟರು|ಇಬ್ಬರ ಸಂಪರ್ಕವೂ ಕಡಿತ|ಆಟ ಪೂರ್ಣ|ಸವಾಲು ತಪ್ಪಿತು|{count} ನಾಣ್ಯ ಮರುಪಾವತಿ|ಬಹುಮಾನ +{count} ನಾಣ್ಯ|ಪ್ರವೇಶ -{count} ನಾಣ್ಯ',
  'ml':
      'പിന്മാറ്റത്തോടെ മത്സരം അവസാനിച്ചു|സമയം തീർന്ന് മത്സരം അവസാനിച്ചു|സമനില അംഗീകരിച്ചു|എതിരാളി മത്സരം വിട്ടു|ഇരുവരുടെയും ബന്ധം നഷ്ടപ്പെട്ടു|കളി പൂർത്തി|വെല്ലുവിളി പൂർത്തിയായില്ല|{count} നാണയങ്ങൾ മടക്കി|സമ്മാനം +{count} നാണയങ്ങൾ|പ്രവേശനം -{count} നാണയങ്ങൾ',
  'mr':
      'राजीनाम्याने सामना संपला|वेळ संपल्याने सामना संपला|बरोबरी मान्य|प्रतिस्पर्धी सामना सोडून गेला|दोघांचे कनेक्शन तुटले|खेळ पूर्ण|आव्हान अपूर्ण|{count} नाणी परत|बक्षीस +{count} नाणी|प्रवेश -{count} नाणी',
  'bn':
      'আত্মসমর্পণে ম্যাচ শেষ|সময় ফুরিয়ে ম্যাচ শেষ|ড্র মেনে নেওয়া হয়েছে|প্রতিপক্ষ ম্যাচ ছেড়েছে|দুজনের সংযোগ বিচ্ছিন্ন|খেলা সম্পূর্ণ|চ্যালেঞ্জ অসম্পূর্ণ|{count} কয়েন ফেরত|পুরস্কার +{count} কয়েন|প্রবেশ -{count} কয়েন',
  'gu':
      'રાજીનામાથી મેચ પૂરી|સમયથી મેચ પૂરી|ડ્રો સ્વીકાર્યો|વિરોધીએ મેચ છોડી|બંનેનું જોડાણ તૂટ્યું|રમત પૂર્ણ|પડકાર અધૂરો|{count} સિક્કા પરત|ઇનામ +{count} સિક્કા|પ્રવેશ -{count} સિક્કા',
  'pa':
      'ਅਸਤੀਫ਼ੇ ਨਾਲ ਮੈਚ ਮੁੱਕਿਆ|ਸਮਾਂ ਮੁੱਕਣ ਨਾਲ ਮੈਚ ਖ਼ਤਮ|ਬਰਾਬਰੀ ਮਨਜ਼ੂਰ|ਵਿਰੋਧੀ ਮੈਚ ਛੱਡ ਗਿਆ|ਦੋਵਾਂ ਦਾ ਸੰਪਰਕ ਟੁੱਟਿਆ|ਖੇਡ ਪੂਰੀ|ਚੁਣੌਤੀ ਅਧੂਰੀ|{count} ਸਿੱਕੇ ਵਾਪਸ|ਇਨਾਮ +{count} ਸਿੱਕੇ|ਦਾਖ਼ਲਾ -{count} ਸਿੱਕੇ',
  'ur':
      'دستبرداری سے میچ ختم|وقت ختم ہونے سے میچ ختم|برابری منظور|حریف میچ چھوڑ گیا|دونوں کا رابطہ ٹوٹ گیا|کھیل مکمل|چیلنج نامکمل|{count} سکے واپس|انعام +{count} سکے|داخلہ -{count} سکے',
  'ar':
      'انتهت المباراة بالاستسلام|انتهت المباراة بالوقت|اتُّفق على التعادل|غادر الخصم المباراة|انقطع اتصال اللاعبين|اكتملت المباراة|لم يكتمل التحدي|أُعيدت {count} عملة|جائزة +{count} عملة|دخول -{count} عملة',
  'es':
      'Partida terminada por abandono|Partida terminada por tiempo|Tablas acordadas|El rival salió de la partida|Ambos jugadores desconectados|Partida completada|Desafío no resuelto|{count} monedas devueltas|Premio +{count} monedas|Entrada -{count} monedas',
  'fr':
      'Partie terminée par abandon|Partie terminée au temps|Nulle convenue|L’adversaire a quitté la partie|Les deux joueurs sont déconnectés|Partie terminée|Défi non réussi|{count} pièces remboursées|Prix +{count} pièces|Entrée -{count} pièces',
  'de':
      'Partie durch Aufgabe beendet|Partie durch Zeitablauf beendet|Remis vereinbart|Gegner hat die Partie verlassen|Beide Spieler getrennt|Partie beendet|Aufgabe nicht gelöst|{count} Münzen erstattet|Preis +{count} Münzen|Einsatz -{count} Münzen',
  'it':
      'Partita terminata per abbandono|Partita terminata per tempo|Patta concordata|L’avversario ha lasciato la partita|Entrambi i giocatori disconnessi|Partita completata|Sfida non riuscita|{count} monete rimborsate|Premio +{count} monete|Ingresso -{count} monete',
  'pt':
      'Partida terminada por desistência|Partida terminada por tempo|Empate acordado|O adversário deixou a partida|Ambos os jogadores desligados|Partida concluída|Desafio não resolvido|{count} moedas devolvidas|Prémio +{count} moedas|Entrada -{count} moedas',
  'ru':
      'Партия завершена сдачей|Партия завершена по времени|Ничья согласована|Соперник покинул партию|Оба игрока отключены|Партия завершена|Задание не выполнено|Возвращено {count} монет|Приз +{count} монет|Взнос -{count} монет',
  'uk':
      'Партія завершена здачею|Партія завершена за часом|Нічию погоджено|Суперник залишив партію|Обох гравців від’єднано|Партія завершена|Завдання не виконано|Повернуто {count} монет|Приз +{count} монет|Внесок -{count} монет',
  'tr':
      'Maç terk ile bitti|Maç süreyle bitti|Beraberlik kabul edildi|Rakip maçtan ayrıldı|İki oyuncu da bağlantıyı kaybetti|Oyun tamamlandı|Görev başarılamadı|{count} jeton iade edildi|Ödül +{count} jeton|Giriş -{count} jeton',
  'fa':
      'بازی با تسلیم پایان یافت|بازی با پایان زمان تمام شد|تساوی توافق شد|حریف بازی را ترک کرد|ارتباط هر دو بازیکن قطع شد|بازی کامل شد|چالش حل نشد|{count} سکه بازگشت|جایزه +{count} سکه|ورودی -{count} سکه',
  'zh':
      '对局因认输结束|对局因超时结束|协议和棋|对手离开对局|双方均已断线|对局完成|挑战未完成|已退还{count}金币|奖励+{count}金币|入场-{count}金币',
  'ja':
      '投了で対局終了|時間切れで対局終了|合意による引き分け|相手が対局を退出|両者の接続が切れました|対局終了|挑戦未達成|{count}コイン返却|賞金+{count}コイン|参加費-{count}コイン',
  'ko':
      '기권으로 대국 종료|시간 초과로 대국 종료|무승부 합의|상대가 대국을 떠남|두 플레이어 연결 끊김|대국 완료|도전 미완료|{count}코인 환불|상금 +{count}코인|참가 -{count}코인',
  'id':
      'Pertandingan selesai karena menyerah|Pertandingan selesai karena waktu|Remis disepakati|Lawan meninggalkan pertandingan|Kedua pemain terputus|Permainan selesai|Tantangan belum selesai|{count} koin dikembalikan|Hadiah +{count} koin|Masuk -{count} koin',
  'ms':
      'Perlawanan tamat kerana menyerah|Perlawanan tamat kerana masa|Seri dipersetujui|Lawan meninggalkan perlawanan|Kedua-dua pemain terputus|Permainan selesai|Cabaran belum selesai|{count} syiling dipulangkan|Hadiah +{count} syiling|Masuk -{count} syiling',
  'th':
      'เกมจบด้วยการยอมแพ้|เกมจบเพราะหมดเวลา|ตกลงเสมอ|คู่ต่อสู้ออกจากเกม|ผู้เล่นทั้งสองขาดการเชื่อมต่อ|เกมจบ|ยังไม่ผ่านโจทย์|คืน {count} เหรียญ|รางวัล +{count} เหรียญ|ค่าเข้า -{count} เหรียญ',
  'vi':
      'Ván kết thúc do đầu hàng|Ván kết thúc vì hết giờ|Đồng ý hòa|Đối thủ rời ván|Cả hai mất kết nối|Ván hoàn tất|Chưa vượt thử thách|Hoàn {count} xu|Thưởng +{count} xu|Phí vào -{count} xu',
  'pl':
      'Partia zakończona poddaniem|Partia zakończona na czas|Uzgodniono remis|Przeciwnik opuścił partię|Obaj gracze rozłączeni|Partia ukończona|Wyzwanie nieukończone|Zwrócono {count} monet|Nagroda +{count} monet|Wpisowe -{count} monet',
  'nl':
      'Partij beëindigd door opgave|Partij beëindigd door tijd|Remise overeengekomen|Tegenstander verliet de partij|Beide spelers niet verbonden|Partij voltooid|Uitdaging niet gehaald|{count} munten terugbetaald|Prijs +{count} munten|Inleg -{count} munten',
  'sv':
      'Partiet slutade genom uppgivning|Partiet slutade på tid|Remi överenskommen|Motståndaren lämnade partiet|Båda spelarna frånkopplade|Partiet klart|Utmaningen missades|{count} mynt återbetalade|Pris +{count} mynt|Insats -{count} mynt',
  'el':
      'Η παρτίδα έληξε με παραίτηση|Η παρτίδα έληξε από χρόνο|Συμφωνήθηκε ισοπαλία|Ο αντίπαλος έφυγε από την παρτίδα|Αποσυνδέθηκαν και οι δύο παίκτες|Η παρτίδα ολοκληρώθηκε|Η πρόκληση δεν ολοκληρώθηκε|Επιστράφηκαν {count} νομίσματα|Έπαθλο +{count} νομίσματα|Είσοδος -{count} νομίσματα',
  'he':
      'המשחק הסתיים בכניעה|המשחק הסתיים בזמן|הוסכם על תיקו|היריב עזב את המשחק|שני השחקנים נותקו|המשחק הושלם|האתגר לא הושלם|הוחזרו {count} מטבעות|פרס +{count} מטבעות|כניסה -{count} מטבעות',
  'sw':
      'Mechi imeisha kwa kujisalimisha|Mechi imeisha kwa muda|Sare imekubaliwa|Mpinzani ameondoka kwenye mechi|Wachezaji wote wamekatika|Mchezo umekamilika|Changamoto haijakamilika|Sarafu {count} zimerudishwa|Tuzo +{count} sarafu|Kiingilio -{count} sarafu',
};

const _rows = <String, String>{
  'en':
      '''Select a piece to see legal moves.|{piece} from {square} has {count} options.|{piece} has no legal target from {square}.|That move is blocked. Pick a highlighted square.|Move undone.|Waiting for your opponent to move.|ChessVerseAI is calculating its reply.|{side} to move.|{side} is in check.|Choose a promotion piece for {square}.|Need a nudge? Blue lights suggest {from} → {to}. You can still choose any legal move.|No legal moves found.|Step progress|Evaluation|Your move|Last move|Piece hint|Analyze|Why is this weak?|Analyze move|AI TRAINING • 3-LEVEL HINTS • GAME REVIEW''',
  'te':
      '''చట్టబద్ధమైన ఎత్తులను చూడటానికి పావును ఎంచుకోండి.|{square}లోని {piece}కు {count} అవకాశాలు ఉన్నాయి.|{square}లోని {piece}కు చట్టబద్ధమైన గమ్యం లేదు.|ఆ ఎత్తుకు అడ్డంకి ఉంది. హైలైట్ చేసిన గడిని ఎంచుకోండి.|ఎత్తు వెనక్కి తీసుకోబడింది.|ప్రత్యర్థి ఎత్తు కోసం వేచి ఉంది.|ChessVerseAI తన సమాధానాన్ని లెక్కిస్తోంది.|ఆడవలసిన పక్షం: {side}.|చెక్‌లో ఉన్న పక్షం: {side}.|{square} కోసం ప్రమోషన్ పావును ఎంచుకోండి.|సహాయం కావాలా? నీలి వెలుగులు {from} → {to} సూచిస్తున్నాయి. ఏ చట్టబద్ధమైన ఎత్తునైనా ఎంచుకోవచ్చు.|చట్టబద్ధమైన ఎత్తులు లేవు.|దశ పురోగతి|మూల్యాంకనం|మీ ఎత్తు|చివరి ఎత్తు|పావు సూచన|విశ్లేషించండి|ఇది ఎందుకు బలహీనమైనది?|ఎత్తును విశ్లేషించండి|AI శిక్షణ • 3-దశల సూచనలు • ఆట సమీక్ష''',
  'hi':
      '''वैध चालें देखने के लिए मोहरा चुनें।|{square} पर {piece} के लिए {count} विकल्प हैं।|{square} पर {piece} का कोई वैध लक्ष्य नहीं है।|यह चाल अवरुद्ध है। प्रकाशित खाना चुनें।|चाल वापस ली गई।|प्रतिद्वंद्वी की चाल की प्रतीक्षा है।|ChessVerseAI अपना जवाब गणना कर रहा है।|चाल की बारी: {side}।|शह में पक्ष: {side}।|{square} के लिए पदोन्नति मोहरा चुनें।|संकेत चाहिए? नीली रोशनी {from} → {to} सुझाती है। आप कोई भी वैध चाल चुन सकते हैं।|कोई वैध चाल नहीं मिली।|चरण प्रगति|मूल्यांकन|आपकी चाल|पिछली चाल|मोहरे का संकेत|विश्लेषण करें|यह कमजोर क्यों है?|चाल का विश्लेषण|AI प्रशिक्षण • 3-स्तरीय संकेत • खेल समीक्षा''',
  'ta':
      '''சட்டபூர்வ நகர்வுகளைக் காண காயைத் தேர்ந்தெடுக்கவும்.|{square} இல் {piece} க்கு {count} வாய்ப்புகள் உள்ளன.|{square} இல் {piece} க்கு சட்டபூர்வ இலக்கு இல்லை.|அந்த நகர்வு தடுக்கப்பட்டுள்ளது. ஒளிரும் கட்டத்தைத் தேர்ந்தெடுக்கவும்.|நகர்வு மீட்டெடுக்கப்பட்டது.|எதிரியின் நகர்வுக்காகக் காத்திருக்கிறது.|ChessVerseAI பதிலைக் கணக்கிடுகிறது.|நகர வேண்டிய தரப்பு: {side}.|செக்கில் உள்ள தரப்பு: {side}.|{square} க்கான பதவி உயர்வு காயைத் தேர்ந்தெடுக்கவும்.|உதவி வேண்டுமா? நீல ஒளி {from} → {to} பரிந்துரைக்கிறது. எந்தச் சட்டபூர்வ நகர்வையும் தேர்ந்தெடுக்கலாம்.|சட்டபூர்வ நகர்வுகள் இல்லை.|படி முன்னேற்றம்|மதிப்பீடு|உங்கள் நகர்வு|கடைசி நகர்வு|காய் குறிப்பு|பகுப்பாய்வு|இது ஏன் பலவீனமானது?|நகர்வைப் பகுப்பாய்வு செய்க|AI பயிற்சி • 3-நிலைக் குறிப்புகள் • ஆட்ட மதிப்பாய்வு''',
  'kn':
      '''ಕಾನೂನುಬದ್ಧ ನಡೆಗಳನ್ನು ನೋಡಲು ಕಾಯಿಯನ್ನು ಆಯ್ಕೆಮಾಡಿ.|{square} ನಲ್ಲಿರುವ {piece} ಗೆ {count} ಆಯ್ಕೆಗಳಿವೆ.|{square} ನಲ್ಲಿರುವ {piece} ಗೆ ಕಾನೂನುಬದ್ಧ ಗುರಿಯಿಲ್ಲ.|ಆ ನಡೆಗೆ ಅಡ್ಡಿಯಿದೆ. ಬೆಳಗಿಸಿದ ಚೌಕವನ್ನು ಆಯ್ಕೆಮಾಡಿ.|ನಡೆಯನ್ನು ಹಿಂತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ.|ಎದುರಾಳಿಯ ನಡೆಗಾಗಿ ಕಾಯುತ್ತಿದೆ.|ChessVerseAI ಉತ್ತರವನ್ನು ಲೆಕ್ಕಿಸುತ್ತಿದೆ.|ನಡೆಯುವ ಪಕ್ಷ: {side}.|ಚೆಕ್‌ನಲ್ಲಿರುವ ಪಕ್ಷ: {side}.|{square} ಗಾಗಿ ಬಡ್ತಿ ಕಾಯಿಯನ್ನು ಆಯ್ಕೆಮಾಡಿ.|ಸುಳಿವು ಬೇಕೇ? ನೀಲಿ ಬೆಳಕು {from} → {to} ಸೂಚಿಸುತ್ತದೆ. ಯಾವುದೇ ಕಾನೂನುಬದ್ಧ ನಡೆ ಆಯ್ಕೆಮಾಡಬಹುದು.|ಕಾನೂನುಬದ್ಧ ನಡೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ.|ಹಂತದ ಪ್ರಗತಿ|ಮೌಲ್ಯಮಾಪನ|ನಿಮ್ಮ ನಡೆ|ಕೊನೆಯ ನಡೆ|ಕಾಯಿಯ ಸುಳಿವು|ವಿಶ್ಲೇಷಿಸಿ|ಇದು ಏಕೆ ದುರ್ಬಲ?|ನಡೆಯನ್ನು ವಿಶ್ಲೇಷಿಸಿ|AI ತರಬೇತಿ • 3-ಹಂತದ ಸುಳಿವುಗಳು • ಆಟದ ವಿಮರ್ಶೆ''',
  'ml':
      '''നിയമാനുസൃത നീക്കങ്ങൾ കാണാൻ കരു തിരഞ്ഞെടുക്കുക.|{square} ലെ {piece} ന് {count} സാധ്യതകളുണ്ട്.|{square} ലെ {piece} ന് നിയമാനുസൃത ലക്ഷ്യമില്ല.|ആ നീക്കം തടസ്സപ്പെട്ടിരിക്കുന്നു. തെളിച്ചമുള്ള കളം തിരഞ്ഞെടുക്കുക.|നീക്കം പിൻവലിച്ചു.|എതിരാളിയുടെ നീക്കത്തിനായി കാത്തിരിക്കുന്നു.|ChessVerseAI മറുപടി കണക്കാക്കുന്നു.|നീക്കേണ്ട പക്ഷം: {side}.|ചെക്കിലുള്ള പക്ഷം: {side}.|{square} നുള്ള സ്ഥാനക്കയറ്റ കരു തിരഞ്ഞെടുക്കുക.|സൂചന വേണോ? നീല വെളിച്ചം {from} → {to} നിർദേശിക്കുന്നു. ഏത് നിയമാനുസൃത നീക്കവും തിരഞ്ഞെടുക്കാം.|നിയമാനുസൃത നീക്കങ്ങളില്ല.|ഘട്ട പുരോഗതി|മൂല്യനിർണയം|നിങ്ങളുടെ നീക്കം|അവസാന നീക്കം|കരുവിന്റെ സൂചന|വിശകലനം|ഇത് ദുർബലമായത് എന്തുകൊണ്ട്?|നീക്കം വിശകലനം ചെയ്യുക|AI പരിശീലനം • 3-തല സൂചനകൾ • കളി അവലോകനം''',
  'mr':
      '''वैध चाली पाहण्यासाठी मोहरा निवडा.|{square} वरील {piece} साठी {count} पर्याय आहेत.|{square} वरील {piece} साठी वैध लक्ष्य नाही.|या चालीला अडथळा आहे. प्रकाशित घर निवडा.|चाल मागे घेतली.|प्रतिस्पर्ध्याच्या चालीची वाट पाहत आहे.|ChessVerseAI उत्तराची गणना करत आहे.|चालीची पाळी: {side}.|शहमध्ये असलेला पक्ष: {side}.|{square} साठी पदोन्नती मोहरा निवडा.|संकेत हवा? निळा प्रकाश {from} → {to} सुचवतो. कोणतीही वैध चाल निवडू शकता.|वैध चाली सापडल्या नाहीत.|टप्प्याची प्रगती|मूल्यांकन|तुमची चाल|मागील चाल|मोहऱ्याचा संकेत|विश्लेषण करा|ही चाल कमकुवत का आहे?|चालीचे विश्लेषण|AI प्रशिक्षण • 3-स्तरीय संकेत • खेळाचे परीक्षण''',
  'bn':
      '''বৈধ চাল দেখতে ঘুঁটি বেছে নিন।|{square}-এর {piece}-এর জন্য {count}টি বিকল্প আছে।|{square}-এর {piece}-এর কোনো বৈধ লক্ষ্য নেই।|চালটি বাধাপ্রাপ্ত। উজ্জ্বল ঘর বেছে নিন।|চাল ফিরিয়ে নেওয়া হয়েছে।|প্রতিপক্ষের চালের অপেক্ষায়।|ChessVerseAI উত্তর গণনা করছে।|চালের পালা: {side}।|চেকে থাকা পক্ষ: {side}।|{square}-এর জন্য উন্নীত ঘুঁটি বেছে নিন।|ইঙ্গিত চান? নীল আলো {from} → {to} নির্দেশ করে। যেকোনো বৈধ চাল বেছে নিতে পারেন।|কোনো বৈধ চাল পাওয়া যায়নি।|ধাপের অগ্রগতি|মূল্যায়ন|আপনার চাল|শেষ চাল|ঘুঁটির ইঙ্গিত|বিশ্লেষণ|এটি দুর্বল কেন?|চাল বিশ্লেষণ|AI প্রশিক্ষণ • 3-স্তরের ইঙ্গিত • খেলা পর্যালোচনা''',
  'gu':
      '''કાયદેસર ચાલ જોવા મહોરું પસંદ કરો.|{square} પરના {piece} માટે {count} વિકલ્પો છે.|{square} પરના {piece} માટે કાયદેસર લક્ષ્ય નથી.|આ ચાલ અવરોધિત છે. પ્રકાશિત ઘર પસંદ કરો.|ચાલ પાછી ખેંચાઈ.|વિરોધીની ચાલની રાહ જોવાઈ રહી છે.|ChessVerseAI જવાબની ગણતરી કરે છે.|ચાલનો વારો: {side}.|શાહમાં રહેલો પક્ષ: {side}.|{square} માટે બઢતીનું મહોરું પસંદ કરો.|સંકેત જોઈએ? વાદળી પ્રકાશ {from} → {to} સૂચવે છે. કોઈપણ કાયદેસર ચાલ પસંદ કરી શકો છો.|કાયદેસર ચાલ મળી નથી.|તબક્કાની પ્રગતિ|મૂલ્યાંકન|તમારી ચાલ|છેલ્લી ચાલ|મહોરાનો સંકેત|વિશ્લેષણ|આ નબળી કેમ છે?|ચાલનું વિશ્લેષણ|AI તાલીમ • 3-સ્તરીય સંકેતો • રમતની સમીક્ષા''',
  'pa':
      '''ਜਾਇਜ਼ ਚਾਲਾਂ ਵੇਖਣ ਲਈ ਮੋਹਰਾ ਚੁਣੋ।|{square} ਉੱਤੇ {piece} ਲਈ {count} ਵਿਕਲਪ ਹਨ।|{square} ਉੱਤੇ {piece} ਦਾ ਕੋਈ ਜਾਇਜ਼ ਨਿਸ਼ਾਨਾ ਨਹੀਂ।|ਇਹ ਚਾਲ ਰੁਕੀ ਹੋਈ ਹੈ। ਚਮਕਦਾ ਖਾਨਾ ਚੁਣੋ।|ਚਾਲ ਵਾਪਸ ਲਈ ਗਈ।|ਵਿਰੋਧੀ ਦੀ ਚਾਲ ਦੀ ਉਡੀਕ ਹੈ।|ChessVerseAI ਜਵਾਬ ਦੀ ਗਣਨਾ ਕਰ ਰਿਹਾ ਹੈ।|ਚਾਲ ਦੀ ਵਾਰੀ: {side}।|ਸ਼ਹ ਵਿੱਚ ਪੱਖ: {side}।|{square} ਲਈ ਤਰੱਕੀ ਵਾਲਾ ਮੋਹਰਾ ਚੁਣੋ।|ਸੰਕੇਤ ਚਾਹੀਦਾ ਹੈ? ਨੀਲੀ ਰੌਸ਼ਨੀ {from} → {to} ਸੁਝਾਉਂਦੀ ਹੈ। ਕੋਈ ਵੀ ਜਾਇਜ਼ ਚਾਲ ਚੁਣ ਸਕਦੇ ਹੋ।|ਕੋਈ ਜਾਇਜ਼ ਚਾਲ ਨਹੀਂ ਮਿਲੀ।|ਪੜਾਅ ਦੀ ਤਰੱਕੀ|ਮੁਲਾਂਕਣ|ਤੁਹਾਡੀ ਚਾਲ|ਪਿਛਲੀ ਚਾਲ|ਮੋਹਰੇ ਦਾ ਸੰਕੇਤ|ਵਿਸ਼ਲੇਸ਼ਣ|ਇਹ ਕਮਜ਼ੋਰ ਕਿਉਂ ਹੈ?|ਚਾਲ ਦਾ ਵਿਸ਼ਲੇਸ਼ਣ|AI ਸਿਖਲਾਈ • 3-ਪੱਧਰੀ ਸੰਕੇਤ • ਖੇਡ ਸਮੀਖਿਆ''',
  'ur':
      '''جائز چالیں دیکھنے کے لیے مہرہ چنیں۔|{square} پر {piece} کے لیے {count} امکانات ہیں۔|{square} پر {piece} کا کوئی جائز ہدف نہیں۔|یہ چال مسدود ہے۔ نمایاں خانہ چنیں۔|چال واپس لے لی گئی۔|حریف کی چال کا انتظار ہے۔|ChessVerseAI جواب کا حساب لگا رہا ہے۔|چال کی باری: {side}۔|شہ میں فریق: {side}۔|{square} کے لیے ترقی کا مہرہ چنیں۔|اشارہ چاہیے؟ نیلی روشنی {from} → {to} تجویز کرتی ہے۔ آپ کوئی بھی جائز چال چن سکتے ہیں۔|کوئی جائز چال نہیں ملی۔|مرحلے کی پیش رفت|جائزہ|آپ کی چال|پچھلی چال|مہرے کا اشارہ|تجزیہ کریں|یہ کمزور کیوں ہے؟|چال کا تجزیہ|AI تربیت • 3 درجوں کے اشارے • کھیل کا جائزہ''',
  'ar':
      '''اختر قطعة لرؤية النقلات القانونية.|للقطعة {piece} على {square} عدد خيارات: {count}.|لا توجد وجهة قانونية للقطعة {piece} على {square}.|هذه النقلة محجوبة. اختر مربعًا مضاءً.|تم التراجع عن النقلة.|في انتظار نقلة خصمك.|يحسب ChessVerseAI رده.|الدور: {side}.|الطرف في كش: {side}.|اختر قطعة الترقية في {square}.|تحتاج تلميحًا؟ تشير الإضاءة الزرقاء إلى {from} → {to}. يمكنك اختيار أي نقلة قانونية.|لم يتم العثور على نقلات قانونية.|تقدم الخطوات|التقييم|نقلتك|آخر نقلة|تلميح القطعة|تحليل|لماذا هذه النقلة ضعيفة؟|تحليل النقلة|تدريب AI • تلميحات من 3 مستويات • مراجعة المباراة''',
  'es':
      '''Selecciona una pieza para ver las jugadas legales.|{piece} en {square} tiene {count} opciones.|{piece} en {square} no tiene destinos legales.|Esa jugada está bloqueada. Elige una casilla resaltada.|Jugada deshecha.|Esperando la jugada de tu rival.|ChessVerseAI está calculando su respuesta.|Juegan: {side}.|Bando en jaque: {side}.|Elige una pieza de promoción para {square}.|¿Una pista? Las luces azules sugieren {from} → {to}. Puedes elegir cualquier jugada legal.|No se encontraron jugadas legales.|Progreso de pasos|Evaluación|Tu jugada|Última jugada|Pista de pieza|Analizar|¿Por qué es débil?|Analizar jugada|ENTRENAMIENTO IA • PISTAS DE 3 NIVELES • ANÁLISIS DE PARTIDA''',
  'fr':
      '''Sélectionnez une pièce pour voir les coups légaux.|{piece} en {square} a {count} possibilités.|{piece} en {square} n’a aucune destination légale.|Ce coup est bloqué. Choisissez une case éclairée.|Coup annulé.|En attente du coup adverse.|ChessVerseAI calcule sa réponse.|Trait : {side}.|Camp en échec : {side}.|Choisissez une pièce de promotion pour {square}.|Un indice ? Les lumières bleues suggèrent {from} → {to}. Vous pouvez choisir tout coup légal.|Aucun coup légal trouvé.|Progression des étapes|Évaluation|Votre coup|Dernier coup|Indice de pièce|Analyser|Pourquoi est-ce faible ?|Analyser le coup|ENTRAÎNEMENT IA • INDICES À 3 NIVEAUX • ANALYSE DE PARTIE''',
  'de':
      '''Wähle eine Figur, um legale Züge zu sehen.|{piece} auf {square} hat {count} Möglichkeiten.|{piece} auf {square} hat kein legales Zielfeld.|Dieser Zug ist blockiert. Wähle ein markiertes Feld.|Zug zurückgenommen.|Warte auf den Zug des Gegners.|ChessVerseAI berechnet seine Antwort.|Am Zug: {side}.|Im Schach: {side}.|Wähle die Umwandlungsfigur für {square}.|Ein Hinweis? Blaue Lichter empfehlen {from} → {to}. Du kannst jeden legalen Zug wählen.|Keine legalen Züge gefunden.|Schrittfortschritt|Bewertung|Dein Zug|Letzter Zug|Figurenhinweis|Analysieren|Warum ist das schwach?|Zug analysieren|KI-TRAINING • 3-STUFIGE HINWEISE • PARTIEANALYSE''',
  'it':
      '''Seleziona un pezzo per vedere le mosse legali.|{piece} in {square} ha {count} possibilità.|{piece} in {square} non ha destinazioni legali.|Questa mossa è bloccata. Scegli una casa evidenziata.|Mossa annullata.|In attesa della mossa avversaria.|ChessVerseAI sta calcolando la risposta.|Tocca a: {side}.|Lato sotto scacco: {side}.|Scegli il pezzo di promozione per {square}.|Un indizio? Le luci blu suggeriscono {from} → {to}. Puoi scegliere qualsiasi mossa legale.|Nessuna mossa legale trovata.|Avanzamento dei passi|Valutazione|La tua mossa|Ultima mossa|Indizio sul pezzo|Analizza|Perché è debole?|Analizza mossa|ALLENAMENTO IA • INDIZI A 3 LIVELLI • ANALISI PARTITA''',
  'pt':
      '''Selecione uma peça para ver os lances legais.|{piece} em {square} tem {count} opções.|{piece} em {square} não tem destino legal.|Esse lance está bloqueado. Escolha uma casa destacada.|Lance desfeito.|A aguardar o lance do adversário.|ChessVerseAI está a calcular a resposta.|Vez de: {side}.|Lado em xeque: {side}.|Escolha uma peça de promoção para {square}.|Uma dica? As luzes azuis sugerem {from} → {to}. Pode escolher qualquer lance legal.|Nenhum lance legal encontrado.|Progresso das etapas|Avaliação|O seu lance|Último lance|Dica de peça|Analisar|Por que é fraco?|Analisar lance|TREINO IA • DICAS DE 3 NÍVEIS • ANÁLISE DA PARTIDA''',
  'ru':
      '''Выберите фигуру, чтобы увидеть допустимые ходы.|У {piece} на {square} вариантов: {count}.|У {piece} на {square} нет допустимой цели.|Этот ход заблокирован. Выберите подсвеченное поле.|Ход отменён.|Ожидание хода соперника.|ChessVerseAI рассчитывает ответ.|Ходят: {side}.|Под шахом: {side}.|Выберите фигуру превращения для {square}.|Нужна подсказка? Синие огни предлагают {from} → {to}. Можно выбрать любой допустимый ход.|Допустимых ходов не найдено.|Прогресс шагов|Оценка|Ваш ход|Последний ход|Подсказка фигуры|Анализ|Почему ход слабый?|Анализ хода|ТРЕНИРОВКА ИИ • 3 УРОВНЯ ПОДСКАЗОК • РАЗБОР ПАРТИИ''',
  'uk':
      '''Виберіть фігуру, щоб побачити допустимі ходи.|У {piece} на {square} варіантів: {count}.|У {piece} на {square} немає допустимої цілі.|Цей хід заблоковано. Виберіть підсвічене поле.|Хід скасовано.|Очікування ходу суперника.|ChessVerseAI обчислює відповідь.|Ходять: {side}.|Під шахом: {side}.|Виберіть фігуру перетворення для {square}.|Потрібна підказка? Сині вогні пропонують {from} → {to}. Можна вибрати будь-який допустимий хід.|Допустимих ходів не знайдено.|Прогрес кроків|Оцінка|Ваш хід|Останній хід|Підказка фігури|Аналіз|Чому хід слабкий?|Аналіз ходу|ТРЕНУВАННЯ ШІ • 3 РІВНІ ПІДКАЗОК • РОЗБІР ПАРТІЇ''',
  'tr':
      '''Yasal hamleleri görmek için bir taş seçin.|{square} üzerindeki {piece} için {count} seçenek var.|{square} üzerindeki {piece} için yasal hedef yok.|Bu hamle engelli. Vurgulanan bir kare seçin.|Hamle geri alındı.|Rakibinizin hamlesi bekleniyor.|ChessVerseAI yanıtını hesaplıyor.|Hamle sırası: {side}.|Şah altında: {side}.|{square} için terfi taşı seçin.|İpucu ister misiniz? Mavi ışıklar {from} → {to} öneriyor. Herhangi bir yasal hamle seçebilirsiniz.|Yasal hamle bulunamadı.|Adım ilerlemesi|Değerlendirme|Hamleniz|Son hamle|Taş ipucu|Analiz et|Neden zayıf?|Hamleyi analiz et|YAPAY ZEKÂ EĞİTİMİ • 3 SEVİYELİ İPUÇLARI • OYUN İNCELEMESİ''',
  'fa':
      '''برای دیدن حرکت‌های مجاز یک مهره انتخاب کنید.|{piece} در {square} دارای {count} گزینه است.|{piece} در {square} مقصد مجازی ندارد.|این حرکت مسدود است. خانه روشن را انتخاب کنید.|حرکت برگردانده شد.|در انتظار حرکت حریف.|ChessVerseAI پاسخ خود را محاسبه می‌کند.|نوبت حرکت: {side}.|طرف در کیش: {side}.|مهره ترفیع برای {square} را انتخاب کنید.|راهنمایی می‌خواهید؟ نور آبی {from} → {to} را پیشنهاد می‌کند. هر حرکت مجازی را می‌توانید انتخاب کنید.|حرکت مجازی پیدا نشد.|پیشرفت مراحل|ارزیابی|حرکت شما|آخرین حرکت|راهنمای مهره|تحلیل|چرا ضعیف است؟|تحلیل حرکت|آموزش هوش مصنوعی • راهنمایی 3 مرحله‌ای • بررسی بازی''',
  'zh':
      '''选择棋子以查看合法着法。|{square}上的{piece}有{count}种选择。|{square}上的{piece}没有合法目标。|这步棋被阻挡。请选择高亮格子。|已撤销着法。|等待对手走棋。|ChessVerseAI正在计算应对。|行棋方：{side}。|被将军方：{side}。|为{square}选择升变棋子。|需要提示吗？蓝光建议{from} → {to}。你仍可选择任何合法着法。|未找到合法着法。|步骤进度|评估|你的着法|上一步|棋子提示|分析|为什么这步较弱？|分析着法|AI训练 • 3级提示 • 对局复盘''',
  'ja':
      '''合法手を見るには駒を選んでください。|{square}の{piece}には{count}通りの手があります。|{square}の{piece}には合法な移動先がありません。|その手は妨げられています。光っているマスを選んでください。|手を取り消しました。|相手の着手を待っています。|ChessVerseAIが応手を計算しています。|手番：{side}。|チェックされている側：{side}。|{square}の昇格先の駒を選んでください。|ヒントが必要ですか？青い光は{from} → {to}を勧めています。他の合法手も選べます。|合法手が見つかりません。|ステップの進行|評価|あなたの手|直前の手|駒のヒント|分析|なぜ弱い手なのか？|着手を分析|AIトレーニング • 3段階ヒント • 対局レビュー''',
  'ko':
      '''합법적인 수를 보려면 기물을 선택하세요.|{square}의 {piece}에는 {count}개의 선택지가 있습니다.|{square}의 {piece}에는 합법적인 목적지가 없습니다.|이 수는 막혀 있습니다. 강조된 칸을 선택하세요.|수를 되돌렸습니다.|상대의 수를 기다리는 중입니다.|ChessVerseAI가 응수를 계산 중입니다.|차례: {side}.|체크 상태인 쪽: {side}.|{square}에서 승격할 기물을 선택하세요.|힌트가 필요한가요? 파란빛이 {from} → {to}를 제안합니다. 다른 합법적인 수도 선택할 수 있습니다.|합법적인 수를 찾지 못했습니다.|단계 진행|평가|나의 수|마지막 수|기물 힌트|분석|왜 약한 수인가요?|수 분석|AI 훈련 • 3단계 힌트 • 대국 복기''',
  'id':
      '''Pilih buah untuk melihat langkah legal.|{piece} di {square} memiliki {count} pilihan.|{piece} di {square} tidak memiliki tujuan legal.|Langkah itu terhalang. Pilih petak yang disorot.|Langkah dibatalkan.|Menunggu langkah lawan.|ChessVerseAI sedang menghitung balasannya.|Giliran: {side}.|Pihak yang diskak: {side}.|Pilih buah promosi untuk {square}.|Perlu petunjuk? Cahaya biru menyarankan {from} → {to}. Anda tetap dapat memilih langkah legal lainnya.|Tidak ditemukan langkah legal.|Kemajuan tahap|Evaluasi|Langkah Anda|Langkah terakhir|Petunjuk buah|Analisis|Mengapa ini lemah?|Analisis langkah|LATIHAN AI • PETUNJUK 3 TINGKAT • ULASAN PERMAINAN''',
  'ms':
      '''Pilih buah untuk melihat gerakan sah.|{piece} di {square} mempunyai {count} pilihan.|{piece} di {square} tiada sasaran sah.|Gerakan itu terhalang. Pilih petak yang diserlahkan.|Gerakan dibatalkan.|Menunggu gerakan lawan.|ChessVerseAI sedang mengira balasannya.|Giliran: {side}.|Pihak dalam syah: {side}.|Pilih buah kenaikan untuk {square}.|Perlukan petunjuk? Cahaya biru mencadangkan {from} → {to}. Anda masih boleh memilih sebarang gerakan sah.|Tiada gerakan sah ditemui.|Kemajuan langkah|Penilaian|Gerakan anda|Gerakan terakhir|Petunjuk buah|Analisis|Mengapa ini lemah?|Analisis gerakan|LATIHAN AI • PETUNJUK 3 TAHAP • ULASAN PERMAINAN''',
  'th':
      '''เลือกตัวหมากเพื่อดูตาเดินที่ถูกกติกา|{piece} ที่ {square} มี {count} ทางเลือก|{piece} ที่ {square} ไม่มีปลายทางที่ถูกกติกา|ตานี้ถูกขวาง เลือกช่องที่ไฮไลต์|ย้อนตาเดินแล้ว|กำลังรอคู่ต่อสู้เดิน|ChessVerseAI กำลังคำนวณตาตอบ|ฝ่ายที่ต้องเดิน: {side}|ฝ่ายที่ถูกรุก: {side}|เลือกตัวหมากเลื่อนขั้นที่ {square}|ต้องการคำใบ้ไหม? แสงสีน้ำเงินแนะนำ {from} → {to} คุณยังเลือกตาเดินที่ถูกกติกาอื่นได้|ไม่พบตาเดินที่ถูกกติกา|ความคืบหน้าของขั้นตอน|การประเมิน|ตาเดินของคุณ|ตาเดินล่าสุด|คำใบ้ตัวหมาก|วิเคราะห์|ทำไมตานี้อ่อน?|วิเคราะห์ตาเดิน|ฝึกกับ AI • คำใบ้ 3 ระดับ • ทบทวนเกม''',
  'vi':
      '''Chọn quân để xem các nước đi hợp lệ.|{piece} ở {square} có {count} lựa chọn.|{piece} ở {square} không có ô đích hợp lệ.|Nước đi này bị chặn. Hãy chọn ô được tô sáng.|Đã hoàn tác nước đi.|Đang chờ đối thủ đi.|ChessVerseAI đang tính nước đáp.|Lượt đi: {side}.|Bên bị chiếu: {side}.|Chọn quân phong cấp cho {square}.|Cần gợi ý? Ánh sáng xanh gợi ý {from} → {to}. Bạn vẫn có thể chọn bất kỳ nước đi hợp lệ nào.|Không tìm thấy nước đi hợp lệ.|Tiến độ các bước|Đánh giá|Nước đi của bạn|Nước đi cuối|Gợi ý quân|Phân tích|Tại sao nước này yếu?|Phân tích nước đi|HUẤN LUYỆN AI • GỢI Ý 3 CẤP • XEM LẠI VÁN''',
  'pl':
      '''Wybierz figurę, aby zobaczyć legalne ruchy.|{piece} na {square} ma {count} możliwości.|{piece} na {square} nie ma legalnego pola docelowego.|Ten ruch jest zablokowany. Wybierz podświetlone pole.|Ruch cofnięty.|Oczekiwanie na ruch przeciwnika.|ChessVerseAI oblicza odpowiedź.|Na ruchu: {side}.|Szachowany kolor: {side}.|Wybierz figurę promocji na {square}.|Potrzebujesz wskazówki? Niebieskie światła sugerują {from} → {to}. Możesz wybrać dowolny legalny ruch.|Nie znaleziono legalnych ruchów.|Postęp kroków|Ocena|Twój ruch|Ostatni ruch|Wskazówka figury|Analizuj|Dlaczego to słabe?|Analizuj ruch|TRENING AI • WSKAZÓWKI 3-STOPNIOWE • ANALIZA PARTII''',
  'nl':
      '''Selecteer een stuk om legale zetten te zien.|{piece} op {square} heeft {count} mogelijkheden.|{piece} op {square} heeft geen legaal doelveld.|Die zet is geblokkeerd. Kies een gemarkeerd veld.|Zet teruggenomen.|Wachten op de zet van je tegenstander.|ChessVerseAI berekent zijn antwoord.|Aan zet: {side}.|Schaak voor: {side}.|Kies een promotiestuk voor {square}.|Een hint nodig? Blauwe lichten suggereren {from} → {to}. Je kunt nog steeds elke legale zet kiezen.|Geen legale zetten gevonden.|Voortgang|Evaluatie|Jouw zet|Laatste zet|Stukhint|Analyseren|Waarom is dit zwak?|Zet analyseren|AI-TRAINING • HINTS OP 3 NIVEAUS • PARTIJANALYSE''',
  'sv':
      '''Välj en pjäs för att se lagliga drag.|{piece} på {square} har {count} alternativ.|{piece} på {square} har inget lagligt målfält.|Det draget är blockerat. Välj en markerad ruta.|Draget ångrades.|Väntar på motståndarens drag.|ChessVerseAI beräknar sitt svar.|Vid draget: {side}.|I schack: {side}.|Välj en promoveringspjäs för {square}.|Behöver du en ledtråd? Blå ljus föreslår {from} → {to}. Du kan fortfarande välja valfritt lagligt drag.|Inga lagliga drag hittades.|Stegförlopp|Utvärdering|Ditt drag|Senaste drag|Pjäsledtråd|Analysera|Varför är det svagt?|Analysera drag|AI-TRÄNING • LEDTRÅDAR I 3 NIVÅER • PARTIANALYS''',
  'el':
      '''Επιλέξτε κομμάτι για να δείτε νόμιμες κινήσεις.|Το {piece} στο {square} έχει {count} επιλογές.|Το {piece} στο {square} δεν έχει νόμιμο προορισμό.|Αυτή η κίνηση εμποδίζεται. Επιλέξτε φωτισμένο τετράγωνο.|Η κίνηση αναιρέθηκε.|Αναμονή για την κίνηση του αντιπάλου.|Το ChessVerseAI υπολογίζει την απάντησή του.|Σειρά: {side}.|Πλευρά σε σαχ: {side}.|Επιλέξτε κομμάτι προαγωγής για το {square}.|Χρειάζεστε υπόδειξη; Το μπλε φως προτείνει {from} → {to}. Μπορείτε να επιλέξετε οποιαδήποτε νόμιμη κίνηση.|Δεν βρέθηκαν νόμιμες κινήσεις.|Πρόοδος βημάτων|Αξιολόγηση|Η κίνησή σας|Τελευταία κίνηση|Υπόδειξη κομματιού|Ανάλυση|Γιατί είναι αδύναμη;|Ανάλυση κίνησης|ΕΚΠΑΙΔΕΥΣΗ AI • ΥΠΟΔΕΙΞΕΙΣ 3 ΕΠΙΠΕΔΩΝ • ΑΝΑΛΥΣΗ ΠΑΡΤΙΔΑΣ''',
  'he':
      '''בחרו כלי כדי לראות מסעים חוקיים.|לכלי {piece} ב־{square} יש {count} אפשרויות.|לכלי {piece} ב־{square} אין יעד חוקי.|המסע חסום. בחרו משבצת מוארת.|המסע בוטל.|ממתין למסע היריב.|ChessVerseAI מחשב את תגובתו.|תור: {side}.|הצד בשח: {side}.|בחרו כלי להכתרה ב־{square}.|צריכים רמז? האור הכחול מציע {from} → {to}. עדיין אפשר לבחור כל מסע חוקי.|לא נמצאו מסעים חוקיים.|התקדמות השלבים|הערכה|המסע שלכם|המסע האחרון|רמז לכלי|ניתוח|למה זה חלש?|ניתוח מסע|אימון AI • רמזים ב־3 רמות • סקירת המשחק''',
  'sw':
      '''Chagua kete kuona hatua halali.|{piece} kwenye {square} ina chaguo {count}.|{piece} kwenye {square} haina lengo halali.|Hatua hiyo imezuiwa. Chagua kisanduku kilichoangazwa.|Hatua imerudishwa.|Inasubiri hatua ya mpinzani.|ChessVerseAI inahesabu jibu lake.|Zamu: {side}.|Upande ulio kwenye shaha: {side}.|Chagua kete ya kupandishwa kwenye {square}.|Unahitaji kidokezo? Mwanga wa bluu unapendekeza {from} → {to}. Bado unaweza kuchagua hatua yoyote halali.|Hakuna hatua halali zilizopatikana.|Maendeleo ya hatua|Tathmini|Hatua yako|Hatua ya mwisho|Kidokezo cha kete|Changanua|Kwa nini ni dhaifu?|Changanua hatua|MAFUNZO YA AI • VIDOKEZO VYA NGAZI 3 • MAPITIO YA MCHEZO''',
};
