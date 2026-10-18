/// Result messages and bundled puzzle titles for every supported language.
const gameFeedbackKeys = ['saved', 'retry', 'easy', 'medium', 'hard'];
const gameFeedbackTranslations = <String, List<String>>{
  'en': [
    'Saved locally. Open Saved Games to review this match.',
    'This attempt is not counted as a loss. Review the position and retry today.',
    'Easy puzzle',
    'Medium puzzle',
    'Hard puzzle',
  ],
  'te': [
    'ఈ పరికరంలో సేవ్ అయింది. ఈ ఆటను సమీక్షించడానికి సేవ్ చేసిన ఆటలను తెరవండి.',
    'ఈ ప్రయత్నాన్ని ఓటమిగా లెక్కించము. స్థానాన్ని సమీక్షించి ఈరోజు మళ్లీ ప్రయత్నించండి.',
    'సులభమైన పజిల్',
    'మధ్యస్థ పజిల్',
    'కఠినమైన పజిల్',
  ],
  'hi': [
    'इस डिवाइस पर सहेजा गया। इस मैच की समीक्षा के लिए सहेजे गए खेल खोलें।',
    'इस प्रयास को हार नहीं माना जाएगा। स्थिति की समीक्षा करें और आज फिर कोशिश करें।',
    'आसान पहेली',
    'मध्यम पहेली',
    'कठिन पहेली',
  ],
  'ta': [
    'இந்தச் சாதனத்தில் சேமிக்கப்பட்டது. இந்த ஆட்டத்தை ஆய்வு செய்ய சேமித்த ஆட்டங்களைத் திறக்கவும்.',
    'இந்த முயற்சி தோல்வியாகக் கணக்கிடப்படாது. நிலையை ஆய்வு செய்து இன்று மீண்டும் முயலவும்.',
    'எளிய புதிர்',
    'நடுத்தரப் புதிர்',
    'கடினமான புதிர்',
  ],
  'kn': [
    'ಈ ಸಾಧನದಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ. ಈ ಆಟವನ್ನು ಪರಿಶೀಲಿಸಲು ಉಳಿಸಿದ ಆಟಗಳನ್ನು ತೆರೆಯಿರಿ.',
    'ಈ ಪ್ರಯತ್ನವನ್ನು ಸೋಲು ಎಂದು ಪರಿಗಣಿಸುವುದಿಲ್ಲ. ಸ್ಥಾನವನ್ನು ಪರಿಶೀಲಿಸಿ ಇಂದು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    'ಸುಲಭ ಒಗಟು',
    'ಮಧ್ಯಮ ಒಗಟು',
    'ಕಠಿಣ ಒಗಟು',
  ],
  'ml': [
    'ഈ ഉപകരണത്തിൽ സംരക്ഷിച്ചു. ഈ കളി അവലോകനം ചെയ്യാൻ സംരക്ഷിച്ച കളികൾ തുറക്കുക.',
    'ഈ ശ്രമം തോൽവിയായി കണക്കാക്കില്ല. സ്ഥിതി വിലയിരുത്തി ഇന്ന് വീണ്ടും ശ്രമിക്കുക.',
    'എളുപ്പമുള്ള പസിൽ',
    'ഇടത്തരം പസിൽ',
    'കഠിനമായ പസിൽ',
  ],
  'mr': [
    'या डिव्हाइसवर जतन केले. या खेळाचे पुनरावलोकन करण्यासाठी जतन केलेले खेळ उघडा.',
    'हा प्रयत्न पराभव म्हणून मोजला जाणार नाही. स्थिती तपासा आणि आज पुन्हा प्रयत्न करा.',
    'सोपी कोडी',
    'मध्यम कोडी',
    'अवघड कोडी',
  ],
  'bn': [
    'এই ডিভাইসে সংরক্ষিত হয়েছে। এই খেলা পর্যালোচনা করতে সংরক্ষিত খেলাগুলি খুলুন।',
    'এই প্রচেষ্টা হার হিসেবে গণনা হবে না। অবস্থান পর্যালোচনা করে আজ আবার চেষ্টা করুন।',
    'সহজ ধাঁধা',
    'মাঝারি ধাঁধা',
    'কঠিন ধাঁধা',
  ],
  'gu': [
    'આ ઉપકરણ પર સાચવ્યું. આ રમતની સમીક્ષા કરવા સાચવેલી રમતો ખોલો.',
    'આ પ્રયાસને હાર તરીકે ગણવામાં નહીં આવે. સ્થિતિની સમીક્ષા કરીને આજે ફરી પ્રયાસ કરો.',
    'સરળ કોયડો',
    'મધ્યમ કોયડો',
    'અઘરો કોયડો',
  ],
  'pa': [
    'ਇਸ ਡਿਵਾਈਸ ਉੱਤੇ ਸੰਭਾਲਿਆ ਗਿਆ। ਇਸ ਖੇਡ ਦੀ ਸਮੀਖਿਆ ਲਈ ਸੰਭਾਲੀਆਂ ਖੇਡਾਂ ਖੋਲ੍ਹੋ।',
    'ਇਸ ਕੋਸ਼ਿਸ਼ ਨੂੰ ਹਾਰ ਨਹੀਂ ਗਿਣਿਆ ਜਾਵੇਗਾ। ਸਥਿਤੀ ਦੀ ਸਮੀਖਿਆ ਕਰਕੇ ਅੱਜ ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
    'ਸੌਖੀ ਬੁਝਾਰਤ',
    'ਦਰਮਿਆਨੀ ਬੁਝਾਰਤ',
    'ਔਖੀ ਬੁਝਾਰਤ',
  ],
  'ur': [
    'اس آلے پر محفوظ ہو گیا۔ اس کھیل کا جائزہ لینے کے لیے محفوظ کھیل کھولیں۔',
    'یہ کوشش شکست شمار نہیں ہوگی۔ پوزیشن کا جائزہ لیں اور آج دوبارہ کوشش کریں۔',
    'آسان پہیلی',
    'درمیانی پہیلی',
    'مشکل پہیلی',
  ],
  'ar': [
    'تم الحفظ على هذا الجهاز. افتح المباريات المحفوظة لمراجعة هذه المباراة.',
    'لا تُحتسب هذه المحاولة خسارة. راجع الوضع وحاول مجددًا اليوم.',
    'لغز سهل',
    'لغز متوسط',
    'لغز صعب',
  ],
  'es': [
    'Guardado en este dispositivo. Abre las partidas guardadas para revisar esta partida.',
    'Este intento no cuenta como derrota. Revisa la posición y vuelve a intentarlo hoy.',
    'Problema fácil',
    'Problema intermedio',
    'Problema difícil',
  ],
  'fr': [
    'Enregistré sur cet appareil. Ouvrez les parties enregistrées pour analyser cette partie.',
    'Cet essai ne compte pas comme une défaite. Analysez la position et réessayez aujourd’hui.',
    'Problème facile',
    'Problème intermédiaire',
    'Problème difficile',
  ],
  'de': [
    'Auf diesem Gerät gespeichert. Öffne die gespeicherten Partien, um diese Partie zu analysieren.',
    'Dieser Versuch zählt nicht als Niederlage. Analysiere die Stellung und versuche es heute erneut.',
    'Leichtes Rätsel',
    'Mittelschweres Rätsel',
    'Schweres Rätsel',
  ],
  'it': [
    'Salvata su questo dispositivo. Apri le partite salvate per analizzare questa partita.',
    'Questo tentativo non conta come sconfitta. Analizza la posizione e riprova oggi.',
    'Problema facile',
    'Problema intermedio',
    'Problema difficile',
  ],
  'pt': [
    'Salvo neste dispositivo. Abra as partidas salvas para analisar esta partida.',
    'Esta tentativa não conta como derrota. Analise a posição e tente novamente hoje.',
    'Problema fácil',
    'Problema intermediário',
    'Problema difícil',
  ],
  'ru': [
    'Сохранено на этом устройстве. Откройте сохранённые партии для анализа этой партии.',
    'Эта попытка не считается поражением. Проанализируйте позицию и попробуйте ещё раз сегодня.',
    'Лёгкая задача',
    'Средняя задача',
    'Сложная задача',
  ],
  'uk': [
    'Збережено на цьому пристрої. Відкрийте збережені партії для аналізу цієї партії.',
    'Ця спроба не вважається поразкою. Проаналізуйте позицію та спробуйте ще раз сьогодні.',
    'Легка задача',
    'Середня задача',
    'Складна задача',
  ],
  'tr': [
    'Bu cihaza kaydedildi. Bu oyunu incelemek için kayıtlı oyunları açın.',
    'Bu deneme yenilgi sayılmaz. Konumu inceleyin ve bugün tekrar deneyin.',
    'Kolay bulmaca',
    'Orta bulmaca',
    'Zor bulmaca',
  ],
  'fa': [
    'در این دستگاه ذخیره شد. برای بررسی این بازی، بازی‌های ذخیره‌شده را باز کنید.',
    'این تلاش باخت محسوب نمی‌شود. وضعیت را بررسی کنید و امروز دوباره تلاش کنید.',
    'معمای آسان',
    'معمای متوسط',
    'معمای دشوار',
  ],
  'zh': [
    '已保存在此设备上。打开已保存的对局以复盘本局。',
    '本次尝试不计为失败。复盘局面，今天再试一次。',
    '简单棋题',
    '中等棋题',
    '困难棋题',
  ],
  'ja': [
    'この端末に保存しました。保存済みの対局を開いて、この対局を振り返りましょう。',
    'この挑戦は負けに数えられません。局面を確認して、今日もう一度挑戦しましょう。',
    '初級パズル',
    '中級パズル',
    '上級パズル',
  ],
  'ko': [
    '이 기기에 저장했습니다. 저장된 대국을 열어 이 대국을 복기하세요.',
    '이번 시도는 패배로 기록되지 않습니다. 포지션을 검토하고 오늘 다시 도전하세요.',
    '쉬운 퍼즐',
    '중간 퍼즐',
    '어려운 퍼즐',
  ],
  'id': [
    'Disimpan di perangkat ini. Buka permainan tersimpan untuk meninjau permainan ini.',
    'Percobaan ini tidak dihitung sebagai kekalahan. Tinjau posisi dan coba lagi hari ini.',
    'Teka-teki mudah',
    'Teka-teki sedang',
    'Teka-teki sulit',
  ],
  'ms': [
    'Disimpan pada peranti ini. Buka permainan tersimpan untuk menyemak permainan ini.',
    'Percubaan ini tidak dikira sebagai kekalahan. Semak kedudukan dan cuba lagi hari ini.',
    'Teka-teki mudah',
    'Teka-teki sederhana',
    'Teka-teki sukar',
  ],
  'th': [
    'บันทึกไว้ในอุปกรณ์นี้แล้ว เปิดเกมที่บันทึกไว้เพื่อทบทวนเกมนี้',
    'ความพยายามนี้ไม่นับเป็นการแพ้ ทบทวนตำแหน่งแล้วลองใหม่วันนี้',
    'ปริศนาง่าย',
    'ปริศนาปานกลาง',
    'ปริศนายาก',
  ],
  'vi': [
    'Đã lưu trên thiết bị này. Mở các ván đã lưu để xem lại ván này.',
    'Lần thử này không tính là thua. Xem lại thế cờ và thử lại hôm nay.',
    'Câu đố dễ',
    'Câu đố trung bình',
    'Câu đố khó',
  ],
  'pl': [
    'Zapisano na tym urządzeniu. Otwórz zapisane partie, aby przeanalizować tę partię.',
    'Ta próba nie liczy się jako przegrana. Przeanalizuj pozycję i spróbuj ponownie dzisiaj.',
    'Łatwa zagadka',
    'Średnia zagadka',
    'Trudna zagadka',
  ],
  'nl': [
    'Op dit apparaat opgeslagen. Open opgeslagen partijen om deze partij te analyseren.',
    'Deze poging telt niet als verlies. Analyseer de stelling en probeer het vandaag opnieuw.',
    'Makkelijke puzzel',
    'Gemiddelde puzzel',
    'Moeilijke puzzel',
  ],
  'sv': [
    'Sparat på den här enheten. Öppna sparade partier för att analysera det här partiet.',
    'Det här försöket räknas inte som en förlust. Analysera ställningen och försök igen idag.',
    'Lätt pussel',
    'Medelsvårt pussel',
    'Svårt pussel',
  ],
  'el': [
    'Αποθηκεύτηκε σε αυτή τη συσκευή. Ανοίξτε τις αποθηκευμένες παρτίδες για να αναλύσετε αυτή την παρτίδα.',
    'Αυτή η προσπάθεια δεν μετρά ως ήττα. Αναλύστε τη θέση και δοκιμάστε ξανά σήμερα.',
    'Εύκολος γρίφος',
    'Μέτριος γρίφος',
    'Δύσκολος γρίφος',
  ],
  'he': [
    'נשמר במכשיר הזה. פתחו את המשחקים השמורים כדי לנתח את המשחק הזה.',
    'הניסיון הזה לא נחשב להפסד. בדקו את העמדה ונסו שוב היום.',
    'חידה קלה',
    'חידה בינונית',
    'חידה קשה',
  ],
  'sw': [
    'Imehifadhiwa kwenye kifaa hiki. Fungua michezo iliyohifadhiwa ili kuchambua mchezo huu.',
    'Jaribio hili halihesabiwi kama kushindwa. Chunguza nafasi na ujaribu tena leo.',
    'Fumbo rahisi',
    'Fumbo la wastani',
    'Fumbo gumu',
  ],
};
String gameFeedbackText(String key, String language) {
  final index = gameFeedbackKeys.indexOf(key);
  if (index < 0) return key;
  return (gameFeedbackTranslations[language] ??
      gameFeedbackTranslations['en']!)[index];
}

String localizedPuzzleTitle(String title, String language) {
  final match = RegExp(r'^(Easy|Medium|Hard) Puzzle (\d+)$').firstMatch(title);
  if (match == null || language == 'en') return title;
  return '${gameFeedbackText(match[1]!.toLowerCase(), language)} ${match[2]}';
}
