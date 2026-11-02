/// A short spoken turn announcement. Player names remain verbatim.
String cupTurnAnnouncement(String language, String name, {required bool mine}) {
  final copy = _turns[language] ?? _turns['en']!;
  return (mine ? copy.$1 : copy.$2).replaceFirst('{name}', name);
}

const _turns = <String, (String, String)>{
  'en': ("{name}, it's your turn.", "It's {name}'s turn."),
  'te': ('{name}, ఇప్పుడు నీ వంతు.', 'ఇప్పుడు {name} వంతు.'),
  'hi': ('{name}, अब आपकी चाल है।', 'अब {name} की चाल है।'),
  'ta': ('{name}, இப்போது உங்கள் முறை.', 'இப்போது {name} விளையாடும் முறை.'),
  'kn': ('{name}, ಈಗ ನಿಮ್ಮ ಸರದಿ.', 'ಈಗ {name} ಅವರ ಸರದಿ.'),
  'ml': ('{name}, ഇനി നിങ്ങളുടെ ഊഴമാണ്.', 'ഇനി {name} കളിക്കേണ്ട ഊഴമാണ്.'),
  'mr': ('{name}, आता तुमची चाल आहे.', 'आता {name} यांची चाल आहे.'),
  'bn': ('{name}, এখন আপনার চাল।', 'এখন {name} চাল দেবেন।'),
  'gu': ('{name}, હવે તમારો વારો છે.', 'હવે {name}નો વારો છે.'),
  'pa': ('{name}, ਹੁਣ ਤੁਹਾਡੀ ਵਾਰੀ ਹੈ।', 'ਹੁਣ {name} ਦੀ ਵਾਰੀ ਹੈ।'),
  'ur': ('{name}، اب آپ کی چال ہے۔', 'اب {name} کی چال ہے۔'),
  'ar': ('{name}، حان دورك.', 'حان دور {name}.'),
  'he': ('{name}, עכשיו תורך.', 'עכשיו תורו של השחקן {name}.'),
  'fa': ('{name}، حالا نوبت شماست.', 'حالا نوبت {name} است.'),
  'de': ('{name}, du bist am Zug.', 'Jetzt ist {name} am Zug.'),
  'el': ('{name}, είναι η σειρά σου.', 'Σειρά έχει ο παίκτης {name}.'),
  'es': ('{name}, te toca.', 'Le toca a {name}.'),
  'fr': ('{name}, à toi de jouer.', 'C’est à {name} de jouer.'),
  'id': ('{name}, sekarang giliranmu.', 'Sekarang giliran {name}.'),
  'it': ('{name}, tocca a te.', 'Adesso tocca a {name}.'),
  'ja': ('{name}さん、あなたの番です。', '次は{name}さんの番です。'),
  'ko': ('{name}님, 지금 두실 차례예요.', '지금은 {name}님 차례예요.'),
  'ms': ('{name}, sekarang giliran anda.', 'Sekarang giliran {name}.'),
  'nl': ('{name}, jij bent aan zet.', '{name} is aan zet.'),
  'pl': ('{name}, teraz twój ruch.', 'Teraz ruch gracza {name}.'),
  'pt': ('{name}, é a sua vez.', 'Agora é a vez de {name}.'),
  'ru': ('{name}, ваш ход.', 'Сейчас ход игрока {name}.'),
  'sv': ('{name}, det är ditt drag.', 'Nu är det {name} som är på drag.'),
  'sw': ('{name}, ni zamu yako.', 'Sasa ni zamu ya {name}.'),
  'th': ('{name} ตอนนี้ถึงตาคุณเดินแล้ว', 'ตอนนี้ถึงตา {name} เดิน'),
  'tr': ('{name}, sıra sende.', 'Şimdi {name} oynayacak.'),
  'uk': ('{name}, ваш хід.', 'Зараз ходить {name}.'),
  'vi': ('{name}, đến lượt bạn đi.', 'Bây giờ đến lượt {name}.'),
  'zh': ('{name}，轮到你走了。', '现在轮到{name}走了。'),
};
