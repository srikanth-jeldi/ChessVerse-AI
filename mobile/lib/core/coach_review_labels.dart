/// Shared review labels for every locale in the language picker.
const reviewLabelKeys = <String>[
  'title',
  'moveQuality',
  'evaluationGraph',
  'moveByMove',
  'explain',
  'showThreat',
  'retryPosition',
  'strength',
  'turningPoint',
  'importantMoments',
  'trainingFocus',
  'trainingPlan',
  'recommended',
  'best',
  'great',
  'good',
  'playable',
  'inaccuracy',
  'mistake',
  'blunder',
];

final Map<String, List<String>> reviewLabelTranslations = {
  for (final entry in _rows.entries) entry.key: entry.value.split('|'),
};

const _rows = <String, String>{
  'en':
      '''AI game review|Move quality|Evaluation graph|Move-by-move coaching|Explain simply|Show threat|Retry position|Your strength|Turning point|Important moments|Next training focus|Personal training plan|Recommended|Best|Great|Good|Playable|Inaccuracy|Mistake|Blunder''',
  'te':
      '''AI గేమ్ సమీక్ష|ఎత్తుల నాణ్యత|మూల్యాంకన గ్రాఫ్|ప్రతి ఎత్తుకు కోచింగ్|సులభంగా వివరించండి|ప్రమాదాన్ని చూపండి|స్థితిని మళ్లీ ప్రయత్నించండి|మీ బలం|మలుపు|ముఖ్యమైన క్షణాలు|తదుపరి శిక్షణ లక్ష్యం|వ్యక్తిగత శిక్షణ ప్రణాళిక|సిఫార్సు|ఉత్తమం|చాలా మంచి|మంచి|ఆడదగినది|స్వల్ప తప్పు|తప్పు|పెద్ద తప్పు''',
  'hi':
      '''AI गेम समीक्षा|चाल की गुणवत्ता|मूल्यांकन ग्राफ|हर चाल की कोचिंग|सरल रूप से समझाएँ|खतरा दिखाएँ|स्थिति फिर खेलें|आपकी ताकत|निर्णायक मोड़|महत्वपूर्ण क्षण|अगले प्रशिक्षण का लक्ष्य|व्यक्तिगत प्रशिक्षण योजना|अनुशंसित|सर्वश्रेष्ठ|बहुत अच्छा|अच्छा|खेलने योग्य|अशुद्ध चाल|गलती|गंभीर गलती''',
  'ta':
      '''AI ஆட்ட மதிப்பாய்வு|நகர்வின் தரம்|மதிப்பீட்டு வரைபடம்|ஒவ்வொரு நகர்விற்கும் பயிற்சி|எளிதாக விளக்கவும்|அச்சுறுத்தலைக் காட்டவும்|நிலையை மீண்டும் முயலவும்|உங்கள் பலம்|திருப்புமுனை|முக்கிய தருணங்கள்|அடுத்த பயிற்சி இலக்கு|தனிப்பட்ட பயிற்சித் திட்டம்|பரிந்துரை|சிறந்தது|மிக நன்று|நன்று|ஆடத்தக்கது|சிறிய பிழை|தவறு|பெரும் தவறு''',
  'kn':
      '''AI ಆಟದ ವಿಮರ್ಶೆ|ನಡೆಯ ಗುಣಮಟ್ಟ|ಮೌಲ್ಯಮಾಪನ ಗ್ರಾಫ್|ಪ್ರತಿ ನಡೆಯ ತರಬೇತಿ|ಸರಳವಾಗಿ ವಿವರಿಸಿ|ಬೆದರಿಕೆ ತೋರಿಸಿ|ಸ್ಥಿತಿಯನ್ನು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ|ನಿಮ್ಮ ಬಲ|ತಿರುವಿನ ಕ್ಷಣ|ಮುಖ್ಯ ಕ್ಷಣಗಳು|ಮುಂದಿನ ತರಬೇತಿ ಗುರಿ|ವೈಯಕ್ತಿಕ ತರಬೇತಿ ಯೋಜನೆ|ಶಿಫಾರಸು|ಅತ್ಯುತ್ತಮ|ಬಹಳ ಒಳ್ಳೆಯದು|ಒಳ್ಳೆಯದು|ಆಡಬಹುದಾದ ನಡೆ|ಸಣ್ಣ ತಪ್ಪು|ತಪ್ಪು|ದೊಡ್ಡ ತಪ್ಪು''',
  'ml':
      '''AI ഗെയിം അവലോകനം|നീക്കത്തിന്റെ നിലവാരം|വിലയിരുത്തൽ ഗ്രാഫ്|ഓരോ നീക്കത്തിനും പരിശീലനം|ലളിതമായി വിശദീകരിക്കുക|ഭീഷണി കാണിക്കുക|സ്ഥിതി വീണ്ടും ശ്രമിക്കുക|നിങ്ങളുടെ കരുത്ത്|വഴിത്തിരിവ്|പ്രധാന നിമിഷങ്ങൾ|അടുത്ത പരിശീലന ലക്ഷ്യം|വ്യക്തിഗത പരിശീലന പദ്ധതി|ശുപാർശ|ഏറ്റവും മികച്ചത്|വളരെ നല്ലത്|നല്ലത്|കളിക്കാവുന്നത്|ചെറിയ പിഴവ്|തെറ്റ്|വലിയ പിഴവ്''',
  'mr':
      '''AI खेळाचे पुनरावलोकन|चालीची गुणवत्ता|मूल्यांकन आलेख|प्रत्येक चालीचे प्रशिक्षण|सोपे समजावून सांगा|धोका दाखवा|स्थिती पुन्हा खेळा|तुमची ताकद|निर्णायक वळण|महत्त्वाचे क्षण|पुढील प्रशिक्षणाचे लक्ष्य|वैयक्तिक प्रशिक्षण योजना|शिफारस|सर्वोत्तम|खूप चांगले|चांगले|खेळण्यायोग्य|किरकोळ चूक|चूक|मोठी चूक''',
  'bn':
      '''AI খেলার পর্যালোচনা|চালের মান|মূল্যায়ন গ্রাফ|প্রতি চালের প্রশিক্ষণ|সহজ করে বোঝান|হুমকি দেখান|অবস্থান আবার খেলুন|আপনার শক্তি|মোড় ঘোরার মুহূর্ত|গুরুত্বপূর্ণ মুহূর্ত|পরের প্রশিক্ষণের লক্ষ্য|ব্যক্তিগত প্রশিক্ষণ পরিকল্পনা|প্রস্তাবিত|সেরা|খুব ভালো|ভালো|খেলার উপযুক্ত|সামান্য ভুল|ভুল|মারাত্মক ভুল''',
  'gu':
      '''AI રમતની સમીક્ષા|ચાલની ગુણવત્તા|મૂલ્યાંકન આલેખ|દરેક ચાલનું માર્ગદર્શન|સરળ રીતે સમજાવો|ખતરો બતાવો|સ્થિતિ ફરી રમો|તમારી તાકાત|નિર્ણાયક વળાંક|મહત્વની ક્ષણો|આગળની તાલીમનું લક્ષ્ય|વ્યક્તિગત તાલીમ યોજના|ભલામણ|શ્રેષ્ઠ|ખૂબ સારું|સારું|રમવા યોગ્ય|નાની ભૂલ|ભૂલ|મોટી ભૂલ''',
  'pa':
      '''AI ਖੇਡ ਸਮੀਖਿਆ|ਚਾਲ ਦੀ ਗੁਣਵੱਤਾ|ਮੁਲਾਂਕਣ ਗ੍ਰਾਫ|ਹਰ ਚਾਲ ਦੀ ਸਿਖਲਾਈ|ਸੌਖੇ ਤਰੀਕੇ ਨਾਲ ਸਮਝਾਓ|ਖ਼ਤਰਾ ਵਿਖਾਓ|ਸਥਿਤੀ ਦੁਬਾਰਾ ਖੇਡੋ|ਤੁਹਾਡੀ ਤਾਕਤ|ਨਿਰਣਾਇਕ ਮੋੜ|ਮਹੱਤਵਪੂਰਨ ਪਲ|ਅਗਲੀ ਸਿਖਲਾਈ ਦਾ ਟੀਚਾ|ਨਿੱਜੀ ਸਿਖਲਾਈ ਯੋਜਨਾ|ਸਿਫ਼ਾਰਸ਼|ਸਭ ਤੋਂ ਵਧੀਆ|ਬਹੁਤ ਵਧੀਆ|ਵਧੀਆ|ਖੇਡਣ ਯੋਗ|ਛੋਟੀ ਗਲਤੀ|ਗਲਤੀ|ਵੱਡੀ ਗਲਤੀ''',
  'ur':
      '''AI کھیل کا جائزہ|چال کا معیار|جائزے کا گراف|ہر چال کی تربیت|آسانی سے سمجھائیں|خطرہ دکھائیں|پوزیشن دوبارہ کھیلیں|آپ کی طاقت|فیصلہ کن موڑ|اہم لمحات|اگلی تربیت کا ہدف|ذاتی تربیتی منصوبہ|تجویز کردہ|بہترین|بہت اچھا|اچھا|کھیلنے کے قابل|معمولی غلطی|غلطی|سنگین غلطی''',
  'ar':
      '''مراجعة المباراة بالذكاء الاصطناعي|جودة النقلات|رسم التقييم|تدريب نقلة بنقلة|اشرح ببساطة|أظهر التهديد|أعد لعب الوضع|نقطة قوتك|نقطة التحول|لحظات مهمة|هدف التدريب التالي|خطة تدريب شخصية|موصى به|الأفضل|ممتاز|جيد|قابل للعب|عدم دقة|خطأ|خطأ فادح''',
  'es':
      '''Análisis de partida con IA|Calidad de jugadas|Gráfico de evaluación|Análisis jugada a jugada|Explicar fácilmente|Mostrar amenaza|Reintentar posición|Tu fortaleza|Punto de inflexión|Momentos importantes|Próximo objetivo de entrenamiento|Plan de entrenamiento personal|Recomendado|La mejor|Excelente|Buena|Jugable|Imprecisión|Error|Error grave''',
  'fr':
      '''Analyse de partie IA|Qualité des coups|Graphe d’évaluation|Coaching coup par coup|Expliquer simplement|Voir la menace|Rejouer la position|Votre point fort|Tournant de la partie|Moments importants|Prochain objectif d’entraînement|Plan d’entraînement personnel|Recommandé|Meilleur|Excellent|Bon|Jouable|Imprécision|Erreur|Gaffe''',
  'de':
      '''KI-Spielanalyse|Zugqualität|Bewertungsgrafik|Zug-für-Zug-Coaching|Einfach erklären|Drohung zeigen|Stellung erneut spielen|Deine Stärke|Wendepunkt|Wichtige Momente|Nächster Trainingsschwerpunkt|Persönlicher Trainingsplan|Empfohlen|Bester|Großartig|Gut|Spielbar|Ungenauigkeit|Fehler|Grober Fehler''',
  'it':
      '''Analisi della partita IA|Qualità delle mosse|Grafico della valutazione|Analisi mossa per mossa|Spiega semplicemente|Mostra la minaccia|Riprova la posizione|Il tuo punto di forza|Punto di svolta|Momenti importanti|Prossimo obiettivo di allenamento|Piano di allenamento personale|Consigliato|Migliore|Ottima|Buona|Giocabile|Imprecisione|Errore|Grave errore''',
  'pt':
      '''Análise de partida com IA|Qualidade dos lances|Gráfico de avaliação|Análise lance a lance|Explicar de forma simples|Mostrar ameaça|Repetir posição|O seu ponto forte|Ponto de viragem|Momentos importantes|Próximo objetivo de treino|Plano de treino pessoal|Recomendado|Melhor|Excelente|Bom|Jogável|Imprecisão|Erro|Erro grave''',
  'ru':
      '''Разбор партии с ИИ|Качество ходов|График оценки|Разбор каждого хода|Объяснить просто|Показать угрозу|Повторить позицию|Ваша сильная сторона|Переломный момент|Важные моменты|Следующая цель тренировки|Личный план тренировок|Рекомендуется|Лучший|Отличный|Хороший|Приемлемый|Неточность|Ошибка|Грубая ошибка''',
  'uk':
      '''Розбір партії зі ШІ|Якість ходів|Графік оцінки|Розбір кожного ходу|Пояснити просто|Показати загрозу|Повторити позицію|Ваша сильна сторона|Переломний момент|Важливі моменти|Наступна мета тренування|Особистий план тренувань|Рекомендовано|Найкращий|Чудовий|Хороший|Прийнятний|Неточність|Помилка|Груба помилка''',
  'tr':
      '''Yapay zekâ oyun incelemesi|Hamle kalitesi|Değerlendirme grafiği|Hamle hamle koçluk|Basitçe açıkla|Tehdidi göster|Konumu yeniden oyna|Güçlü yönün|Dönüm noktası|Önemli anlar|Sonraki antrenman hedefi|Kişisel antrenman planı|Önerilen|En iyi|Harika|İyi|Oynanabilir|İsabetsizlik|Hata|Büyük hata''',
  'fa':
      '''بررسی بازی با هوش مصنوعی|کیفیت حرکت‌ها|نمودار ارزیابی|آموزش حرکت‌به‌حرکت|ساده توضیح بده|تهدید را نشان بده|وضعیت را دوباره بازی کن|نقطهٔ قوت شما|نقطهٔ عطف|لحظه‌های مهم|هدف تمرین بعدی|برنامهٔ تمرین شخصی|پیشنهادی|بهترین|عالی|خوب|قابل بازی|بی‌دقتی|اشتباه|اشتباه بزرگ''',
  'zh':
      '''AI 对局复盘|着法质量|评估曲线|逐步指导|简单解释|显示威胁|重试局面|你的优势|转折点|关键时刻|下一个训练重点|个人训练计划|推荐|最佳|极好|好|可行|不精确|失误|严重失误''',
  'ja':
      '''AI対局レビュー|指し手の質|評価グラフ|一手ごとの指導|簡単に説明|脅威を表示|局面を再挑戦|あなたの強み|転換点|重要な場面|次の練習目標|個人練習計画|おすすめ|最善|素晴らしい|良い|指せる手|不正確|ミス|大きなミス''',
  'ko':
      '''AI 경기 복기|수의 품질|평가 그래프|한 수씩 코칭|쉽게 설명|위협 보기|국면 다시 풀기|나의 강점|전환점|중요한 순간|다음 훈련 목표|개인 훈련 계획|추천|최선|매우 좋음|좋음|둘 만함|부정확|실수|큰 실수''',
  'id':
      '''Tinjauan permainan AI|Kualitas langkah|Grafik evaluasi|Pelatihan per langkah|Jelaskan sederhana|Tampilkan ancaman|Ulangi posisi|Kekuatanmu|Titik balik|Momen penting|Fokus latihan berikutnya|Rencana latihan pribadi|Disarankan|Terbaik|Sangat bagus|Bagus|Dapat dimainkan|Kurang akurat|Kesalahan|Kesalahan besar''',
  'ms':
      '''Semakan permainan AI|Kualiti langkah|Graf penilaian|Bimbingan setiap langkah|Terangkan dengan mudah|Tunjukkan ancaman|Cuba semula kedudukan|Kekuatan anda|Titik perubahan|Detik penting|Fokus latihan seterusnya|Pelan latihan peribadi|Disyorkan|Terbaik|Sangat baik|Baik|Boleh dimainkan|Kurang tepat|Kesilapan|Kesilapan besar''',
  'th':
      '''ทบทวนเกมด้วย AI|คุณภาพตาเดิน|กราฟการประเมิน|คำแนะนำทีละตา|อธิบายง่าย ๆ|แสดงภัยคุกคาม|ลองตำแหน่งอีกครั้ง|จุดแข็งของคุณ|จุดเปลี่ยน|ช่วงเวลาสำคัญ|เป้าหมายฝึกถัดไป|แผนฝึกส่วนบุคคล|แนะนำ|ดีที่สุด|ยอดเยี่ยม|ดี|พอเล่นได้|ไม่แม่นยำ|ผิดพลาด|ผิดพลาดร้ายแรง''',
  'vi':
      '''AI xem lại ván đấu|Chất lượng nước đi|Biểu đồ đánh giá|Huấn luyện từng nước|Giải thích đơn giản|Hiện đe dọa|Thử lại thế cờ|Điểm mạnh của bạn|Bước ngoặt|Thời điểm quan trọng|Trọng tâm luyện tập tiếp theo|Kế hoạch luyện tập cá nhân|Đề xuất|Tốt nhất|Rất tốt|Tốt|Chơi được|Thiếu chính xác|Sai lầm|Sai lầm nghiêm trọng''',
  'pl':
      '''Analiza partii AI|Jakość ruchów|Wykres oceny|Trening ruch po ruchu|Wyjaśnij prosto|Pokaż groźbę|Powtórz pozycję|Twoja mocna strona|Punkt zwrotny|Ważne momenty|Następny cel treningu|Osobisty plan treningu|Zalecane|Najlepszy|Świetny|Dobry|Grywalny|Niedokładność|Błąd|Poważny błąd''',
  'nl':
      '''AI-partijanalyse|Zetkwaliteit|Evaluatiegrafiek|Coaching per zet|Eenvoudig uitleggen|Dreiging tonen|Stelling opnieuw spelen|Je sterke punt|Keerpunt|Belangrijke momenten|Volgend trainingsdoel|Persoonlijk trainingsplan|Aanbevolen|Beste|Uitstekend|Goed|Speelbaar|Onnauwkeurigheid|Fout|Grote fout''',
  'sv':
      '''AI-partianalys|Dragkvalitet|Utvärderingsgraf|Träning drag för drag|Förklara enkelt|Visa hot|Försök ställningen igen|Din styrka|Vändpunkt|Viktiga ögonblick|Nästa träningsmål|Personlig träningsplan|Rekommenderat|Bäst|Utmärkt|Bra|Spelbart|Oexakt|Misstag|Grovt misstag''',
  'el':
      '''Ανάλυση παρτίδας με ΤΝ|Ποιότητα κινήσεων|Γράφημα αξιολόγησης|Καθοδήγηση ανά κίνηση|Εξήγησε απλά|Δείξε την απειλή|Παίξε ξανά τη θέση|Το δυνατό σου σημείο|Σημείο καμπής|Σημαντικές στιγμές|Επόμενος στόχος προπόνησης|Προσωπικό πρόγραμμα προπόνησης|Προτεινόμενο|Καλύτερη|Εξαιρετική|Καλή|Παικτή|Ανακρίβεια|Λάθος|Σοβαρό λάθος''',
  'he':
      '''סקירת משחק AI|איכות המסעים|גרף הערכה|אימון מסע אחר מסע|הסבר בפשטות|הצג איום|נסה שוב את העמדה|החוזקה שלך|נקודת מפנה|רגעים חשובים|יעד האימון הבא|תוכנית אימון אישית|מומלץ|הטוב ביותר|מצוין|טוב|אפשרי|אי־דיוק|טעות|טעות חמורה''',
  'sw':
      '''Uchambuzi wa mchezo wa AI|Ubora wa hatua|Grafu ya tathmini|Mafunzo hatua kwa hatua|Eleza kwa urahisi|Onyesha tishio|Jaribu nafasi tena|Nguvu yako|Hatua ya mabadiliko|Nyakati muhimu|Lengo linalofuata la mafunzo|Mpango binafsi wa mafunzo|Inapendekezwa|Bora zaidi|Nzuri sana|Nzuri|Inachezeka|Kutokuwa sahihi|Kosa|Kosa kubwa''',
};
