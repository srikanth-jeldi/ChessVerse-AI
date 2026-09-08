import 'app_language.dart';

const analysisMetadataKeys = [
  'colour',
  'clock',
  'bullet',
  'blitz',
  'rapid',
  'classical',
  'win',
  'loss',
  'draw'
];
const Map<String, String> analysisMetadataRows = {
  'en': 'Colour|Time control|Bullet|Blitz|Rapid|Classical|Win|Loss|Draw',
  'te': 'రంగు|సమయ నియంత్రణ|బుల్లెట్|బ్లిట్జ్|రాపిడ్|క్లాసికల్|గెలుపు|ఓటమి|డ్రా',
  'hi': 'रंग|समय नियंत्रण|बुलेट|ब्लिट्ज़|रैपिड|क्लासिकल|जीत|हार|ड्रॉ',
  'ta':
      'நிறம்|நேரக் கட்டுப்பாடு|புல்லெட்|பிளிட்ஸ்|ரேபிட்|கிளாசிக்கல்|வெற்றி|தோல்வி|சமநிலை',
  'kn':
      'ಬಣ್ಣ|ಸಮಯ ನಿಯಂತ್ರಣ|ಬುಲೆಟ್|ಬ್ಲಿಟ್ಜ್|ರ‍್ಯಾಪಿಡ್|ಕ್ಲಾಸಿಕಲ್|ಗೆಲುವು|ಸೋಲು|ಡ್ರಾ',
  'ml':
      'നിറം|സമയ നിയന്ത്രണം|ബുള്ളറ്റ്|ബ്ലിറ്റ്സ്|റാപിഡ്|ക്ലാസിക്കൽ|ജയം|തോൽവി|സമനില',
  'mr': 'रंग|वेळ नियंत्रण|बुलेट|ब्लिट्झ|रॅपिड|क्लासिकल|विजय|पराभव|बरोबरी',
  'bn': 'রং|সময় নিয়ন্ত্রণ|বুলেট|ব্লিৎজ|র‍্যাপিড|ক্লাসিক্যাল|জয়|হার|ড্র',
  'gu': 'રંગ|સમય નિયંત્રણ|બુલેટ|બ્લિટ્ઝ|રેપિડ|ક્લાસિકલ|જીત|હાર|ડ્રો',
  'pa': 'ਰੰਗ|ਸਮਾਂ ਨਿਯੰਤਰਣ|ਬੁਲੇਟ|ਬਲਿਟਜ਼|ਰੈਪਿਡ|ਕਲਾਸੀਕਲ|ਜਿੱਤ|ਹਾਰ|ਬਰਾਬਰੀ',
  'ur': 'رنگ|وقت کی حد|بلٹ|بلٹز|ریپڈ|کلاسیکل|جیت|ہار|برابری',
  'ar': 'اللون|نظام الوقت|بوليت|خاطف|سريع|كلاسيكي|فوز|خسارة|تعادل',
  'he': 'צבע|קצב משחק|בולט|בזק|מהיר|קלאסי|ניצחון|הפסד|תיקו',
  'fa': 'رنگ|کنترل زمان|بولت|برق‌آسا|سریع|کلاسیک|برد|باخت|مساوی',
  'tr':
      'Renk|Zaman kontrolü|Kurşun|Yıldırım|Hızlı|Klasik|Galibiyet|Mağlubiyet|Beraberlik',
  'es':
      'Color|Control de tiempo|Bala|Relámpago|Rápidas|Clásicas|Victoria|Derrota|Tablas',
  'fr': 'Couleur|Cadence|Bullet|Blitz|Rapide|Classique|Victoire|Défaite|Nulle',
  'de':
      'Farbe|Bedenkzeit|Bullet|Blitz|Schnellschach|Klassisch|Sieg|Niederlage|Remis',
  'it': 'Colore|Cadenza|Bullet|Lampo|Rapido|Classico|Vittoria|Sconfitta|Patta',
  'pt': 'Cor|Ritmo|Bullet|Relâmpago|Rápido|Clássico|Vitória|Derrota|Empate',
  'ru': 'Цвет|Контроль времени|Пуля|Блиц|Рапид|Классика|Победа|Поражение|Ничья',
  'uk': 'Колір|Контроль часу|Куля|Бліц|Рапід|Класика|Перемога|Поразка|Нічия',
  'pl':
      'Kolor|Tempo gry|Bullet|Błyskawiczne|Szybkie|Klasyczne|Wygrana|Przegrana|Remis',
  'nl':
      'Kleur|Speeltempo|Bullet|Snelschaken|Rapid|Klassiek|Winst|Verlies|Remise',
  'sv': 'Färg|Betänketid|Bullet|Blixt|Snabbschack|Klassiskt|Vinst|Förlust|Remi',
  'el': 'Χρώμα|Χρόνος σκέψης|Μπούλετ|Μπλιτς|Ράπιντ|Κλασικό|Νίκη|Ήττα|Ισοπαλία',
  'zh': '颜色|用时规则|超快棋|闪电棋|快棋|慢棋|胜利|失败|和棋',
  'ja': '色|持ち時間|バレット|ブリッツ|ラピッド|クラシカル|勝利|敗北|引き分け',
  'ko': '색상|시간 규칙|불릿|블리츠|래피드|클래시컬|승리|패배|무승부',
  'id': 'Warna|Kontrol waktu|Peluru|Kilat|Cepat|Klasik|Menang|Kalah|Remis',
  'ms': 'Warna|Kawalan masa|Peluru|Kilat|Pantas|Klasik|Menang|Kalah|Seri',
  'th': 'สี|เวลาควบคุม|บุลเลต|บลิตซ์|แรพิด|คลาสสิก|ชนะ|แพ้|เสมอ',
  'vi':
      'Màu|Thời gian thi đấu|Cờ siêu chớp|Cờ chớp|Cờ nhanh|Cờ tiêu chuẩn|Thắng|Thua|Hòa',
  'sw':
      'Rangi|Udhibiti wa muda|Risasi|Umeme|Haraka|Kawaida|Ushindi|Kushindwa|Sare',
};

String localizeAnalysisMetadata(String value, String code) {
  final normalized = switch (value.trim().toLowerCase()) {
    'color' => 'colour',
    'time_control' || 'timecontrol' => 'clock',
    'won' || 'victory' || 'you win' => 'win',
    'lost' || 'defeat' || 'you lose' => 'loss',
    'drawn' => 'draw',
    final other => other,
  };
  final index = analysisMetadataKeys.indexOf(normalized);
  return index < 0
      ? value
      : analysisMetadataRows[AppLanguageController.resolveCode(code)]!
          .split('|')[index];
}
