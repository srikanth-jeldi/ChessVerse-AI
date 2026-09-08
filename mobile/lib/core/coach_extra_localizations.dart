import 'app_language.dart';

const coachExtraKeys = <String>[
  'completeGame',
  'noMistakes',
  'noEngineLoss',
  'engineLoss',
  'noVariation',
  'noThreat',
  'graphHelp',
  'mistakePuzzle',
  'nextPuzzle',
  'finishSet',
  'trainingComplete',
  'close',
];

final Map<String, List<String>> coachExtraTranslations = {
  for (final entry in _rows.entries) entry.key: entry.value.split('|'),
};

String coachExtraText(String key, String code,
    [Map<String, String> values = const {}]) {
  final index = coachExtraKeys.indexOf(key);
  if (index < 0) throw ArgumentError.value(key, 'key');
  var text =
      coachExtraTranslations[AppLanguageController.resolveCode(code)]![index];
  for (final value in values.entries) {
    text = text.replaceAll('{${value.key}}', value.value);
  }
  return text;
}

const _rows = <String, String>{
  'en':
      '''Complete a game to unlock move review.|No reviewed mistakes to train|Engine: no evaluation lost|Engine loss|No additional principal variation was returned.|No forcing opponent threat was found in the available review. Run engine analysis for a deeper forcing line.|Tap or drag across the graph to restore a reviewed position.|Mistake puzzle {index} of {total}|Next puzzle|Finish set|Training complete: {count} real-game mistakes reviewed.|Close''',
  'te':
      '''ఎత్తుల సమీక్ష కోసం ఒక గేమ్ పూర్తి చేయండి.|సాధన చేయడానికి సమీక్షించిన తప్పులు లేవు|ఇంజిన్: మూల్యాంకన నష్టం లేదు|ఇంజిన్ నష్టం|అదనపు ప్రధాన కొనసాగింపు అందలేదు.|అందుబాటులోని సమీక్షలో ప్రత్యర్థి బలవంతపు ప్రమాదం కనిపించలేదు. లోతైన కొనసాగింపు కోసం ఇంజిన్ విశ్లేషణ చేయండి.|సమీక్షించిన స్థితికి వెళ్లడానికి గ్రాఫ్‌పై ట్యాప్ లేదా డ్రాగ్ చేయండి.|తప్పుల పజిల్ {index} / {total}|తదుపరి పజిల్|సాధన ముగించండి|సాధన పూర్తయింది: నిజమైన గేమ్‌లలోని {count} తప్పులను సమీక్షించారు.|మూసివేయండి''',
  'hi':
      '''चालों की समीक्षा खोलने के लिए एक खेल पूरा करें।|अभ्यास के लिए समीक्षा की गई गलतियाँ नहीं हैं|इंजन: मूल्यांकन में कोई नुकसान नहीं|इंजन के अनुसार नुकसान|कोई अतिरिक्त मुख्य चाल-क्रम नहीं मिला।|उपलब्ध समीक्षा में प्रतिद्वंद्वी का कोई मजबूर करने वाला खतरा नहीं मिला। गहरा चाल-क्रम जानने के लिए इंजन विश्लेषण चलाएँ।|समीक्षित स्थिति बहाल करने के लिए ग्राफ पर टैप या ड्रैग करें।|गलती की पहेली {index} / {total}|अगली पहेली|अभ्यास समाप्त करें|प्रशिक्षण पूरा: वास्तविक खेलों की {count} गलतियों की समीक्षा हुई।|बंद करें''',
  'ta':
      '''நகர்வு மதிப்பாய்வைத் திறக்க ஒரு ஆட்டத்தை முடிக்கவும்.|பயிற்சிக்கு மதிப்பாய்வு செய்த தவறுகள் இல்லை|இயந்திரம்: மதிப்பீட்டில் இழப்பு இல்லை|இயந்திரம் கணித்த இழப்பு|கூடுதல் முதன்மைத் தொடர்ச்சி கிடைக்கவில்லை.|கிடைக்கும் மதிப்பாய்வில் எதிராளியின் கட்டாய அச்சுறுத்தல் காணப்படவில்லை. ஆழமான தொடர்ச்சிக்கு இயந்திரப் பகுப்பாய்வை இயக்கவும்.|மதிப்பாய்வு செய்த நிலையை மீட்டமைக்க வரைபடத்தைத் தட்டவும் அல்லது இழுக்கவும்.|தவறு புதிர் {index} / {total}|அடுத்த புதிர்|பயிற்சியை முடிக்கவும்|பயிற்சி முடிந்தது: உண்மை ஆட்டங்களின் {count} தவறுகள் மதிப்பாய்வு செய்யப்பட்டன.|மூடவும்''',
  'kn':
      '''ನಡೆಯ ವಿಮರ್ಶೆ ತೆರೆಯಲು ಒಂದು ಆಟವನ್ನು ಪೂರ್ಣಗೊಳಿಸಿ.|ಅಭ್ಯಾಸ ಮಾಡಲು ವಿಮರ್ಶಿಸಿದ ತಪ್ಪುಗಳಿಲ್ಲ|ಇಂಜಿನ್: ಮೌಲ್ಯಮಾಪನ ನಷ್ಟವಿಲ್ಲ|ಇಂಜಿನ್ ಲೆಕ್ಕದ ನಷ್ಟ|ಹೆಚ್ಚುವರಿ ಮುಖ್ಯ ಮುಂದುವರಿಕೆ ದೊರೆಯಲಿಲ್ಲ.|ಲಭ್ಯ ವಿಮರ್ಶೆಯಲ್ಲಿ ಎದುರಾಳಿಯ ಬಲವಂತದ ಬೆದರಿಕೆ ಕಂಡುಬಂದಿಲ್ಲ. ಆಳವಾದ ಮುಂದುವರಿಕೆಗೆ ಇಂಜಿನ್ ವಿಶ್ಲೇಷಣೆ ನಡೆಸಿ.|ವಿಮರ್ಶಿಸಿದ ಸ್ಥಿತಿಯನ್ನು ಮರುಸ್ಥಾಪಿಸಲು ಗ್ರಾಫ್ ಮೇಲೆ ಟ್ಯಾಪ್ ಮಾಡಿ ಅಥವಾ ಎಳೆಯಿರಿ.|ತಪ್ಪಿನ ಒಗಟು {index} / {total}|ಮುಂದಿನ ಒಗಟು|ಅಭ್ಯಾಸ ಮುಗಿಸಿ|ತರಬೇತಿ ಪೂರ್ಣ: ನಿಜವಾದ ಆಟಗಳ {count} ತಪ್ಪುಗಳನ್ನು ವಿಮರ್ಶಿಸಲಾಗಿದೆ.|ಮುಚ್ಚಿ''',
  'ml':
      '''നീക്കങ്ങളുടെ അവലോകനം തുറക്കാൻ ഒരു കളി പൂർത്തിയാക്കുക.|പരിശീലിക്കാൻ അവലോകനം ചെയ്ത തെറ്റുകളില്ല|എൻജിൻ: വിലയിരുത്തലിൽ നഷ്ടമില്ല|എൻജിൻ കണക്കാക്കിയ നഷ്ടം|കൂടുതൽ പ്രധാന തുടർച്ച ലഭിച്ചില്ല.|ലഭ്യമായ അവലോകനത്തിൽ എതിരാളിയുടെ നിർബന്ധിത ഭീഷണി കണ്ടെത്തിയില്ല. കൂടുതൽ ആഴത്തിലുള്ള തുടർച്ചയ്ക്കായി എൻജിൻ വിശകലനം നടത്തുക.|അവലോകനം ചെയ്ത സ്ഥിതി വീണ്ടെടുക്കാൻ ഗ്രാഫിൽ തൊടുകയോ വലിക്കുകയോ ചെയ്യുക.|തെറ്റിന്റെ പസിൽ {index} / {total}|അടുത്ത പസിൽ|പരിശീലനം അവസാനിപ്പിക്കുക|പരിശീലനം പൂർത്തിയായി: യഥാർത്ഥ കളികളിലെ {count} തെറ്റുകൾ അവലോകനം ചെയ്തു.|അടയ്ക്കുക''',
  'mr':
      '''चालींचे पुनरावलोकन उघडण्यासाठी एक खेळ पूर्ण करा.|सरावासाठी पुनरावलोकित चुका नाहीत|इंजिन: मूल्यांकनात नुकसान नाही|इंजिननुसार नुकसान|अतिरिक्त मुख्य चालक्रम मिळाला नाही.|उपलब्ध पुनरावलोकनात प्रतिस्पर्ध्याचा सक्तीचा धोका आढळला नाही. सखोल चालक्रमासाठी इंजिन विश्लेषण करा.|पुनरावलोकित स्थिती आणण्यासाठी आलेखावर टॅप करा किंवा ओढा.|चुकीचे कोडे {index} / {total}|पुढील कोडे|सराव पूर्ण करा|प्रशिक्षण पूर्ण: प्रत्यक्ष खेळांतील {count} चुकांचे पुनरावलोकन झाले.|बंद करा''',
  'bn':
      '''চালের পর্যালোচনা খুলতে একটি খেলা শেষ করুন।|অনুশীলনের জন্য পর্যালোচিত ভুল নেই|ইঞ্জিন: মূল্যায়নের ক্ষতি নেই|ইঞ্জিন অনুযায়ী ক্ষতি|অতিরিক্ত প্রধান চালের ধারা পাওয়া যায়নি।|উপলব্ধ পর্যালোচনায় প্রতিপক্ষের বাধ্যতামূলক হুমকি পাওয়া যায়নি। আরও গভীর চালের ধারার জন্য ইঞ্জিন বিশ্লেষণ চালান।|পর্যালোচিত অবস্থান ফেরাতে গ্রাফে ট্যাপ করুন বা টানুন।|ভুলের ধাঁধা {index} / {total}|পরের ধাঁধা|অনুশীলন শেষ করুন|প্রশিক্ষণ শেষ: বাস্তব খেলার {count}টি ভুল পর্যালোচিত হয়েছে।|বন্ধ করুন''',
  'gu':
      '''ચાલની સમીક્ષા ખોલવા એક રમત પૂર્ણ કરો.|અભ્યાસ માટે સમીક્ષા કરેલી ભૂલો નથી|એન્જિન: મૂલ્યાંકનમાં નુકસાન નથી|એન્જિન મુજબ નુકસાન|વધારાનો મુખ્ય ચાલક્રમ મળ્યો નથી.|ઉપલબ્ધ સમીક્ષામાં વિરોધીનો ફરજ પાડતો ખતરો મળ્યો નથી. વધુ ઊંડા ચાલક્રમ માટે એન્જિન વિશ્લેષણ ચલાવો.|સમીક્ષિત સ્થિતિ પાછી લાવવા આલેખ પર ટૅપ કરો અથવા ખેંચો.|ભૂલનો કોયડો {index} / {total}|આગળનો કોયડો|અભ્યાસ પૂર્ણ કરો|તાલીમ પૂર્ણ: વાસ્તવિક રમતોની {count} ભૂલોની સમીક્ષા થઈ.|બંધ કરો''',
  'pa':
      '''ਚਾਲਾਂ ਦੀ ਸਮੀਖਿਆ ਖੋਲ੍ਹਣ ਲਈ ਇੱਕ ਖੇਡ ਪੂਰੀ ਕਰੋ।|ਅਭਿਆਸ ਲਈ ਸਮੀਖਿਆ ਕੀਤੀਆਂ ਗਲਤੀਆਂ ਨਹੀਂ ਹਨ|ਇੰਜਣ: ਮੁਲਾਂਕਣ ਵਿੱਚ ਕੋਈ ਨੁਕਸਾਨ ਨਹੀਂ|ਇੰਜਣ ਅਨੁਸਾਰ ਨੁਕਸਾਨ|ਕੋਈ ਵਾਧੂ ਮੁੱਖ ਚਾਲ-ਕ੍ਰਮ ਨਹੀਂ ਮਿਲਿਆ।|ਉਪਲਬਧ ਸਮੀਖਿਆ ਵਿੱਚ ਵਿਰੋਧੀ ਦਾ ਮਜਬੂਰ ਕਰਨ ਵਾਲਾ ਖ਼ਤਰਾ ਨਹੀਂ ਮਿਲਿਆ। ਡੂੰਘੇ ਚਾਲ-ਕ੍ਰਮ ਲਈ ਇੰਜਣ ਵਿਸ਼ਲੇਸ਼ਣ ਚਲਾਓ।|ਸਮੀਖਿਆ ਕੀਤੀ ਸਥਿਤੀ ਵਾਪਸ ਲਿਆਉਣ ਲਈ ਗ੍ਰਾਫ ਉੱਤੇ ਟੈਪ ਕਰੋ ਜਾਂ ਖਿੱਚੋ।|ਗਲਤੀ ਦੀ ਬੁਝਾਰਤ {index} / {total}|ਅਗਲੀ ਬੁਝਾਰਤ|ਅਭਿਆਸ ਪੂਰਾ ਕਰੋ|ਸਿਖਲਾਈ ਪੂਰੀ: ਅਸਲ ਖੇਡਾਂ ਦੀਆਂ {count} ਗਲਤੀਆਂ ਦੀ ਸਮੀਖਿਆ ਹੋਈ।|ਬੰਦ ਕਰੋ''',
  'ur':
      '''چالوں کا جائزہ کھولنے کے لیے ایک کھیل مکمل کریں۔|مشق کے لیے جائزہ لی گئی غلطیاں نہیں ہیں|انجن: جائزے میں کوئی نقصان نہیں|انجن کے مطابق نقصان|کوئی اضافی مرکزی سلسلہ نہیں ملا۔|دستیاب جائزے میں حریف کا کوئی مجبور کرنے والا خطرہ نہیں ملا۔ گہرے سلسلے کے لیے انجن تجزیہ چلائیں۔|جائزہ لی گئی پوزیشن بحال کرنے کے لیے گراف پر ٹیپ کریں یا کھینچیں۔|غلطی کی پہیلی {index} / {total}|اگلی پہیلی|مشق ختم کریں|تربیت مکمل: اصل کھیلوں کی {count} غلطیوں کا جائزہ لیا گیا۔|بند کریں''',
  'ar':
      '''أكمل مباراة لفتح مراجعة النقلات.|لا توجد أخطاء تمت مراجعتها للتدريب|المحرك: لا خسارة في التقييم|خسارة التقييم وفق المحرك|لم يُرجع المحرك تتابعًا رئيسيًا إضافيًا.|لم يُعثر على تهديد إجباري للخصم في المراجعة المتاحة. شغّل تحليل المحرك للحصول على تتابع إجباري أعمق.|المس الرسم أو اسحب عليه لاستعادة وضع تمت مراجعته.|لغز خطأ {index} من {total}|اللغز التالي|إنهاء المجموعة|اكتمل التدريب: تمت مراجعة {count} أخطاء من مباريات فعلية.|إغلاق''',
  'es':
      '''Completa una partida para desbloquear el análisis de jugadas.|No hay errores analizados para practicar|Motor: sin pérdida de evaluación|Pérdida según el motor|No se recibió ninguna variante principal adicional.|No se encontró una amenaza forzante del rival en el análisis disponible. Ejecuta el análisis del motor para buscar una línea forzante más profunda.|Toca o arrastra sobre el gráfico para restaurar una posición analizada.|Problema de error {index} de {total}|Siguiente problema|Terminar serie|Entrenamiento completo: {count} errores de partidas reales analizados.|Cerrar''',
  'fr':
      '''Terminez une partie pour débloquer l’analyse des coups.|Aucune erreur analysée à travailler|Moteur : aucune perte d’évaluation|Perte selon le moteur|Aucune variante principale supplémentaire n’a été renvoyée.|Aucune menace forcée adverse n’a été trouvée dans l’analyse disponible. Lancez une analyse moteur pour chercher une suite forcée plus profonde.|Touchez ou faites glisser le graphique pour restaurer une position analysée.|Exercice d’erreur {index} sur {total}|Exercice suivant|Terminer la série|Entraînement terminé : {count} erreurs de parties réelles analysées.|Fermer''',
  'de':
      '''Beende eine Partie, um die Zuganalyse freizuschalten.|Keine analysierten Fehler zum Trainieren|Engine: kein Bewertungsverlust|Engine-Bewertungsverlust|Keine zusätzliche Hauptvariante wurde zurückgegeben.|In der verfügbaren Analyse wurde keine zwingende gegnerische Drohung gefunden. Starte eine Engine-Analyse für eine tiefere forcierte Variante.|Tippe oder ziehe über die Grafik, um eine analysierte Stellung wiederherzustellen.|Fehleraufgabe {index} von {total}|Nächste Aufgabe|Serie beenden|Training abgeschlossen: {count} Fehler aus echten Partien analysiert.|Schließen''',
  'it':
      '''Completa una partita per sbloccare l’analisi delle mosse.|Nessun errore analizzato da allenare|Motore: nessuna perdita di valutazione|Perdita secondo il motore|Non è stata restituita un’ulteriore variante principale.|Nell’analisi disponibile non è stata trovata una minaccia forzante dell’avversario. Avvia l’analisi del motore per una linea forzante più profonda.|Tocca o trascina sul grafico per ripristinare una posizione analizzata.|Esercizio sull’errore {index} di {total}|Esercizio successivo|Termina la serie|Allenamento completato: analizzati {count} errori di partite reali.|Chiudi''',
  'pt':
      '''Conclua uma partida para desbloquear a análise de lances.|Não há erros analisados para treinar|Motor: sem perda de avaliação|Perda segundo o motor|Não foi devolvida uma variante principal adicional.|Não foi encontrada uma ameaça forçante do adversário na análise disponível. Execute a análise do motor para procurar uma linha forçante mais profunda.|Toque ou arraste no gráfico para restaurar uma posição analisada.|Problema de erro {index} de {total}|Próximo problema|Terminar série|Treino concluído: {count} erros de partidas reais analisados.|Fechar''',
  'ru':
      '''Завершите партию, чтобы открыть разбор ходов.|Нет разобранных ошибок для тренировки|Движок: оценка не ухудшилась|Потеря оценки по движку|Дополнительный главный вариант не получен.|В доступном разборе не найдена форсированная угроза соперника. Запустите анализ движка для поиска более глубокого форсированного варианта.|Нажмите на график или проведите по нему, чтобы восстановить разобранную позицию.|Задача по ошибке {index} из {total}|Следующая задача|Завершить серию|Тренировка завершена: разобрано {count} ошибок из реальных партий.|Закрыть''',
  'uk':
      '''Завершіть партію, щоб відкрити розбір ходів.|Немає розібраних помилок для тренування|Рушій: оцінка не погіршилася|Втрата оцінки за рушієм|Додатковий головний варіант не отримано.|У доступному розборі не знайдено форсованої загрози суперника. Запустіть аналіз рушія для пошуку глибшого форсованого варіанта.|Торкніться графіка або проведіть по ньому, щоб відновити розібрану позицію.|Задача за помилкою {index} з {total}|Наступна задача|Завершити серію|Тренування завершено: розібрано {count} помилок із реальних партій.|Закрити''',
  'tr':
      '''Hamle incelemesini açmak için bir oyunu tamamla.|Çalışılacak incelenmiş hata yok|Motor: değerlendirme kaybı yok|Motora göre kayıp|Ek ana varyant döndürülmedi.|Mevcut incelemede rakibin zorlayıcı bir tehdidi bulunmadı. Daha derin zorlayıcı bir devam yolu için motor analizini çalıştır.|İncelenen konumu geri yüklemek için grafiğe dokun veya üzerinde sürükle.|Hata bulmacası {index} / {total}|Sonraki bulmaca|Seriyi bitir|Antrenman tamamlandı: gerçek oyunlardan {count} hata incelendi.|Kapat''',
  'fa':
      '''برای باز شدن بررسی حرکت‌ها یک بازی را کامل کنید.|اشتباه بررسی‌شده‌ای برای تمرین نیست|موتور: بدون افت ارزیابی|افت ارزیابی موتور|ادامهٔ اصلی دیگری دریافت نشد.|در بررسی موجود تهدید اجباری از حریف پیدا نشد. برای یافتن ادامهٔ اجباری عمیق‌تر تحلیل موتور را اجرا کنید.|برای بازیابی وضعیت بررسی‌شده روی نمودار بزنید یا بکشید.|معمای اشتباه {index} از {total}|معمای بعدی|پایان مجموعه|تمرین کامل شد: {count} اشتباه از بازی‌های واقعی بررسی شد.|بستن''',
  'zh':
      '''完成一盘棋以解锁逐步复盘。|没有可供练习的已复盘失误|引擎：评估没有下降|引擎评估损失|未返回额外的主要变化。|现有复盘未发现对手的强制威胁。运行引擎分析以寻找更深入的强制变化。|点击或拖动图表以恢复已复盘的局面。|失误练习 {index} / {total}|下一题|完成练习组|训练完成：已复盘 {count} 个实战失误。|关闭''',
  'ja':
      '''一局終えると指し手の振り返りが使えます。|練習する振り返り済みのミスはありません|エンジン：評価の損失なし|エンジン評価の損失|追加の主要変化は返されませんでした。|現在の分析では相手の強制的な脅威は見つかりませんでした。より深い強制手順を探すにはエンジン解析を実行してください。|グラフをタップまたはドラッグして振り返った局面を復元します。|ミス練習問題 {index} / {total}|次の問題|練習を終了|練習完了：実戦のミスを {count} 件振り返りました。|閉じる''',
  'ko':
      '''한 경기를 끝내면 수별 복기가 열립니다.|연습할 검토된 실수가 없습니다|엔진: 평가 손실 없음|엔진 평가 손실|추가 주요 수순이 반환되지 않았습니다.|현재 복기에서 상대의 강제적인 위협을 찾지 못했습니다. 더 깊은 강제 수순을 찾으려면 엔진 분석을 실행하세요.|그래프를 누르거나 드래그하여 검토한 국면을 복원하세요.|실수 퍼즐 {index} / {total}|다음 퍼즐|세트 마치기|훈련 완료: 실전 실수 {count}개를 검토했습니다.|닫기''',
  'id':
      '''Selesaikan permainan untuk membuka tinjauan langkah.|Tidak ada kesalahan yang ditinjau untuk dilatih|Mesin: tidak ada penurunan evaluasi|Penurunan menurut mesin|Tidak ada variasi utama tambahan yang dikembalikan.|Tidak ditemukan ancaman memaksa dari lawan dalam tinjauan yang tersedia. Jalankan analisis mesin untuk mencari jalur memaksa yang lebih dalam.|Ketuk atau seret pada grafik untuk memulihkan posisi yang ditinjau.|Teka-teki kesalahan {index} dari {total}|Teka-teki berikutnya|Selesaikan set|Latihan selesai: {count} kesalahan permainan nyata ditinjau.|Tutup''',
  'ms':
      '''Lengkapkan permainan untuk membuka semakan langkah.|Tiada kesilapan yang disemak untuk dilatih|Enjin: tiada kehilangan penilaian|Kehilangan menurut enjin|Tiada variasi utama tambahan dikembalikan.|Tiada ancaman memaksa daripada lawan ditemui dalam semakan yang tersedia. Jalankan analisis enjin untuk mencari laluan memaksa yang lebih mendalam.|Ketik atau seret pada graf untuk memulihkan kedudukan yang disemak.|Teka-teki kesilapan {index} daripada {total}|Teka-teki seterusnya|Tamatkan set|Latihan selesai: {count} kesilapan permainan sebenar disemak.|Tutup''',
  'th':
      '''เล่นให้จบหนึ่งเกมเพื่อปลดล็อกการทบทวนตาเดิน|ไม่มีข้อผิดพลาดที่ทบทวนให้ฝึก|เอนจิน: คะแนนประเมินไม่ลดลง|คะแนนที่เสียตามเอนจิน|ไม่ได้รับลำดับหลักเพิ่มเติม|ไม่พบภัยคุกคามที่บังคับจากคู่ต่อสู้ในการทบทวนที่มีอยู่ เรียกใช้การวิเคราะห์เอนจินเพื่อหาลำดับบังคับที่ลึกขึ้น|แตะหรือลากบนกราฟเพื่อคืนตำแหน่งที่ทบทวน|ปริศนาข้อผิดพลาด {index} จาก {total}|ปริศนาถัดไป|จบชุดฝึก|ฝึกเสร็จแล้ว: ทบทวนข้อผิดพลาดจากเกมจริง {count} ครั้ง|ปิด''',
  'vi':
      '''Hoàn thành một ván để mở phần xem lại từng nước.|Không có sai lầm đã xem lại để luyện|Máy: không mất điểm đánh giá|Mức giảm đánh giá theo máy|Không có biến chính bổ sung được trả về.|Không tìm thấy đe dọa bắt buộc của đối thủ trong phần xem xét hiện có. Chạy phân tích máy để tìm biến bắt buộc sâu hơn.|Chạm hoặc kéo trên biểu đồ để khôi phục thế cờ đã xem xét.|Bài tập sai lầm {index} / {total}|Bài tập tiếp theo|Kết thúc bộ|Luyện tập hoàn tất: đã xem xét {count} sai lầm trong ván thực tế.|Đóng''',
  'pl':
      '''Dokończ partię, aby odblokować analizę ruchów.|Brak przeanalizowanych błędów do ćwiczenia|Silnik: brak straty oceny|Strata według silnika|Nie zwrócono dodatkowego wariantu głównego.|W dostępnej analizie nie znaleziono wymuszającej groźby przeciwnika. Uruchom analizę silnika, aby znaleźć głębszy wymuszony wariant.|Dotknij wykresu lub przeciągnij po nim, aby przywrócić analizowaną pozycję.|Zadanie z błędu {index} z {total}|Następne zadanie|Zakończ serię|Trening zakończony: przeanalizowano {count} błędów z rzeczywistych partii.|Zamknij''',
  'nl':
      '''Voltooi een partij om de zetanalyse te ontgrendelen.|Geen geanalyseerde fouten om te oefenen|Engine: geen evaluatieverlies|Verlies volgens de engine|Er is geen extra hoofdvariant teruggegeven.|In de beschikbare analyse is geen dwingende dreiging van de tegenstander gevonden. Start een engine-analyse voor een diepere geforceerde variant.|Tik of sleep over de grafiek om een geanalyseerde stelling te herstellen.|Foutenpuzzel {index} van {total}|Volgende puzzel|Reeks voltooien|Training voltooid: {count} fouten uit echte partijen geanalyseerd.|Sluiten''',
  'sv':
      '''Slutför ett parti för att låsa upp draganalysen.|Inga analyserade misstag att träna på|Motor: ingen utvärderingsförlust|Förlust enligt motorn|Ingen ytterligare huvudvariant returnerades.|Inget tvingande hot från motståndaren hittades i den tillgängliga analysen. Kör motoranalys för att hitta en djupare forcerad variant.|Tryck eller dra över grafen för att återställa en analyserad ställning.|Misstagsproblem {index} av {total}|Nästa problem|Avsluta serien|Träningen klar: {count} misstag från riktiga partier analyserade.|Stäng''',
  'el':
      '''Ολοκλήρωσε μια παρτίδα για να ανοίξεις την ανάλυση κινήσεων.|Δεν υπάρχουν αναλυμένα λάθη για προπόνηση|Μηχανή: καμία απώλεια αξιολόγησης|Απώλεια σύμφωνα με τη μηχανή|Δεν επιστράφηκε πρόσθετη κύρια βαριάντα.|Δεν βρέθηκε αναγκαστική απειλή του αντιπάλου στη διαθέσιμη ανάλυση. Εκτέλεσε ανάλυση μηχανής για βαθύτερη αναγκαστική βαριάντα.|Πάτησε ή σύρε στο γράφημα για να επαναφέρεις μια αναλυμένη θέση.|Άσκηση λάθους {index} από {total}|Επόμενη άσκηση|Ολοκλήρωση σειράς|Η προπόνηση ολοκληρώθηκε: αναλύθηκαν {count} λάθη πραγματικών παρτίδων.|Κλείσιμο''',
  'he':
      '''השלימו משחק כדי לפתוח סקירת מסעים.|אין טעויות שנותחו לתרגול|מנוע: ללא אובדן הערכה|אובדן הערכה לפי המנוע|לא התקבלה וריאציה ראשית נוספת.|לא נמצא איום כפוי של היריב בסקירה הזמינה. הפעילו ניתוח מנוע כדי למצוא המשך כפוי עמוק יותר.|הקישו או גררו על הגרף כדי לשחזר עמדה שנותחה.|תרגיל טעות {index} מתוך {total}|התרגיל הבא|סיום הסדרה|האימון הושלם: נותחו {count} טעויות ממשחקים אמיתיים.|סגירה''',
  'sw':
      '''Maliza mchezo ili kufungua uchambuzi wa hatua.|Hakuna makosa yaliyochambuliwa ya kufanyia mazoezi|Injini: hakuna upotevu wa tathmini|Upotevu kulingana na injini|Hakuna mfululizo mkuu wa ziada uliorejeshwa.|Hakuna tishio la kulazimisha la mpinzani lililopatikana katika uchambuzi uliopo. Endesha uchambuzi wa injini kutafuta mfululizo wa kulazimisha wa kina zaidi.|Gusa au buruta kwenye grafu ili kurejesha nafasi iliyochambuliwa.|Fumbo la kosa {index} kati ya {total}|Fumbo linalofuata|Maliza seti|Mafunzo yamekamilika: makosa {count} ya michezo halisi yamechambuliwa.|Funga''',
};
