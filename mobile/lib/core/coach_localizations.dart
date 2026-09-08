import 'app_language.dart';
import 'coach_review_labels.dart';

/// Offline, parameterised coaching copy. Chess notation is passed as data,
/// never translated. A missing entry is observable through [contains].
class CoachLocalizations {
  CoachLocalizations(String language)
      : language = AppLanguageController.resolveCode(language);
  final String language;

  static const keys = <String>[
    'trainMistakes',
    'white',
    'black',
    'principled',
    'opening',
    'middlegame',
    'endgame',
    'centreLesson',
    'slowGame',
    'principledExplanation',
    'threatTitle',
    'immediateReply',
    'alternative',
    'continuation',
    'gotIt',
    'retry',
    'back',
    'positionBefore',
    'findContinuation',
    'restored',
    'bestFound',
    'goodTry',
    'preferred',
  ];

  static final Map<String, List<String>> translations = {
    for (final entry in _rows.entries) entry.key: entry.value.split('|'),
  };

  bool contains(String key) =>
      (keys.contains(key) && translations[language]?.length == keys.length) ||
      (reviewLabelKeys.contains(key) &&
          reviewLabelTranslations[language]?.length == reviewLabelKeys.length);

  String text(String key, [Map<String, String> parameters = const {}]) {
    final reviewIndex = reviewLabelKeys.indexOf(key);
    if (reviewIndex >= 0) {
      return reviewLabelTranslations[language]![reviewIndex];
    }
    final index = keys.indexOf(key);
    if (index < 0) {
      throw ArgumentError.value(key, 'key', 'Unknown coaching key');
    }
    var result = translations[language]![index];
    for (final parameter in parameters.entries) {
      result = result.replaceAll('{${parameter.key}}', parameter.value);
    }
    return result;
  }

  String source(String value) {
    final key = _sources[value];
    return key == null ? value : text(key);
  }

  static const _sources = <String, String>{
    'White': 'white',
    'Black': 'black',
    'Principled': 'principled',
    'Opening': 'opening',
    'Middlegame': 'middlegame',
    'Endgame': 'endgame',
    'Best': 'best',
    'Great': 'great',
    'Good': 'good',
    'Playable': 'playable',
    'Inaccuracy': 'inaccuracy',
    'Mistake': 'mistake',
    'Blunder': 'blunder',
    'Complete one centre-control lesson before the next rated game.':
        'centreLesson',
    'Play one slower game and apply the same thinking routine.': 'slowGame',
    'This move improves central influence or development. Keep king safety in view.':
        'principledExplanation',
  };

  static const _rows = <String, String>{
    'en':
        '''Train reviewed mistakes|White|Black|Principled|Opening|Middlegame|Endgame|Complete one centre-control lesson before the next rated game.|Play one slower game and apply the same thinking routine.|This move improves central influence or development. Keep king safety in view.|Opponent threat|Immediate opponent reply|Best alternative|Engine continuation|Got it|Try again|Back to review|Position before move {move}|{side} to move · Find the strongest continuation|Reviewed position restored|Best move found.|Good try.|The engine preferred {move}.''',
    'te':
        '''సమీక్షించిన తప్పులను సాధన చేయండి|తెలుపు|నలుపు|సూత్రబద్ధమైన ఎత్తు|ఓపెనింగ్|మధ్యగేమ్|ఎండ్‌గేమ్|తదుపరి రేటెడ్ గేమ్‌కు ముందు కేంద్ర నియంత్రణపై ఒక పాఠాన్ని పూర్తి చేయండి.|ఒక నెమ్మది గేమ్ ఆడి ఇదే ఆలోచనా విధానాన్ని అనుసరించండి.|ఈ ఎత్తు కేంద్రంపై ప్రభావాన్ని లేదా పావుల అభివృద్ధిని మెరుగుపరుస్తుంది. రాజు భద్రతను కూడా గమనించండి.|ప్రత్యర్థి ప్రమాదం|ప్రత్యర్థి తక్షణ సమాధానం|ఉత్తమ ప్రత్యామ్నాయం|ఇంజిన్ కొనసాగింపు|అర్థమైంది|మళ్లీ ప్రయత్నించండి|సమీక్షకు తిరిగి వెళ్లండి|{move}వ ఎత్తుకు ముందు స్థితి|{side} ఆడాలి · అత్యుత్తమ కొనసాగింపును కనుగొనండి|సమీక్షించిన స్థితి పునరుద్ధరించబడింది|ఉత్తమ ఎత్తును కనుగొన్నారు.|మంచి ప్రయత్నం.|ఇంజిన్ సూచించిన ఎత్తు {move}.''',
    'hi':
        '''समीक्षा की गई गलतियों का अभ्यास करें|सफेद|काला|सिद्धान्तसम्मत|ओपनिंग|मध्य खेल|अंतिम खेल|अगले रेटेड खेल से पहले केंद्र नियंत्रण का एक पाठ पूरा करें।|एक धीमा खेल खेलें और उसी सोचने की प्रक्रिया को अपनाएँ।|यह चाल केंद्र पर प्रभाव या मोहरों के विकास को बेहतर करती है। राजा की सुरक्षा का ध्यान रखें।|प्रतिद्वंद्वी का खतरा|प्रतिद्वंद्वी का तत्काल जवाब|सबसे अच्छा विकल्प|इंजन की सुझाई चालों का क्रम|समझ गया|फिर कोशिश करें|समीक्षा पर लौटें|चाल {move} से पहले की स्थिति|{side} की चाल · सबसे मजबूत अगला क्रम खोजें|समीक्षित स्थिति बहाल की गई|सर्वश्रेष्ठ चाल मिल गई।|अच्छा प्रयास।|इंजन ने {move} को बेहतर माना।''',
    'ta':
        '''மதிப்பாய்வு செய்த தவறுகளைப் பயிற்சி செய்யவும்|வெள்ளை|கருப்பு|கொள்கை சார்ந்தது|தொடக்கம்|நடு ஆட்டம்|இறுதி ஆட்டம்|அடுத்த தரவரிசை ஆட்டத்திற்கு முன் மையக் கட்டுப்பாடு குறித்த ஒரு பாடத்தை முடிக்கவும்.|ஒரு மெதுவான ஆட்டத்தை விளையாடி அதே சிந்தனை முறையைப் பயன்படுத்தவும்.|இந்த நகர்வு மைய ஆதிக்கத்தை அல்லது காய்களின் வளர்ச்சியை மேம்படுத்துகிறது. ராஜாவின் பாதுகாப்பையும் கவனிக்கவும்.|எதிராளியின் அச்சுறுத்தல்|எதிராளியின் உடனடி பதில்|சிறந்த மாற்று|இயந்திரம் பரிந்துரைக்கும் தொடர்ச்சி|புரிந்தது|மீண்டும் முயலவும்|மதிப்பாய்வுக்குத் திரும்பவும்|நகர்வு {move}க்கு முந்தைய நிலை|{side} நகர்த்த வேண்டும் · சிறந்த தொடர்ச்சியைக் கண்டறியவும்|மதிப்பாய்வு செய்த நிலை மீட்டமைக்கப்பட்டது|சிறந்த நகர்வு கண்டறியப்பட்டது.|நல்ல முயற்சி.|இயந்திரம் {move}ஐ விரும்பியது.''',
    'kn':
        '''ವಿಮರ್ಶಿಸಿದ ತಪ್ಪುಗಳನ್ನು ಅಭ್ಯಾಸ ಮಾಡಿ|ಬಿಳಿ|ಕಪ್ಪು|ತತ್ವಬದ್ಧ ನಡೆ|ಆರಂಭ|ಮಧ್ಯದ ಆಟ|ಅಂತಿಮ ಆಟ|ಮುಂದಿನ ರೇಟೆಡ್ ಆಟಕ್ಕೆ ಮೊದಲು ಕೇಂದ್ರ ನಿಯಂತ್ರಣದ ಒಂದು ಪಾಠವನ್ನು ಪೂರ್ಣಗೊಳಿಸಿ.|ಒಂದು ನಿಧಾನಗತಿಯ ಆಟ ಆಡಿ ಅದೇ ಆಲೋಚನಾ ವಿಧಾನವನ್ನು ಬಳಸಿ.|ಈ ನಡೆ ಕೇಂದ್ರದ ಪ್ರಭಾವ ಅಥವಾ ಕಾಯಿಗಳ ಅಭಿವೃದ್ಧಿಯನ್ನು ಸುಧಾರಿಸುತ್ತದೆ. ರಾಜನ ಸುರಕ್ಷತೆಯನ್ನೂ ಗಮನಿಸಿ.|ಎದುರಾಳಿಯ ಬೆದರಿಕೆ|ಎದುರಾಳಿಯ ತಕ್ಷಣದ ಉತ್ತರ|ಉತ್ತಮ ಪರ್ಯಾಯ|ಇಂಜಿನ್ ಸೂಚಿಸಿದ ಮುಂದುವರಿಕೆ|ಅರ್ಥವಾಯಿತು|ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ|ವಿಮರ್ಶೆಗೆ ಹಿಂತಿರುಗಿ|{move}ನೇ ನಡೆಗೆ ಮೊದಲಿನ ಸ್ಥಿತಿ|{side} ನಡೆಯಬೇಕು · ಅತ್ಯುತ್ತಮ ಮುಂದುವರಿಕೆಯನ್ನು ಕಂಡುಹಿಡಿಯಿರಿ|ವಿಮರ್ಶಿಸಿದ ಸ್ಥಿತಿಯನ್ನು ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ|ಅತ್ಯುತ್ತಮ ನಡೆ ಕಂಡುಬಂದಿದೆ.|ಒಳ್ಳೆಯ ಪ್ರಯತ್ನ.|ಇಂಜಿನ್ {move} ನಡೆಯನ್ನು ಆಯ್ಕೆ ಮಾಡಿತು.''',
    'ml':
        '''അവലോകനം ചെയ്ത തെറ്റുകൾ പരിശീലിക്കുക|വെള്ള|കറുപ്പ്|തത്വാധിഷ്ഠിതം|ഓപ്പണിംഗ്|മധ്യഘട്ടം|അവസാനഘട്ടം|അടുത്ത റേറ്റഡ് കളിക്ക് മുമ്പ് കേന്ദ്ര നിയന്ത്രണത്തെക്കുറിച്ചുള്ള ഒരു പാഠം പൂർത്തിയാക്കുക.|ഒരു സാവധാനമുള്ള കളി കളിച്ച് അതേ ചിന്താരീതി പ്രയോഗിക്കുക.|ഈ നീക്കം കേന്ദ്രത്തിലെ സ്വാധീനമോ കരുക്കളുടെ വികസനമോ മെച്ചപ്പെടുത്തുന്നു. രാജാവിന്റെ സുരക്ഷയും ശ്രദ്ധിക്കുക.|എതിരാളിയുടെ ഭീഷണി|എതിരാളിയുടെ ഉടനെയുള്ള മറുപടി|മികച്ച ബദൽ|എൻജിൻ നിർദേശിക്കുന്ന തുടർച്ച|മനസ്സിലായി|വീണ്ടും ശ്രമിക്കുക|അവലോകനത്തിലേക്ക് മടങ്ങുക|{move} നീക്കത്തിന് മുമ്പുള്ള സ്ഥിതി|{side} നീക്കണം · ഏറ്റവും മികച്ച തുടർച്ച കണ്ടെത്തുക|അവലോകനം ചെയ്ത സ്ഥിതി പുനഃസ്ഥാപിച്ചു|മികച്ച നീക്കം കണ്ടെത്തി.|നല്ല ശ്രമം.|എൻജിൻ {move} തിരഞ്ഞെടുത്തു.''',
    'mr':
        '''पुनरावलोकन केलेल्या चुकांचा सराव करा|पांढरा|काळा|तत्त्वानुसार|सुरुवात|मध्यखेळ|अंतिम खेळ|पुढील रेटेड खेळापूर्वी केंद्र नियंत्रणाचा एक धडा पूर्ण करा.|एक संथ खेळ खेळा आणि तीच विचारपद्धती वापरा.|ही चाल केंद्रावरील प्रभाव किंवा सोंगट्यांचा विकास सुधारते. राजाच्या सुरक्षिततेकडे लक्ष ठेवा.|प्रतिस्पर्ध्याचा धोका|प्रतिस्पर्ध्याचे त्वरित उत्तर|सर्वोत्तम पर्याय|इंजिनने सुचवलेला क्रम|समजले|पुन्हा प्रयत्न करा|पुनरावलोकनाकडे परत|चाल {move} पूर्वीची स्थिती|{side}ची चाल · सर्वोत्तम पुढील क्रम शोधा|पुनरावलोकित स्थिती पुनर्स्थापित केली|सर्वोत्तम चाल सापडली.|चांगला प्रयत्न.|इंजिनने {move} पसंत केली.''',
    'bn':
        '''পর্যালোচিত ভুলগুলো অনুশীলন করুন|সাদা|কালো|নীতিসম্মত|ওপেনিং|মধ্যখেলা|শেষখেলা|পরের রেটেড খেলার আগে কেন্দ্র নিয়ন্ত্রণের একটি পাঠ শেষ করুন।|একটি ধীরগতির খেলা খেলুন এবং একই চিন্তার পদ্ধতি প্রয়োগ করুন।|এই চাল কেন্দ্রের ওপর প্রভাব বা ঘুঁটির বিকাশ বাড়ায়। রাজার নিরাপত্তার দিকে নজর রাখুন।|প্রতিপক্ষের হুমকি|প্রতিপক্ষের তাৎক্ষণিক জবাব|সেরা বিকল্প|ইঞ্জিনের প্রস্তাবিত ধারাবাহিকতা|বুঝেছি|আবার চেষ্টা করুন|পর্যালোচনায় ফিরুন|{move} নম্বর চালের আগের অবস্থান|{side} চালবে · সবচেয়ে শক্তিশালী ধারাবাহিকতা খুঁজুন|পর্যালোচিত অবস্থান পুনরুদ্ধার হয়েছে|সেরা চাল পাওয়া গেছে।|ভালো চেষ্টা।|ইঞ্জিন {move} পছন্দ করেছে।''',
    'gu':
        '''સમીક્ષા કરેલી ભૂલોનો અભ્યાસ કરો|સફેદ|કાળો|સિદ્ધાંત અનુસાર|શરૂઆત|મધ્ય રમત|અંતિમ રમત|આગલી રેટેડ રમત પહેલાં કેન્દ્ર નિયંત્રણનો એક પાઠ પૂર્ણ કરો.|એક ધીમી રમત રમો અને એ જ વિચારવાની રીત અપનાવો.|આ ચાલ કેન્દ્ર પરનો પ્રભાવ અથવા મહોરાંનો વિકાસ સુધારે છે. રાજાની સુરક્ષા ધ્યાનમાં રાખો.|વિરોધીનો ખતરો|વિરોધીનો તાત્કાલિક જવાબ|શ્રેષ્ઠ વિકલ્પ|એન્જિન સૂચવેલો ક્રમ|સમજાયું|ફરી પ્રયાસ કરો|સમીક્ષા પર પાછા જાઓ|ચાલ {move} પહેલાંની સ્થિતિ|{side}ની ચાલ · શ્રેષ્ઠ આગળનો ક્રમ શોધો|સમીક્ષા કરેલી સ્થિતિ પુનઃસ્થાપિત થઈ|શ્રેષ્ઠ ચાલ મળી.|સારો પ્રયાસ.|એન્જિને {move} પસંદ કરી.''',
    'pa':
        '''ਸਮੀਖਿਆ ਕੀਤੀਆਂ ਗਲਤੀਆਂ ਦਾ ਅਭਿਆਸ ਕਰੋ|ਚਿੱਟਾ|ਕਾਲਾ|ਸਿਧਾਂਤਕ|ਸ਼ੁਰੂਆਤ|ਵਿਚਕਾਰਲੀ ਖੇਡ|ਅੰਤਲੀ ਖੇਡ|ਅਗਲੀ ਰੇਟਿੰਗ ਵਾਲੀ ਖੇਡ ਤੋਂ ਪਹਿਲਾਂ ਕੇਂਦਰ ਨਿਯੰਤਰਣ ਦਾ ਇੱਕ ਪਾਠ ਪੂਰਾ ਕਰੋ।|ਇੱਕ ਹੌਲੀ ਖੇਡ ਖੇਡੋ ਅਤੇ ਉਹੀ ਸੋਚਣ ਦਾ ਤਰੀਕਾ ਵਰਤੋ।|ਇਹ ਚਾਲ ਕੇਂਦਰ ਉੱਤੇ ਪ੍ਰਭਾਵ ਜਾਂ ਮੋਹਰਿਆਂ ਦੇ ਵਿਕਾਸ ਨੂੰ ਸੁਧਾਰਦੀ ਹੈ। ਰਾਜੇ ਦੀ ਸੁਰੱਖਿਆ ਦਾ ਧਿਆਨ ਰੱਖੋ।|ਵਿਰੋਧੀ ਦਾ ਖ਼ਤਰਾ|ਵਿਰੋਧੀ ਦਾ ਤੁਰੰਤ ਜਵਾਬ|ਸਭ ਤੋਂ ਵਧੀਆ ਵਿਕਲਪ|ਇੰਜਣ ਵੱਲੋਂ ਸੁਝਾਇਆ ਕ੍ਰਮ|ਸਮਝ ਆ ਗਈ|ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ|ਸਮੀਖਿਆ ਵੱਲ ਮੁੜੋ|ਚਾਲ {move} ਤੋਂ ਪਹਿਲਾਂ ਦੀ ਸਥਿਤੀ|{side} ਦੀ ਚਾਲ · ਸਭ ਤੋਂ ਮਜ਼ਬੂਤ ਅਗਲਾ ਕ੍ਰਮ ਲੱਭੋ|ਸਮੀਖਿਆ ਕੀਤੀ ਸਥਿਤੀ ਬਹਾਲ ਹੋਈ|ਸਭ ਤੋਂ ਵਧੀਆ ਚਾਲ ਮਿਲ ਗਈ।|ਵਧੀਆ ਕੋਸ਼ਿਸ਼।|ਇੰਜਣ ਨੇ {move} ਨੂੰ ਤਰਜੀਹ ਦਿੱਤੀ।''',
    'ur':
        '''جائزہ لی گئی غلطیوں کی مشق کریں|سفید|سیاہ|اصولی|ابتدائی کھیل|درمیانی کھیل|آخری کھیل|اگلے ریٹڈ کھیل سے پہلے مرکز پر قابو کا ایک سبق مکمل کریں۔|ایک سست رفتار کھیل کھیلیں اور سوچنے کا وہی طریقہ اپنائیں۔|یہ چال مرکز پر اثر یا مہروں کی ترقی بہتر کرتی ہے۔ بادشاہ کی حفاظت کو ذہن میں رکھیں۔|حریف کا خطرہ|حریف کا فوری جواب|بہترین متبادل|انجن کا تجویز کردہ تسلسل|سمجھ گیا|دوبارہ کوشش کریں|جائزے پر واپس جائیں|چال {move} سے پہلے کی پوزیشن|{side} کی چال · سب سے مضبوط تسلسل تلاش کریں|جائزہ لی گئی پوزیشن بحال ہوگئی|بہترین چال مل گئی۔|اچھی کوشش۔|انجن نے {move} کو ترجیح دی۔''',
    'ar':
        '''تدرّب على الأخطاء التي تمت مراجعتها|الأبيض|الأسود|نقلة مبدئية|الافتتاح|وسط اللعب|نهاية اللعب|أكمل درسًا عن السيطرة على المركز قبل المباراة المصنفة التالية.|العب مباراة أبطأ وطبّق طريقة التفكير نفسها.|تحسّن هذه النقلة التأثير في المركز أو تطوير القطع. انتبه إلى سلامة الملك.|تهديد الخصم|رد الخصم الفوري|أفضل بديل|التتابع المقترح من المحرك|فهمت|حاول مجددًا|العودة إلى المراجعة|الوضع قبل النقلة {move}|الدور لـ{side} · اعثر على أقوى تتابع|تمت استعادة الوضع الذي تمت مراجعته|تم العثور على أفضل نقلة.|محاولة جيدة.|فضّل المحرك {move}.''',
    'es':
        '''Practicar los errores revisados|Blancas|Negras|Conforme a los principios|Apertura|Medio juego|Final|Completa una lección sobre el control del centro antes de la próxima partida puntuada.|Juega una partida más lenta y aplica la misma rutina de pensamiento.|Esta jugada mejora la influencia central o el desarrollo. Ten en cuenta la seguridad del rey.|Amenaza rival|Respuesta inmediata del rival|Mejor alternativa|Continuación del motor|Entendido|Intentar de nuevo|Volver al análisis|Posición antes de la jugada {move}|Juegan {side} · Encuentra la continuación más fuerte|Posición analizada restaurada|Has encontrado la mejor jugada.|Buen intento.|El motor prefería {move}.''',
    'fr':
        '''Travailler les erreurs analysées|Blancs|Noirs|Respect des principes|Ouverture|Milieu de partie|Finale|Terminez une leçon sur le contrôle du centre avant la prochaine partie classée.|Jouez une partie plus lente et appliquez la même méthode de réflexion.|Ce coup améliore le contrôle du centre ou le développement. Gardez la sécurité du roi à l’esprit.|Menace adverse|Réponse adverse immédiate|Meilleure alternative|Suite du moteur|Compris|Réessayer|Retour à l’analyse|Position avant le coup {move}|Trait aux {side} · Trouvez la meilleure suite|Position analysée restaurée|Meilleur coup trouvé.|Bien essayé.|Le moteur préférait {move}.''',
    'de':
        '''Analysierte Fehler trainieren|Weiß|Schwarz|Prinzipientreu|Eröffnung|Mittelspiel|Endspiel|Schließe vor der nächsten gewerteten Partie eine Lektion zur Zentrumskontrolle ab.|Spiele eine langsamere Partie und wende dieselbe Denkroutine an.|Dieser Zug verbessert den Einfluss im Zentrum oder die Entwicklung. Behalte die Königssicherheit im Blick.|Gegnerische Drohung|Unmittelbare gegnerische Antwort|Beste Alternative|Engine-Fortsetzung|Verstanden|Erneut versuchen|Zurück zur Analyse|Stellung vor Zug {move}|{side} am Zug · Finde die stärkste Fortsetzung|Analysierte Stellung wiederhergestellt|Bester Zug gefunden.|Guter Versuch.|Die Engine bevorzugte {move}.''',
    'it':
        '''Allenati sugli errori analizzati|Bianco|Nero|Coerente con i principi|Apertura|Mediogioco|Finale|Completa una lezione sul controllo del centro prima della prossima partita classificata.|Gioca una partita più lenta e applica lo stesso metodo di ragionamento.|Questa mossa migliora il controllo del centro o lo sviluppo. Tieni presente la sicurezza del re.|Minaccia avversaria|Risposta immediata dell’avversario|Migliore alternativa|Continuazione del motore|Capito|Riprova|Torna all’analisi|Posizione prima della mossa {move}|Muove il {side} · Trova la continuazione più forte|Posizione analizzata ripristinata|Mossa migliore trovata.|Bel tentativo.|Il motore preferiva {move}.''',
    'pt':
        '''Treinar os erros analisados|Brancas|Pretas|De acordo com os princípios|Abertura|Meio-jogo|Final|Conclua uma lição sobre controlo do centro antes da próxima partida classificada.|Jogue uma partida mais lenta e aplique a mesma rotina de pensamento.|Este lance melhora a influência no centro ou o desenvolvimento. Tenha em conta a segurança do rei.|Ameaça adversária|Resposta imediata do adversário|Melhor alternativa|Continuação do motor|Entendido|Tentar novamente|Voltar à análise|Posição antes do lance {move}|Jogam as {side} · Encontre a continuação mais forte|Posição analisada restaurada|Melhor lance encontrado.|Boa tentativa.|O motor preferia {move}.''',
    'ru':
        '''Отработать разобранные ошибки|Белые|Чёрные|Принципиальный ход|Дебют|Миттельшпиль|Эндшпиль|Пройдите урок по контролю центра перед следующей рейтинговой партией.|Сыграйте партию с более медленным контролем и примените тот же порядок обдумывания.|Этот ход усиливает влияние в центре или развивает фигуры. Помните о безопасности короля.|Угроза соперника|Немедленный ответ соперника|Лучшая альтернатива|Продолжение движка|Понятно|Попробовать снова|Назад к разбору|Позиция перед ходом {move}|Ход: {side} · Найдите сильнейшее продолжение|Разобранная позиция восстановлена|Лучший ход найден.|Хорошая попытка.|Движок предпочитал {move}.''',
    'uk':
        '''Відпрацювати розібрані помилки|Білі|Чорні|Принциповий хід|Дебют|Мітельшпіль|Ендшпіль|Пройдіть урок із контролю центру перед наступною рейтинговою партією.|Зіграйте повільнішу партію та застосуйте той самий порядок обмірковування.|Цей хід посилює вплив у центрі або розвиває фігури. Пам’ятайте про безпеку короля.|Загроза суперника|Негайна відповідь суперника|Найкраща альтернатива|Продовження рушія|Зрозуміло|Спробувати знову|Назад до розбору|Позиція перед ходом {move}|Хід: {side} · Знайдіть найсильніше продовження|Розібрану позицію відновлено|Найкращий хід знайдено.|Гарна спроба.|Рушій віддавав перевагу {move}.''',
    'tr':
        '''İncelenen hataları çalış|Beyaz|Siyah|İlkelere uygun|Açılış|Oyun ortası|Oyun sonu|Sonraki puanlı oyundan önce merkez kontrolü üzerine bir ders tamamla.|Daha yavaş bir oyun oyna ve aynı düşünme yöntemini uygula.|Bu hamle merkez etkisini veya gelişimi artırır. Şah güvenliğini göz önünde bulundur.|Rakibin tehdidi|Rakibin hemen vereceği yanıt|En iyi alternatif|Motorun devam yolu|Anladım|Tekrar dene|İncelemeye dön|{move}. hamleden önceki konum|{side} oynar · En güçlü devam yolunu bul|İncelenen konum geri yüklendi|En iyi hamle bulundu.|İyi deneme.|Motor {move} hamlesini tercih etti.''',
    'fa':
        '''اشتباه‌های بررسی‌شده را تمرین کنید|سفید|سیاه|اصولی|شروع بازی|وسط بازی|آخر بازی|پیش از بازی ریتینگ‌دار بعدی یک درس کنترل مرکز را کامل کنید.|یک بازی آهسته‌تر انجام دهید و همان روش فکر کردن را به کار ببرید.|این حرکت نفوذ در مرکز یا گسترش مهره‌ها را بهتر می‌کند. امنیت شاه را در نظر بگیرید.|تهدید حریف|پاسخ فوری حریف|بهترین جایگزین|ادامهٔ پیشنهادی موتور|متوجه شدم|دوباره تلاش کنید|بازگشت به بررسی|وضعیت پیش از حرکت {move}|نوبت {side} · قوی‌ترین ادامه را پیدا کنید|وضعیت بررسی‌شده بازیابی شد|بهترین حرکت پیدا شد.|تلاش خوبی بود.|موتور {move} را ترجیح داد.''',
    'zh':
        '''练习已复盘的失误|白方|黑方|符合原则|开局|中局|残局|在下一盘等级分对局前，完成一节中心控制课程。|下一盘慢棋，并运用相同的思考流程。|这步棋增强了对中心的影响或促进了出子。请注意王的安全。|对手的威胁|对手的即时应对|最佳替代着法|引擎建议的续着|明白了|再试一次|返回复盘|第 {move} 步前的局面|{side}走棋 · 找出最强续着|已恢复复盘局面|找到了最佳着法。|不错的尝试。|引擎更推荐 {move}。''',
    'ja':
        '''振り返ったミスを練習する|白|黒|原則に沿った手|序盤|中盤|終盤|次のレーティング戦の前に、中央支配のレッスンを一つ終えましょう。|持ち時間の長い対局を一局指し、同じ思考手順を使いましょう。|この手は中央への影響力や駒の展開を改善します。キングの安全にも気を配りましょう。|相手の脅威|相手の直後の応手|最善の代案|エンジンの継続手順|了解|再挑戦|振り返りに戻る|{move}手目前の局面|{side}の手番 · 最強の継続手順を見つけよう|振り返りの局面を復元しました|最善手が見つかりました。|よい挑戦です。|エンジンは {move} を推奨しました。''',
    'ko':
        '''검토한 실수 연습|백|흑|원칙에 맞는 수|초반|중반|종반|다음 레이팅 경기 전에 중앙 통제 수업 하나를 완료하세요.|시간이 더 긴 경기를 한 판 두고 같은 사고 절차를 적용하세요.|이 수는 중앙 영향력이나 기물 전개를 개선합니다. 킹의 안전도 염두에 두세요.|상대의 위협|상대의 즉각적인 응수|최선의 대안|엔진의 후속 수순|알겠습니다|다시 시도|복기로 돌아가기|{move}번째 수 이전의 국면|{side} 차례 · 가장 강력한 후속 수순을 찾으세요|검토한 국면을 복원했습니다|최선의 수를 찾았습니다.|좋은 시도입니다.|엔진은 {move}을 선호했습니다.''',
    'id':
        '''Latih kesalahan yang ditinjau|Putih|Hitam|Sesuai prinsip|Pembukaan|Permainan tengah|Permainan akhir|Selesaikan satu pelajaran penguasaan pusat sebelum permainan berperingkat berikutnya.|Mainkan satu permainan yang lebih lambat dan terapkan pola berpikir yang sama.|Langkah ini meningkatkan pengaruh di pusat atau perkembangan buah. Perhatikan keamanan raja.|Ancaman lawan|Balasan langsung lawan|Alternatif terbaik|Kelanjutan mesin|Mengerti|Coba lagi|Kembali ke tinjauan|Posisi sebelum langkah {move}|Giliran {side} · Temukan kelanjutan terkuat|Posisi yang ditinjau dipulihkan|Langkah terbaik ditemukan.|Usaha bagus.|Mesin lebih memilih {move}.''',
    'ms':
        '''Latih kesilapan yang disemak|Putih|Hitam|Mengikut prinsip|Pembukaan|Pertengahan permainan|Akhir permainan|Lengkapkan satu pelajaran kawalan pusat sebelum permainan berkadar seterusnya.|Mainkan satu permainan lebih perlahan dan gunakan kaedah berfikir yang sama.|Langkah ini meningkatkan pengaruh di pusat atau perkembangan buah. Perhatikan keselamatan raja.|Ancaman lawan|Balasan segera lawan|Pilihan terbaik|Sambungan enjin|Faham|Cuba lagi|Kembali ke semakan|Kedudukan sebelum langkah {move}|Giliran {side} · Cari sambungan terkuat|Kedudukan yang disemak dipulihkan|Langkah terbaik ditemui.|Cubaan yang baik.|Enjin memilih {move}.''',
    'th':
        '''ฝึกแก้ข้อผิดพลาดที่ทบทวน|ฝ่ายขาว|ฝ่ายดำ|เดินตามหลักการ|ช่วงเปิดเกม|ช่วงกลางเกม|ช่วงท้ายเกม|เรียนเรื่องการควบคุมศูนย์กลางหนึ่งบทก่อนเกมจัดอันดับครั้งถัดไป|เล่นเกมที่มีเวลามากขึ้นหนึ่งเกมและใช้กระบวนการคิดแบบเดิม|ตานี้เพิ่มอิทธิพลในศูนย์กลางหรือพัฒนาตัวหมาก อย่าลืมความปลอดภัยของคิง|ภัยคุกคามจากคู่ต่อสู้|การตอบโต้ทันทีของคู่ต่อสู้|ทางเลือกที่ดีที่สุด|ลำดับเดินที่เอนจินแนะนำ|เข้าใจแล้ว|ลองอีกครั้ง|กลับไปทบทวน|ตำแหน่งก่อนตาที่ {move}|ตาเดินของ{side} · หาลำดับเดินที่แข็งแกร่งที่สุด|คืนค่าตำแหน่งที่ทบทวนแล้ว|พบตาเดินที่ดีที่สุดแล้ว|พยายามได้ดี|เอนจินเลือก {move}''',
    'vi':
        '''Luyện các sai lầm đã xem lại|Trắng|Đen|Đúng nguyên tắc|Khai cuộc|Trung cuộc|Tàn cuộc|Hoàn thành một bài học kiểm soát trung tâm trước ván đấu tính điểm tiếp theo.|Chơi một ván có thời gian dài hơn và áp dụng cùng quy trình suy nghĩ.|Nước đi này tăng ảnh hưởng ở trung tâm hoặc phát triển quân. Hãy chú ý an toàn của vua.|Đe dọa của đối thủ|Đáp trả tức thì của đối thủ|Phương án thay thế tốt nhất|Diễn biến máy đề xuất|Đã hiểu|Thử lại|Quay lại xem xét|Thế cờ trước nước {move}|Lượt {side} · Tìm diễn biến mạnh nhất|Đã khôi phục thế cờ được xem xét|Đã tìm ra nước đi tốt nhất.|Cố gắng tốt.|Máy ưu tiên {move}.''',
    'pl':
        '''Ćwicz przeanalizowane błędy|Białe|Czarne|Zgodny z zasadami|Debiut|Gra środkowa|Końcówka|Przed następną partią rankingową ukończ lekcję kontroli centrum.|Rozegraj jedną wolniejszą partię i zastosuj ten sam schemat myślenia.|Ten ruch poprawia wpływ na centrum lub rozwój figur. Pamiętaj o bezpieczeństwie króla.|Groźba przeciwnika|Natychmiastowa odpowiedź przeciwnika|Najlepsza alternatywa|Kontynuacja silnika|Rozumiem|Spróbuj ponownie|Wróć do analizy|Pozycja przed ruchem {move}|Ruch: {side} · Znajdź najsilniejszą kontynuację|Przywrócono analizowaną pozycję|Znaleziono najlepszy ruch.|Dobra próba.|Silnik wolał {move}.''',
    'nl':
        '''Oefen geanalyseerde fouten|Wit|Zwart|Volgens de principes|Opening|Middenspel|Eindspel|Voltooi vóór de volgende ratingpartij een les over centrumcontrole.|Speel een langzamere partij en pas dezelfde denkroutine toe.|Deze zet verbetert de invloed in het centrum of de ontwikkeling. Houd de veiligheid van de koning in de gaten.|Dreiging van de tegenstander|Direct antwoord van de tegenstander|Beste alternatief|Vervolg van de engine|Begrepen|Opnieuw proberen|Terug naar analyse|Stelling vóór zet {move}|{side} aan zet · Vind het sterkste vervolg|Geanalyseerde stelling hersteld|Beste zet gevonden.|Goede poging.|De engine gaf de voorkeur aan {move}.''',
    'sv':
        '''Träna på analyserade misstag|Vit|Svart|Principenligt|Öppning|Mittspel|Slutspel|Slutför en lektion om centrumkontroll före nästa rankade parti.|Spela ett långsammare parti och använd samma tankerutin.|Det här draget förbättrar inflytandet i centrum eller utvecklingen. Tänk på kungens säkerhet.|Motståndarens hot|Motståndarens omedelbara svar|Bästa alternativ|Motorns fortsättning|Jag förstår|Försök igen|Tillbaka till analysen|Ställning före drag {move}|{side} vid draget · Hitta den starkaste fortsättningen|Analyserad ställning återställd|Bästa draget hittat.|Bra försök.|Motorn föredrog {move}.''',
    'el':
        '''Εξασκήσου στα λάθη που αναλύθηκαν|Λευκά|Μαύρα|Σύμφωνη με τις αρχές|Άνοιγμα|Μέσο παιχνιδιού|Φινάλε|Ολοκλήρωσε ένα μάθημα ελέγχου του κέντρου πριν από την επόμενη βαθμολογημένη παρτίδα.|Παίξε μια πιο αργή παρτίδα και εφάρμοσε την ίδια διαδικασία σκέψης.|Αυτή η κίνηση βελτιώνει την επιρροή στο κέντρο ή την ανάπτυξη. Πρόσεχε την ασφάλεια του βασιλιά.|Απειλή αντιπάλου|Άμεση απάντηση αντιπάλου|Καλύτερη εναλλακτική|Συνέχεια της μηχανής|Κατάλαβα|Δοκίμασε ξανά|Επιστροφή στην ανάλυση|Θέση πριν από την κίνηση {move}|Παίζουν τα {side} · Βρες την ισχυρότερη συνέχεια|Η αναλυμένη θέση αποκαταστάθηκε|Βρέθηκε η καλύτερη κίνηση.|Καλή προσπάθεια.|Η μηχανή προτιμούσε {move}.''',
    'he':
        '''תרגול טעויות שנותחו|לבן|שחור|לפי העקרונות|פתיחה|מציעת המשחק|סיום|השלימו שיעור אחד בשליטה במרכז לפני המשחק המדורג הבא.|שחקו משחק איטי יותר ויישמו את אותה שגרת חשיבה.|המסע משפר את ההשפעה במרכז או את פיתוח הכלים. שימו לב לבטיחות המלך.|איום היריב|תגובה מיידית של היריב|החלופה הטובה ביותר|המשך המנוע|הבנתי|נסו שוב|חזרה לסקירה|העמדה לפני מסע {move}|תור {side} · מצאו את ההמשך החזק ביותר|העמדה שנותחה שוחזרה|נמצא המסע הטוב ביותר.|ניסיון טוב.|המנוע העדיף {move}.''',
    'sw':
        '''Fanyia mazoezi makosa yaliyopitiwa|Nyeupe|Nyeusi|Kwa kufuata kanuni|Ufunguzi|Mchezo wa kati|Mwisho wa mchezo|Kamilisha somo moja la udhibiti wa katikati kabla ya mchezo unaofuata wa ukadiriaji.|Cheza mchezo mmoja wa polepole zaidi na utumie utaratibu uleule wa kufikiri.|Hatua hii huongeza ushawishi katikati au ukuzaji wa kete. Zingatia usalama wa mfalme.|Tishio la mpinzani|Jibu la haraka la mpinzani|Mbadala bora|Mwendelezo wa injini|Nimeelewa|Jaribu tena|Rudi kwenye uchambuzi|Nafasi kabla ya hatua {move}|Zamu ya {side} · Tafuta mwendelezo wenye nguvu zaidi|Nafasi iliyochambuliwa imerejeshwa|Hatua bora imepatikana.|Jaribio zuri.|Injini ilipendelea {move}.''',
  };
}
