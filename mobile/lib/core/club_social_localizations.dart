import 'app_language.dart';

const clubSocialKeys = [
  'create',
  'invite',
  'name',
  'description',
  'identity',
  'send',
  'challenges',
  'empty',
  'incoming',
  'outgoing',
  'expired',
  'declined',
  'cancelled',
];
const clubSocialRows = <String, String>{
  'en': 'Create your club|Invite friends|Club name|Description|Email or @username|Send invitation|Challenges|No challenges yet|Received|Sent|Expired|Declined|Cancelled',
  'te': 'మీ క్లబ్ సృష్టించండి|స్నేహితులను ఆహ్వానించండి|క్లబ్ పేరు|వివరణ|ఇమెయిల్ లేదా @యూజర్‌నేమ్|ఆహ్వానం పంపండి|సవాళ్లు|ఇంకా సవాళ్లు లేవు|వచ్చినవి|పంపినవి|గడువు ముగిసింది|తిరస్కరించారు|రద్దయింది',
  'hi': 'अपना क्लब बनाएँ|दोस्तों को आमंत्रित करें|क्लब का नाम|विवरण|ईमेल या @यूज़रनेम|निमंत्रण भेजें|चुनौतियाँ|अभी कोई चुनौती नहीं|प्राप्त|भेजी गई|समय समाप्त|अस्वीकृत|रद्द',
  'ta': 'உங்கள் கிளப்பை உருவாக்குங்கள்|நண்பர்களை அழைக்கவும்|கிளப் பெயர்|விளக்கம்|மின்னஞ்சல் அல்லது @பயனர்பெயர்|அழைப்பை அனுப்பு|சவால்கள்|இன்னும் சவால்கள் இல்லை|பெறப்பட்டவை|அனுப்பியவை|காலாவதியானது|மறுக்கப்பட்டது|ரத்தானது',
  'kn': 'ನಿಮ್ಮ ಕ್ಲಬ್ ರಚಿಸಿ|ಸ್ನೇಹಿತರನ್ನು ಆಹ್ವಾನಿಸಿ|ಕ್ಲಬ್ ಹೆಸರು|ವಿವರಣೆ|ಇಮೇಲ್ ಅಥವಾ @ಬಳಕೆದಾರಹೆಸರು|ಆಹ್ವಾನ ಕಳುಹಿಸಿ|ಸವಾಲುಗಳು|ಇನ್ನೂ ಸವಾಲುಗಳಿಲ್ಲ|ಸ್ವೀಕರಿಸಿದವು|ಕಳುಹಿಸಿದವು|ಅವಧಿ ಮುಗಿದಿದೆ|ನಿರಾಕರಿಸಲಾಗಿದೆ|ರದ್ದಾಗಿದೆ',
  'ml': 'നിങ്ങളുടെ ക്ലബ് സൃഷ്ടിക്കുക|സുഹൃത്തുക്കളെ ക്ഷണിക്കുക|ക്ലബിന്റെ പേര്|വിവരണം|ഇമെയിൽ അല്ലെങ്കിൽ @ഉപയോക്തൃനാമം|ക്ഷണം അയയ്ക്കുക|വെല്ലുവിളികൾ|വെല്ലുവിളികളില്ല|ലഭിച്ചവ|അയച്ചവ|കാലാവധി കഴിഞ്ഞു|നിരസിച്ചു|റദ്ദാക്കി',
  'mr': 'तुमचा क्लब तयार करा|मित्रांना आमंत्रित करा|क्लबचे नाव|वर्णन|ईमेल किंवा @वापरकर्तानाव|आमंत्रण पाठवा|आव्हाने|अद्याप आव्हाने नाहीत|मिळालेली|पाठवलेली|मुदत संपली|नाकारले|रद्द',
  'bn': 'নিজের ক্লাব তৈরি করুন|বন্ধুদের আমন্ত্রণ জানান|ক্লাবের নাম|বিবরণ|ইমেল বা @ব্যবহারকারীনাম|আমন্ত্রণ পাঠান|চ্যালেঞ্জ|এখনও চ্যালেঞ্জ নেই|প্রাপ্ত|পাঠানো|মেয়াদ শেষ|প্রত্যাখ্যাত|বাতিল',
  'gu': 'તમારી ક્લબ બનાવો|મિત્રોને આમંત્રણ આપો|ક્લબનું નામ|વર્ણન|ઈમેલ અથવા @વપરાશકર્તાનામ|આમંત્રણ મોકલો|પડકારો|હજી કોઈ પડકાર નથી|મળેલા|મોકલેલા|સમય પૂરો|નકારેલ|રદ',
  'pa': 'ਆਪਣਾ ਕਲੱਬ ਬਣਾਓ|ਦੋਸਤਾਂ ਨੂੰ ਸੱਦੋ|ਕਲੱਬ ਦਾ ਨਾਮ|ਵੇਰਵਾ|ਈਮੇਲ ਜਾਂ @ਵਰਤੋਂਕਾਰਨਾਮ|ਸੱਦਾ ਭੇਜੋ|ਚੁਣੌਤੀਆਂ|ਹਾਲੇ ਚੁਣੌਤੀਆਂ ਨਹੀਂ|ਪ੍ਰਾਪਤ|ਭੇਜੀਆਂ|ਮਿਆਦ ਪੁੱਗੀ|ਰੱਦ ਕੀਤੀਆਂ|ਰੱਦ',
  'ur': 'اپنا کلب بنائیں|دوستوں کو مدعو کریں|کلب کا نام|تفصیل|ای میل یا @صارف نام|دعوت بھیجیں|چیلنجز|ابھی کوئی چیلنج نہیں|موصول|بھیجے گئے|میعاد ختم|مسترد|منسوخ',
  'ar': 'أنشئ ناديك|ادعُ الأصدقاء|اسم النادي|الوصف|البريد الإلكتروني أو @اسم المستخدم|إرسال الدعوة|التحديات|لا توجد تحديات بعد|الواردة|المرسلة|انتهت الصلاحية|مرفوض|ملغى',
  'es': 'Crea tu club|Invitar amigos|Nombre del club|Descripción|Correo o @usuario|Enviar invitación|Desafíos|Aún no hay desafíos|Recibidos|Enviados|Caducado|Rechazado|Cancelado',
  'fr': 'Créer votre club|Inviter des amis|Nom du club|Description|E-mail ou @identifiant|Envoyer une invitation|Défis|Aucun défi pour le moment|Reçus|Envoyés|Expiré|Refusé|Annulé',
  'de': 'Eigenen Club erstellen|Freunde einladen|Clubname|Beschreibung|E-Mail oder @Benutzername|Einladung senden|Herausforderungen|Noch keine Herausforderungen|Empfangen|Gesendet|Abgelaufen|Abgelehnt|Abgebrochen',
  'it': 'Crea il tuo club|Invita amici|Nome del club|Descrizione|Email o @nomeutente|Invia invito|Sfide|Ancora nessuna sfida|Ricevute|Inviate|Scaduta|Rifiutata|Annullata',
  'pt': 'Crie seu clube|Convidar amigos|Nome do clube|Descrição|E-mail ou @usuário|Enviar convite|Desafios|Ainda não há desafios|Recebidos|Enviados|Expirado|Recusado|Cancelado',
  'ru': 'Создать свой клуб|Пригласить друзей|Название клуба|Описание|Почта или @имяпользователя|Отправить приглашение|Вызовы|Вызовов пока нет|Входящие|Отправленные|Срок истёк|Отклонён|Отменён',
  'uk': 'Створити свій клуб|Запросити друзів|Назва клубу|Опис|Пошта або @ім’якористувача|Надіслати запрошення|Виклики|Викликів ще немає|Отримані|Надіслані|Термін минув|Відхилено|Скасовано',
  'tr': 'Kulübünü oluştur|Arkadaşlarını davet et|Kulüp adı|Açıklama|E-posta veya @kullanıcıadı|Davet gönder|Meydan okumalar|Henüz meydan okuma yok|Gelen|Gönderilen|Süresi doldu|Reddedildi|İptal edildi',
  'fa': 'باشگاه خود را بسازید|دعوت از دوستان|نام باشگاه|توضیحات|ایمیل یا @نام‌کاربری|ارسال دعوت|چالش‌ها|هنوز چالشی نیست|دریافتی|ارسالی|منقضی|رد شده|لغو شده',
  'zh': '创建你的俱乐部|邀请朋友|俱乐部名称|简介|邮箱或@用户名|发送邀请|挑战|暂无挑战|收到的|发出的|已过期|已拒绝|已取消',
  'ja': 'クラブを作成|友達を招待|クラブ名|説明|メールまたは@ユーザー名|招待を送信|対戦リクエスト|まだリクエストがありません|受信|送信|期限切れ|辞退|キャンセル',
  'ko': '내 클럽 만들기|친구 초대|클럽 이름|설명|이메일 또는 @사용자이름|초대 보내기|대결 신청|아직 대결 신청이 없습니다|받은 신청|보낸 신청|만료됨|거절됨|취소됨',
  'id': 'Buat klub Anda|Undang teman|Nama klub|Deskripsi|Email atau @namapengguna|Kirim undangan|Tantangan|Belum ada tantangan|Diterima|Dikirim|Kedaluwarsa|Ditolak|Dibatalkan',
  'ms': 'Cipta kelab anda|Jemput rakan|Nama kelab|Penerangan|E-mel atau @namapengguna|Hantar jemputan|Cabaran|Belum ada cabaran|Diterima|Dihantar|Tamat tempoh|Ditolak|Dibatalkan',
  'th': 'สร้างคลับของคุณ|เชิญเพื่อน|ชื่อคลับ|รายละเอียด|อีเมลหรือ @ชื่อผู้ใช้|ส่งคำเชิญ|คำท้า|ยังไม่มีคำท้า|ได้รับ|ส่งแล้ว|หมดอายุ|ปฏิเสธแล้ว|ยกเลิกแล้ว',
  'vi': 'Tạo câu lạc bộ|Mời bạn bè|Tên câu lạc bộ|Mô tả|Email hoặc @tênngườidùng|Gửi lời mời|Thách đấu|Chưa có thách đấu|Đã nhận|Đã gửi|Hết hạn|Đã từ chối|Đã hủy',
  'pl': 'Utwórz swój klub|Zaproś znajomych|Nazwa klubu|Opis|E-mail lub @użytkownik|Wyślij zaproszenie|Wyzwania|Brak wyzwań|Otrzymane|Wysłane|Wygasło|Odrzucono|Anulowano',
  'nl': 'Maak je club|Vrienden uitnodigen|Clubnaam|Beschrijving|E-mail of @gebruikersnaam|Uitnodiging versturen|Uitdagingen|Nog geen uitdagingen|Ontvangen|Verzonden|Verlopen|Afgewezen|Geannuleerd',
  'sv': 'Skapa din klubb|Bjud in vänner|Klubbnamn|Beskrivning|E-post eller @användarnamn|Skicka inbjudan|Utmaningar|Inga utmaningar ännu|Mottagna|Skickade|Utgången|Avböjd|Avbruten',
  'el': 'Δημιουργήστε λέσχη|Προσκαλέστε φίλους|Όνομα λέσχης|Περιγραφή|Email ή @όνομαχρήστη|Αποστολή πρόσκλησης|Προκλήσεις|Δεν υπάρχουν προκλήσεις|Εισερχόμενες|Απεσταλμένες|Έληξε|Απορρίφθηκε|Ακυρώθηκε',
  'he': 'יצירת מועדון|הזמנת חברים|שם המועדון|תיאור|דוא״ל או @שםמשתמש|שליחת הזמנה|אתגרים|אין אתגרים עדיין|התקבלו|נשלחו|פג תוקף|נדחה|בוטל',
  'sw': 'Unda klabu yako|Alika marafiki|Jina la klabu|Maelezo|Barua pepe au @jinolamtumiaji|Tuma mwaliko|Changamoto|Bado hakuna changamoto|Zilizopokelewa|Zilizotumwa|Muda umeisha|Imekataliwa|Imeghairiwa',
};
String clubSocialText(String key, String language) {
  final index = clubSocialKeys.indexOf(key);
  if (index < 0) throw ArgumentError.value(key);
  return clubSocialRows[AppLanguageController.resolveCode(language)]!.split(
    '|',
  )[index];
}
