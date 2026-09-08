import '../features/analysis/domain/ai_review_report.dart';
import '../features/analysis/domain/personal_ai_coach.dart';
import 'app_language.dart';
import 'coach_localizations.dart';
import 'review_narrative_localizations.dart';

/// Bundled UI copy. No network or translation service is involved.
const personalCoachKeys = <String>[
  'title',
  'loading',
  'askPosition',
  'example',
  'compare',
  'followUp',
  'signin',
  'feedbackHelpfulSaved',
  'feedbackSaved',
  'feedbackError',
  'useful',
  'helpful',
  'notHelpful',
  'remaining',
  'autoLanguage',
  'whyBad',
  'opponentThreat',
  'bestPlan',
  'pattern',
  'practice',
  'unavailable',
  'played',
  'loss',
  'calculate',
  'practiceAnswer',
];

final personalCoachTranslations = <String, List<String>>{
  for (final e in _rows.entries) e.key: e.value.split('|'),
};

String personalCoachText(String key, String code) {
  if (key == 'boardSemantics' || key == 'apiError') {
    return _extraRows[AppLanguageController.resolveCode(code)]!
        .split('|')[key == 'boardSemantics' ? 0 : 1];
  }
  if (key == 'back') return CoachLocalizations(code).text('back');
  final index = personalCoachKeys.indexOf(key);
  if (index < 0) throw ArgumentError.value(key, 'key');
  return personalCoachTranslations[AppLanguageController.resolveCode(code)]![
      index];
}

const _extraRows = <String, String>{
  'en':
      'Board explanation with best-move, threat, and candidate arrows|Could not load the answer. Please try again.',
  'te':
      'ఉత్తమ ఎత్తు, ప్రమాదం, సాధ్యమైన ఎత్తుల బాణాలతో బోర్డు వివరణ|సమాధానం లోడ్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
  'hi':
      'सर्वश्रेष्ठ चाल, खतरे और संभावित चालों के तीरों सहित बोर्ड का विवरण|उत्तर लोड नहीं हुआ। फिर प्रयास करें।',
  'ta':
      'சிறந்த நகர்வு, அச்சுறுத்தல், சாத்திய நகர்வுகளின் அம்புகளுடன் பலகை விளக்கம்|பதிலை ஏற்ற முடியவில்லை. மீண்டும் முயலுங்கள்.',
  'kn':
      'ಉತ್ತಮ ನಡೆ, ಬೆದರಿಕೆ ಮತ್ತು ಸಾಧ್ಯ ನಡೆಗಳ ಬಾಣಗಳೊಂದಿಗೆ ಬೋರ್ಡಿನ ವಿವರಣೆ|ಉತ್ತರ ಲೋಡ್ ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  'ml':
      'മികച്ച നീക്കം, ഭീഷണി, സാധ്യതാ നീക്കങ്ങളുടെ അമ്പുകളുള്ള ബോർഡ് വിശദീകരണം|മറുപടി ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കൂ.',
  'mr':
      'सर्वोत्तम चाल, धोका आणि संभाव्य चालींचे बाण असलेले पटाचे स्पष्टीकरण|उत्तर लोड झाले नाही. पुन्हा प्रयत्न करा.',
  'bn':
      'সেরা চাল, হুমকি ও সম্ভাব্য চালের তীরসহ বোর্ডের ব্যাখ্যা|উত্তর লোড হয়নি। আবার চেষ্টা করুন।',
  'gu':
      'શ્રેષ્ઠ ચાલ, ખતરા અને સંભવિત ચાલોના તીર સાથે બોર્ડની સમજૂતી|જવાબ લોડ થયો નથી. ફરી પ્રયત્ન કરો.',
  'pa':
      'ਸਭ ਤੋਂ ਵਧੀਆ ਚਾਲ, ਖ਼ਤਰੇ ਅਤੇ ਸੰਭਾਵੀ ਚਾਲਾਂ ਦੇ ਤੀਰਾਂ ਨਾਲ ਬੋਰਡ ਦੀ ਵਿਆਖਿਆ|ਜਵਾਬ ਲੋਡ ਨਹੀਂ ਹੋਇਆ। ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
  'ur':
      'بہترین چال، خطرے اور ممکنہ چالوں کے تیروں کے ساتھ بورڈ کی وضاحت|جواب لوڈ نہیں ہوا۔ دوبارہ کوشش کریں۔',
  'ar':
      'شرح الرقعة بأسهم أفضل نقلة والتهديد والنقلات المرشحة|تعذر تحميل الإجابة. حاول مجددًا.',
  'es':
      'Explicación del tablero con flechas de mejor jugada, amenaza y candidatas|No se pudo cargar la respuesta. Inténtalo de nuevo.',
  'fr':
      'Explication de l’échiquier avec flèches du meilleur coup, de la menace et des candidats|Impossible de charger la réponse. Réessayez.',
  'de':
      'Bretterklärung mit Pfeilen für besten Zug, Drohung und Kandidaten|Antwort konnte nicht geladen werden. Bitte erneut versuchen.',
  'it':
      'Spiegazione della scacchiera con frecce per mossa migliore, minaccia e candidate|Impossibile caricare la risposta. Riprova.',
  'pt':
      'Explicação do tabuleiro com setas do melhor lance, ameaça e candidatos|Não foi possível carregar a resposta. Tente novamente.',
  'ru':
      'Объяснение доски со стрелками лучшего хода, угрозы и кандидатов|Не удалось загрузить ответ. Повторите попытку.',
  'uk':
      'Пояснення дошки зі стрілками найкращого ходу, загрози та кандидатів|Не вдалося завантажити відповідь. Спробуйте ще раз.',
  'tr':
      'En iyi hamle, tehdit ve aday oklarıyla tahta açıklaması|Yanıt yüklenemedi. Lütfen yeniden dene.',
  'fa':
      'توضیح صفحه با پیکان‌های بهترین حرکت، تهدید و حرکت‌های نامزد|پاسخ بارگیری نشد. دوباره تلاش کنید.',
  'zh': '棋盘说明，含最佳着法、威胁和候选着法箭头|无法加载回答，请重试。',
  'ja': '最善手、脅威、候補手の矢印を含む盤面の説明|回答を読み込めませんでした。再試行してください。',
  'ko': '최선의 수, 위협, 후보 수 화살표가 있는 보드 설명|답변을 불러올 수 없습니다. 다시 시도하세요.',
  'id':
      'Penjelasan papan dengan panah langkah terbaik, ancaman, dan kandidat|Jawaban tidak dapat dimuat. Coba lagi.',
  'ms':
      'Penjelasan papan dengan anak panah langkah terbaik, ancaman dan calon|Jawapan tidak dapat dimuatkan. Cuba lagi.',
  'th':
      'คำอธิบายกระดานพร้อมลูกศรตาที่ดีที่สุด ภัยคุกคาม และตาที่เป็นตัวเลือก|โหลดคำตอบไม่ได้ โปรดลองอีกครั้ง',
  'vi':
      'Giải thích bàn cờ với mũi tên nước tốt nhất, đe dọa và ứng viên|Không tải được câu trả lời. Vui lòng thử lại.',
  'pl':
      'Opis szachownicy ze strzałkami najlepszego ruchu, zagrożenia i kandydatów|Nie udało się wczytać odpowiedzi. Spróbuj ponownie.',
  'nl':
      'Borduitleg met pijlen voor beste zet, dreiging en kandidaten|Antwoord kon niet worden geladen. Probeer opnieuw.',
  'sv':
      'Brädförklaring med pilar för bästa drag, hot och kandidater|Svaret kunde inte laddas. Försök igen.',
  'el':
      'Εξήγηση σκακιέρας με βέλη καλύτερης κίνησης, απειλής και υποψηφίων|Δεν φορτώθηκε η απάντηση. Δοκιμάστε ξανά.',
  'he':
      'הסבר הלוח עם חצים למסע הטוב ביותר, לאיום ולמועמדים|לא ניתן לטעון את התשובה. נסו שוב.',
  'sw':
      'Maelezo ya ubao yenye mishale ya hatua bora, tishio na hatua zinazopendekezwa|Jibu halikuweza kupakiwa. Jaribu tena.',
};

String questionLabel(CoachQuestion question, String code) =>
    personalCoachText(question.name, code);

/// Engine notation, scores and counts stay data, never translated prose.
/// A missing best move is not presented as a recommended move.
String personalCoachAnswer(
    AiMoveInsight insight, CoachQuestion question, String code) {
  final labels = CoachLocalizations(code);
  String t(String key) => personalCoachText(key, code);
  final parts = <String>[];
  final best = insight.bestMove?.trim();
  final threat = insight.opponentThreat?.trim();
  if (question == CoachQuestion.whyBad) {
    parts.add(
        '${t('played')}: ${insight.notation} · ${localizeReviewNarrative(labels.source(insight.label), code)}');
    parts.add(personalCoachTheme(insight.coachingTheme, code));
    if (insight.centipawnLoss != null) {
      parts.add('${t('loss')}: ${insight.centipawnLoss} cp');
    }
    parts.add(localizeReviewNarrative(insight.explanation, code));
  } else if (question == CoachQuestion.pattern) {
    parts.add(personalCoachTheme(insight.coachingTheme, code));
    parts.add(localizeReviewNarrative(insight.explanation, code));
    parts.add(t('calculate'));
  } else if (question == CoachQuestion.bestPlan) {
    parts.add(
        '${labels.source(insight.phase)} · ${personalCoachTheme(insight.coachingTheme, code)}');
  } else if (question == CoachQuestion.practice) {
    parts.add(t('practiceAnswer').replaceAll(
        '{count}', '${insight.principalVariation.length.clamp(2, 6)}'));
  }
  if (best != null && best.isNotEmpty) {
    parts.add('${labels.text('best')}: $best');
  }
  if (threat != null && threat.isNotEmpty && threat != '(none)') {
    parts.add('${labels.text('immediateReply')}: $threat');
  } else {
    parts.add(t('unavailable'));
  }
  if (insight.principalVariation.isNotEmpty) {
    parts.add(
        '${labels.text('continuation')}: ${insight.principalVariation.take(6).join(' → ')}');
  } else {
    parts.add(t('calculate'));
  }
  return parts.where((p) => p.isNotEmpty).join('\n\n');
}

/// Translates only the deterministic server's known sentence grammar.
/// Unrecognised model/user prose is retained, never replaced with a stock answer.
String localizeCoachApiAnswer(String answer, String code) {
  final resolved = AppLanguageController.resolveCode(code);
  if (resolved == 'en') return answer;
  final labels = CoachLocalizations(resolved);
  final row = personalCoachApiTranslations[resolved]!;
  String fill(int i, Map<String, String> args) {
    var value = row[i];
    for (final e in args.entries) {
      value = value.replaceAll('{${e.key}}', e.value);
    }
    return value;
  }

  // Shield quoted user text from the narrative translator.
  final memory = RegExp(r'^Following your earlier question, "([\s\S]*?)": ')
      .firstMatch(answer);
  String result = memory == null ? answer : answer.substring(memory.end);
  result = result.replaceAllMapped(
      RegExp(
          r'If you play (.+?), Stockfish grades it (.+?) with a (\d+) centipawn loss\.'),
      (m) => fill(1, {
            'move': m[1]!,
            'grade':
                localizeReviewNarrative(labels.source(_titleCase(m[2]!)), code),
            'count': m[3]!
          }));
  result = result.replaceAll('It is a sound practical choice.', row[2]);
  result = result.replaceAllMapped(
      RegExp(r'The stronger move is (.+?)\.'), (m) => fill(3, {'move': m[1]!}));
  result = result.replaceAllMapped(
      RegExp(r"The opponent's most forcing reply is (.+?)\."),
      (m) => fill(4, {'move': m[1]!}));
  result = result.replaceAllMapped(
      RegExp(r'The immediate engine threat is (.+?)\.'),
      (m) => '${labels.text('immediateReply')}: ${m[1]}.');
  result = result.replaceAllMapped(
      RegExp(r'(.+?) is a good move\. It keeps the position under control\.'),
      (m) => fill(5, {'move': m[1]!}));
  result = result.replaceAllMapped(
      RegExp(
          r'(.+?) gives the opponent a stronger reply\. Prefer (.+?) and check their forcing move first\.'),
      (m) => fill(6, {'move': m[1]!, 'best': m[2]!}));
  result = result.replaceAllMapped(
      RegExp(
          r'Play (.+?)\. It preserves more of your position and meets the immediate reply (.+?)\.'),
      (m) => fill(7, {'move': m[1]!, 'reply': m[2]!}));
  result = result.replaceAllMapped(
      RegExp(
          r'^(.+?) was graded (.+?)\. ([\s\S]+?)(?= A concrete line is | No forcing continuation|$)'),
      (m) => '${fill(8, {
                'move': m[1]!,
                'grade': localizeReviewNarrative(
                    labels.source(_titleCase(m[2]!)), code)
              })} ${localizeReviewNarrative(m[3]!, resolved)}');
  result = result.replaceAllMapped(RegExp(r'A concrete line is (.+?)\.'),
      (m) => '${labels.text('continuation')}: ${m[1]}.');
  result = result.replaceAll(
      'No forcing continuation was returned.', _noLine[resolved]!);
  result = result.replaceAll(
      'no single forcing move', personalCoachText('unavailable', resolved));
  result = localizeReviewNarrative(result, resolved);
  return '${memory == null ? '' : '${fill(0, {
          'question': memory[1]!
        })} '}$result';
}

String _titleCase(String input) =>
    input.isEmpty ? input : '${input[0].toUpperCase()}${input.substring(1)}';
const _noLine = <String, String>{
  'en': 'No forcing continuation was returned.',
  'te': 'బలవంతపు కొనసాగింపు ఇవ్వబడలేదు.',
  'hi': 'कोई बाध्यकारी क्रम नहीं मिला।',
  'ta': 'கட்டாயத் தொடர்ச்சி வழங்கப்படவில்லை.',
  'kn': 'ಬಲವಂತದ ಮುಂದುವರಿಕೆ ನೀಡಲಾಗಿಲ್ಲ.',
  'ml': 'നിർബന്ധിത തുടർച്ച നൽകിയിട്ടില്ല.',
  'mr': 'सक्तीचा पुढील क्रम मिळाला नाही.',
  'bn': 'কোনো বাধ্যকারী ক্রম পাওয়া যায়নি।',
  'gu': 'કોઈ ફરજ પાડતો ક્રમ મળ્યો નથી.',
  'pa': 'ਕੋਈ ਮਜਬੂਰ ਕਰਨ ਵਾਲਾ ਕ੍ਰਮ ਨਹੀਂ ਮਿਲਿਆ।',
  'ur': 'کوئی مجبور کرنے والا سلسلہ نہیں ملا۔',
  'ar': 'لم يُقدم تسلسل إجباري.',
  'es': 'No se proporcionó una continuación forzada.',
  'fr': 'Aucune suite forcée n’a été fournie.',
  'de': 'Es wurde keine forcierte Fortsetzung geliefert.',
  'it': 'Non è stata fornita una continuazione forzante.',
  'pt': 'Não foi fornecida uma continuação forçada.',
  'ru': 'Форсированное продолжение не предоставлено.',
  'uk': 'Форсоване продовження не надано.',
  'tr': 'Zorlayıcı bir devam yolu sunulmadı.',
  'fa': 'ادامهٔ اجباری ارائه نشد.',
  'zh': '未提供强制变化。',
  'ja': '強制的な続きは提示されませんでした。',
  'ko': '강제 수순이 제공되지 않았습니다.',
  'id': 'Kelanjutan memaksa tidak diberikan.',
  'ms': 'Sambungan memaksa tidak diberikan.',
  'th': 'ไม่มีลำดับบังคับที่ให้มา',
  'vi': 'Không có diễn biến cưỡng bức được cung cấp.',
  'pl': 'Nie podano wymuszonej kontynuacji.',
  'nl': 'Er werd geen gedwongen voortzetting gegeven.',
  'sv': 'Ingen tvingande fortsättning angavs.',
  'el': 'Δεν δόθηκε αναγκαστική συνέχεια.',
  'he': 'לא סופק המשך כפוי.',
  'sw': 'Hakuna mwendelezo wa kulazimisha uliotolewa.',
};
final personalCoachApiTranslations = <String, List<String>>{
  for (final e in _apiRows.entries) e.key: e.value.split('|'),
};
const _apiRows = <String, String>{
  'en':
      '''Following your earlier question, "{question}":|If you play {move}, Stockfish grades it {grade} with a {count} centipawn loss.|It is a sound practical choice.|The stronger move is {move}.|The opponent's most forcing reply is {move}.|{move} is a good move. It keeps the position under control.|{move} gives the opponent a stronger reply. Prefer {best} and check their forcing move first.|Play {move}. It preserves more of your position and meets the immediate reply {reply}.|{move} was graded {grade}.''',
  'te':
      '''మీ మునుపటి ప్రశ్న "{question}"కు కొనసాగింపుగా:|{move} ఆడితే Stockfish అంచనా {grade}; నష్టం {count} సెంటిపాన్లు.|ఇది ఆచరణలో సరైన ఎంపిక.|బలమైన ఎత్తు {move}.|ప్రత్యర్థి అత్యంత బలవంతపు సమాధానం {move}.|{move} మంచి ఎత్తు. ఇది స్థితిని నియంత్రణలో ఉంచుతుంది.|{move} ప్రత్యర్థికి బలమైన సమాధానం ఇస్తుంది. {best} ఎంచుకొని ముందుగా వారి బలవంతపు ఎత్తును చూడండి.|{move} ఆడండి. ఇది స్థితిని మెరుగ్గా కాపాడి తక్షణ సమాధానం {reply}ను ఎదుర్కొంటుంది.|{move} అంచనా: {grade}.''',
  'hi':
      '''आपके पहले प्रश्न "{question}" के आगे:|{move} खेलने पर Stockfish का आकलन {grade} है, {count} सेंटिपॉन की हानि के साथ।|यह व्यावहारिक रूप से सही विकल्प है।|अधिक मजबूत चाल {move} है।|विरोधी का सबसे बाध्यकारी जवाब {move} है।|{move} अच्छी चाल है। यह स्थिति को नियंत्रण में रखती है।|{move} विरोधी को मजबूत जवाब देता है। {best} चुनें और पहले उसकी बाध्यकारी चाल जाँचें।|{move} खेलें। यह स्थिति को बेहतर बचाता है और तत्काल जवाब {reply} का सामना करता है।|{move} का आकलन {grade} था।''',
  'ta':
      '''முந்தைய "{question}" கேள்வியைத் தொடர்ந்து:|{move} ஆடினால் Stockfish மதிப்பீடு {grade}; இழப்பு {count} சென்டிபான்.|இது நடைமுறையில் நல்ல தேர்வு.|வலுவான நகர்வு {move}.|எதிரியின் மிகக் கட்டாயமான பதில் {move}.|{move} நல்ல நகர்வு. இது நிலையை கட்டுப்பாட்டில் வைக்கிறது.|{move} எதிரிக்கு வலுவான பதிலைத் தருகிறது. {best} தேர்ந்து முதலில் எதிரியின் கட்டாய நகர்வைப் பாருங்கள்.|{move} ஆடுங்கள். இது நிலையை மேம்படப் பாதுகாத்து உடனடி பதில் {reply} ஐ எதிர்கொள்கிறது.|{move} மதிப்பீடு {grade}.''',
  'kn':
      '''ನಿಮ್ಮ ಹಿಂದಿನ ಪ್ರಶ್ನೆ "{question}" ಮುಂದುವರಿಸಿ:|{move} ಆಡಿದರೆ Stockfish ಮೌಲ್ಯಮಾಪನ {grade}; ನಷ್ಟ {count} ಸೆಂಟಿಪಾನ್.|ಇದು ಪ್ರಾಯೋಗಿಕವಾಗಿ ಸರಿಯಾದ ಆಯ್ಕೆ.|ಬಲವಾದ ನಡೆ {move}.|ಎದುರಾಳಿಯ ಅತ್ಯಂತ ಬಲವಂತದ ಉತ್ತರ {move}.|{move} ಒಳ್ಳೆಯ ನಡೆ. ಇದು ಸ್ಥಿತಿಯನ್ನು ನಿಯಂತ್ರಣದಲ್ಲಿಡುತ್ತದೆ.|{move} ಎದುರಾಳಿಗೆ ಬಲವಾದ ಉತ್ತರ ನೀಡುತ್ತದೆ. {best} ಆಯ್ದು ಮೊದಲು ಅವರ ಬಲವಂತದ ನಡೆ ಪರಿಶೀಲಿಸಿ.|{move} ಆಡಿ. ಇದು ಸ್ಥಿತಿಯನ್ನು ಚೆನ್ನಾಗಿ ಕಾಪಾಡಿ ತಕ್ಷಣದ ಉತ್ತರ {reply} ಎದುರಿಸುತ್ತದೆ.|{move} ಮೌಲ್ಯಮಾಪನ {grade}.''',
  'ml':
      '''നിങ്ങളുടെ മുൻചോദ്യം "{question}" തുടർന്ന്:|{move} കളിച്ചാൽ Stockfish വിലയിരുത്തൽ {grade}; നഷ്ടം {count} സെന്റിപോൺ.|ഇത് പ്രായോഗികമായി നല്ല തിരഞ്ഞെടുപ്പാണ്.|കൂടുതൽ ശക്തമായ നീക്കം {move}.|എതിരാളിയുടെ ഏറ്റവും നിർബന്ധിത മറുപടി {move}.|{move} നല്ല നീക്കമാണ്. സ്ഥിതി നിയന്ത്രണത്തിൽ നിർത്തുന്നു.|{move} എതിരാളിക്ക് ശക്തമായ മറുപടി നൽകുന്നു. {best} തിരഞ്ഞെടുക്കുകയും ആദ്യം അവരുടെ നിർബന്ധിത നീക്കം പരിശോധിക്കുകയും ചെയ്യൂ.|{move} കളിക്കൂ. ഇത് സ്ഥിതി കൂടുതൽ സംരക്ഷിച്ച് ഉടനടി മറുപടി {reply} നേരിടുന്നു.|{move} വിലയിരുത്തൽ {grade}.''',
  'mr':
      '''तुमच्या आधीच्या "{question}" प्रश्नानुसार:|{move} खेळल्यास Stockfish चे मूल्यांकन {grade}, नुकसान {count} सेंटिपॉन.|हा व्यवहार्य आणि योग्य पर्याय आहे.|अधिक मजबूत चाल {move} आहे.|प्रतिस्पर्ध्याचे सर्वाधिक सक्तीचे उत्तर {move} आहे.|{move} चांगली चाल आहे. ती स्थिती नियंत्रणात ठेवते.|{move} प्रतिस्पर्ध्याला मजबूत उत्तर देते. {best} निवडा आणि आधी त्याची सक्तीची चाल तपासा.|{move} खेळा. ती स्थिती अधिक चांगली राखते आणि तात्काळ उत्तर {reply} हाताळते.|{move} चे मूल्यांकन {grade} होते.''',
  'bn':
      '''আপনার আগের প্রশ্ন "{question}" অনুসারে:|{move} খেললে Stockfish মূল্যায়ন {grade}, ক্ষতি {count} সেন্টিপন।|এটি বাস্তবে ভালো পছন্দ।|আরও শক্তিশালী চাল {move}।|প্রতিপক্ষের সবচেয়ে বাধ্যকারী জবাব {move}।|{move} ভালো চাল। এটি অবস্থান নিয়ন্ত্রণে রাখে।|{move} প্রতিপক্ষকে শক্তিশালী জবাব দেয়। {best} বেছে আগে তার বাধ্যকারী চাল দেখুন।|{move} খেলুন। এটি অবস্থান আরও ভালো রাখে ও তাৎক্ষণিক জবাব {reply} সামলায়।|{move} মূল্যায়ন ছিল {grade}।''',
  'gu':
      '''તમારા અગાઉના પ્રશ્ન "{question}" અનુસાર:|{move} રમો તો Stockfish મૂલ્યાંકન {grade}; નુકસાન {count} સેન્ટિપોન.|આ વ્યવહારિક રીતે યોગ્ય પસંદગી છે.|વધુ મજબૂત ચાલ {move} છે.|વિરોધીનો સૌથી ફરજ પાડતો જવાબ {move} છે.|{move} સારી ચાલ છે. તે સ્થિતિ નિયંત્રણમાં રાખે છે.|{move} વિરોધીને મજબૂત જવાબ આપે છે. {best} પસંદ કરી પહેલાં તેની ફરજ પાડતી ચાલ તપાસો.|{move} રમો. તે સ્થિતિ વધુ સારી રાખે છે અને તાત્કાલિક જવાબ {reply} સામે રક્ષણ આપે છે.|{move} નું મૂલ્યાંકન {grade} હતું.''',
  'pa':
      '''ਤੁਹਾਡੇ ਪਿਛਲੇ ਸਵਾਲ "{question}" ਅਨੁਸਾਰ:|{move} ਖੇਡਣ ਉੱਤੇ Stockfish ਮੁਲਾਂਕਣ {grade}, ਘਾਟਾ {count} ਸੈਂਟੀਪੌਨ ਹੈ।|ਇਹ ਅਮਲੀ ਤੌਰ ਤੇ ਸਹੀ ਚੋਣ ਹੈ।|ਵੱਧ ਮਜ਼ਬੂਤ ਚਾਲ {move} ਹੈ।|ਵਿਰੋਧੀ ਦਾ ਸਭ ਤੋਂ ਮਜਬੂਰ ਕਰਨ ਵਾਲਾ ਜਵਾਬ {move} ਹੈ।|{move} ਚੰਗੀ ਚਾਲ ਹੈ। ਇਹ ਸਥਿਤੀ ਕਾਬੂ ਵਿੱਚ ਰੱਖਦੀ ਹੈ।|{move} ਵਿਰੋਧੀ ਨੂੰ ਮਜ਼ਬੂਤ ਜਵਾਬ ਦਿੰਦੀ ਹੈ। {best} ਚੁਣੋ ਤੇ ਪਹਿਲਾਂ ਉਸ ਦੀ ਮਜਬੂਰ ਕਰਨ ਵਾਲੀ ਚਾਲ ਵੇਖੋ।|{move} ਖੇਡੋ। ਇਹ ਸਥਿਤੀ ਵੱਧ ਬਚਾਉਂਦੀ ਅਤੇ ਤੁਰੰਤ ਜਵਾਬ {reply} ਰੋਕਦੀ ਹੈ।|{move} ਦਾ ਮੁਲਾਂਕਣ {grade} ਸੀ।''',
  'ur':
      '''آپ کے پچھلے سوال "{question}" کے بعد:|{move} کھیلنے پر Stockfish کی درجہ بندی {grade} ہے، {count} سینٹی پون نقصان کے ساتھ۔|یہ عملی طور پر درست انتخاب ہے۔|زیادہ مضبوط چال {move} ہے۔|حریف کا سب سے مجبور کرنے والا جواب {move} ہے۔|{move} اچھی چال ہے۔ یہ پوزیشن قابو میں رکھتی ہے۔|{move} حریف کو مضبوط جواب دیتی ہے۔ {best} چنیں اور پہلے اس کی مجبور کرنے والی چال دیکھیں۔|{move} کھیلیں۔ یہ پوزیشن بہتر بچاتی ہے اور فوری جواب {reply} کا سامنا کرتی ہے۔|{move} کی درجہ بندی {grade} تھی۔''',
  'ar':
      '''متابعة لسؤالك السابق "{question}":|إذا لعبت {move}، يصنفها Stockfish بأنها {grade} بخسارة {count} سنتيبيدق.|إنه اختيار عملي سليم.|النقلة الأقوى هي {move}.|رد الخصم الأكثر إجبارًا هو {move}.|{move} نقلة جيدة. تُبقي الوضع تحت السيطرة.|{move} يمنح الخصم ردًا أقوى. فضّل {best} وافحص نقلته الإجبارية أولًا.|العب {move}. تحافظ أكثر على وضعك وتواجه الرد الفوري {reply}.|صُنفت {move} بأنها {grade}.''',
  'es':
      '''Siguiendo tu pregunta anterior, "{question}":|Si juegas {move}, Stockfish la valora como {grade}, con pérdida de {count} centipeones.|Es una buena elección práctica.|La jugada más fuerte es {move}.|La respuesta más forzada del rival es {move}.|{move} es una buena jugada. Mantiene la posición bajo control.|{move} permite una respuesta más fuerte. Prefiere {best} y revisa primero la jugada forzada rival.|Juega {move}. Conserva mejor tu posición y responde a la réplica inmediata {reply}.|{move} se valoró como {grade}.''',
  'fr':
      '''Suite à votre question précédente, "{question}" :|Si vous jouez {move}, Stockfish l’évalue {grade}, avec une perte de {count} centipions.|C’est un choix pratique solide.|Le coup le plus fort est {move}.|La réponse adverse la plus contraignante est {move}.|{move} est un bon coup. Il garde la position sous contrôle.|{move} permet une réponse adverse plus forte. Préférez {best} et vérifiez d’abord le coup forcé adverse.|Jouez {move}. Il préserve mieux votre position et répond à la réplique immédiate {reply}.|{move} a été évalué {grade}.''',
  'de':
      '''Zu deiner früheren Frage „{question}“:|Bei {move} bewertet Stockfish den Zug als {grade} mit {count} Zentibauern Verlust.|Das ist eine solide praktische Wahl.|Der stärkere Zug ist {move}.|Die zwingendste Antwort des Gegners ist {move}.|{move} ist ein guter Zug. Er hält die Stellung unter Kontrolle.|{move} erlaubt eine stärkere Antwort. Bevorzuge {best} und prüfe zuerst den forcierten gegnerischen Zug.|Spiele {move}. Das bewahrt mehr von deiner Stellung und begegnet der direkten Antwort {reply}.|{move} wurde als {grade} bewertet.''',
  'it':
      '''Seguendo la tua domanda precedente, "{question}":|Se giochi {move}, Stockfish valuta {grade} con una perdita di {count} centipedoni.|È una scelta pratica solida.|La mossa più forte è {move}.|La risposta più forzante dell’avversario è {move}.|{move} è una buona mossa. Mantiene la posizione sotto controllo.|{move} concede una risposta più forte. Preferisci {best} e controlla prima la mossa forzante avversaria.|Gioca {move}. Conserva meglio la posizione e affronta la risposta immediata {reply}.|{move} è stata valutata {grade}.''',
  'pt':
      '''Na sequência da sua pergunta anterior, "{question}":|Se jogar {move}, Stockfish classifica como {grade}, com perda de {count} centipeões.|É uma escolha prática sólida.|O lance mais forte é {move}.|A resposta mais forçada do adversário é {move}.|{move} é um bom lance. Mantém a posição sob controlo.|{move} permite uma resposta mais forte. Prefira {best} e verifique primeiro o lance forçado adversário.|Jogue {move}. Preserva melhor a sua posição e enfrenta a resposta imediata {reply}.|{move} foi classificado como {grade}.''',
  'ru':
      '''Продолжая ваш предыдущий вопрос «{question}»:|При {move} Stockfish оценивает ход как {grade} с потерей {count} сантипешек.|Это надёжный практический выбор.|Более сильный ход — {move}.|Самый форсирующий ответ соперника — {move}.|{move} — хороший ход. Он сохраняет контроль над позицией.|{move} даёт сопернику более сильный ответ. Предпочтите {best} и сначала проверьте его форсирующий ход.|Играйте {move}. Это лучше сохраняет позицию и отражает немедленный ответ {reply}.|{move} оценён как {grade}.''',
  'uk':
      '''Продовжуючи ваше попереднє запитання «{question}»:|Після {move} Stockfish оцінює хід як {grade} із втратою {count} сантипішаків.|Це надійний практичний вибір.|Сильніший хід — {move}.|Найфорсованіша відповідь суперника — {move}.|{move} — хороший хід. Він зберігає контроль над позицією.|{move} дає супернику сильнішу відповідь. Оберіть {best} і спершу перевірте його форсований хід.|Грайте {move}. Це краще зберігає позицію та зустрічає негайну відповідь {reply}.|{move} оцінено як {grade}.''',
  'tr':
      '''Önceki “{question}” sorunu takiben:|{move} oynarsan Stockfish {count} santipiyon kaybıyla {grade} olarak değerlendirir.|Sağlam bir pratik seçimdir.|Daha güçlü hamle {move}.|Rakibin en zorlayıcı yanıtı {move}.|{move} iyi bir hamledir. Konumu kontrol altında tutar.|{move} rakibe daha güçlü yanıt verir. {best} tercih et ve önce zorlayıcı hamlesini kontrol et.|{move} oyna. Konumunu daha iyi korur ve hemen gelen {reply} yanıtını karşılar.|{move}, {grade} olarak değerlendirildi.''',
  'fa':
      '''در ادامهٔ پرسش پیشین شما «{question}»:|اگر {move} بازی کنید، Stockfish آن را {grade} با افت {count} سانتی‌پیاده ارزیابی می‌کند.|این انتخاب عملی مناسبی است.|حرکت قوی‌تر {move} است.|اجباری‌ترین پاسخ حریف {move} است.|{move} حرکت خوبی است. وضعیت را تحت کنترل نگه می‌دارد.|{move} پاسخ قوی‌تری به حریف می‌دهد. {best} را ترجیح دهید و ابتدا حرکت اجباری او را بررسی کنید.|{move} بازی کنید. وضعیت را بهتر حفظ می‌کند و پاسخ فوری {reply} را پوشش می‌دهد.|{move} به صورت {grade} ارزیابی شد.''',
  'zh':
      '''接着您之前的问题“{question}”：|如果走 {move}，Stockfish 评价为{grade}，损失 {count} 厘兵。|这是稳健的实战选择。|更强的着法是 {move}。|对手最强制的应招是 {move}。|{move} 是好棋，能保持对局面的控制。|{move} 让对手有更强的应招。优先考虑 {best}，并先检查对手的强制着法。|走 {move}。它更好地保持局面，并应对直接应招 {reply}。|{move} 被评价为{grade}。''',
  'ja':
      '''前の質問「{question}」に続いて：|{move} と指すと、Stockfish の評価は{grade}で、損失は{count}センチポーンです。|実戦的に堅実な選択です。|より強い手は {move} です。|相手の最も強制的な応手は {move} です。|{move} は良い手で、局面の主導権を保ちます。|{move} は相手により強い応手を与えます。{best} を選び、まず相手の強制手を確認しましょう。|{move} と指しましょう。局面をよりよく保ち、直後の応手 {reply} に対応します。|{move} は{grade}と評価されました。''',
  'ko':
      '''이전 질문 “{question}”에 이어:|{move}를 두면 Stockfish는 {count}센티폰 손실로 {grade}로 평가합니다.|실전에서 건실한 선택입니다.|더 강한 수는 {move}입니다.|상대의 가장 강제적인 응수는 {move}입니다.|{move}는 좋은 수입니다. 포지션을 통제할 수 있습니다.|{move}는 상대에게 더 강한 응수를 줍니다. {best}를 선택하고 먼저 상대의 강제 수를 확인하세요.|{move}를 두세요. 포지션을 더 잘 유지하며 즉각적인 응수 {reply}에 대응합니다.|{move}는 {grade}로 평가되었습니다.''',
  'id':
      '''Melanjutkan pertanyaanmu sebelumnya, "{question}":|Jika memainkan {move}, Stockfish menilai {grade} dengan kehilangan {count} sentipion.|Ini pilihan praktis yang baik.|Langkah lebih kuat adalah {move}.|Balasan lawan paling memaksa adalah {move}.|{move} adalah langkah baik. Posisi tetap terkendali.|{move} memberi lawan balasan lebih kuat. Pilih {best} dan periksa langkah memaksanya dahulu.|Mainkan {move}. Ini lebih menjaga posisi dan menghadapi balasan langsung {reply}.|{move} dinilai {grade}.''',
  'ms':
      '''Menyusuli soalan anda sebelum ini, "{question}":|Jika bermain {move}, Stockfish menilai {grade} dengan kehilangan {count} sentibidak.|Ini pilihan praktikal yang baik.|Langkah lebih kuat ialah {move}.|Balasan lawan paling memaksa ialah {move}.|{move} ialah langkah baik. Kedudukan kekal terkawal.|{move} memberi lawan balasan lebih kuat. Pilih {best} dan periksa langkah memaksanya dahulu.|Mainkan {move}. Ini lebih menjaga kedudukan dan menghadapi balasan segera {reply}.|{move} dinilai {grade}.''',
  'th':
      '''ต่อจากคำถามก่อนหน้า “{question}”:|หากเดิน {move} Stockfish ประเมินว่า{grade} เสีย {count} เซนติพอว์น|เป็นทางเลือกที่ดีในทางปฏิบัติ|ตาที่แข็งแกร่งกว่าคือ {move}|ตาตอบที่บังคับที่สุดของคู่ต่อสู้คือ {move}|{move} เป็นตาที่ดี ช่วยคุมตำแหน่งไว้|{move} ให้คู่ต่อสู้ตอบได้แรงกว่า ควรเลือก {best} และตรวจตาบังคับของเขาก่อน|เดิน {move} ช่วยรักษาตำแหน่งได้ดีกว่าและรับมือตาตอบทันที {reply}|{move} ถูกประเมินว่า{grade}''',
  'vi':
      '''Tiếp theo câu hỏi trước của bạn, "{question}":|Nếu đi {move}, Stockfish đánh giá {grade} với mất {count} centipawn.|Đây là lựa chọn thực tế vững chắc.|Nước mạnh hơn là {move}.|Nước đáp cưỡng bức nhất của đối thủ là {move}.|{move} là nước tốt. Nó giữ thế cờ trong tầm kiểm soát.|{move} cho đối thủ nước đáp mạnh hơn. Ưu tiên {best} và kiểm tra nước cưỡng bức của họ trước.|Đi {move}. Nó giữ thế cờ tốt hơn và đối phó nước đáp ngay {reply}.|{move} được đánh giá {grade}.''',
  'pl':
      '''Nawiązując do twojego wcześniejszego pytania „{question}”:|Po {move} Stockfish ocenia ruch jako {grade} ze stratą {count} centypionów.|To solidny praktyczny wybór.|Silniejszy ruch to {move}.|Najbardziej wymuszająca odpowiedź przeciwnika to {move}.|{move} to dobry ruch. Utrzymuje kontrolę nad pozycją.|{move} pozwala na silniejszą odpowiedź. Wybierz {best} i najpierw sprawdź wymuszający ruch przeciwnika.|Zagraj {move}. Lepiej zachowuje pozycję i odpiera natychmiastową odpowiedź {reply}.|{move} oceniono jako {grade}.''',
  'nl':
      '''Naar aanleiding van je eerdere vraag “{question}”:|Als je {move} speelt, beoordeelt Stockfish dit als {grade} met {count} centipionnen verlies.|Het is een degelijke praktische keuze.|De sterkere zet is {move}.|Het meest dwingende antwoord van de tegenstander is {move}.|{move} is een goede zet. Het houdt de stelling onder controle.|{move} geeft de tegenstander een sterker antwoord. Kies {best} en controleer eerst diens dwingende zet.|Speel {move}. Het behoudt je stelling beter en beantwoordt de directe reactie {reply}.|{move} werd beoordeeld als {grade}.''',
  'sv':
      '''Efter din tidigare fråga ”{question}”:|Om du spelar {move} bedömer Stockfish det som {grade} med {count} centibönders förlust.|Det är ett sunt praktiskt val.|Det starkare draget är {move}.|Motståndarens mest tvingande svar är {move}.|{move} är ett bra drag. Det håller ställningen under kontroll.|{move} ger motståndaren ett starkare svar. Föredra {best} och kontrollera först det tvingande draget.|Spela {move}. Det bevarar ställningen bättre och bemöter det omedelbara svaret {reply}.|{move} bedömdes som {grade}.''',
  'el':
      '''Σε συνέχεια της προηγούμενης ερώτησής σας «{question}»:|Αν παίξετε {move}, το Stockfish αξιολογεί {grade} με απώλεια {count} εκατοστών πιονιού.|Είναι μια σωστή πρακτική επιλογή.|Η ισχυρότερη κίνηση είναι {move}.|Η πιο αναγκαστική απάντηση του αντιπάλου είναι {move}.|Η {move} είναι καλή κίνηση. Κρατά τη θέση υπό έλεγχο.|Η {move} δίνει ισχυρότερη απάντηση στον αντίπαλο. Προτιμήστε {best} και ελέγξτε πρώτα την αναγκαστική του κίνηση.|Παίξτε {move}. Διατηρεί καλύτερα τη θέση και αντιμετωπίζει την άμεση απάντηση {reply}.|Η {move} αξιολογήθηκε ως {grade}.''',
  'he':
      '''בהמשך לשאלתך הקודמת ״{question}״:|אם תשחקו {move}, Stockfish מדרג {grade} עם הפסד של {count} סנטירגלי.|זו בחירה מעשית טובה.|המסע החזק יותר הוא {move}.|התגובה הכופה ביותר של היריב היא {move}.|{move} הוא מסע טוב. הוא שומר על שליטה בעמדה.|{move} נותן ליריב תגובה חזקה יותר. העדיפו {best} ובדקו קודם את המסע הכופה שלו.|שחקו {move}. הוא שומר טוב יותר על העמדה ועונה לתגובה המיידית {reply}.|{move} דורג בתור {grade}.''',
  'sw':
      '''Kufuatia swali lako la awali, "{question}":|Ukicheza {move}, Stockfish hukadiria {grade} kwa hasara ya {count} sentiponi.|Ni chaguo zuri la vitendo.|Hatua yenye nguvu zaidi ni {move}.|Jibu la mpinzani linalolazimisha zaidi ni {move}.|{move} ni hatua nzuri. Hudumisha udhibiti wa nafasi.|{move} humpa mpinzani jibu lenye nguvu zaidi. Pendelea {best} na kagua hatua yake ya kulazimisha kwanza.|Cheza {move}. Huhifadhi nafasi yako vizuri zaidi na kukabili jibu la haraka {reply}.|{move} ilikadiriwa {grade}.''',
};

const personalCoachThemeKeys = <String>[
  'opening',
  'kingSafety',
  'hangingPieces',
  'missedCaptures',
  'timeManagement',
  'endgame',
  'tactics',
  'calculation'
];
final personalCoachThemes = <String, List<String>>{
  for (final e in _themeRows.entries) e.key: e.value.split('|'),
};
String personalCoachTheme(String? theme, String code) {
  final index = personalCoachThemeKeys.indexOf(theme ?? 'calculation');
  return personalCoachThemes[AppLanguageController.resolveCode(code)]![
      index < 0 ? 7 : index];
}

const _themeRows = <String, String>{
  'en':
      '''Development and centre control: finish development before launching an attack.|King safety: address checks and mating threats first.|Piece safety: watch loose pieces and overloaded defenders.|Forcing-move scan: check checks, captures and threats.|Candidate-move selection: compare two candidates before deciding.|Endgame technique: activate the king and calculate pawn races.|Tactical calculation: study forcing sequences and tactical motifs.|Calculation: what changes after your move, and what is the opponent’s most forcing reply?''',
  'te':
      '''అభివృద్ధి, కేంద్ర నియంత్రణ: దాడికి ముందు పావులేతర ముక్కల అభివృద్ధిని పూర్తి చేయండి.|రాజు భద్రత: ముందుగా చెక్స్, చెక్‌మేట్ ప్రమాదాలను ఎదుర్కోండి.|ముక్కల భద్రత: రక్షణలేని ముక్కలు, అధిక బాధ్యతలున్న రక్షకులను గమనించండి.|బలవంతపు ఎత్తుల పరిశీలన: చెక్స్, క్యాప్చర్లు, ప్రమాదాలను చూడండి.|ఎత్తుల ఎంపిక: నిర్ణయానికి ముందు రెండు సాధ్యమైన ఎత్తులను పోల్చండి.|చివరి దశ నైపుణ్యం: రాజును చురుకుగా చేసి పావుల పరుగు లెక్కించండి.|వ్యూహాత్మక లెక్కింపు: బలవంతపు ఎత్తుల క్రమాలు, వ్యూహ నమూనాలను నేర్చుకోండి.|లెక్కింపు: మీ ఎత్తుతో ఏమి మారుతుంది? ప్రత్యర్థి అత్యంత బలవంతపు సమాధానం ఏమిటి?''',
  'hi':
      '''विकास और केंद्र पर नियंत्रण: आक्रमण से पहले मोहरों का विकास पूरा करें।|राजा की सुरक्षा: पहले शह और मात के खतरों का सामना करें।|मोहरों की सुरक्षा: असुरक्षित मोहरों और अधिक भार वाले रक्षकों पर ध्यान दें।|बाध्यकारी चालों की जाँच: शह, मारने वाली चालें और खतरे देखें।|संभावित चालों का चयन: निर्णय से पहले दो चालों की तुलना करें।|अंतिम खेल तकनीक: राजा को सक्रिय करें और प्यादों की दौड़ की गणना करें।|सामरिक गणना: बाध्यकारी क्रम और सामरिक पैटर्न सीखें।|गणना: आपकी चाल के बाद क्या बदलता है और विरोधी का सबसे बाध्यकारी जवाब क्या है?''',
  'ta':
      '''வளர்ச்சியும் மையக் கட்டுப்பாடும்: தாக்குதலுக்கு முன் காய்களின் வளர்ச்சியை முடிக்கவும்.|ராஜாவின் பாதுகாப்பு: முதலில் செக் மற்றும் செக்மேட் அச்சுறுத்தல்களை எதிர்கொள்ளவும்.|காய்களின் பாதுகாப்பு: பாதுகாப்பற்ற காய்களையும் அதிக பொறுப்புள்ள பாதுகாவலர்களையும் கவனிக்கவும்.|கட்டாய நகர்வுகளின் தேடல்: செக், பிடிப்புகள், அச்சுறுத்தல்களைப் பார்க்கவும்.|நகர்வு தேர்வு: முடிவெடுக்கும் முன் இரண்டு வாய்ப்புகளை ஒப்பிடவும்.|இறுதியாட்ட நுட்பம்: ராஜாவைச் செயல்படுத்தி சிப்பாய்களின் பந்தயத்தைக் கணக்கிடவும்.|தந்திரக் கணக்கீடு: கட்டாயத் தொடர்களையும் தந்திர வடிவங்களையும் படிக்கவும்.|கணக்கீடு: உங்கள் நகர்வால் என்ன மாறுகிறது? எதிரியின் மிகக் கட்டாயமான பதில் எது?''',
  'kn':
      '''ಅಭಿವೃದ್ಧಿ ಮತ್ತು ಕೇಂದ್ರ ನಿಯಂತ್ರಣ: ದಾಳಿಗೂ ಮುನ್ನ ಕಾಯಿಗಳ ಅಭಿವೃದ್ಧಿ ಪೂರ್ಣಗೊಳಿಸಿ.|ರಾಜನ ಸುರಕ್ಷತೆ: ಮೊದಲು ಚೆಕ್ ಮತ್ತು ಚೆಕ್‌ಮೇಟ್ ಬೆದರಿಕೆಗಳನ್ನು ಎದುರಿಸಿ.|ಕಾಯಿಗಳ ಸುರಕ್ಷತೆ: ರಕ್ಷಣೆಯಿಲ್ಲದ ಕಾಯಿಗಳು ಮತ್ತು ಹೆಚ್ಚು ಹೊಣೆ ಹೊತ್ತ ರಕ್ಷಕರನ್ನು ಗಮನಿಸಿ.|ಬಲವಂತದ ನಡೆಗಳ ಪರಿಶೀಲನೆ: ಚೆಕ್‌ಗಳು, ಸೆರೆಹಿಡಿಯುವಿಕೆ ಮತ್ತು ಬೆದರಿಕೆಗಳನ್ನು ನೋಡಿ.|ಸಾಧ್ಯ ನಡೆಗಳ ಆಯ್ಕೆ: ತೀರ್ಮಾನಕ್ಕೆ ಮುನ್ನ ಎರಡು ನಡೆಗಳನ್ನು ಹೋಲಿಸಿ.|ಅಂತ್ಯಾಟದ ತಂತ್ರ: ರಾಜನನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ ಪ್ಯಾದೆಗಳ ಓಟವನ್ನು ಲೆಕ್ಕಿಸಿ.|ತಂತ್ರದ ಲೆಕ್ಕಾಚಾರ: ಬಲವಂತದ ಕ್ರಮಗಳು ಮತ್ತು ತಂತ್ರ ಮಾದರಿಗಳನ್ನು ಕಲಿಯಿರಿ.|ಲೆಕ್ಕಾಚಾರ: ನಿಮ್ಮ ನಡೆಯ ನಂತರ ಏನು ಬದಲಾಗುತ್ತದೆ? ಎದುರಾಳಿಯ ಅತ್ಯಂತ ಬಲವಂತದ ಉತ್ತರ ಯಾವುದು?''',
  'ml':
      '''വികസനവും കേന്ദ്രനിയന്ത്രണവും: ആക്രമണത്തിന് മുമ്പ് കരുക്കളുടെ വികസനം പൂർത്തിയാക്കൂ.|രാജാവിന്റെ സുരക്ഷ: ആദ്യം ചെക്കും ചെക്ക്മേറ്റ് ഭീഷണിയും നേരിടൂ.|കരുക്കളുടെ സുരക്ഷ: സംരക്ഷണമില്ലാത്ത കരുക്കളും അധിക ചുമതലയുള്ള പ്രതിരോധകരും ശ്രദ്ധിക്കൂ.|നിർബന്ധിത നീക്കങ്ങളുടെ പരിശോധന: ചെക്കുകൾ, പിടിച്ചെടുക്കലുകൾ, ഭീഷണികൾ നോക്കൂ.|നീക്കങ്ങളുടെ തിരഞ്ഞെടുപ്പ്: തീരുമാനത്തിന് മുമ്പ് രണ്ട് സാധ്യതകൾ താരതമ്യം ചെയ്യൂ.|അന്ത്യഘട്ട സാങ്കേതികത: രാജാവിനെ സജീവമാക്കി കാലാളുകളുടെ ഓട്ടം കണക്കുകൂട്ടൂ.|തന്ത്രപരമായ കണക്കുകൂട്ടൽ: നിർബന്ധിത ക്രമങ്ങളും തന്ത്രമാതൃകകളും പഠിക്കൂ.|കണക്കുകൂട്ടൽ: നിങ്ങളുടെ നീക്കത്തിന് ശേഷം എന്ത് മാറുന്നു? എതിരാളിയുടെ ഏറ്റവും നിർബന്ധിത മറുപടി ഏത്?''',
  'mr':
      '''विकास आणि केंद्रावर नियंत्रण: हल्ल्याआधी मोहऱ्यांचा विकास पूर्ण करा.|राजाची सुरक्षितता: आधी शह आणि मातचे धोके दूर करा.|मोहऱ्यांची सुरक्षितता: असुरक्षित मोहरे व जादा जबाबदारीचे रक्षक पाहा.|भाग पाडणाऱ्या चालींची तपासणी: शह, मारण्याच्या चाली आणि धोके पाहा.|संभाव्य चालींची निवड: निर्णयाआधी दोन चालींची तुलना करा.|अंतिम खेळाचे तंत्र: राजा सक्रिय करा आणि प्याद्यांच्या शर्यतीची गणना करा.|डावपेचांची गणना: सक्तीचे क्रम आणि डावपेचांचे नमुने शिका.|गणना: तुमच्या चालीनंतर काय बदलते आणि प्रतिस्पर्ध्याचे सर्वाधिक सक्तीचे उत्तर कोणते?''',
  'bn':
      '''উন্নয়ন ও কেন্দ্র নিয়ন্ত্রণ: আক্রমণের আগে ঘুঁটির উন্নয়ন শেষ করুন।|রাজার নিরাপত্তা: আগে চেক ও মেটের হুমকি সামলান।|ঘুঁটির নিরাপত্তা: অরক্ষিত ঘুঁটি ও অতিরিক্ত দায়িত্বের রক্ষক দেখুন।|বাধ্যকারী চাল যাচাই: চেক, ঘুঁটি নেওয়া ও হুমকি দেখুন।|সম্ভাব্য চাল নির্বাচন: সিদ্ধান্তের আগে দুটি চাল তুলনা করুন।|শেষ খেলার কৌশল: রাজাকে সক্রিয় করুন ও প্যাদার দৌড় গণনা করুন।|কৌশলগত গণনা: বাধ্যকারী ক্রম ও কৌশলগত ধরন শিখুন।|গণনা: আপনার চালের পরে কী বদলায় এবং প্রতিপক্ষের সবচেয়ে বাধ্যকারী জবাব কী?''',
  'gu':
      '''વિકાસ અને કેન્દ્ર નિયંત્રણ: હુમલા પહેલાં મહોરાંનો વિકાસ પૂરો કરો.|રાજાની સુરક્ષા: પહેલાં શહ અને માતના ખતરા દૂર કરો.|મહોરાંની સુરક્ષા: અસુરક્ષિત મહોરાં અને વધુ જવાબદારીવાળા રક્ષકો જુઓ.|ફરજ પાડતી ચાલો તપાસો: શહ, મારવાની ચાલો અને ખતરા જુઓ.|સંભવિત ચાલની પસંદગી: નિર્ણય પહેલાં બે ચાલ સરખાવો.|અંતિમ રમતની તકનીક: રાજાને સક્રિય કરો અને પ્યાદાંની દોડ ગણો.|વ્યૂહાત્મક ગણતરી: ફરજ પાડતા ક્રમ અને વ્યૂહની રચનાઓ શીખો.|ગણતરી: તમારી ચાલ પછી શું બદલાય છે અને વિરોધીનો સૌથી ફરજ પાડતો જવાબ કયો છે?''',
  'pa':
      '''ਵਿਕਾਸ ਅਤੇ ਕੇਂਦਰ ਕੰਟਰੋਲ: ਹਮਲੇ ਤੋਂ ਪਹਿਲਾਂ ਮੋਹਰਿਆਂ ਦਾ ਵਿਕਾਸ ਪੂਰਾ ਕਰੋ।|ਰਾਜੇ ਦੀ ਸੁਰੱਖਿਆ: ਪਹਿਲਾਂ ਸ਼ਹ ਅਤੇ ਮਾਤ ਦੇ ਖ਼ਤਰੇ ਰੋਕੋ।|ਮੋਹਰਿਆਂ ਦੀ ਸੁਰੱਖਿਆ: ਅਸੁਰੱਖਿਅਤ ਮੋਹਰੇ ਅਤੇ ਵੱਧ ਜ਼ਿੰਮੇਵਾਰੀ ਵਾਲੇ ਰੱਖਿਅਕ ਵੇਖੋ।|ਮਜਬੂਰ ਕਰਨ ਵਾਲੀਆਂ ਚਾਲਾਂ: ਸ਼ਹ, ਮਾਰਨ ਦੀਆਂ ਚਾਲਾਂ ਅਤੇ ਖ਼ਤਰੇ ਵੇਖੋ।|ਸੰਭਾਵੀ ਚਾਲਾਂ ਦੀ ਚੋਣ: ਫ਼ੈਸਲੇ ਤੋਂ ਪਹਿਲਾਂ ਦੋ ਚਾਲਾਂ ਦੀ ਤੁਲਨਾ ਕਰੋ।|ਅੰਤਲੀ ਖੇਡ ਦੀ ਤਕਨੀਕ: ਰਾਜੇ ਨੂੰ ਸਰਗਰਮ ਕਰੋ ਅਤੇ ਪਿਆਦਿਆਂ ਦੀ ਦੌੜ ਗਿਣੋ।|ਦਾਅਪੇਚਾਂ ਦੀ ਗਿਣਤੀ: ਮਜਬੂਰ ਕਰਨ ਵਾਲੇ ਕ੍ਰਮ ਅਤੇ ਨਮੂਨੇ ਸਿੱਖੋ।|ਗਿਣਤੀ: ਤੁਹਾਡੀ ਚਾਲ ਮਗਰੋਂ ਕੀ ਬਦਲਦਾ ਹੈ ਅਤੇ ਵਿਰੋਧੀ ਦਾ ਸਭ ਤੋਂ ਮਜਬੂਰ ਕਰਨ ਵਾਲਾ ਜਵਾਬ ਕੀ ਹੈ?''',
  'ur':
      '''ترقی اور مرکز پر قابو: حملے سے پہلے مہروں کی ترقی مکمل کریں۔|بادشاہ کی حفاظت: پہلے شہ اور مات کے خطرات روکیں۔|مہروں کی حفاظت: غیر محفوظ مہرے اور زیادہ ذمہ داری والے محافظ دیکھیں۔|مجبور کرنے والی چالیں: شہ، مارنے کی چالیں اور خطرات دیکھیں۔|ممکنہ چالوں کا انتخاب: فیصلے سے پہلے دو چالوں کا موازنہ کریں۔|آخری کھیل کی تکنیک: بادشاہ کو فعال کریں اور پیادوں کی دوڑ شمار کریں۔|حکمت عملی کی گنتی: مجبور کرنے والے سلسلے اور نمونے سیکھیں۔|گنتی: آپ کی چال کے بعد کیا بدلتا ہے اور حریف کا سب سے مجبور کرنے والا جواب کیا ہے؟''',
  'ar':
      '''التطوير والسيطرة على المركز: أكمل تطوير القطع قبل الهجوم.|سلامة الملك: عالج الكش وتهديدات المات أولًا.|سلامة القطع: راقب القطع غير المحمية والمدافعين المثقلين بالمهام.|فحص النقلات الإجبارية: افحص الكش والأخذ والتهديدات.|اختيار النقلات المرشحة: قارن نقلتين قبل القرار.|تقنية النهاية: نشّط الملك واحسب سباقات البيادق.|الحساب التكتيكي: ادرس التسلسلات الإجبارية والأفكار التكتيكية.|الحساب: ما الذي يتغير بعد نقلتك وما أقوى رد إجباري للخصم؟''',
  'es':
      '''Desarrollo y control central: completa el desarrollo antes de atacar.|Seguridad del rey: responde primero a jaques y amenazas de mate.|Seguridad de piezas: vigila piezas sueltas y defensores sobrecargados.|Exploración forzada: revisa jaques, capturas y amenazas.|Selección de candidatas: compara dos jugadas antes de decidir.|Técnica de finales: activa el rey y calcula carreras de peones.|Cálculo táctico: estudia secuencias forzadas y motivos tácticos.|Cálculo: ¿qué cambia tras tu jugada y cuál es la respuesta más forzada del rival?''',
  'fr':
      '''Développement et contrôle du centre : terminez le développement avant d’attaquer.|Sécurité du roi : répondez d’abord aux échecs et menaces de mat.|Sécurité des pièces : surveillez les pièces sans défense et les défenseurs surchargés.|Recherche de coups forcés : vérifiez échecs, prises et menaces.|Choix des candidats : comparez deux coups avant de décider.|Technique de finale : activez le roi et calculez les courses de pions.|Calcul tactique : étudiez les suites forcées et les motifs tactiques.|Calcul : que change votre coup et quelle est la réponse adverse la plus contraignante ?''',
  'de':
      '''Entwicklung und Zentrumskontrolle: Entwicklung vor dem Angriff abschließen.|Königssicherheit: zuerst Schachs und Mattdrohungen abwehren.|Figurensicherheit: ungedeckte Figuren und überlastete Verteidiger beachten.|Forcierte Züge prüfen: Schachs, Schlagzüge und Drohungen untersuchen.|Kandidatenwahl: vor der Entscheidung zwei Züge vergleichen.|Endspieltechnik: König aktivieren und Bauernrennen berechnen.|Taktische Berechnung: forcierte Folgen und taktische Motive untersuchen.|Berechnung: Was ändert dein Zug, und was ist die zwingendste Antwort des Gegners?''',
  'it':
      '''Sviluppo e controllo del centro: completa lo sviluppo prima di attaccare.|Sicurezza del re: affronta prima scacchi e minacce di matto.|Sicurezza dei pezzi: osserva pezzi indifesi e difensori sovraccarichi.|Ricerca di mosse forzanti: controlla scacchi, catture e minacce.|Scelta delle candidate: confronta due mosse prima di decidere.|Tecnica di finale: attiva il re e calcola le corse dei pedoni.|Calcolo tattico: studia sequenze forzanti e motivi tattici.|Calcolo: cosa cambia dopo la tua mossa e qual è la risposta più forzante dell’avversario?''',
  'pt':
      '''Desenvolvimento e controlo central: termine o desenvolvimento antes de atacar.|Segurança do rei: responda primeiro a xeques e ameaças de mate.|Segurança das peças: observe peças desprotegidas e defensores sobrecarregados.|Procura de lances forçados: verifique xeques, capturas e ameaças.|Seleção de candidatos: compare dois lances antes de decidir.|Técnica de finais: ative o rei e calcule corridas de peões.|Cálculo tático: estude sequências forçadas e motivos táticos.|Cálculo: o que muda após o seu lance e qual é a resposta mais forçada do adversário?''',
  'ru':
      '''Развитие и контроль центра: завершите развитие перед атакой.|Безопасность короля: сначала отразите шахи и угрозы мата.|Безопасность фигур: следите за незащищёнными фигурами и перегруженными защитниками.|Поиск форсирующих ходов: проверяйте шахи, взятия и угрозы.|Выбор кандидатов: сравните два хода до решения.|Техника эндшпиля: активизируйте короля и рассчитайте гонки пешек.|Тактический расчёт: изучайте форсированные варианты и тактические мотивы.|Расчёт: что меняется после вашего хода и каков самый форсирующий ответ соперника?''',
  'uk':
      '''Розвиток і контроль центру: завершіть розвиток перед атакою.|Безпека короля: спочатку відбийте шахи та загрози мату.|Безпека фігур: стежте за незахищеними фігурами та перевантаженими захисниками.|Пошук форсованих ходів: перевіряйте шахи, взяття й загрози.|Вибір кандидатів: порівняйте два ходи перед рішенням.|Техніка ендшпілю: активізуйте короля й розрахуйте перегони пішаків.|Тактичний розрахунок: вивчайте форсовані послідовності й тактичні мотиви.|Розрахунок: що зміниться після вашого ходу і яка найфорсованіша відповідь суперника?''',
  'tr':
      '''Gelişim ve merkez kontrolü: saldırmadan önce gelişimi tamamla.|Şah güvenliği: önce şahları ve mat tehditlerini karşıla.|Taş güvenliği: savunmasız taşlara ve aşırı yüklenmiş savunuculara bak.|Zorlayıcı hamle taraması: şahları, alışları ve tehditleri kontrol et.|Aday seçimi: karar vermeden önce iki hamleyi karşılaştır.|Oyun sonu tekniği: şahı etkinleştir ve piyon yarışlarını hesapla.|Taktik hesap: zorlayıcı dizileri ve taktik motifleri incele.|Hesap: hamlenden sonra ne değişir ve rakibin en zorlayıcı yanıtı nedir?''',
  'fa':
      '''گسترش و کنترل مرکز: پیش از حمله گسترش مهره‌ها را کامل کنید.|امنیت شاه: نخست کیش و تهدید مات را رفع کنید.|امنیت مهره‌ها: مهره‌های بی‌دفاع و مدافعان پربار را بررسی کنید.|بررسی حرکت‌های اجباری: کیش، گرفتن و تهدید را بررسی کنید.|انتخاب حرکت نامزد: پیش از تصمیم دو حرکت را مقایسه کنید.|تکنیک آخر بازی: شاه را فعال کنید و رقابت پیاده‌ها را محاسبه کنید.|محاسبهٔ تاکتیکی: دنباله‌های اجباری و الگوهای تاکتیکی را مطالعه کنید.|محاسبه: پس از حرکت شما چه چیزی تغییر می‌کند و اجباری‌ترین پاسخ حریف چیست؟''',
  'zh':
      '''发展与中心控制：进攻前先完成出子。|王的安全：先应对将军和将杀威胁。|棋子安全：注意无保护的棋子和负担过重的防守子。|强制着法检查：寻找将军、吃子和威胁。|候选着法选择：决定前比较两个候选着法。|残局技术：积极用王并计算兵的竞赛。|战术计算：学习强制变化和战术主题。|计算：走棋后有什么变化，对手最强制的应招是什么？''',
  'ja':
      '''展開と中央支配：攻撃前に駒の展開を完了しましょう。|キングの安全：まずチェックとメイトの脅威に対応しましょう。|駒の安全：守られていない駒と過負荷の守備駒に注意しましょう。|強制手の確認：チェック、駒取り、脅威を調べましょう。|候補手の選択：決定前に2つの候補を比べましょう。|終盤技術：キングを活用しポーン競争を計算しましょう。|戦術計算：強制手順と戦術モチーフを学びましょう。|計算：自分の手で何が変わり、相手の最も強制的な応手は何でしょうか？''',
  'ko':
      '''전개와 중앙 장악: 공격 전에 전개를 마치세요.|킹 안전: 먼저 체크와 체크메이트 위협을 막으세요.|기물 안전: 무방비 기물과 과부하된 수비 기물을 살피세요.|강제 수 점검: 체크, 잡기, 위협을 확인하세요.|후보 수 선택: 결정 전에 두 후보를 비교하세요.|엔드게임 기술: 킹을 활성화하고 폰 경주를 계산하세요.|전술 계산: 강제 수순과 전술 패턴을 공부하세요.|계산: 내 수 이후 무엇이 바뀌며 상대의 가장 강제적인 응수는 무엇인가요?''',
  'id':
      '''Pengembangan dan kendali pusat: selesaikan pengembangan sebelum menyerang.|Keamanan raja: tangani skak dan ancaman mat terlebih dahulu.|Keamanan buah: awasi buah tak terlindungi dan pembela yang kelebihan beban.|Pencarian langkah memaksa: periksa skak, tangkapan, dan ancaman.|Pemilihan kandidat: bandingkan dua langkah sebelum memutuskan.|Teknik akhir: aktifkan raja dan hitung perlombaan pion.|Perhitungan taktis: pelajari urutan memaksa dan motif taktis.|Perhitungan: apa yang berubah setelah langkahmu dan apa balasan lawan yang paling memaksa?''',
  'ms':
      '''Perkembangan dan kawalan pusat: lengkapkan perkembangan sebelum menyerang.|Keselamatan raja: tangani syah dan ancaman mat dahulu.|Keselamatan buah: awasi buah tidak terlindung dan pembela yang terbeban.|Semakan langkah memaksa: periksa syah, tangkapan dan ancaman.|Pemilihan calon: bandingkan dua langkah sebelum memutuskan.|Teknik akhir: aktifkan raja dan kira perlumbaan bidak.|Pengiraan taktikal: pelajari urutan memaksa dan motif taktikal.|Pengiraan: apa yang berubah selepas langkah anda dan apakah balasan lawan yang paling memaksa?''',
  'th':
      '''การพัฒนาหมากและคุมศูนย์กลาง: พัฒนาหมากให้เสร็จก่อนโจมตี|ความปลอดภัยของคิง: รับมือรุกและภัยรุกฆาตก่อน|ความปลอดภัยของหมาก: ระวังหมากไร้ตัวคุ้มกันและตัวป้องกันที่รับภาระเกินไป|ตรวจตาบังคับ: ดูรุก การกิน และภัยคุกคาม|การเลือกตา: เปรียบเทียบสองตาก่อนตัดสินใจ|เทคนิคท้ายเกม: ใช้คิงอย่างแข็งขันและคำนวณการแข่งของเบี้ย|การคำนวณแท็กติก: ศึกษาลำดับบังคับและรูปแบบแท็กติก|การคำนวณ: หลังเดินอะไรเปลี่ยน และตาตอบที่บังคับที่สุดของคู่ต่อสู้คืออะไร?''',
  'vi':
      '''Phát triển và kiểm soát trung tâm: hoàn tất phát triển trước khi tấn công.|An toàn vua: xử lý chiếu và đe dọa chiếu hết trước.|An toàn quân: chú ý quân không được bảo vệ và quân phòng thủ quá tải.|Tìm nước cưỡng bức: kiểm tra chiếu, bắt quân và đe dọa.|Chọn ứng viên: so sánh hai nước trước khi quyết định.|Kỹ thuật tàn cuộc: kích hoạt vua và tính cuộc đua tốt.|Tính chiến thuật: học chuỗi cưỡng bức và mô típ chiến thuật.|Tính toán: điều gì thay đổi sau nước của bạn và nước đáp cưỡng bức nhất của đối thủ là gì?''',
  'pl':
      '''Rozwój i kontrola centrum: zakończ rozwój przed atakiem.|Bezpieczeństwo króla: najpierw odpieraj szachy i groźby mata.|Bezpieczeństwo figur: uważaj na niebronione figury i przeciążonych obrońców.|Przegląd wymuszeń: sprawdź szachy, bicia i groźby.|Wybór kandydatów: porównaj dwa ruchy przed decyzją.|Technika końcówek: aktywizuj króla i oblicz wyścigi pionów.|Obliczenia taktyczne: badaj wymuszone sekwencje i motywy taktyczne.|Obliczenia: co zmienia twój ruch i jaka jest najbardziej wymuszająca odpowiedź przeciwnika?''',
  'nl':
      '''Ontwikkeling en centrumcontrole: voltooi de ontwikkeling vóór de aanval.|Koningsveiligheid: beantwoord eerst schaak en matdreigingen.|Stukveiligheid: let op ongedekte stukken en overbelaste verdedigers.|Dwingende zetten zoeken: bekijk schaakzetten, slagzetten en dreigingen.|Kandidatenkeuze: vergelijk twee zetten vóór je beslist.|Eindspeltechniek: activeer de koning en bereken pionnenwedlopen.|Tactische berekening: bestudeer gedwongen reeksen en tactische motieven.|Berekening: wat verandert je zet en wat is het meest dwingende antwoord van de tegenstander?''',
  'sv':
      '''Utveckling och centrumkontroll: avsluta utvecklingen före angrepp.|Kungssäkerhet: bemöt först schackar och matthot.|Pjössäkerhet: se upp med ogarderade pjäser och överbelastade försvarare.|Sök tvingande drag: granska schackar, slag och hot.|Kandidatval: jämför två drag före beslutet.|Slutspelsteknik: aktivera kungen och beräkna bondekapplöpningar.|Taktisk beräkning: studera tvingande följder och taktiska motiv.|Beräkning: vad ändras efter ditt drag och vilket är motståndarens mest tvingande svar?''',
  'el':
      '''Ανάπτυξη και έλεγχος κέντρου: ολοκληρώστε την ανάπτυξη πριν επιτεθείτε.|Ασφάλεια βασιλιά: αντιμετωπίστε πρώτα σαχ και απειλές ματ.|Ασφάλεια κομματιών: προσέξτε απροστάτευτα κομμάτια και υπερφορτωμένους αμυνόμενους.|Έλεγχος αναγκαστικών κινήσεων: ελέγξτε σαχ, παρσίματα και απειλές.|Επιλογή υποψηφίων: συγκρίνετε δύο κινήσεις πριν αποφασίσετε.|Τεχνική φινάλε: ενεργοποιήστε τον βασιλιά και υπολογίστε τις κούρσες πιονιών.|Τακτικός υπολογισμός: μελετήστε αναγκαστικές συνέχειες και τακτικά μοτίβα.|Υπολογισμός: τι αλλάζει μετά την κίνησή σας και ποια είναι η πιο αναγκαστική απάντηση του αντιπάλου;''',
  'he':
      '''פיתוח ושליטה במרכז: השלימו פיתוח לפני ההתקפה.|בטיחות המלך: טפלו קודם בשחים ובאיומי מט.|בטיחות הכלים: שימו לב לכלים לא מוגנים ולמגינים עמוסים.|סריקת מסעים כופים: בדקו שח, הכאות ואיומים.|בחירת מועמדים: השוו שני מסעים לפני ההחלטה.|טכניקת סיום: הפעילו את המלך וחשבו מרוצי רגלים.|חישוב טקטי: למדו רצפים כופים ורעיונות טקטיים.|חישוב: מה משתנה אחרי המסע ומה התגובה הכופה ביותר של היריב?''',
  'sw':
      '''Maendeleo na udhibiti wa katikati: maliza kuendeleza kete kabla ya kushambulia.|Usalama wa mfalme: shughulikia shah na vitisho vya mat kwanza.|Usalama wa kete: angalia kete zisizolindwa na walinzi waliolemewa.|Ukaguzi wa hatua za kulazimisha: chunguza shah, ukamataji na vitisho.|Uchaguzi wa hatua: linganisha hatua mbili kabla ya kuamua.|Mbinu za mwisho: amsha mfalme na hesabu mbio za askari.|Hesabu za mbinu: soma mfululizo wa kulazimisha na mifumo ya mbinu.|Hesabu: nini hubadilika baada ya hatua yako na jibu gani la mpinzani linalazimisha zaidi?''',
};

const _rows = <String, String>{
  'en':
      '''Personal AI Coach|Preparing your explanation…|Ask about this position|Example: What if I play f2f3?|Compare up to 3 moves (optional)|Ask a follow-up|Sign in for custom questions. Quick questions remain available.|Helpful feedback saved.|Feedback saved.|Could not save feedback. Try again.|Was this useful?|Helpful|Not helpful|{count} questions remaining today|Device language|How was this move assessed?|What was the threat?|What should I play?|What pattern should I study?|How do I improve?|No immediate reply was provided by the engine.|Played move|Evaluation loss|Before moving, check the opponent’s checks, captures and threats.|Retry the position. Calculate {count} half-moves before moving. Solve it twice without a hint.''',
  'te':
      '''వ్యక్తిగత AI కోచ్|వివరణ సిద్ధమవుతోంది…|ఈ స్థితి గురించి అడగండి|ఉదాహరణ: f2f3 ఆడితే ఏమవుతుంది?|గరిష్ఠంగా 3 ఎత్తులను పోల్చండి (ఐచ్ఛికం)|తదుపరి ప్రశ్న అడగండి|మీ ప్రశ్నల కోసం సైన్ ఇన్ చేయండి. సిద్ధంగా ఉన్న ప్రశ్నలు అందుబాటులో ఉన్నాయి.|ఉపయోగకరమైన అభిప్రాయం భద్రపరచబడింది.|అభిప్రాయం భద్రపరచబడింది.|అభిప్రాయాన్ని భద్రపరచలేకపోయాము. మళ్లీ ప్రయత్నించండి.|ఇది ఉపయోగపడిందా?|ఉపయోగపడింది|ఉపయోగపడలేదు|ఈ రోజు ఇంకా {count} ప్రశ్నలు|పరికర భాష|ఈ ఎత్తును ఎలా అంచనా వేశారు?|ప్రమాదం ఏమిటి?|నేను ఏ ఎత్తు ఆడాలి?|ఏ నమూనాను నేర్చుకోవాలి?|నేను ఎలా మెరుగుపడాలి?|ఇంజిన్ తక్షణ సమాధానాన్ని ఇవ్వలేదు.|ఆడిన ఎత్తు|మూల్యాంకన నష్టం|ఎత్తు వేయడానికి ముందు ప్రత్యర్థి చెక్స్, క్యాప్చర్లు, ప్రమాదాలను పరిశీలించండి.|స్థితిని మళ్లీ ప్రయత్నించండి. ఆడే ముందు {count} అర్ధ ఎత్తులను లెక్కించండి. సూచన లేకుండా రెండుసార్లు పరిష్కరించండి.''',
  'hi':
      '''व्यक्तिगत AI कोच|आपका स्पष्टीकरण तैयार हो रहा है…|इस स्थिति के बारे में पूछें|उदाहरण: अगर मैं f2f3 खेलूँ तो?|अधिकतम 3 चालों की तुलना करें (वैकल्पिक)|अगला प्रश्न पूछें|अपने प्रश्नों के लिए साइन इन करें। तैयार प्रश्न उपलब्ध हैं।|उपयोगी प्रतिक्रिया सहेजी गई।|प्रतिक्रिया सहेजी गई।|प्रतिक्रिया सहेजी नहीं गई। फिर कोशिश करें।|क्या यह उपयोगी था?|उपयोगी|उपयोगी नहीं|आज {count} प्रश्न बाकी हैं|डिवाइस की भाषा|इस चाल का आकलन कैसे हुआ?|खतरा क्या था?|मुझे क्या खेलना चाहिए?|कौन सा पैटर्न सीखूँ?|मैं कैसे सुधार करूँ?|इंजन ने तत्काल जवाब नहीं दिया।|खेली गई चाल|मूल्यांकन हानि|चाल से पहले विरोधी की शह, मारने वाली चालें और खतरे देखें।|स्थिति फिर खेलें। खेलने से पहले {count} अर्ध-चालों की गणना करें। बिना संकेत दो बार हल करें।''',
  'ta':
      '''தனிப்பட்ட AI பயிற்சியாளர்|விளக்கம் தயாராகிறது…|இந்த நிலையைப் பற்றிக் கேளுங்கள்|உதாரணம்: f2f3 ஆடினால் என்ன ஆகும்?|3 நகர்வுகள் வரை ஒப்பிடுங்கள் (விருப்பம்)|தொடர்க் கேள்வி கேளுங்கள்|சொந்தக் கேள்விகளுக்கு உள்நுழையுங்கள். தயார் கேள்விகள் கிடைக்கும்.|பயனுள்ள கருத்து சேமிக்கப்பட்டது.|கருத்து சேமிக்கப்பட்டது.|கருத்தைச் சேமிக்க முடியவில்லை. மீண்டும் முயலுங்கள்.|இது பயனுள்ளதா?|பயனுள்ளது|பயனில்லை|இன்று {count} கேள்விகள் மீதம்|சாதன மொழி|இந்த நகர்வு எவ்வாறு மதிப்பிடப்பட்டது?|அச்சுறுத்தல் என்ன?|நான் என்ன ஆட வேண்டும்?|எந்த வடிவத்தைக் கற்க வேண்டும்?|எப்படி மேம்படுவது?|இயந்திரம் உடனடி பதிலை வழங்கவில்லை.|ஆடிய நகர்வு|மதிப்பீட்டு இழப்பு|ஆடுவதற்கு முன் எதிரியின் செக்குகள், பிடிப்புகள், அச்சுறுத்தல்களைச் சரிபாருங்கள்.|நிலையை மீண்டும் முயலுங்கள். ஆடும் முன் {count} அரை நகர்வுகளைக் கணக்கிடுங்கள். குறிப்பின்றி இருமுறை தீர்க்கவும்.''',
  'kn':
      '''ವೈಯಕ್ತಿಕ AI ತರಬೇತುದಾರ|ವಿವರಣೆ ಸಿದ್ಧವಾಗುತ್ತಿದೆ…|ಈ ಸ್ಥಿತಿಯ ಬಗ್ಗೆ ಕೇಳಿ|ಉದಾಹರಣೆ: f2f3 ಆಡಿದರೆ?|3 ನಡೆಗಳವರೆಗೆ ಹೋಲಿಸಿ (ಐಚ್ಛಿಕ)|ಮುಂದಿನ ಪ್ರಶ್ನೆ ಕೇಳಿ|ನಿಮ್ಮ ಪ್ರಶ್ನೆಗಳಿಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ. ಸಿದ್ಧ ಪ್ರಶ್ನೆಗಳು ಲಭ್ಯವಿವೆ.|ಉಪಯುಕ್ತ ಪ್ರತಿಕ್ರಿಯೆ ಉಳಿಸಲಾಗಿದೆ.|ಪ್ರತಿಕ್ರಿಯೆ ಉಳಿಸಲಾಗಿದೆ.|ಪ್ರತಿಕ್ರಿಯೆ ಉಳಿಸಲಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.|ಇದು ಉಪಯುಕ್ತವೇ?|ಉಪಯುಕ್ತ|ಉಪಯುಕ್ತವಲ್ಲ|ಇಂದು {count} ಪ್ರಶ್ನೆಗಳು ಬಾಕಿ|ಸಾಧನದ ಭಾಷೆ|ಈ ನಡೆಯನ್ನು ಹೇಗೆ ಅಂದಾಜಿಸಲಾಗಿದೆ?|ಬೆದರಿಕೆ ಏನಿತ್ತು?|ನಾನು ಏನು ಆಡಬೇಕು?|ಯಾವ ಮಾದರಿಯನ್ನು ಕಲಿಯಬೇಕು?|ಹೇಗೆ ಸುಧಾರಿಸಬೇಕು?|ಎಂಜಿನ್ ತಕ್ಷಣದ ಉತ್ತರ ನೀಡಿಲ್ಲ.|ಆಡಿದ ನಡೆ|ಮೌಲ್ಯಮಾಪನ ನಷ್ಟ|ಆಡುವ ಮುನ್ನ ಎದುರಾಳಿಯ ಚೆಕ್‌ಗಳು, ಸೆರೆಹಿಡಿಯುವ ನಡೆಗಳು ಮತ್ತು ಬೆದರಿಕೆಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.|ಸ್ಥಿತಿಯನ್ನು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ. ಆಡುವ ಮುನ್ನ {count} ಅರ್ಧ ನಡೆಗಳನ್ನು ಲೆಕ್ಕಿಸಿ. ಸೂಚನೆ ಇಲ್ಲದೆ ಎರಡು ಬಾರಿ ಪರಿಹರಿಸಿ.''',
  'ml':
      '''വ്യക്തിഗത AI പരിശീലകൻ|വിശദീകരണം തയ്യാറാകുന്നു…|ഈ സ്ഥിതിയെക്കുറിച്ച് ചോദിക്കൂ|ഉദാഹരണം: f2f3 കളിച്ചാൽ?|3 നീക്കങ്ങൾ വരെ താരതമ്യം ചെയ്യൂ (ഐച്ഛികം)|തുടർചോദ്യം ചോദിക്കൂ|സ്വന്തം ചോദ്യങ്ങൾക്ക് സൈൻ ഇൻ ചെയ്യൂ. തയ്യാറായ ചോദ്യങ്ങൾ ലഭ്യമാണ്.|ഉപയോഗപ്രദമായ അഭിപ്രായം സംരക്ഷിച്ചു.|അഭിപ്രായം സംരക്ഷിച്ചു.|അഭിപ്രായം സംരക്ഷിക്കാനായില്ല. വീണ്ടും ശ്രമിക്കൂ.|ഇത് ഉപകാരപ്പെട്ടോ?|ഉപകാരപ്പെട്ടു|ഉപകാരപ്പെട്ടില്ല|ഇന്ന് {count} ചോദ്യങ്ങൾ ബാക്കി|ഉപകരണ ഭാഷ|ഈ നീക്കം എങ്ങനെ വിലയിരുത്തി?|ഭീഷണി എന്തായിരുന്നു?|ഞാൻ എന്ത് കളിക്കണം?|ഏത് മാതൃക പഠിക്കണം?|എങ്ങനെ മെച്ചപ്പെടാം?|എൻജിൻ ഉടനടി മറുപടി നൽകിയില്ല.|കളിച്ച നീക്കം|മൂല്യനഷ്ടം|നീക്കത്തിന് മുമ്പ് എതിരാളിയുടെ ചെക്കുകൾ, പിടിച്ചെടുക്കലുകൾ, ഭീഷണികൾ പരിശോധിക്കൂ.|സ്ഥിതി വീണ്ടും ശ്രമിക്കൂ. കളിക്കും മുമ്പ് {count} അർധനീക്കങ്ങൾ കണക്കുകൂട്ടൂ. സൂചനയില്ലാതെ രണ്ടുതവണ പരിഹരിക്കൂ.''',
  'mr':
      '''वैयक्तिक AI प्रशिक्षक|स्पष्टीकरण तयार होत आहे…|या स्थितीबद्दल विचारा|उदाहरण: मी f2f3 खेळलो तर?|जास्तीत जास्त 3 चालींची तुलना करा (ऐच्छिक)|पुढचा प्रश्न विचारा|स्वतःच्या प्रश्नांसाठी साइन इन करा. तयार प्रश्न उपलब्ध आहेत.|उपयुक्त अभिप्राय जतन केला.|अभिप्राय जतन केला.|अभिप्राय जतन झाला नाही. पुन्हा प्रयत्न करा.|हे उपयोगी होते का?|उपयुक्त|उपयुक्त नाही|आज {count} प्रश्न उरले|उपकरणाची भाषा|या चालीचे मूल्यमापन कसे झाले?|धोका काय होता?|मी काय खेळावे?|कोणता नमुना शिकावा?|मी कशी सुधारणा करू?|इंजिनने तात्काळ उत्तर दिले नाही.|खेळलेली चाल|मूल्यांकनातील नुकसान|खेळण्याआधी प्रतिस्पर्ध्याचे शह, मारण्याच्या चाली आणि धोके तपासा.|स्थिती पुन्हा खेळा. खेळण्याआधी {count} अर्धचाली मोजा. संकेताशिवाय दोनदा सोडवा.''',
  'bn':
      '''ব্যক্তিগত AI প্রশিক্ষক|ব্যাখ্যা তৈরি হচ্ছে…|এই অবস্থান সম্পর্কে জিজ্ঞাসা করুন|উদাহরণ: f2f3 খেললে কী হবে?|সর্বোচ্চ 3টি চাল তুলনা করুন (ঐচ্ছিক)|আরও প্রশ্ন করুন|নিজের প্রশ্নের জন্য সাইন ইন করুন। তৈরি প্রশ্নগুলি পাওয়া যাবে।|উপকারী মতামত সংরক্ষিত।|মতামত সংরক্ষিত।|মতামত সংরক্ষণ হয়নি। আবার চেষ্টা করুন।|এটি কি কাজে লেগেছে?|উপকারী|উপকারী নয়|আজ {count}টি প্রশ্ন বাকি|ডিভাইসের ভাষা|এই চালের মূল্যায়ন কীভাবে হয়েছে?|হুমকি কী ছিল?|আমার কী খেলা উচিত?|কোন ধরন শিখব?|কীভাবে উন্নতি করব?|ইঞ্জিন তাৎক্ষণিক জবাব দেয়নি।|খেলা চাল|মূল্যায়নের ক্ষতি|চালের আগে প্রতিপক্ষের চেক, ঘুঁটি নেওয়ার চাল এবং হুমকি যাচাই করুন।|অবস্থান আবার খেলুন। খেলার আগে {count}টি অর্ধচাল গণনা করুন। ইঙ্গিত ছাড়া দুবার সমাধান করুন।''',
  'gu':
      '''વ્યક્તિગત AI કોચ|સમજૂતી તૈયાર થઈ રહી છે…|આ સ્થિતિ વિશે પૂછો|ઉદાહરણ: હું f2f3 રમું તો?|વધુમાં વધુ 3 ચાલ સરખાવો (વૈકલ્પિક)|આગળનો પ્રશ્ન પૂછો|તમારા પ્રશ્નો માટે સાઇન ઇન કરો. તૈયાર પ્રશ્નો ઉપલબ્ધ છે.|ઉપયોગી પ્રતિસાદ સાચવ્યો.|પ્રતિસાદ સાચવ્યો.|પ્રતિસાદ સાચવી શકાયો નહીં. ફરી પ્રયત્ન કરો.|આ ઉપયોગી હતું?|ઉપયોગી|ઉપયોગી નથી|આજે {count} પ્રશ્ન બાકી|ઉપકરણની ભાષા|આ ચાલનું મૂલ્યાંકન કેવી રીતે થયું?|ખતરો શું હતો?|મારે શું રમવું જોઈએ?|કઈ રચના શીખવી જોઈએ?|હું કેવી રીતે સુધરું?|એન્જિને તાત્કાલિક જવાબ આપ્યો નથી.|રમેલી ચાલ|મૂલ્યાંકન નુકસાન|રમતાં પહેલાં વિરોધીના શહ, મારવાની ચાલો અને ખતરા તપાસો.|સ્થિતિ ફરી રમો. રમતાં પહેલાં {count} અર્ધચાલ ગણો. સંકેત વગર બે વાર ઉકેલો.''',
  'pa':
      '''ਨਿੱਜੀ AI ਕੋਚ|ਵਿਆਖਿਆ ਤਿਆਰ ਹੋ ਰਹੀ ਹੈ…|ਇਸ ਸਥਿਤੀ ਬਾਰੇ ਪੁੱਛੋ|ਉਦਾਹਰਨ: ਜੇ ਮੈਂ f2f3 ਖੇਡਾਂ?|ਵੱਧ ਤੋਂ ਵੱਧ 3 ਚਾਲਾਂ ਦੀ ਤੁਲਨਾ ਕਰੋ (ਵਿਕਲਪਿਕ)|ਅਗਲਾ ਸਵਾਲ ਪੁੱਛੋ|ਆਪਣੇ ਸਵਾਲਾਂ ਲਈ ਸਾਈਨ ਇਨ ਕਰੋ। ਤਿਆਰ ਸਵਾਲ ਉਪਲਬਧ ਹਨ।|ਲਾਭਦਾਇਕ ਰਾਏ ਸੰਭਾਲੀ ਗਈ।|ਰਾਏ ਸੰਭਾਲੀ ਗਈ।|ਰਾਏ ਸੰਭਾਲ ਨਹੀਂ ਸਕੇ। ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ।|ਕੀ ਇਹ ਲਾਭਦਾਇਕ ਸੀ?|ਲਾਭਦਾਇਕ|ਲਾਭਦਾਇਕ ਨਹੀਂ|ਅੱਜ {count} ਸਵਾਲ ਬਾਕੀ|ਡਿਵਾਈਸ ਦੀ ਭਾਸ਼ਾ|ਇਸ ਚਾਲ ਦਾ ਮੁਲਾਂਕਣ ਕਿਵੇਂ ਹੋਇਆ?|ਖ਼ਤਰਾ ਕੀ ਸੀ?|ਮੈਂ ਕੀ ਖੇਡਾਂ?|ਕਿਹੜਾ ਨਮੂਨਾ ਸਿੱਖਾਂ?|ਮੈਂ ਸੁਧਾਰ ਕਿਵੇਂ ਕਰਾਂ?|ਇੰਜਣ ਨੇ ਤੁਰੰਤ ਜਵਾਬ ਨਹੀਂ ਦਿੱਤਾ।|ਖੇਡੀ ਚਾਲ|ਮੁਲਾਂਕਣ ਘਾਟਾ|ਖੇਡਣ ਤੋਂ ਪਹਿਲਾਂ ਵਿਰੋਧੀ ਦੇ ਸ਼ਹ, ਮਾਰਨ ਵਾਲੀਆਂ ਚਾਲਾਂ ਅਤੇ ਖ਼ਤਰੇ ਵੇਖੋ।|ਸਥਿਤੀ ਮੁੜ ਖੇਡੋ। ਖੇਡਣ ਤੋਂ ਪਹਿਲਾਂ {count} ਅੱਧ-ਚਾਲਾਂ ਗਿਣੋ। ਇਸ਼ਾਰੇ ਬਿਨਾਂ ਦੋ ਵਾਰ ਹੱਲ ਕਰੋ।''',
  'ur':
      '''ذاتی AI کوچ|وضاحت تیار ہو رہی ہے…|اس پوزیشن کے بارے میں پوچھیں|مثال: اگر میں f2f3 کھیلوں؟|زیادہ سے زیادہ 3 چالوں کا موازنہ کریں (اختیاری)|اگلا سوال پوچھیں|اپنے سوالات کے لیے سائن ان کریں۔ تیار سوالات دستیاب ہیں۔|مفید رائے محفوظ ہوگئی۔|رائے محفوظ ہوگئی۔|رائے محفوظ نہ ہوسکی۔ دوبارہ کوشش کریں۔|کیا یہ مفید تھا؟|مفید|غیر مفید|آج {count} سوال باقی ہیں|آلے کی زبان|اس چال کا جائزہ کیسے لیا گیا؟|خطرہ کیا تھا؟|مجھے کیا کھیلنا چاہیے؟|کون سا نمونہ سیکھوں؟|میں کیسے بہتر ہوں؟|انجن نے فوری جواب نہیں دیا۔|کھیلی گئی چال|جائزے میں نقصان|چال سے پہلے حریف کی شہ، مارنے کی چالیں اور خطرے دیکھیں۔|پوزیشن دوبارہ کھیلیں۔ کھیلنے سے پہلے {count} نصف چالیں شمار کریں۔ اشارے کے بغیر دو بار حل کریں۔''',
  'ar':
      '''مدرب ذكاء اصطناعي شخصي|جارٍ إعداد الشرح…|اسأل عن هذا الوضع|مثال: ماذا لو لعبت f2f3؟|قارن حتى 3 نقلات (اختياري)|اطرح سؤال متابعة|سجّل الدخول لأسئلتك الخاصة. الأسئلة الجاهزة متاحة.|تم حفظ الملاحظة المفيدة.|تم حفظ الملاحظة.|تعذر حفظ الملاحظة. حاول مجددًا.|هل كان هذا مفيدًا؟|مفيد|غير مفيد|بقي {count} سؤال اليوم|لغة الجهاز|كيف قُيّمت هذه النقلة؟|ما التهديد؟|ماذا ألعب؟|أي نمط أدرس؟|كيف أتحسن؟|لم يقدم المحرك ردًا فوريًا.|النقلة الملعوبة|خسارة التقييم|قبل النقل، تحقق من كش الخصم والأخذ والتهديدات.|أعد الوضع. احسب {count} نصف نقلة قبل اللعب. حلّه مرتين دون تلميح.''',
  'es':
      '''Entrenador personal de IA|Preparando la explicación…|Pregunta sobre esta posición|Ejemplo: ¿Y si juego f2f3?|Compara hasta 3 jugadas (opcional)|Haz otra pregunta|Inicia sesión para preguntas propias. Las preguntas rápidas siguen disponibles.|Comentario útil guardado.|Comentario guardado.|No se pudo guardar. Inténtalo de nuevo.|¿Fue útil?|Útil|No fue útil|Quedan {count} preguntas hoy|Idioma del dispositivo|¿Cómo se evaluó esta jugada?|¿Cuál era la amenaza?|¿Qué debo jugar?|¿Qué patrón debo estudiar?|¿Cómo mejoro?|El motor no proporcionó una respuesta inmediata.|Jugada realizada|Pérdida de evaluación|Antes de jugar, revisa los jaques, capturas y amenazas del rival.|Repite la posición. Calcula {count} medias jugadas antes de mover. Resuélvela dos veces sin pistas.''',
  'fr':
      '''Coach IA personnel|Préparation de l’explication…|Posez une question sur cette position|Exemple : Et si je joue f2f3 ?|Comparez jusqu’à 3 coups (facultatif)|Posez une autre question|Connectez-vous pour vos questions. Les questions rapides restent disponibles.|Avis utile enregistré.|Avis enregistré.|Impossible d’enregistrer l’avis. Réessayez.|Était-ce utile ?|Utile|Pas utile|Il reste {count} questions aujourd’hui|Langue de l’appareil|Comment ce coup a-t-il été évalué ?|Quelle était la menace ?|Que dois-je jouer ?|Quel motif dois-je étudier ?|Comment progresser ?|Le moteur n’a pas fourni de réponse immédiate.|Coup joué|Perte d’évaluation|Avant de jouer, vérifiez les échecs, prises et menaces adverses.|Rejouez la position. Calculez {count} demi-coups avant de jouer. Résolvez-la deux fois sans indice.''',
  'de':
      '''Persönlicher KI-Trainer|Erklärung wird vorbereitet…|Frage zu dieser Stellung|Beispiel: Was, wenn ich f2f3 spiele?|Bis zu 3 Züge vergleichen (optional)|Weitere Frage stellen|Für eigene Fragen anmelden. Schnellfragen bleiben verfügbar.|Hilfreiche Rückmeldung gespeichert.|Rückmeldung gespeichert.|Speichern fehlgeschlagen. Erneut versuchen.|War das hilfreich?|Hilfreich|Nicht hilfreich|Heute noch {count} Fragen|Gerätesprache|Wie wurde dieser Zug bewertet?|Was war die Drohung?|Was soll ich spielen?|Welches Motiv soll ich üben?|Wie verbessere ich mich?|Die Engine lieferte keine unmittelbare Antwort.|Gespielter Zug|Bewertungsverlust|Prüfe vor dem Zug gegnerische Schachs, Schlagzüge und Drohungen.|Spiele die Stellung erneut. Berechne {count} Halbzüge vor dem Ziehen. Löse sie zweimal ohne Hinweis.''',
  'it':
      '''Allenatore IA personale|Preparazione della spiegazione…|Chiedi di questa posizione|Esempio: E se gioco f2f3?|Confronta fino a 3 mosse (facoltativo)|Fai un’altra domanda|Accedi per domande personali. Le domande rapide restano disponibili.|Riscontro utile salvato.|Riscontro salvato.|Impossibile salvare. Riprova.|È stato utile?|Utile|Non utile|Restano {count} domande oggi|Lingua del dispositivo|Come è stata valutata questa mossa?|Qual era la minaccia?|Cosa devo giocare?|Quale schema devo studiare?|Come miglioro?|Il motore non ha fornito una risposta immediata.|Mossa giocata|Perdita di valutazione|Prima di muovere, controlla scacchi, catture e minacce avversarie.|Riprova la posizione. Calcola {count} semimosse prima di muovere. Risolvila due volte senza suggerimenti.''',
  'pt':
      '''Treinador pessoal de IA|A preparar a explicação…|Pergunte sobre esta posição|Exemplo: E se jogar f2f3?|Compare até 3 lances (opcional)|Faça outra pergunta|Inicie sessão para perguntas próprias. As perguntas rápidas continuam disponíveis.|Comentário útil guardado.|Comentário guardado.|Não foi possível guardar. Tente novamente.|Foi útil?|Útil|Não foi útil|Restam {count} perguntas hoje|Idioma do dispositivo|Como foi avaliado este lance?|Qual era a ameaça?|O que devo jogar?|Que padrão devo estudar?|Como melhorar?|O motor não forneceu uma resposta imediata.|Lance jogado|Perda de avaliação|Antes de jogar, verifique os xeques, capturas e ameaças adversários.|Repita a posição. Calcule {count} meios-lances antes de jogar. Resolva duas vezes sem dicas.''',
  'ru':
      '''Личный ИИ-тренер|Подготовка объяснения…|Спросите об этой позиции|Пример: Что если сыграть f2f3?|Сравнить до 3 ходов (необязательно)|Задать следующий вопрос|Войдите для своих вопросов. Быстрые вопросы доступны без входа.|Полезный отзыв сохранён.|Отзыв сохранён.|Не удалось сохранить отзыв. Повторите.|Это было полезно?|Полезно|Не полезно|Сегодня осталось {count} вопросов|Язык устройства|Как оценён этот ход?|В чём была угроза?|Что мне сыграть?|Какой мотив изучить?|Как улучшить игру?|Движок не предоставил немедленный ответ.|Сыгранный ход|Потеря оценки|Перед ходом проверьте шахи, взятия и угрозы соперника.|Повторите позицию. Рассчитайте {count} полуходов до хода. Решите дважды без подсказок.''',
  'uk':
      '''Особистий ШІ-тренер|Підготовка пояснення…|Запитайте про цю позицію|Приклад: А якщо зіграти f2f3?|Порівняйте до 3 ходів (необов’язково)|Поставте наступне запитання|Увійдіть для власних запитань. Швидкі запитання залишаються доступними.|Корисний відгук збережено.|Відгук збережено.|Не вдалося зберегти. Спробуйте ще раз.|Це було корисно?|Корисно|Не корисно|Сьогодні залишилося {count} запитань|Мова пристрою|Як оцінено цей хід?|У чому була загроза?|Що мені зіграти?|Який мотив вивчити?|Як покращити гру?|Рушій не надав негайної відповіді.|Зіграний хід|Втрата оцінки|Перед ходом перевірте шахи, взяття та загрози суперника.|Повторіть позицію. Розрахуйте {count} півходів до ходу. Розв’яжіть двічі без підказок.''',
  'tr':
      '''Kişisel yapay zekâ koçu|Açıklama hazırlanıyor…|Bu konum hakkında sor|Örnek: f2f3 oynarsam ne olur?|En fazla 3 hamleyi karşılaştır (isteğe bağlı)|Devam sorusu sor|Kendi soruların için giriş yap. Hızlı sorular kullanılabilir.|Yararlı geri bildirim kaydedildi.|Geri bildirim kaydedildi.|Kaydedilemedi. Yeniden dene.|Yararlı mıydı?|Yararlı|Yararlı değil|Bugün {count} soru kaldı|Cihaz dili|Bu hamle nasıl değerlendirildi?|Tehdit neydi?|Ne oynamalıyım?|Hangi motifi çalışmalıyım?|Nasıl gelişirim?|Motor hemen verilecek bir yanıt sunmadı.|Oynanan hamle|Değerlendirme kaybı|Oynamadan önce rakibin şahlarını, alışlarını ve tehditlerini kontrol et.|Konumu tekrar dene. Oynamadan önce {count} yarım hamle hesapla. İpucu olmadan iki kez çöz.''',
  'fa':
      '''مربی شخصی هوش مصنوعی|توضیح در حال آماده‌سازی است…|دربارهٔ این وضعیت بپرسید|مثال: اگر f2f3 بازی کنم؟|تا 3 حرکت را مقایسه کنید (اختیاری)|پرسش بعدی را بپرسید|برای پرسش‌های خود وارد شوید. پرسش‌های آماده در دسترس‌اند.|بازخورد مفید ذخیره شد.|بازخورد ذخیره شد.|ذخیره نشد. دوباره تلاش کنید.|مفید بود؟|مفید|غیرمفید|امروز {count} پرسش باقی مانده|زبان دستگاه|این حرکت چگونه ارزیابی شد؟|تهدید چه بود؟|چه بازی کنم؟|کدام الگو را بیاموزم؟|چگونه بهتر شوم؟|موتور پاسخ فوری ارائه نکرد.|حرکت بازی‌شده|افت ارزیابی|پیش از حرکت، کیش‌ها، گرفتن‌ها و تهدیدهای حریف را بررسی کنید.|وضعیت را دوباره بازی کنید. پیش از حرکت {count} نیم‌حرکت محاسبه کنید. دو بار بدون راهنمایی حل کنید.''',
  'zh':
      '''个人 AI 教练|正在准备讲解…|询问这个局面|例如：如果走 f2f3 呢？|比较最多 3 步棋（可选）|继续提问|登录后可自定义提问。快捷问题仍可使用。|已保存有帮助的反馈。|反馈已保存。|无法保存反馈，请重试。|有帮助吗？|有帮助|没有帮助|今天还可提问 {count} 次|设备语言|这步棋是如何评价的？|有什么威胁？|我该走什么？|我该学习什么模式？|如何提高？|引擎未提供直接应招。|实战着法|评估损失|走棋前检查对手的将军、吃子和威胁。|重试此局面。走棋前计算 {count} 个半回合。不用提示解出两次。''',
  'ja':
      '''個人 AI コーチ|解説を準備中…|この局面について質問|例：f2f3 と指したら？|最大3手を比較（任意）|続けて質問|自由な質問にはログインしてください。定型質問は利用できます。|役立つとの評価を保存しました。|評価を保存しました。|保存できませんでした。再試行してください。|役立ちましたか？|役立った|役立たなかった|本日の残り質問数：{count}|端末の言語|この手はどう評価されましたか？|どんな脅威がありましたか？|何を指すべきですか？|どのパターンを学ぶべきですか？|どう上達できますか？|エンジンは直後の応手を提示しませんでした。|指した手|評価値の損失|指す前に相手のチェック、駒取り、脅威を確認しましょう。|局面を再挑戦しましょう。指す前に{count}半手を計算し、ヒントなしで2回解きましょう。''',
  'ko':
      '''개인 AI 코치|설명을 준비하는 중…|이 포지션에 대해 질문|예: f2f3를 두면 어떨까요?|최대 3개 수 비교 (선택)|추가 질문|자유 질문은 로그인 후 이용하세요. 빠른 질문은 계속 이용할 수 있습니다.|도움이 된다는 평가를 저장했습니다.|평가를 저장했습니다.|저장할 수 없습니다. 다시 시도하세요.|도움이 되었나요?|도움됨|도움 안 됨|오늘 질문 {count}개 남음|기기 언어|이 수는 어떻게 평가되었나요?|위협은 무엇이었나요?|무엇을 두어야 하나요?|어떤 패턴을 공부할까요?|어떻게 실력을 높일까요?|엔진이 즉각적인 응수를 제공하지 않았습니다.|실제 수|평가 손실|두기 전에 상대의 체크, 잡기, 위협을 확인하세요.|포지션을 다시 풀어 보세요. 두기 전에 {count}반수를 계산하세요. 힌트 없이 두 번 해결하세요.''',
  'id':
      '''Pelatih AI pribadi|Menyiapkan penjelasan…|Tanyakan tentang posisi ini|Contoh: Bagaimana jika saya main f2f3?|Bandingkan hingga 3 langkah (opsional)|Ajukan pertanyaan lanjutan|Masuk untuk pertanyaan sendiri. Pertanyaan cepat tetap tersedia.|Umpan balik bermanfaat disimpan.|Umpan balik disimpan.|Gagal menyimpan. Coba lagi.|Apakah ini membantu?|Membantu|Tidak membantu|Sisa {count} pertanyaan hari ini|Bahasa perangkat|Bagaimana langkah ini dinilai?|Apa ancamannya?|Apa yang harus saya mainkan?|Pola apa yang perlu dipelajari?|Bagaimana cara meningkat?|Mesin tidak memberikan balasan langsung.|Langkah dimainkan|Kehilangan evaluasi|Sebelum melangkah, periksa skak, tangkapan, dan ancaman lawan.|Ulangi posisi. Hitung {count} setengah langkah sebelum bergerak. Selesaikan dua kali tanpa petunjuk.''',
  'ms':
      '''Jurulatih AI peribadi|Menyediakan penjelasan…|Tanya tentang kedudukan ini|Contoh: Jika saya main f2f3?|Bandingkan sehingga 3 langkah (pilihan)|Tanya soalan susulan|Log masuk untuk soalan sendiri. Soalan pantas masih tersedia.|Maklum balas berguna disimpan.|Maklum balas disimpan.|Tidak dapat menyimpan. Cuba lagi.|Adakah ini membantu?|Membantu|Tidak membantu|Baki {count} soalan hari ini|Bahasa peranti|Bagaimana langkah ini dinilai?|Apakah ancamannya?|Apakah yang patut saya mainkan?|Corak apa yang perlu dipelajari?|Bagaimana untuk meningkat?|Enjin tidak memberikan balasan segera.|Langkah dimainkan|Kehilangan penilaian|Sebelum bergerak, semak syah, tangkapan dan ancaman lawan.|Cuba kedudukan semula. Kira {count} separuh langkah sebelum bergerak. Selesaikan dua kali tanpa petunjuk.''',
  'th':
      '''โค้ช AI ส่วนตัว|กำลังเตรียมคำอธิบาย…|ถามเกี่ยวกับตำแหน่งนี้|ตัวอย่าง: ถ้าเดิน f2f3 ล่ะ?|เปรียบเทียบได้สูงสุด 3 ตา (ไม่บังคับ)|ถามต่อ|เข้าสู่ระบบเพื่อถามเอง คำถามด่วนยังใช้ได้|บันทึกความเห็นว่ามีประโยชน์แล้ว|บันทึกความเห็นแล้ว|บันทึกไม่ได้ โปรดลองอีกครั้ง|มีประโยชน์ไหม?|มีประโยชน์|ไม่มีประโยชน์|วันนี้เหลือ {count} คำถาม|ภาษาของอุปกรณ์|ตานี้ประเมินอย่างไร?|ภัยคุกคามคืออะไร?|ควรเดินอะไร?|ควรศึกษารูปแบบใด?|จะพัฒนาอย่างไร?|เอนจินไม่ได้ให้ตาตอบทันที|ตาที่เดิน|คะแนนประเมินที่เสียไป|ก่อนเดิน ตรวจดูรุก การกิน และภัยคุกคามของคู่ต่อสู้|ลองตำแหน่งอีกครั้ง คำนวณ {count} ครึ่งตาก่อนเดิน แก้ให้ได้สองครั้งโดยไม่ใช้คำใบ้''',
  'vi':
      '''Huấn luyện viên AI cá nhân|Đang chuẩn bị giải thích…|Hỏi về thế cờ này|Ví dụ: Nếu tôi đi f2f3 thì sao?|So sánh tối đa 3 nước (tùy chọn)|Hỏi tiếp|Đăng nhập để tự đặt câu hỏi. Câu hỏi nhanh vẫn dùng được.|Đã lưu phản hồi hữu ích.|Đã lưu phản hồi.|Không lưu được. Hãy thử lại.|Có hữu ích không?|Hữu ích|Không hữu ích|Hôm nay còn {count} câu hỏi|Ngôn ngữ thiết bị|Nước này được đánh giá thế nào?|Mối đe dọa là gì?|Tôi nên đi gì?|Tôi nên học mẫu nào?|Làm sao để tiến bộ?|Máy không cung cấp nước đáp ngay lập tức.|Nước đã đi|Điểm đánh giá bị mất|Trước khi đi, kiểm tra các nước chiếu, bắt quân và đe dọa của đối thủ.|Thử lại thế cờ. Tính {count} nửa nước trước khi đi. Giải hai lần không cần gợi ý.''',
  'pl':
      '''Osobisty trener AI|Przygotowywanie wyjaśnienia…|Zapytaj o tę pozycję|Przykład: A jeśli zagram f2f3?|Porównaj do 3 ruchów (opcjonalnie)|Zadaj kolejne pytanie|Zaloguj się, aby zadawać własne pytania. Szybkie pytania są dostępne.|Zapisano przydatną opinię.|Zapisano opinię.|Nie udało się zapisać. Spróbuj ponownie.|Czy to było przydatne?|Przydatne|Nieprzydatne|Pozostało dziś {count} pytań|Język urządzenia|Jak oceniono ten ruch?|Jakie było zagrożenie?|Co mam zagrać?|Jaki motyw ćwiczyć?|Jak się poprawić?|Silnik nie podał natychmiastowej odpowiedzi.|Zagrany ruch|Strata oceny|Przed ruchem sprawdź szachy, bicia i groźby przeciwnika.|Powtórz pozycję. Oblicz {count} półruchów przed ruchem. Rozwiąż dwukrotnie bez podpowiedzi.''',
  'nl':
      '''Persoonlijke AI-coach|Uitleg voorbereiden…|Vraag over deze stelling|Voorbeeld: Wat als ik f2f3 speel?|Vergelijk maximaal 3 zetten (optioneel)|Stel een vervolgvraag|Log in voor eigen vragen. Snelle vragen blijven beschikbaar.|Nuttige feedback opgeslagen.|Feedback opgeslagen.|Opslaan mislukt. Probeer opnieuw.|Was dit nuttig?|Nuttig|Niet nuttig|Vandaag nog {count} vragen|Apparaattaal|Hoe werd deze zet beoordeeld?|Wat was de dreiging?|Wat moet ik spelen?|Welk patroon moet ik leren?|Hoe verbeter ik?|De engine gaf geen directe reactie.|Gespeelde zet|Evaluatieverlies|Controleer vóór je zet de schaakzetten, slagzetten en dreigingen van de tegenstander.|Probeer de stelling opnieuw. Bereken {count} halve zetten vóór je zet. Los tweemaal op zonder hint.''',
  'sv':
      '''Personlig AI-tränare|Förbereder förklaringen…|Fråga om denna ställning|Exempel: Om jag spelar f2f3?|Jämför upp till 3 drag (valfritt)|Ställ en följdfråga|Logga in för egna frågor. Snabbfrågor är tillgängliga.|Hjälpsam återkoppling sparad.|Återkoppling sparad.|Kunde inte spara. Försök igen.|Var detta hjälpsamt?|Hjälpsamt|Inte hjälpsamt|{count} frågor kvar idag|Enhetens språk|Hur bedömdes draget?|Vad var hotet?|Vad ska jag spela?|Vilket mönster ska jag öva?|Hur blir jag bättre?|Motorn gav inget omedelbart svar.|Spelat drag|Utvärderingsförlust|Kontrollera motståndarens schackar, slag och hot före draget.|Försök ställningen igen. Beräkna {count} halvdrag före draget. Lös två gånger utan ledtråd.''',
  'el':
      '''Προσωπικός προπονητής AI|Προετοιμασία εξήγησης…|Ρωτήστε για αυτή τη θέση|Παράδειγμα: Αν παίξω f2f3;|Σύγκριση έως 3 κινήσεων (προαιρετικό)|Κάντε επόμενη ερώτηση|Συνδεθείτε για δικές σας ερωτήσεις. Οι γρήγορες ερωτήσεις είναι διαθέσιμες.|Αποθηκεύτηκε χρήσιμο σχόλιο.|Το σχόλιο αποθηκεύτηκε.|Η αποθήκευση απέτυχε. Δοκιμάστε ξανά.|Ήταν χρήσιμο;|Χρήσιμο|Όχι χρήσιμο|Απομένουν {count} ερωτήσεις σήμερα|Γλώσσα συσκευής|Πώς αξιολογήθηκε η κίνηση;|Ποια ήταν η απειλή;|Τι να παίξω;|Ποιο μοτίβο να μελετήσω;|Πώς να βελτιωθώ;|Η μηχανή δεν έδωσε άμεση απάντηση.|Παιγμένη κίνηση|Απώλεια αξιολόγησης|Πριν παίξετε, ελέγξτε τα σαχ, τα παρσίματα και τις απειλές του αντιπάλου.|Ξαναπαίξτε τη θέση. Υπολογίστε {count} ημικινήσεις πριν παίξετε. Λύστε δύο φορές χωρίς υπόδειξη.''',
  'he':
      '''מאמן AI אישי|מכין הסבר…|שאלו על העמדה הזאת|לדוגמה: מה אם אשחק f2f3?|השוו עד 3 מסעים (רשות)|שאלו שאלת המשך|התחברו לשאלות משלכם. שאלות מהירות עדיין זמינות.|נשמר משוב מועיל.|המשוב נשמר.|שמירת המשוב נכשלה. נסו שוב.|האם זה הועיל?|מועיל|לא מועיל|נותרו {count} שאלות היום|שפת המכשיר|איך הוערך המסע הזה?|מה היה האיום?|מה עליי לשחק?|איזו תבנית ללמוד?|איך להשתפר?|המנוע לא סיפק תגובה מיידית.|המסע ששוחק|אובדן הערכה|לפני המסע בדקו את השחים, ההכאות והאיומים של היריב.|נסו שוב את העמדה. חשבו {count} חצאי מסעים לפני המשחק. פתרו פעמיים ללא רמז.''',
  'sw':
      '''Kocha binafsi wa AI|Inaandaa maelezo…|Uliza kuhusu nafasi hii|Mfano: Nikicheza f2f3 je?|Linganisha hadi hatua 3 (si lazima)|Uliza swali la kufuatilia|Ingia kwa maswali yako. Maswali ya haraka bado yanapatikana.|Maoni yenye manufaa yamehifadhiwa.|Maoni yamehifadhiwa.|Imeshindwa kuhifadhi. Jaribu tena.|Je, hii ilisaidia?|Imesaidia|Haijasaidia|Maswali {count} yamebaki leo|Lugha ya kifaa|Hatua hii ilitathminiwaje?|Tishio lilikuwa nini?|Nicheze nini?|Nijifunze muundo gani?|Ninawezaje kuboresha?|Injini haikutoa jibu la haraka.|Hatua iliyochezwa|Hasara ya tathmini|Kabla ya kucheza, angalia shah, ukamataji na vitisho vya mpinzani.|Jaribu nafasi tena. Hesabu nusu-hatua {count} kabla ya kucheza. Tatua mara mbili bila kidokezo.''',
};
