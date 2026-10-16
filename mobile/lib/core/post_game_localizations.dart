/// Compact, player-controlled completed-game actions in every supported locale.
const postGameKeys = [
  'View result',
  'AI game review',
  'New game',
  'You win',
  'Opponent wins',
  'Draw',
];

String postGameText(String source, String language) {
  final index = postGameKeys.indexOf(source);
  if (index < 0) return source;
  return (postGameTranslations[language] ?? postGameTranslations['en']!)[index];
}

final postGameTranslations = <String, List<String>>{
  for (final row in _rows.entries) row.key: row.value.split('|'),
};

const _rows = {
  'en': 'View result|AI game review|New game|You win|Opponent wins|Draw',
  'te':
      'ఫలితం చూడండి|ఆట విశ్లేషణ|కొత్త ఆట|మీరు గెలిచారు|ప్రత్యర్థి గెలిచారు|సమం',
  'hi':
      'परिणाम देखें|AI खेल विश्लेषण|नया खेल|आप जीत गए|प्रतिद्वंद्वी जीता|ड्रॉ',
  'ta': 'முடிவைக் காண்க|AI ஆட்ட ஆய்வு|புதிய ஆட்டம்|நீங்கள் வென்றீர்கள்|எதிராளி வென்றார்|சமநிலை',
  'kn':
      'ಫಲಿತಾಂಶ ನೋಡಿ|AI ಆಟದ ವಿಶ್ಲೇಷಣೆ|ಹೊಸ ಆಟ|ನೀವು ಗೆದ್ದಿರಿ|ಎದುರಾಳಿ ಗೆದ್ದರು|ಡ್ರಾ',
  'ml':
      'ഫലം കാണുക|AI കളി വിശകലനം|പുതിയ കളി|നിങ്ങൾ ജയിച്ചു|എതിരാളി ജയിച്ചു|സമനില',
  'mr': 'निकाल पाहा|AI खेळ विश्लेषण|नवा खेळ|तुम्ही जिंकलात|प्रतिस्पर्धी जिंकला|बरोबरी',
  'bn': 'ফলাফল দেখুন|AI খেলা বিশ্লেষণ|নতুন খেলা|আপনি জিতেছেন|প্রতিপক্ষ জিতেছে|ড্র',
  'gu':
      'પરિણામ જુઓ|AI રમત વિશ્લેષણ|નવી રમત|તમે જીત્યા|પ્રતિસ્પર્ધી જીત્યા|ડ્રો',
  'pa': 'ਨਤੀਜਾ ਦੇਖੋ|AI ਖੇਡ ਵਿਸ਼ਲੇਸ਼ਣ|ਨਵੀਂ ਖੇਡ|ਤੁਸੀਂ ਜਿੱਤੇ|ਵਿਰੋਧੀ ਜਿੱਤਿਆ|ਡਰਾਅ',
  'ur': 'نتیجہ دیکھیں|AI کھیل کا تجزیہ|نیا کھیل|آپ جیت گئے|حریف جیت گیا|برابری',
  'ar': 'عرض النتيجة|تحليل المباراة بالذكاء الاصطناعي|مباراة جديدة|لقد فزت|فاز الخصم|تعادل',
  'es': 'Ver resultado|Análisis con IA|Nueva partida|Has ganado|Gana el rival|Tablas',
  'fr': 'Voir le résultat|Analyse IA|Nouvelle partie|Vous gagnez|Adversaire gagnant|Nulle',
  'de': 'Ergebnis ansehen|KI-Partieanalyse|Neue Partie|Du gewinnst|Gegner gewinnt|Remis',
  'it': 'Vedi risultato|Analisi IA|Nuova partita|Hai vinto|Vince l’avversario|Patta',
  'pt': 'Ver resultado|Análise com IA|Nova partida|Você venceu|O adversário venceu|Empate',
  'ru': 'Посмотреть результат|Анализ ИИ|Новая партия|Вы победили|Соперник победил|Ничья',
  'uk': 'Переглянути результат|Аналіз ШІ|Нова партія|Ви перемогли|Суперник переміг|Нічия',
  'tr': 'Sonucu gör|Yapay zekâ analizi|Yeni oyun|Kazandınız|Rakip kazandı|Berabere',
  'fa':
      'نمایش نتیجه|تحلیل بازی با هوش مصنوعی|بازی جدید|شما بردید|حریف برد|مساوی',
  'zh': '查看结果|AI棋局分析|新对局|你赢了|对手获胜|和棋',
  'ja': '結果を見る|AI棋譜分析|新しい対局|あなたの勝ち|相手の勝ち|引き分け',
  'ko': '결과 보기|AI 대국 분석|새 대국|승리했습니다|상대 승리|무승부',
  'id': 'Lihat hasil|Analisis AI|Permainan baru|Anda menang|Lawan menang|Remis',
  'ms': 'Lihat keputusan|Analisis AI|Permainan baharu|Anda menang|Lawan menang|Seri',
  'th': 'ดูผลลัพธ์|วิเคราะห์เกมด้วย AI|เกมใหม่|คุณชนะ|คู่ต่อสู้ชนะ|เสมอ',
  'vi': 'Xem kết quả|Phân tích AI|Ván mới|Bạn thắng|Đối thủ thắng|Hòa',
  'pl':
      'Zobacz wynik|Analiza AI|Nowa partia|Wygrywasz|Przeciwnik wygrywa|Remis',
  'nl': 'Bekijk resultaat|AI-partijanalyse|Nieuw spel|Je wint|Tegenstander wint|Remise',
  'sv': 'Visa resultat|AI-partianalys|Nytt parti|Du vinner|Motståndaren vinner|Remi',
  'el': 'Προβολή αποτελέσματος|Ανάλυση με AI|Νέα παρτίδα|Κερδίσατε|Κέρδισε ο αντίπαλος|Ισοπαλία',
  'he': 'הצגת תוצאה|ניתוח משחק AI|משחק חדש|ניצחת|היריב ניצח|תיקו',
  'sw': 'Tazama matokeo|Uchambuzi wa AI|Mchezo mpya|Umeshinda|Mpinzani ameshinda|Sare',
};
