import 'app_language.dart';

const mistakeLessonKeys = [
  'context',
  'played',
  'goal',
  'analysis',
  'missing',
  'better',
  'complete',
  'nextReview',
];
final mistakeLessonTranslations = {
  for (final entry in _rows.entries) entry.key: entry.value.split('|'),
};
String mistakeLessonText(
  String key,
  String language, [
  Map<String, String> values = const {},
]) {
  final index = mistakeLessonKeys.indexOf(key);
  if (index < 0) throw ArgumentError.value(key, 'key');
  var text =
      mistakeLessonTranslations[AppLanguageController.resolveCode(
        language,
      )]![index];
  for (final entry in values.entries) {
    text = text.replaceAll('{${entry.key}}', entry.value);
  }
  return text;
}

const _rows = <String, String>{
  'en': '''Your game · move {move}|You played: {move}|Goal: {focus}. Find a stronger continuation.|Saved analysis|No detailed explanation was saved for this position.|Stronger move: {move}|Exercise complete. You practised the stronger continuation; this does not mean the game is won.|Practise again on {date}''',
  'te': '''మీ ఆట · {move}వ ఎత్తు|అప్పుడు మీరు వేసిన ఎత్తు: {move}|లక్ష్యం: {focus}. మెరుగైన ఎత్తును కనుగొనండి.|సేవ్ అయిన విశ్లేషణ|ఈ స్థానానికి వివరణాత్మక కారణం సేవ్ కాలేదు.|మెరుగైన ఎత్తు: {move}|సాధన పూర్తయింది. మెరుగైన కొనసాగింపును సాధన చేశారు; ఆట గెలిచినట్లు కాదు.|మళ్లీ సాధన చేయాల్సిన తేదీ: {date}''',
  'hi': '''आपका खेल · चाल {move}|आपने खेला था: {move}|लक्ष्य: {focus}। बेहतर चाल खोजें।|सहेजा गया विश्लेषण|इस स्थिति की विस्तृत व्याख्या सहेजी नहीं गई थी।|बेहतर चाल: {move}|अभ्यास पूरा हुआ। आपने बेहतर चाल-क्रम का अभ्यास किया; इसका मतलब खेल जीतना नहीं है।|फिर अभ्यास करें: {date}''',
  'ta': '''உங்கள் ஆட்டம் · நகர்வு {move}|நீங்கள் விளையாடிய நகர்வு: {move}|இலக்கு: {focus}. சிறந்த தொடர்ச்சியைக் கண்டறியுங்கள்.|சேமித்த பகுப்பாய்வு|இந்த நிலைக்கான விரிவான விளக்கம் சேமிக்கப்படவில்லை.|சிறந்த நகர்வு: {move}|பயிற்சி முடிந்தது. சிறந்த தொடர்ச்சியைப் பயிற்சி செய்தீர்கள்; இது ஆட்டத்தில் வென்றதாகாது.|மீண்டும் பயிற்சி செய்யும் தேதி: {date}''',
  'kn': '''ನಿಮ್ಮ ಆಟ · ನಡೆ {move}|ನೀವು ಆಡಿದ ನಡೆ: {move}|ಗುರಿ: {focus}. ಉತ್ತಮ ಮುಂದುವರಿಕೆಯನ್ನು ಕಂಡುಕೊಳ್ಳಿ.|ಉಳಿಸಿದ ವಿಶ್ಲೇಷಣೆ|ಈ ಸ್ಥಿತಿಗೆ ವಿವರವಾದ ವಿವರಣೆಯನ್ನು ಉಳಿಸಲಾಗಿಲ್ಲ.|ಉತ್ತಮ ನಡೆ: {move}|ಅಭ್ಯಾಸ ಪೂರ್ಣಗೊಂಡಿದೆ. ಉತ್ತಮ ಮುಂದುವರಿಕೆಯನ್ನು ಅಭ್ಯಾಸ ಮಾಡಿದ್ದೀರಿ; ಆಟ ಗೆದ್ದಿದ್ದೀರಿ ಎಂದಲ್ಲ.|ಮತ್ತೆ ಅಭ್ಯಾಸ ಮಾಡುವ ದಿನ: {date}''',
  'ml': '''നിങ്ങളുടെ കളി · നീക്കം {move}|നിങ്ങൾ കളിച്ച നീക്കം: {move}|ലക്ഷ്യം: {focus}. മികച്ച തുടർച്ച കണ്ടെത്തുക.|സൂക്ഷിച്ച വിശകലനം|ഈ സ്ഥാനത്തിന്റെ വിശദമായ കാരണം സൂക്ഷിച്ചിട്ടില്ല.|മികച്ച നീക്കം: {move}|പരിശീലനം പൂർത്തിയായി. മികച്ച തുടർച്ച പരിശീലിച്ചു; കളി ജയിച്ചു എന്നല്ല.|വീണ്ടും പരിശീലിക്കേണ്ട തീയതി: {date}''',
  'mr': '''तुमचा खेळ · चाल {move}|तुम्ही खेळलेली चाल: {move}|ध्येय: {focus}. अधिक चांगली चाल शोधा.|जतन केलेले विश्लेषण|या स्थितीसाठी तपशीलवार स्पष्टीकरण जतन केलेले नाही.|अधिक चांगली चाल: {move}|सराव पूर्ण झाला. तुम्ही अधिक चांगल्या चाल-क्रमाचा सराव केला; याचा अर्थ खेळ जिंकला असा नाही.|पुन्हा सरावाची तारीख: {date}''',
  'bn': '''আপনার খেলা · চাল {move}|আপনি খেলেছিলেন: {move}|লক্ষ্য: {focus}। আরও ভালো চাল খুঁজুন।|সংরক্ষিত বিশ্লেষণ|এই অবস্থানের বিস্তারিত ব্যাখ্যা সংরক্ষিত নেই।|আরও ভালো চাল: {move}|অনুশীলন শেষ। আপনি আরও ভালো চালের ধারাবাহিকতা অনুশীলন করেছেন; এর অর্থ খেলায় জয় নয়।|আবার অনুশীলনের তারিখ: {date}''',
  'gu': '''તમારી રમત · ચાલ {move}|તમે રમેલી ચાલ: {move}|લક્ષ્ય: {focus}. વધુ સારી ચાલ શોધો.|સાચવેલું વિશ્લેષણ|આ સ્થિતિનું વિગતવાર કારણ સાચવેલું નથી.|વધુ સારી ચાલ: {move}|અભ્યાસ પૂર્ણ થયો. તમે વધુ સારા ચાલક્રમનો અભ્યાસ કર્યો; તેનો અર્થ રમત જીત્યા એવો નથી.|ફરી અભ્યાસની તારીખ: {date}''',
  'pa': '''ਤੁਹਾਡੀ ਖੇਡ · ਚਾਲ {move}|ਤੁਸੀਂ ਖੇਡਿਆ ਸੀ: {move}|ਟੀਚਾ: {focus}। ਬਿਹਤਰ ਚਾਲ ਲੱਭੋ।|ਸੰਭਾਲਿਆ ਵਿਸ਼ਲੇਸ਼ਣ|ਇਸ ਸਥਿਤੀ ਦੀ ਵਿਸਤ੍ਰਿਤ ਵਿਆਖਿਆ ਸੰਭਾਲੀ ਨਹੀਂ ਗਈ।|ਬਿਹਤਰ ਚਾਲ: {move}|ਅਭਿਆਸ ਪੂਰਾ ਹੋਇਆ। ਤੁਸੀਂ ਬਿਹਤਰ ਚਾਲ-ਕ੍ਰਮ ਦਾ ਅਭਿਆਸ ਕੀਤਾ; ਇਸਦਾ ਮਤਲਬ ਖੇਡ ਜਿੱਤਣਾ ਨਹੀਂ ਹੈ।|ਮੁੜ ਅਭਿਆਸ ਦੀ ਤਾਰੀਖ: {date}''',
  'ur': '''آپ کا کھیل · چال {move}|آپ نے کھیلا تھا: {move}|مقصد: {focus}۔ بہتر چال تلاش کریں۔|محفوظ تجزیہ|اس پوزیشن کی تفصیلی وضاحت محفوظ نہیں کی گئی۔|بہتر چال: {move}|مشق مکمل ہوئی۔ آپ نے بہتر سلسلے کی مشق کی؛ اس کا مطلب کھیل جیتنا نہیں ہے۔|دوبارہ مشق کی تاریخ: {date}''',
  'ar': '''مباراتك · النقلة {move}|لعبت سابقًا: {move}|الهدف: {focus}. ابحث عن متابعة أقوى.|التحليل المحفوظ|لم يُحفظ شرح مفصّل لهذا الوضع.|النقلة الأقوى: {move}|اكتمل التمرين. تدرّبت على التتابع الأقوى؛ هذا لا يعني الفوز بالمباراة.|تدرّب مجددًا في {date}''',
  'es': '''Tu partida · jugada {move}|Jugaste: {move}|Objetivo: {focus}. Encuentra una continuación mejor.|Análisis guardado|No se guardó una explicación detallada de esta posición.|Jugada más fuerte: {move}|Ejercicio completado. Practicaste la continuación más fuerte; esto no significa que hayas ganado la partida.|Vuelve a practicar el {date}''',
  'fr': '''Votre partie · coup {move}|Vous aviez joué : {move}|Objectif : {focus}. Trouvez une meilleure suite.|Analyse enregistrée|Aucune explication détaillée n’a été enregistrée pour cette position.|Meilleur coup : {move}|Exercice terminé. Vous avez travaillé la meilleure suite ; cela ne signifie pas que la partie est gagnée.|À retravailler le {date}''',
  'de': '''Deine Partie · Zug {move}|Du hast gespielt: {move}|Ziel: {focus}. Finde eine stärkere Fortsetzung.|Gespeicherte Analyse|Für diese Stellung wurde keine ausführliche Erklärung gespeichert.|Stärkerer Zug: {move}|Übung abgeschlossen. Du hast die stärkere Fortsetzung geübt; das bedeutet keinen Partiegewinn.|Erneut üben am {date}''',
  'it': '''La tua partita · mossa {move}|Avevi giocato: {move}|Obiettivo: {focus}. Trova una continuazione migliore.|Analisi salvata|Non è stata salvata una spiegazione dettagliata di questa posizione.|Mossa più forte: {move}|Esercizio completato. Hai praticato la continuazione più forte; questo non significa aver vinto la partita.|Ripassa il {date}''',
  'pt': '''Sua partida · lance {move}|Você jogou: {move}|Objetivo: {focus}. Encontre uma continuação melhor.|Análise salva|Não foi salva uma explicação detalhada desta posição.|Lance mais forte: {move}|Exercício concluído. Você praticou a continuação mais forte; isso não significa que venceu a partida.|Pratique novamente em {date}''',
  'ru': '''Ваша партия · ход {move}|Вы сыграли: {move}|Цель: {focus}. Найдите более сильное продолжение.|Сохранённый анализ|Подробное объяснение этой позиции не было сохранено.|Более сильный ход: {move}|Упражнение завершено. Вы отработали более сильное продолжение; это не означает победу в партии.|Повторите {date}''',
  'uk': '''Ваша партія · хід {move}|Ви зіграли: {move}|Мета: {focus}. Знайдіть сильніше продовження.|Збережений аналіз|Докладне пояснення цієї позиції не було збережено.|Сильніший хід: {move}|Вправу завершено. Ви відпрацювали сильніше продовження; це не означає перемогу в партії.|Повторіть {date}''',
  'tr': '''Oyunun · hamle {move}|Oynadığın hamle: {move}|Hedef: {focus}. Daha güçlü bir devam yolu bul.|Kayıtlı analiz|Bu konum için ayrıntılı bir açıklama kaydedilmemiş.|Daha güçlü hamle: {move}|Alıştırma tamamlandı. Daha güçlü devam yolunu çalıştın; bu, oyunu kazandığın anlamına gelmez.|Tekrar çalış: {date}''',
  'fa': '''بازی شما · حرکت {move}|شما بازی کردید: {move}|هدف: {focus}. ادامهٔ قوی‌تری پیدا کنید.|تحلیل ذخیره‌شده|توضیح مفصلی برای این وضعیت ذخیره نشده است.|حرکت قوی‌تر: {move}|تمرین تمام شد. ادامهٔ قوی‌تر را تمرین کردید؛ این به معنی بردن بازی نیست.|تمرین دوباره در {date}''',
  'zh': '''你的棋局 · 第{move}步|你当时走了：{move}|目标：{focus}。找出更强的后续走法。|已保存的分析|此局面未保存详细解释。|更强的走法：{move}|练习完成。你练习了更强的后续走法；这不代表赢得了棋局。|下次练习日期：{date}''',
  'ja': '''あなたの対局 · {move}手目|実戦で指した手：{move}|目標：{focus}。より良い手順を見つけましょう。|保存された分析|この局面の詳しい説明は保存されていません。|より良い手：{move}|練習完了。より良い手順を練習しました。対局に勝ったという意味ではありません。|次の復習日：{date}''',
  'ko': '''내 대국 · {move}번째 수|실전에서 둔 수: {move}|목표: {focus}. 더 나은 진행을 찾으세요.|저장된 분석|이 포지션의 자세한 설명이 저장되지 않았습니다.|더 나은 수: {move}|연습 완료. 더 나은 진행을 연습했습니다. 대국에서 이겼다는 뜻은 아닙니다.|다음 복습일: {date}''',
  'id': '''Permainanmu · langkah {move}|Kamu memainkan: {move}|Tujuan: {focus}. Temukan kelanjutan yang lebih kuat.|Analisis tersimpan|Tidak ada penjelasan terperinci yang tersimpan untuk posisi ini.|Langkah lebih kuat: {move}|Latihan selesai. Kamu telah melatih kelanjutan yang lebih kuat; ini bukan berarti memenangkan permainan.|Latih lagi pada {date}''',
  'ms': '''Permainan anda · langkah {move}|Anda telah bermain: {move}|Matlamat: {focus}. Cari kesinambungan yang lebih kuat.|Analisis tersimpan|Tiada penjelasan terperinci disimpan untuk kedudukan ini.|Langkah lebih kuat: {move}|Latihan selesai. Anda telah melatih kesinambungan yang lebih kuat; ini tidak bermaksud anda memenangi permainan.|Berlatih semula pada {date}''',
  'th': '''เกมของคุณ · ตาที่ {move}|คุณเคยเดิน: {move}|เป้าหมาย: {focus} หาชุดการเดินที่ดีกว่า|บทวิเคราะห์ที่บันทึกไว้|ไม่ได้บันทึกคำอธิบายโดยละเอียดสำหรับตำแหน่งนี้|ตาเดินที่ดีกว่า: {move}|ฝึกเสร็จแล้ว คุณได้ฝึกชุดการเดินที่ดีกว่า ไม่ได้หมายความว่าชนะเกมแล้ว|ฝึกอีกครั้งวันที่ {date}''',
  'vi': '''Ván cờ của bạn · nước {move}|Bạn đã đi: {move}|Mục tiêu: {focus}. Tìm chuỗi nước đi tốt hơn.|Phân tích đã lưu|Không có giải thích chi tiết được lưu cho thế cờ này.|Nước đi tốt hơn: {move}|Hoàn thành bài tập. Bạn đã luyện chuỗi nước đi tốt hơn; điều này không có nghĩa là thắng ván cờ.|Luyện lại vào {date}''',
  'pl': '''Twoja partia · ruch {move}|Zagrano: {move}|Cel: {focus}. Znajdź silniejszą kontynuację.|Zapisana analiza|Nie zapisano szczegółowego wyjaśnienia tej pozycji.|Silniejszy ruch: {move}|Ćwiczenie ukończone. Przećwiczono silniejszą kontynuację; nie oznacza to wygranej partii.|Powtórz dnia {date}''',
  'nl': '''Je partij · zet {move}|Je speelde: {move}|Doel: {focus}. Vind een sterkere voortzetting.|Opgeslagen analyse|Voor deze stelling is geen uitgebreide uitleg opgeslagen.|Sterkere zet: {move}|Oefening voltooid. Je hebt de sterkere voortzetting geoefend; dat betekent niet dat de partij gewonnen is.|Oefen opnieuw op {date}''',
  'sv': '''Ditt parti · drag {move}|Du spelade: {move}|Mål: {focus}. Hitta en starkare fortsättning.|Sparad analys|Ingen detaljerad förklaring har sparats för den här ställningen.|Starkare drag: {move}|Övningen är klar. Du har övat den starkare fortsättningen; det betyder inte att partiet är vunnet.|Öva igen den {date}''',
  'el': '''Η παρτίδα σας · κίνηση {move}|Παίξατε: {move}|Στόχος: {focus}. Βρείτε μια ισχυρότερη συνέχεια.|Αποθηκευμένη ανάλυση|Δεν αποθηκεύτηκε λεπτομερής εξήγηση για αυτή τη θέση.|Ισχυρότερη κίνηση: {move}|Η άσκηση ολοκληρώθηκε. Εξασκηθήκατε στην ισχυρότερη συνέχεια· αυτό δεν σημαίνει νίκη στην παρτίδα.|Εξασκηθείτε ξανά στις {date}''',
  'he': '''המשחק שלך · מסע {move}|שיחקת: {move}|מטרה: {focus}. מצאו המשך חזק יותר.|ניתוח שמור|לא נשמר הסבר מפורט לעמדה הזאת.|מסע חזק יותר: {move}|התרגיל הושלם. תרגלת את ההמשך החזק יותר; אין פירוש הדבר שניצחת במשחק.|תרגל שוב בתאריך {date}''',
  'sw': '''Mchezo wako · hatua {move}|Ulicheza: {move}|Lengo: {focus}. Tafuta mwendelezo bora zaidi.|Uchanganuzi uliohifadhiwa|Hakuna maelezo ya kina yaliyohifadhiwa kwa nafasi hii.|Hatua bora zaidi: {move}|Zoezi limekamilika. Umefanya mazoezi ya mwendelezo bora zaidi; hii haimaanishi umeshinda mchezo.|Fanya mazoezi tena tarehe {date}''',
};
