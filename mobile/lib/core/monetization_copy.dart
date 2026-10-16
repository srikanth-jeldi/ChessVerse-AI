String monetizationText(String key, String language) {
  final index = ['hintVideo', 'unavailable', 'loginBonus'].indexOf(key);
  if (index < 0) return key;
  return (monetizationCopy[language] ?? monetizationCopy['en']!).split(
    '|',
  )[index];
}

const monetizationCopy = {
  'en': 'Watch video · 1 hint|No video available. Try again later or use guided practice.|Google / Facebook sign-in: +50 coins once per account.',
  'te': 'వీడియో చూడండి · 1 సూచన|వీడియో అందుబాటులో లేదు. తర్వాత ప్రయత్నించండి లేదా సహాయంతో సాధన చేయండి.|Google / Facebook లాగిన్: ఖాతాకు ఒక్కసారి అదనంగా 50 కాయిన్లు.',
  'hi': 'वीडियो देखें · 1 संकेत|वीडियो उपलब्ध नहीं है। बाद में कोशिश करें या सहायता के साथ अभ्यास करें।|Google / Facebook लॉगिन: प्रति खाते एक बार 50 अतिरिक्त सिक्के।',
  'ta': 'வீடியோ பார்க்கவும் · 1 குறிப்பு|வீடியோ இல்லை. பிறகு முயலவும் அல்லது உதவியுடன் பயிற்சி செய்யவும்.|Google / Facebook உள்நுழைவு: கணக்கிற்கு ஒருமுறை 50 நாணயங்கள்.',
  'kn': 'ವೀಡಿಯೊ ನೋಡಿ · 1 ಸುಳಿವು|ವೀಡಿಯೊ ಲಭ್ಯವಿಲ್ಲ. ನಂತರ ಪ್ರಯತ್ನಿಸಿ ಅಥವಾ ಸಹಾಯದೊಂದಿಗೆ ಅಭ್ಯಾಸ ಮಾಡಿ.|Google / Facebook ಲಾಗಿನ್: ಪ್ರತಿ ಖಾತೆಗೆ ಒಮ್ಮೆ 50 ನಾಣ್ಯಗಳು.',
  'ml': 'വീഡിയോ കാണുക · 1 സൂചന|വീഡിയോ ലഭ്യമല്ല. പിന്നീട് ശ്രമിക്കുക അല്ലെങ്കിൽ സഹായത്തോടെ പരിശീലിക്കുക.|Google / Facebook ലോഗിൻ: അക്കൗണ്ടിന് ഒരിക്കൽ 50 നാണയങ്ങൾ.',
  'mr': 'व्हिडिओ पाहा · 1 संकेत|व्हिडिओ उपलब्ध नाही. नंतर प्रयत्न करा किंवा मार्गदर्शित सराव करा.|Google / Facebook लॉगिन: प्रत्येक खात्याला एकदा 50 नाणी.',
  'bn': 'ভিডিও দেখুন · ১টি ইঙ্গিত|ভিডিও নেই। পরে চেষ্টা করুন বা সহায়তা নিয়ে অনুশীলন করুন।|Google / Facebook লগইন: প্রতি অ্যাকাউন্টে একবার ৫০ কয়েন।',
  'gu': 'વીડિયો જુઓ · 1 સંકેત|વીડિયો ઉપલબ્ધ નથી. પછી પ્રયાસ કરો અથવા મદદ સાથે અભ્યાસ કરો.|Google / Facebook લૉગિન: ખાતા દીઠ એકવાર 50 સિક્કા.',
  'pa': 'ਵੀਡੀਓ ਦੇਖੋ · 1 ਸੰਕੇਤ|ਵੀਡੀਓ ਉਪਲਬਧ ਨਹੀਂ। ਬਾਅਦ ਵਿੱਚ ਕੋਸ਼ਿਸ਼ ਕਰੋ ਜਾਂ ਮਦਦ ਨਾਲ ਅਭਿਆਸ ਕਰੋ।|Google / Facebook ਲੌਗਇਨ: ਹਰੇਕ ਖਾਤੇ ਲਈ ਇੱਕ ਵਾਰ 50 ਸਿੱਕੇ।',
  'ur': 'ویڈیو دیکھیں · 1 اشارہ|ویڈیو دستیاب نہیں۔ بعد میں کوشش کریں یا مدد کے ساتھ مشق کریں۔|Google / Facebook لاگ ان: ہر اکاؤنٹ کو ایک بار 50 سکے۔',
  'ar': 'شاهد فيديو · تلميح واحد|لا يتوفر فيديو. حاول لاحقًا أو استخدم التدريب الموجّه.|تسجيل Google / Facebook: 50 عملة مرة واحدة لكل حساب.',
  'es': 'Ver vídeo · 1 pista|No hay vídeo disponible. Inténtalo más tarde o practica con ayuda.|Accede con Google / Facebook: 50 monedas una vez por cuenta.',
  'fr': 'Voir une vidéo · 1 indice|Aucune vidéo disponible. Réessayez plus tard ou utilisez la pratique guidée.|Connexion Google / Facebook : 50 pièces une seule fois par compte.',
  'de': 'Video ansehen · 1 Hinweis|Kein Video verfügbar. Versuche es später oder übe mit Hilfe.|Google-/Facebook-Anmeldung: einmalig 50 Münzen pro Konto.',
  'it': 'Guarda un video · 1 suggerimento|Nessun video disponibile. Riprova più tardi o usa la pratica guidata.|Accedi con Google / Facebook: 50 monete una volta per account.',
  'pt': 'Ver vídeo · 1 dica|Nenhum vídeo disponível. Tente depois ou pratique com ajuda.|Login Google / Facebook: 50 moedas uma vez por conta.',
  'ru': 'Смотреть видео · 1 подсказка|Видео недоступно. Повторите позже или тренируйтесь с помощью.|Вход через Google / Facebook: 50 монет один раз на аккаунт.',
  'uk': 'Переглянути відео · 1 підказка|Відео недоступне. Спробуйте пізніше або тренуйтеся з допомогою.|Вхід через Google / Facebook: 50 монет один раз на обліковий запис.',
  'tr': 'Video izle · 1 ipucu|Video yok. Daha sonra deneyin veya yardımlı alıştırma yapın.|Google / Facebook girişi: hesap başına bir kez 50 jeton.',
  'fa': 'تماشای ویدیو · ۱ راهنمایی|ویدیو موجود نیست. بعداً تلاش کنید یا با راهنما تمرین کنید.|ورود Google / Facebook: یک بار ۵۰ سکه برای هر حساب.',
  'zh': '观看视频 · 1次提示|暂无视频。请稍后重试，或使用指导练习。|Google / Facebook 登录：每个账号一次奖励50金币。',
  'ja': '動画を見る · ヒント1回|動画がありません。後で試すか、ガイド付き練習をご利用ください。|Google / Facebookログイン：アカウントごとに一度だけ50コイン。',
  'ko': '동영상 보기 · 힌트 1개|동영상이 없습니다. 나중에 시도하거나 도움을 받으며 연습하세요.|Google / Facebook 로그인: 계정당 한 번 50코인.',
  'id': 'Tonton video · 1 petunjuk|Video tidak tersedia. Coba nanti atau gunakan latihan terpandu.|Login Google / Facebook: 50 koin sekali per akun.',
  'ms': 'Tonton video · 1 petunjuk|Video tidak tersedia. Cuba kemudian atau gunakan latihan berpandu.|Log masuk Google / Facebook: 50 syiling sekali setiap akaun.',
  'th': 'ดูวิดีโอ · 1 คำใบ้|ไม่มีวิดีโอ ลองใหม่ภายหลังหรือฝึกแบบมีคำแนะนำ|เข้าสู่ระบบ Google / Facebook: รับ 50 เหรียญครั้งเดียวต่อบัญชี',
  'vi': 'Xem video · 1 gợi ý|Chưa có video. Thử lại sau hoặc luyện tập có hướng dẫn.|Đăng nhập Google / Facebook: 50 xu một lần cho mỗi tài khoản.',
  'pl': 'Obejrzyj film · 1 wskazówka|Brak filmu. Spróbuj później lub ćwicz z pomocą.|Logowanie Google / Facebook: 50 monet jednorazowo na konto.',
  'nl': 'Bekijk video · 1 hint|Geen video beschikbaar. Probeer later of oefen met hulp.|Google-/Facebook-login: eenmalig 50 munten per account.',
  'sv': 'Se video · 1 ledtråd|Ingen video tillgänglig. Försök senare eller öva med hjälp.|Google-/Facebook-inloggning: 50 mynt en gång per konto.',
  'el': 'Δείτε βίντεο · 1 υπόδειξη|Δεν υπάρχει βίντεο. Δοκιμάστε αργότερα ή εξασκηθείτε με βοήθεια.|Σύνδεση Google / Facebook: 50 νομίσματα μία φορά ανά λογαριασμό.',
  'he': 'צפייה בסרטון · רמז אחד|אין סרטון זמין. נסו מאוחר יותר או התאמנו עם הדרכה.|כניסה עם Google / Facebook: 50 מטבעות פעם אחת לכל חשבון.',
  'sw': 'Tazama video · kidokezo 1|Hakuna video. Jaribu baadaye au fanya mazoezi kwa msaada.|Ingia kwa Google / Facebook: sarafu 50 mara moja kwa akaunti.',
};
