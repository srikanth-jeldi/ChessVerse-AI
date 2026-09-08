import 'app_language.dart';
import 'review_training_western_rows.dart';
import 'review_training_group_a.dart';
import 'review_training_group_b.dart';
import 'review_training_group_c.dart';

const reviewTrainingSources = <String>[
  'King safety: your engine-reviewed mistakes repeatedly exposed checks or mating threats. Secure the king before attacking.',
  'Piece safety: run a final opponent-captures scan before every move so loose pieces stop deciding your games.',
  'Endgame conversion: activate the king, improve the worst piece, and calculate pawn races before exchanging.',
  'Tactical vision: pause on every move and scan checks, captures, forks, and direct threats in order.',
  'Opening survival: develop pieces once, fight for the centre, and castle before starting an attack.',
  'Tactical vision: pause on every move and scan checks, captures, and threats in that order.',
  'Endgame conversion: activate the king, create a passed pawn, and simplify only into a winning ending.',
  'Calculation discipline: compare at least two candidate moves before choosing the most forcing line.',
  'Replay the first 10 moves and identify every repeated piece move.',
  'Train 5 positions where castling or meeting a check is urgent.',
  'Use a king-safety scan before starting any attack.',
  'Solve 5 loose-piece and overloaded-defender puzzles.',
  'After every candidate move, verify that each piece is defended.',
  'Practice king activation and one pawn race today.',
  'Replay the game from the first endgame mistake.',
  'Solve 5 puzzles using checks, captures, and threats in order.',
  'Retry the largest evaluation swing without a hint.',
  'Compare two candidate moves before every decision.',
  'Retry each reviewed mistake until solved twice.',
  'Maintain form with one slow game and a full review.',
  'King Safety • Castling safely',
  'Tactics • Hanging pieces',
  'Endgames • Promoting a pawn',
  'Tactics • Knight forks',
  'Tactics • Back-rank mates',
];

final Map<String, List<String>> reviewTrainingTranslations = {
  'en': reviewTrainingSources,
  for (final entry in reviewTrainingGroupB.entries)
    entry.key: entry.value.split('|'),
  for (final entry in reviewTrainingGroupA.entries)
    entry.key: entry.value.split('|'),
  for (final entry in reviewTrainingGroupC.entries)
    entry.key: entry.value.split('|'),
  for (final entry in reviewTrainingRows.entries)
    entry.key: entry.value.split('|'),
  for (final entry in reviewTrainingWesternRows.entries)
    entry.key: entry.value.split('|'),
};

bool supportsReviewTraining(String value) =>
    reviewTrainingSources.contains(value);

String localizeReviewTraining(String value, String code) {
  final index = reviewTrainingSources.indexOf(value);
  if (index < 0) return value;
  final locale = AppLanguageController.resolveCode(code);
  final row = reviewTrainingTranslations[locale];
  // A catalog completeness test must pass before this can be released.
  return row == null ? value : row[index];
}

const reviewTrainingRows = <String, String>{
  'te':
      '''రాజు భద్రత: ఇంజిన్ సమీక్షించిన మీ తప్పులు తరచూ చెక్స్ లేదా మేట్ ప్రమాదాలకు దారితీశాయి. దాడికి ముందు రాజును సురక్షితంగా ఉంచండి.|పావుల భద్రత: ప్రతి ఎత్తుకు ముందు ప్రత్యర్థి చేయగల క్యాప్చర్లను చివరిసారి పరిశీలించండి; రక్షణలేని పావులు మీ గేమ్ ఫలితాన్ని నిర్ణయించకుండా చూడండి.|ఎండ్‌గేమ్ గెలుపుగా మార్చడం: రాజును చురుకుగా చేయండి, బలహీనంగా ఉన్న పావును మెరుగుపరచండి, మార్పిడికి ముందు పాన్‌ల పరుగును లెక్కించండి.|టాక్టికల్ దృష్టి: ప్రతి ఎత్తు ముందు ఆగి చెక్స్, క్యాప్చర్లు, ఫోర్క్‌లు, ప్రత్యక్ష ప్రమాదాలను వరుసగా పరిశీలించండి.|ఓపెనింగ్ రక్షణ: పావులను ఒక్కసారి అభివృద్ధి చేయండి, కేంద్రం కోసం పోరాడండి, దాడికి ముందు క్యాస్లింగ్ చేయండి.|టాక్టికల్ దృష్టి: ప్రతి ఎత్తు ముందు ఆగి చెక్స్, క్యాప్చర్లు, ప్రమాదాలను ఆ క్రమంలో పరిశీలించండి.|ఎండ్‌గేమ్ గెలుపుగా మార్చడం: రాజును చురుకుగా చేయండి, పాస్డ్ పాన్ సృష్టించండి, గెలిచే ఎండ్‌గేమ్ వస్తేనే మార్పిడులతో సరళీకరించండి.|లెక్కింపు క్రమశిక్షణ: అత్యంత బలవంతపు కొనసాగింపును ఎంచుకునే ముందు కనీసం రెండు సాధ్యమైన ఎత్తులను పోల్చండి.|మొదటి 10 ఎత్తులను మళ్లీ ఆడి, ఒకే పావును మళ్లీ కదిలించిన ప్రతి సందర్భాన్ని గుర్తించండి.|క్యాస్లింగ్ లేదా చెక్‌కు సమాధానం అత్యవసరమైన 5 స్థితులను సాధన చేయండి.|ఏ దాడికైనా ముందు రాజు భద్రతను పరిశీలించండి.|రక్షణలేని పావులు, అధిక రక్షణ బాధ్యత ఉన్న పావులపై 5 పజిల్స్ పరిష్కరించండి.|ప్రతి సాధ్యమైన ఎత్తు తర్వాత అన్ని పావులకు రక్షణ ఉందో నిర్ధారించండి.|ఈ రోజు రాజును చురుకుగా చేయడం, ఒక పాన్ పరుగు సాధన చేయండి.|మొదటి ఎండ్‌గేమ్ తప్పు జరిగిన స్థితి నుంచి గేమ్‌ను మళ్లీ ఆడండి.|చెక్స్, క్యాప్చర్లు, ప్రమాదాలను వరుసగా పరిశీలిస్తూ 5 పజిల్స్ పరిష్కరించండి.|మూల్యాంకనంలో అతిపెద్ద మార్పు వచ్చిన స్థితిని సూచన లేకుండా మళ్లీ ప్రయత్నించండి.|ప్రతి నిర్ణయానికి ముందు రెండు సాధ్యమైన ఎత్తులను పోల్చండి.|సమీక్షించిన ప్రతి తప్పును రెండుసార్లు పరిష్కరించే వరకు మళ్లీ ప్రయత్నించండి.|ఒక నెమ్మది గేమ్, పూర్తి సమీక్షతో మీ ఆటస్థాయిని నిలబెట్టుకోండి.|రాజు భద్రత • సురక్షితంగా క్యాస్లింగ్|టాక్టిక్స్ • రక్షణలేని పావులు|ఎండ్‌గేమ్స్ • పాన్ ప్రమోషన్|టాక్టిక్స్ • నైట్ ఫోర్క్‌లు|టాక్టిక్స్ • చివరి వరుస మేట్‌లు''',
  'hi':
      '''राजा की सुरक्षा: इंजन द्वारा जाँची गई आपकी गलतियों से बार-बार चेक या मात के खतरे बने। हमला करने से पहले राजा को सुरक्षित करें।|मोहरों की सुरक्षा: हर चाल से पहले प्रतिद्वंद्वी के संभावित कैप्चर की अंतिम जाँच करें, ताकि असुरक्षित मोहरे आपके खेल का नतीजा तय न करें।|अंतिम खेल में जीत: राजा को सक्रिय करें, सबसे कमजोर मोहरे को सुधारें और अदला-बदली से पहले प्यादों की दौड़ की गणना करें।|सामरिक दृष्टि: हर चाल पर रुकें और क्रम से चेक, कैप्चर, फोर्क और सीधे खतरों की जाँच करें।|ओपनिंग में बचाव: मोहरों का एक बार विकास करें, केंद्र के लिए लड़ें और हमला शुरू करने से पहले कैसलिंग करें।|सामरिक दृष्टि: हर चाल पर रुकें और चेक, कैप्चर तथा खतरों की इसी क्रम में जाँच करें।|अंतिम खेल में जीत: राजा सक्रिय करें, पास्ड प्यादा बनाएँ और केवल जीतने वाले अंतिम खेल में ही स्थिति सरल करें।|गणना का अनुशासन: सबसे मजबूर करने वाला क्रम चुनने से पहले कम से कम दो संभावित चालों की तुलना करें।|पहली 10 चालें फिर खेलें और हर बार दोबारा चले गए मोहरे को पहचानें।|ऐसी 5 स्थितियों का अभ्यास करें जहाँ कैसलिंग या चेक का जवाब देना जरूरी है।|किसी भी हमले से पहले राजा की सुरक्षा जाँचें।|असुरक्षित मोहरों और अधिक भार वाले रक्षकों की 5 पहेलियाँ हल करें।|हर संभावित चाल के बाद जाँचें कि प्रत्येक मोहरा सुरक्षित है।|आज राजा को सक्रिय करने और प्यादों की एक दौड़ का अभ्यास करें।|अंतिम खेल की पहली गलती से खेल दोबारा खेलें।|क्रम से चेक, कैप्चर और खतरों का उपयोग करके 5 पहेलियाँ हल करें।|सबसे बड़े मूल्यांकन बदलाव वाली स्थिति बिना संकेत के फिर हल करें।|हर निर्णय से पहले दो संभावित चालों की तुलना करें।|हर समीक्षा की गई गलती को दो बार हल होने तक दोहराएँ।|एक धीमे खेल और पूर्ण समीक्षा से अपना खेल स्तर बनाए रखें।|राजा की सुरक्षा • सुरक्षित कैसलिंग|रणनीतिक चालें • असुरक्षित मोहरे|अंतिम खेल • प्यादे का प्रमोशन|रणनीतिक चालें • घोड़े के फोर्क|रणनीतिक चालें • अंतिम पंक्ति की मात''',
};
