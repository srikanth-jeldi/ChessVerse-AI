import '../../../core/app_language.dart';

String googleChatMessage(String code) =>
    googleChatMessages[AppLanguageController.resolveCode(code)] ??
    googleChatMessages['en']!;

const Map<String, String> googleChatMessages = {
  'en': 'Sign in with Google to use AI chat and chat rooms.',
  'te': 'AI చాట్, చాట్ రూమ్ వాడాలంటే Google లాగిన్ తప్పనిసరి.',
  'hi': 'AI चैट और चैट रूम इस्तेमाल करने के लिए Google से साइन इन करें।',
  'ta':
      'AI அரட்டை மற்றும் அரட்டை அறைகளைப் பயன்படுத்த Google மூலம் உள்நுழையவும்.',
  'kn': 'AI ಚಾಟ್ ಮತ್ತು ಚಾಟ್ ರೂಮ್ ಬಳಸಲು Google ಮೂಲಕ ಸೈನ್ ಇನ್ ಮಾಡಿ.',
  'ml': 'AI ചാറ്റും ചാറ്റ് റൂമുകളും ഉപയോഗിക്കാൻ Google വഴി സൈൻ ഇൻ ചെയ്യുക.',
  'mr': 'AI चॅट आणि चॅट रूम वापरण्यासाठी Google ने साइन इन करा.',
  'bn': 'AI চ্যাট ও চ্যাট রুম ব্যবহার করতে Google দিয়ে সাইন ইন করুন।',
  'gu': 'AI ચેટ અને ચેટ રૂમ વાપરવા Google વડે સાઇન ઇન કરો.',
  'pa': 'AI ਚੈਟ ਅਤੇ ਚੈਟ ਰੂਮ ਵਰਤਣ ਲਈ Google ਨਾਲ ਸਾਈਨ ਇਨ ਕਰੋ।',
  'ur': 'AI چیٹ اور چیٹ روم استعمال کرنے کے لیے Google سے سائن ان کریں۔',
  'ar': 'سجّل الدخول باستخدام Google لاستخدام دردشة الذكاء الاصطناعي وغرف الدردشة.',
  'es': 'Inicia sesión con Google para usar el chat de IA y las salas de chat.',
  'fr': 'Connectez-vous avec Google pour utiliser le chat IA et les salons de discussion.',
  'de': 'Melde dich mit Google an, um den KI-Chat und die Chaträume zu nutzen.',
  'it': 'Accedi con Google per usare la chat IA e le stanze di chat.',
  'pt': 'Entre com o Google para usar o chat de IA e as salas de bate-papo.',
  'ru': 'Войдите через Google, чтобы использовать чат с ИИ и чат-комнаты.',
  'uk':
      'Увійдіть через Google, щоб користуватися чатом зі ШІ та чат-кімнатами.',
  'tr': 'Yapay zekâ sohbetini ve sohbet odalarını kullanmak için Google ile giriş yapın.',
  'fa': 'برای استفاده از گفت‌وگوی هوش مصنوعی و اتاق‌های گفت‌وگو با Google وارد شوید.',
  'zh': '请使用 Google 登录以使用 AI 聊天和聊天室。',
  'ja': 'AIチャットとチャットルームを利用するには、Googleでログインしてください。',
  'ko': 'AI 채팅과 채팅방을 이용하려면 Google로 로그인하세요.',
  'id': 'Login dengan Google untuk menggunakan chat AI dan ruang chat.',
  'ms':
      'Log masuk dengan Google untuk menggunakan sembang AI dan bilik sembang.',
  'th': 'ลงชื่อเข้าใช้ด้วย Google เพื่อใช้แชต AI และห้องแชต',
  'vi': 'Đăng nhập bằng Google để sử dụng trò chuyện AI và phòng trò chuyện.',
  'pl': 'Zaloguj się przez Google, aby korzystać z czatu AI i pokojów czatu.',
  'nl': 'Log in met Google om AI-chat en chatrooms te gebruiken.',
  'sv': 'Logga in med Google för att använda AI-chatten och chattrummen.',
  'el': 'Συνδεθείτε με το Google για να χρησιμοποιήσετε τη συνομιλία AI και τα δωμάτια συνομιλίας.',
  'he': 'יש להתחבר באמצעות Google כדי להשתמש בצ׳אט AI ובחדרי הצ׳אט.',
  'sw': 'Ingia kwa Google ili kutumia gumzo la AI na vyumba vya mazungumzo.',
};
