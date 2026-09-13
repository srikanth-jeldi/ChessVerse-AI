part of '../main.dart';

class _GameStudioHeader extends StatelessWidget {
  const _GameStudioHeader({
    required this.gameMode,
    required this.playerName,
    required this.soundEnabled,
    required this.onSoundChanged,
    required this.onHome,
    required this.onDailyChallenge,
    required this.onProfile,
    this.onPause,
  });

  final GameMode gameMode;
  final String playerName;
  final bool soundEnabled;
  final ValueChanged<bool> onSoundChanged;
  final VoidCallback onHome;
  final VoidCallback onDailyChallenge;
  final VoidCallback onProfile;
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) {
    final bool compact =
        MediaQuery.sizeOf(context).width < (onPause == null ? 1050 : 1500);
    final String title = switch (gameMode) {
      GameMode.daily => 'Daily Challenge',
      GameMode.puzzle => 'Puzzle Academy',
      GameMode.computer => 'AI Training',
      GameMode.local => 'Local Match',
      GameMode.online => 'Online Battle',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071425).withValues(alpha: 0.96),
        border: const Border(bottom: BorderSide(color: Color(0xFFB47A2B))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: <Widget>[
            if (compact)
              IconButton.outlined(
                key: const ValueKey<String>('desktop-back-to-home'),
                tooltip: 'Back to Home',
                onPressed: onHome,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            else
              OutlinedButton.icon(
                key: const ValueKey<String>('desktop-back-to-home'),
                onPressed: onHome,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Home'),
              ),
            SizedBox(width: compact ? 10 : 16),
            if (onPause != null)
              TextButton.icon(
                key: const ValueKey('pause-computer-game'),
                onPressed: onPause,
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('Pause & Save'),
              ),
            Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/branding/app_icon.png',
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                  ),
                ),
                if (!compact) ...<Widget>[
                  const SizedBox(width: 12),
                  const Text(
                    'ChessVerseAI',
                    style: TextStyle(
                      color: Color(0xFFF2C46D),
                      fontFamily: 'serif',
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: onDailyChallenge,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFFF2C46D),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFF2C46D),
                            fontFamily: 'serif',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!compact)
                          const Text(
                            'Tap for today\'s challenge',
                            style: TextStyle(
                              color: Color(0xFFC7C1B8),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            IconButton.outlined(
              tooltip: soundEnabled ? 'Mute sounds' : 'Enable sounds',
              onPressed: () => onSoundChanged(!soundEnabled),
              icon: Icon(
                soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
              ),
            ),
            const SizedBox(width: 14),
            if (compact)
              IconButton.outlined(
                tooltip: 'Profile',
                onPressed: onProfile,
                icon: const Icon(Icons.person_rounded),
              )
            else
              OutlinedButton.icon(
                onPressed: onProfile,
                icon: const CircleAvatar(
                  radius: 15,
                  backgroundColor: Color(0xFF63D2B8),
                  child: Icon(Icons.person_rounded, size: 19),
                ),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(playerName, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameStudioDock extends StatelessWidget {
  const _GameStudioDock({
    required this.moves,
    required this.capturedWhite,
    required this.capturedBlack,
    required this.onMoveHistory,
  });

  final List<String> moves;
  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;
  final VoidCallback onMoveHistory;

  @override
  Widget build(BuildContext context) {
    final List<String> recentMoves = moves.take(8).toList().reversed.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StudioDockCard(
              child: InkWell(
                onTap: onMoveHistory,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Icon(Icons.format_list_bulleted_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Move history',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: recentMoves.isEmpty
                            ? const Text(
                                'Your moves will appear here.',
                                style: TextStyle(color: Color(0xFF9FA8B8)),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: recentMoves.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, int index) => Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index == recentMoves.length - 1
                                        ? const Color(0xFF63D2B8)
                                        : const Color(0xFF111C30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF33415B),
                                    ),
                                  ),
                                  child: Text(
                                    recentMoves[index],
                                    style: TextStyle(
                                      color: index == recentMoves.length - 1
                                          ? const Color(0xFF061421)
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _StudioDockCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: CapturedMaterial(
                  capturedWhite: capturedWhite,
                  capturedBlack: capturedBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioDockCard extends StatelessWidget {
  const _StudioDockCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071425).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9D6B2A)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StudioCoachPanel extends StatelessWidget {
  const _StudioCoachPanel({
    required this.gameMode,
    required this.activeColor,
    required this.aiThinking,
    required this.coachEnabled,
    required this.coachNote,
    required this.languageCode,
    required this.onLanguage,
    required this.evaluationPawns,
    required this.lastMove,
    required this.lastMoveOwner,
    required this.dailyProgress,
    required this.dailyGoal,
    required this.canUndo,
    required this.hintLabel,
    required this.canHint,
    required this.analyzeLabel,
    required this.onHint,
    required this.onAnalyze,
    required this.onTryAgain,
    required this.onUndo,
    required this.puzzleComplete,
    required this.onNextPuzzle,
    required this.onBackToAcademy,
  });

  final GameMode gameMode;
  final String activeColor;
  final bool aiThinking;
  final bool coachEnabled;
  final String coachNote;
  final String languageCode;
  final VoidCallback onLanguage;
  final double evaluationPawns;
  final String? lastMove;
  final String? lastMoveOwner;
  final int dailyProgress;
  final int dailyGoal;
  final bool canUndo;
  final String hintLabel;
  final bool canHint;
  final String analyzeLabel;
  final VoidCallback onHint;
  final VoidCallback onAnalyze;
  final VoidCallback? onTryAgain;
  final VoidCallback onUndo;
  final bool puzzleComplete;
  final VoidCallback onNextPuzzle;
  final VoidCallback onBackToAcademy;

  @override
  Widget build(BuildContext context) {
    final String modeLabel = switch (gameMode) {
      GameMode.daily => 'DAILY CHALLENGE',
      GameMode.puzzle => 'PUZZLE TRAINING',
      GameMode.computer => 'AI TRAINING • 3-LEVEL HINTS • GAME REVIEW',
      GameMode.local => 'LOCAL MATCH',
      GameMode.online => 'ONLINE BATTLE',
    };
    final String goal = switch (gameMode) {
      GameMode.daily => 'Checkmate in $dailyGoal',
      GameMode.puzzle => 'Checkmate in $dailyGoal',
      GameMode.computer => 'Find the strongest move',
      GameMode.local => 'Outplay your opponent',
      GameMode.online => 'Play a live opponent',
    };
    final String localizedGoal = localizeLiveCoach(
      _localizedCoachGoal(goal, languageCode),
      languageCode,
    );
    final String? localizedMoveOwner = lastMoveOwner == null
        ? null
        : _localizedYourMoveLabel(languageCode);
    final AppLanguage selectedLanguage =
        languageCode == AppLanguageController.systemCode
        ? const AppLanguage(
            AppLanguageController.systemCode,
            'Device',
            'Automatic',
          )
        : AppLanguageController.byCode(languageCode);
    final int progress =
        (gameMode == GameMode.daily || gameMode == GameMode.puzzle)
        ? dailyProgress.clamp(0, dailyGoal)
        : (lastMove == null ? 0 : 1);
    final int goalSteps =
        (gameMode == GameMode.daily || gameMode == GameMode.puzzle)
        ? dailyGoal
        : 3;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool hasBoundedHeight = constraints.hasBoundedHeight;
        final bool compact = constraints.maxHeight < 560;
        final Widget coachMessageCard = _CoachInsightCard(
          icon: Icons.psychology_alt_rounded,
          accent: const Color(0xFF9C6CFF),
          alignStart: true,
          child: SingleChildScrollView(
            child: Text(
              coachEnabled
                  ? coachNote
                  : localizeLiveCoach(
                      'Turn Coach on in Game controls for live move explanations.',
                      languageCode,
                    ),
              style: const TextStyle(
                color: Color(0xFFF2EDE4),
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF061527).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(compact ? 14 : 22),
            border: Border.all(color: const Color(0xFFB47A2B)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (puzzleComplete)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onBackToAcademy,
                            icon: const Icon(Icons.school_rounded),
                            label: Text(
                              localizeLiveCoach('Puzzle Academy', languageCode),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onNextPuzzle,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              coachExtraText('nextPuzzle', languageCode),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                localizeLiveCoach('AI Coach ✦', languageCode),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF63D2B8),
                                  fontFamily: 'serif',
                                  fontSize: compact ? 23 : 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                localizeLiveCoach(modeLabel, languageCode),
                                maxLines: compact ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE2B458),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          key: const ValueKey<String>('live-coach-language'),
                          onPressed: onLanguage,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 8,
                            ),
                            foregroundColor: const Color(0xFFF1BE57),
                          ),
                          icon: const Icon(Icons.translate_rounded, size: 17),
                          label: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compact ? 58 : 82,
                            ),
                            child: Text(
                              '${selectedLanguage.englishName} ▾',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.outlined(
                          tooltip: gameMode == GameMode.online
                              ? 'Undo is unavailable in online games'
                              : 'Undo move',
                          onPressed: canUndo ? onUndo : null,
                          icon: const Icon(Icons.undo_rounded),
                        ),
                      ],
                    ),
                  SizedBox(height: compact ? 8 : 14),
                  _CoachInsightCard(
                    icon: Icons.track_changes_rounded,
                    accent: const Color(0xFF63D2B8),
                    child: Text(
                      '${_localizedGoalLabel(languageCode)}: $localizedGoal',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  if (compact)
                    hasBoundedHeight
                        ? Expanded(child: coachMessageCard)
                        : SizedBox(height: 112, child: coachMessageCard)
                  else
                    SizedBox(height: 84, child: coachMessageCard),
                  if (!compact) ...<Widget>[
                    const SizedBox(height: 10),
                    _CoachInsightCard(
                      icon: Icons.workspace_premium_rounded,
                      accent: const Color(0xFF63D2B8),
                      child: Text(
                        aiThinking
                            ? localizeLiveCoach(
                                'ChessVerseAI is calculating its reply.',
                                languageCode,
                              )
                            : lastMove == null
                            ? _coachCopy(languageCode)[2]
                            : '${localizedMoveOwner ?? 'Last move'}: $lastMove',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF63D2B8),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    hasBoundedHeight
                        ? Expanded(
                            child: _CoachInsightCard(
                              icon: Icons.chat_bubble_rounded,
                              accent: const Color(0xFF63D2B8),
                              alignStart: true,
                              child: SingleChildScrollView(
                                child: Text(
                                  coachEnabled
                                      ? coachNote
                                      : localizeLiveCoach(
                                          'Turn Coach on from Game controls to receive move-by-move explanations.',
                                          languageCode,
                                        ),
                                  style: TextStyle(
                                    color: const Color(0xFFF2EDE4),
                                    fontFamily: 'serif',
                                    fontSize: compact ? 14 : 16,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 160,
                            child: _CoachInsightCard(
                              icon: Icons.chat_bubble_rounded,
                              accent: const Color(0xFF63D2B8),
                              alignStart: true,
                              child: SingleChildScrollView(
                                child: Text(
                                  coachEnabled
                                      ? coachNote
                                      : localizeLiveCoach(
                                          'Turn Coach on from Game controls to receive move-by-move explanations.',
                                          languageCode,
                                        ),
                                  style: TextStyle(
                                    color: const Color(0xFFF2EDE4),
                                    fontFamily: 'serif',
                                    fontSize: compact ? 14 : 16,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                  if (!compact) ...<Widget>[
                    const SizedBox(height: 10),
                    _CoachProgress(
                      progress: progress,
                      goal: goalSteps,
                      languageCode: languageCode,
                    ),
                    const SizedBox(height: 10),
                    _CoachEvaluation(
                      activeColor: activeColor,
                      evaluationPawns: evaluationPawns,
                      languageCode: languageCode,
                    ),
                  ],
                  SizedBox(height: compact ? 8 : 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canHint ? onHint : null,
                          icon: const Icon(Icons.tips_and_updates_outlined),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              localizeLiveCoach(hintLabel, languageCode),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onAnalyze,
                          icon: const Icon(Icons.visibility_outlined),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              localizeLiveCoach(analyzeLabel, languageCode),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onTryAgain,
                          icon: Icon(
                            gameMode == GameMode.online
                                ? Icons.sync_rounded
                                : Icons.refresh_rounded,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              gameMode == GameMode.online
                                  ? localizeLiveCoach('Sync', languageCode)
                                  : localizeLiveCoach(
                                      'Try again',
                                      languageCode,
                                    ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _effectiveLiveCoachLanguage(String code) =>
    AppLanguageController.resolveCode(code);

const Map<String, List<String>> _liveCoachCopy = <String, List<String>>{
  'en': <String>[
    'Goal',
    'Find the strongest move',
    'Select a piece to see legal moves.',
  ],
  'te': <String>[
    'లక్ష్యం',
    'అత్యుత్తమ ఎత్తును కనుగొనండి',
    'చట్టబద్ధమైన ఎత్తులను చూడటానికి ఒక పావును ఎంచుకోండి.',
  ],
  'hi': <String>[
    'लक्ष्य',
    'सबसे मजबूत चाल खोजें',
    'वैध चालें देखने के लिए एक मोहरा चुनें।',
  ],
  'ta': <String>[
    'இலக்கு',
    'சிறந்த நகர்வைக் கண்டறியுங்கள்',
    'சட்டபூர்வ நகர்வுகளைக் காண ஒரு காயைத் தேர்ந்தெடுக்கவும்.',
  ],
  'kn': <String>[
    'ಗುರಿ',
    'ಅತ್ಯುತ್ತಮ ನಡೆಯನ್ನು ಹುಡುಕಿ',
    'ಕಾನೂನುಬದ್ಧ ನಡೆಗಳನ್ನು ನೋಡಲು ಒಂದು ಕಾಯಿಯನ್ನು ಆಯ್ಕೆಮಾಡಿ.',
  ],
  'ml': <String>[
    'ലക്ഷ്യം',
    'ഏറ്റവും മികച്ച നീക്കം കണ്ടെത്തുക',
    'നിയമാനുസൃത നീക്കങ്ങൾ കാണാൻ ഒരു കരു തിരഞ്ഞെടുക്കുക.',
  ],
  'mr': <String>[
    'ध्येय',
    'सर्वोत्तम चाल शोधा',
    'वैध चाली पाहण्यासाठी एक मोहरा निवडा.',
  ],
  'bn': <String>[
    'লক্ষ্য',
    'সবচেয়ে শক্তিশালী চালটি খুঁজুন',
    'বৈধ চাল দেখতে একটি ঘুঁটি নির্বাচন করুন।',
  ],
  'gu': <String>[
    'લક્ષ્ય',
    'સૌથી મજબૂત ચાલ શોધો',
    'માન્ય ચાલ જોવા માટે એક મહોરું પસંદ કરો.',
  ],
  'pa': <String>[
    'ਟੀਚਾ',
    'ਸਭ ਤੋਂ ਮਜ਼ਬੂਤ ਚਾਲ ਲੱਭੋ',
    'ਕਾਨੂੰਨੀ ਚਾਲਾਂ ਦੇਖਣ ਲਈ ਇੱਕ ਮੋਹਰਾ ਚੁਣੋ।',
  ],
  'ur': <String>[
    'مقصد',
    'سب سے مضبوط چال تلاش کریں',
    'قانونی چالیں دیکھنے کے لیے ایک مہرہ منتخب کریں۔',
  ],
  'ar': <String>[
    'الهدف',
    'اعثر على أقوى نقلة',
    'اختر قطعة لرؤية النقلات القانونية.',
  ],
  'es': <String>[
    'Objetivo',
    'Encuentra la jugada más fuerte',
    'Selecciona una pieza para ver los movimientos legales.',
  ],
  'fr': <String>[
    'Objectif',
    'Trouvez le meilleur coup',
    'Sélectionnez une pièce pour voir les coups légaux.',
  ],
  'de': <String>[
    'Ziel',
    'Finde den stärksten Zug',
    'Wähle eine Figur, um die legalen Züge zu sehen.',
  ],
  'it': <String>[
    'Obiettivo',
    'Trova la mossa migliore',
    'Seleziona un pezzo per vedere le mosse legali.',
  ],
  'pt': <String>[
    'Objetivo',
    'Encontre a jogada mais forte',
    'Selecione uma peça para ver as jogadas legais.',
  ],
  'ru': <String>[
    'Цель',
    'Найдите сильнейший ход',
    'Выберите фигуру, чтобы увидеть допустимые ходы.',
  ],
  'uk': <String>[
    'Мета',
    'Знайдіть найсильніший хід',
    'Виберіть фігуру, щоб побачити дозволені ходи.',
  ],
  'tr': <String>[
    'Hedef',
    'En güçlü hamleyi bul',
    'Yasal hamleleri görmek için bir taş seçin.',
  ],
  'fa': <String>[
    'هدف',
    'قوی‌ترین حرکت را پیدا کنید',
    'برای دیدن حرکت‌های مجاز یک مهره را انتخاب کنید.',
  ],
  'zh': <String>['目标', '找出最佳着法', '选择一个棋子以查看合法走法。'],
  'ja': <String>['目標', '最善手を見つける', '合法手を表示するには駒を選択してください。'],
  'ko': <String>['목표', '가장 강한 수를 찾으세요', '합법적인 수를 보려면 말을 선택하세요.'],
  'id': <String>[
    'Tujuan',
    'Temukan langkah terbaik',
    'Pilih bidak untuk melihat langkah yang sah.',
  ],
  'ms': <String>[
    'Matlamat',
    'Cari langkah terbaik',
    'Pilih buah untuk melihat langkah yang sah.',
  ],
  'th': <String>[
    'เป้าหมาย',
    'ค้นหาตาที่ดีที่สุด',
    'เลือกตัวหมากเพื่อดูตาเดินที่ถูกต้อง',
  ],
  'vi': <String>[
    'Mục tiêu',
    'Tìm nước đi mạnh nhất',
    'Chọn một quân để xem các nước đi hợp lệ.',
  ],
  'pl': <String>[
    'Cel',
    'Znajdź najlepszy ruch',
    'Wybierz figurę, aby zobaczyć dozwolone ruchy.',
  ],
  'nl': <String>[
    'Doel',
    'Vind de sterkste zet',
    'Selecteer een stuk om geldige zetten te zien.',
  ],
  'sv': <String>[
    'Mål',
    'Hitta det starkaste draget',
    'Välj en pjäs för att se giltiga drag.',
  ],
  'el': <String>[
    'Στόχος',
    'Βρείτε την ισχυρότερη κίνηση',
    'Επιλέξτε ένα κομμάτι για να δείτε τις νόμιμες κινήσεις.',
  ],
  'he': <String>[
    'מטרה',
    'מצא את המסע החזק ביותר',
    'בחר כלי כדי לראות מסעים חוקיים.',
  ],
  'sw': <String>[
    'Lengo',
    'Tafuta hatua bora zaidi',
    'Chagua kete ili kuona hatua halali.',
  ],
};

List<String> _coachCopy(String languageCode) =>
    _liveCoachCopy[_effectiveLiveCoachLanguage(languageCode)] ??
    _liveCoachCopy['en']!;

String _localizedGoalLabel(String languageCode) => _coachCopy(languageCode)[0];

String _localizedCoachGoal(String goal, String languageCode) =>
    goal == 'Find the strongest move' ? _coachCopy(languageCode)[1] : goal;

String _localizedLiveCoachText(String text, String languageCode) =>
    localizeLiveCoach(text, languageCode);

String _localizedYourMoveLabel(String languageCode) =>
    localizeLiveCoach('Your move', languageCode);

String _localizedCoachUiLabel(String key, String languageCode) =>
    localizeLiveCoach(
      key == 'progress' ? 'Step progress' : 'Evaluation',
      languageCode,
    );

class _CoachInsightCard extends StatelessWidget {
  const _CoachInsightCard({
    required this.icon,
    required this.accent,
    required this.child,
    this.alignStart = false,
  });

  final IconData icon;
  final Color accent;
  final Widget child;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C622D)),
      ),
      child: Row(
        crossAxisAlignment: alignStart
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: accent, size: 25),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CoachProgress extends StatelessWidget {
  const _CoachProgress({
    required this.progress,
    required this.goal,
    required this.languageCode,
  });

  final int progress;
  final int goal;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final int safeGoal = math.max(goal, 1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C622D)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            _localizedCoachUiLabel('progress', languageCode),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress / safeGoal,
                backgroundColor: const Color(0xFF27344A),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF63D2B8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$progress/$safeGoal',
            style: const TextStyle(
              color: Color(0xFF63D2B8),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachEvaluation extends StatelessWidget {
  const _CoachEvaluation({
    required this.activeColor,
    required this.evaluationPawns,
    required this.languageCode,
  });

  final String activeColor;
  final double evaluationPawns;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C622D)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            '${_localizedCoachUiLabel('evaluation', languageCode)} '
            '${evaluationPawns == 0 ? '0.0' : '${evaluationPawns > 0 ? '+' : ''}${evaluationPawns.toStringAsFixed(1)}'}',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF202B3D),
                    Color(0xFF3D4B62),
                    Color(0xFF63D2B8),
                    Color(0xFF202B3D),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                localizeLiveCoach(activeColor, languageCode),
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF63D2B8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineConnectionBanner extends StatelessWidget {
  const _OnlineConnectionBanner({
    required this.reconnecting,
    required this.opponentAway,
    this.tournamentName,
    this.tournamentRound,
  });

  final bool reconnecting;
  final bool opponentAway;
  final String? tournamentName;
  final int? tournamentRound;

  @override
  Widget build(BuildContext context) {
    final bool healthy = !reconnecting && !opponentAway;
    final Color color = healthy
        ? const Color(0xFF63D2B8)
        : const Color(0xFFE5B856);
    final String connection = reconnecting
        ? 'Reconnecting to match…'
        : opponentAway
        ? 'Opponent offline — waiting for reconnect'
        : 'Both players online';
    final String label = tournamentName == null
        ? connection
        : '${tournamentName!.toUpperCase()} • ROUND ${tournamentRound ?? 1} • $connection';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (reconnecting)
            SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.7, color: color),
            )
          else
            Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineArenaBoard extends StatelessWidget {
  const _OnlineArenaBoard({
    required this.board,
    required this.flipped,
    required this.whiteName,
    required this.blackName,
    required this.whitePhotoUrl,
    required this.blackPhotoUrl,
    required this.whiteClock,
    required this.blackClock,
    required this.activeColor,
    required this.matchActive,
    required this.socketConnected,
    required this.connectedPlayers,
    this.tournamentName,
    this.tournamentRound,
    this.compactOverlay = false,
    this.bottomAction,
  });

  final Widget board;
  final bool flipped;
  final String whiteName;
  final String blackName;
  final String? whitePhotoUrl;
  final String? blackPhotoUrl;
  final String whiteClock;
  final String blackClock;
  final String activeColor;
  final bool matchActive;
  final bool socketConnected;
  final int connectedPlayers;
  final String? tournamentName;
  final int? tournamentRound;
  final bool compactOverlay;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final Widget white = _OnlinePlayerRail(
      name: whiteName,
      photoUrl: whitePhotoUrl,
      clock: whiteClock,
      active: matchActive && activeColor == 'white',
      pieceColor: Colors.white,
      compact: compactOverlay,
    );
    final Widget black = _OnlinePlayerRail(
      name: blackName,
      photoUrl: blackPhotoUrl,
      clock: blackClock,
      active: matchActive && activeColor == 'black',
      pieceColor: const Color(0xFF171717),
      compact: compactOverlay,
    );
    if (compactOverlay) {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          board,
          Positioned(
            left: 6,
            right: 6,
            top: 6,
            height: 38,
            child: flipped ? white : black,
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            height: 38,
            child: flipped ? black : white,
          ),
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: _OnlineConnectionBanner(
                reconnecting: !socketConnected,
                opponentAway: socketConnected && connectedPlayers < 2,
                tournamentName: tournamentName,
                tournamentRound: tournamentRound,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        SizedBox(
          height: 28,
          child: Center(
            child: _OnlineConnectionBanner(
              reconnecting: !socketConnected,
              opponentAway: socketConnected && connectedPlayers < 2,
              tournamentName: tournamentName,
              tournamentRound: tournamentRound,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(height: 48, child: flipped ? white : black),
        const SizedBox(height: 4),
        Expanded(child: board),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: OnlineQuickChatPlayerRow(
            playerRail: flipped ? black : white,
            action: bottomAction,
          ),
        ),
      ],
    );
  }
}

/// Reserve space beside the player clock instead of painting chat over it.
class OnlineQuickChatPlayerRow extends StatelessWidget {
  const OnlineQuickChatPlayerRow({
    required this.playerRail,
    this.action,
    super.key,
  });
  final Widget playerRail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => action == null
      ? playerRail
      : Row(
          textDirection: TextDirection.ltr,
          children: [
            Expanded(child: playerRail),
            const SizedBox(width: 6),
            SizedBox(width: 48, height: 48, child: action),
          ],
        );
}

class _OnlinePlayerRail extends StatelessWidget {
  const _OnlinePlayerRail({
    required this.name,
    required this.photoUrl,
    required this.clock,
    required this.active,
    required this.pieceColor,
    this.compact = false,
  });

  final String name;
  final String? photoUrl;
  final String clock;
  final bool active;
  final Color pieceColor;
  final bool compact;

  String get initials {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'CV';
    return words.take(2).map((String word) => word[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final String? usablePhoto = photoUrl != null && photoUrl!.trim().isNotEmpty
        ? photoUrl!.trim()
        : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF173A35) : const Color(0xFF111C1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? const Color(0xFF63D2B8) : const Color(0xFF755A32),
          width: active ? 1.6 : 1,
        ),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF63D2B8).withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        children: <Widget>[
          ClipOval(
            child: SizedBox.square(
              dimension: compact ? 26 : 34,
              child: usablePhoto == null
                  ? _AvatarInitials(initials: initials)
                  : Image.network(
                      usablePhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _AvatarInitials(initials: initials),
                    ),
            ),
          ),
          SizedBox(width: compact ? 5 : 8),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: pieceColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB9914E)),
            ),
          ),
          SizedBox(width: compact ? 5 : 7),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFFF4ECDD),
                fontSize: compact ? 12 : null,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 3 : 5,
            ),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF63D2B8) : const Color(0xFF24272A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              clock,
              style: TextStyle(
                color: active ? const Color(0xFF071A17) : Colors.white,
                fontSize: compact ? 14 : 18,
                fontWeight: FontWeight.w900,
                fontFeatures: const <ui.FontFeature>[
                  ui.FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF1F7E72), Color(0xFF493481)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.compact,
    required this.collapsible,
    required this.expanded,
    required this.whitePlayerName,
    required this.blackPlayerName,
    required this.activeColor,
    required this.gameMode,
    required this.aiLevel,
    required this.aiThinking,
    required this.coachEnabled,
    required this.moves,
    required this.capturedWhite,
    required this.capturedBlack,
    required this.coachNote,
    required this.whiteClock,
    required this.blackClock,
    required this.skin,
    required this.onSkinChanged,
    required this.onGameModeChanged,
    required this.dailyDifficulty,
    required this.dailyProgress,
    required this.dailyGoal,
    required this.dailyMistakes,
    required this.onDailyDifficultyChanged,
    required this.onAiLevelChanged,
    required this.onCoachChanged,
    required this.onNewGameRequested,
    required this.onResign,
    required this.onOfferDraw,
    required this.onMoveHistory,
    required this.onUndo,
    required this.onHint,
    required this.onAnalyze,
    required this.soundEnabled,
    required this.showCoordinates,
    required this.showMoveHints,
    required this.onSoundChanged,
    required this.onShowCoordinatesChanged,
    required this.onShowMoveHintsChanged,
    required this.onEditBlackPlayer,
    required this.onToggleExpanded,
    required this.onLogout,
    required this.canUndo,
    super.key,
  });

  final bool compact;
  final bool collapsible;
  final bool expanded;
  final String whitePlayerName;
  final String blackPlayerName;
  final String activeColor;
  final GameMode gameMode;
  final int aiLevel;
  final bool aiThinking;
  final bool coachEnabled;
  final List<String> moves;
  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;
  final String coachNote;
  final String whiteClock;
  final String blackClock;
  final BoardSkin skin;
  final ValueChanged<BoardSkin> onSkinChanged;
  final ValueChanged<GameMode> onGameModeChanged;
  final DailyChallengeDifficulty dailyDifficulty;
  final int dailyProgress;
  final int dailyGoal;
  final int dailyMistakes;
  final ValueChanged<DailyChallengeDifficulty> onDailyDifficultyChanged;
  final ValueChanged<double> onAiLevelChanged;
  final ValueChanged<bool> onCoachChanged;
  final VoidCallback onNewGameRequested;
  final VoidCallback onResign;
  final VoidCallback onOfferDraw;
  final VoidCallback onMoveHistory;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onAnalyze;
  final bool soundEnabled;
  final bool showCoordinates;
  final bool showMoveHints;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onShowCoordinatesChanged;
  final ValueChanged<bool> onShowMoveHintsChanged;
  final VoidCallback onEditBlackPlayer;
  final VoidCallback onToggleExpanded;
  final VoidCallback onLogout;
  final bool canUndo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final AiProfile aiProfile = aiProfileFor(aiLevel);
        final bool collapsed = collapsible && !expanded;
        final bool collapsedRail = constraints.maxWidth < 310;
        final Widget history = moves.isEmpty
            ? const EmptyMoveState()
            : ListView.separated(
                itemCount: moves.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final bool whiteMove = (moves.length - 1 - index).isEven;
                  final String move = moves[index];
                  return ListTile(
                    dense: true,
                    minLeadingWidth: 32,
                    leading: Text('${moves.length - index}.'),
                    title: Row(
                      children: <Widget>[
                        Expanded(child: Text(move)),
                        MoveQualityBadge(move: move),
                      ],
                    ),
                    subtitle: Text(
                      moveCoachNoteForMove(move, whiteMove),
                      maxLines: 3,
                      overflow: TextOverflow.fade,
                    ),
                  );
                },
              );

        if (collapsedRail) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF17231F).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF98743B).withValues(alpha: 0.72),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      key: const ValueKey<String>('game-controls-handle'),
                      onTap: onToggleExpanded,
                      borderRadius: BorderRadius.circular(8),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.tune_rounded, size: 30),
                            SizedBox(height: 8),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                'GAME CONTROLS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Icon(Icons.chevron_left_rounded, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New game',
                    onPressed: onNewGameRequested,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    tooltip: 'Undo move',
                    onPressed: canUndo ? onUndo : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }

        final List<Widget> controls = <Widget>[
          if (collapsible)
            Semantics(
              button: true,
              label: expanded
                  ? 'Collapse game controls'
                  : 'Expand game controls',
              child: InkWell(
                key: const ValueKey<String>('game-controls-handle'),
                onTap: onToggleExpanded,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.drag_handle_rounded, size: 28),
                      const SizedBox(width: 6),
                      Text(
                        expanded ? 'Less controls' : 'More controls',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  switch (gameMode) {
                    GameMode.computer => 'Solo Challenge',
                    GameMode.daily => 'Daily Checkmate',
                    GameMode.puzzle => 'Puzzle Training',
                    GameMode.local => 'Pass & Play',
                    GameMode.online => 'Online Battle',
                  },
                  style: compact
                      ? Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        )
                      : Theme.of(context).textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'New game',
                onPressed: onNewGameRequested,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Undo move',
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              if (!compact)
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GameModeLauncher(
            selected: gameMode,
            compact: compact,
            onChanged: onGameModeChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusPill(
                icon: Icons.auto_awesome_rounded,
                label: coachEnabled ? 'Coach on' : 'Coach off',
              ),
              if (gameMode == GameMode.computer)
                StatusPill(
                  icon: aiThinking
                      ? Icons.hourglass_top_rounded
                      : Icons.speed_rounded,
                  label: aiThinking ? 'Thinking' : aiProfile.name,
                ),
              if (gameMode == GameMode.daily || gameMode == GameMode.puzzle)
                StatusPill(
                  icon: Icons.local_fire_department_rounded,
                  label: '$dailyProgress/$dailyGoal solved',
                ),
              StatusPill(icon: Icons.memory_rounded, label: activeColor),
            ],
          ),
          if (gameMode == GameMode.local) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey<String>('rename-player-two'),
              onPressed: onEditBlackPlayer,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: Text('Player 2: $blackPlayerName'),
            ),
          ],
          if (gameMode == GameMode.daily) ...<Widget>[
            const SizedBox(height: 10),
            DailyDifficultyChips(
              selected: dailyDifficulty,
              onChanged: onDailyDifficultyChanged,
            ),
            if (dailyMistakes > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '$dailyMistakes attempt${dailyMistakes == 1 ? '' : 's'} missed - keep calculating',
                style: const TextStyle(color: Color(0xFFE2B458)),
              ),
            ],
          ],
          if (collapsed) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: MatchClock(label: whitePlayerName, value: whiteClock),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MatchClock(label: blackPlayerName, value: blackClock),
                ),
              ],
            ),
          ],
          if (collapsed) const SizedBox(height: 10),
        ];

        final List<Widget> expandedOnlyControls = <Widget>[
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              SizedBox(
                width: compact ? 116 : 132,
                child: _PanelActionButton(
                  onPressed: onMoveHistory,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('History'),
                ),
              ),
              SizedBox(
                width: compact ? 100 : 118,
                child: _PanelActionButton(
                  onPressed: onOfferDraw,
                  icon: const Icon(Icons.handshake_rounded),
                  label: const Text('Draw'),
                ),
              ),
              SizedBox(
                width: compact ? 108 : 124,
                child: _PanelActionButton(
                  onPressed: onResign,
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Resign'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: MatchClock(label: whitePlayerName, value: whiteClock),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MatchClock(label: blackPlayerName, value: blackClock),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CoachInsight(note: coachNote, enabled: coachEnabled),
          if (!compact) ...<Widget>[
            const SizedBox(height: 18),
            CapturedMaterial(
              capturedWhite: capturedWhite,
              capturedBlack: capturedBlack,
            ),
          ],
          const SizedBox(height: 18),
          Text('Board', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<BoardSkin>(
            key: const ValueKey<String>('board-theme-menu'),
            initialValue: skin,
            decoration: const InputDecoration(
              labelText: 'Board theme',
              prefixIcon: Icon(Icons.palette_outlined),
              border: OutlineInputBorder(),
            ),
            items: boardPalettes.entries
                .map(
                  (MapEntry<BoardSkin, BoardPalette> entry) =>
                      DropdownMenuItem<BoardSkin>(
                        value: entry.key,
                        child: BoardThemeMenuItem(palette: entry.value),
                      ),
                )
                .toList(),
            onChanged: (BoardSkin? selectedSkin) {
              if (selectedSkin != null) {
                onSkinChanged(selectedSkin);
              }
            },
          ),
          if (gameMode == GameMode.computer) ...<Widget>[
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${aiProfile.name} - Level $aiLevel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '~${aiProfile.elo} Elo',
                  style: const TextStyle(
                    color: Color(0xFF63D2B8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              aiProfile.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              value: aiLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${aiProfile.name} - ~${aiProfile.elo} Elo',
              onChanged: onAiLevelChanged,
            ),
          ],
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: coachEnabled,
              onChanged: onCoachChanged,
              title: const Text('AI coach'),
              secondary: const Icon(Icons.psychology_alt_rounded),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: soundEnabled,
              onChanged: onSoundChanged,
              title: const Text('Sound effects'),
              secondary: const Icon(Icons.volume_up_rounded),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: showCoordinates,
              onChanged: onShowCoordinatesChanged,
              title: const Text('Show coordinates'),
              secondary: const Icon(Icons.grid_4x4_rounded),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: showMoveHints,
              onChanged: onShowMoveHintsChanged,
              title: const Text('Move hints'),
              secondary: const Icon(Icons.lightbulb_outline_rounded),
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.view_in_ar_rounded),
            title: Text('Piece theme'),
            subtitle: Text('Staunton 3D active - more themes coming soon'),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onHint,
                  icon: const Icon(Icons.psychology_alt_rounded),
                  label: const Text('Hint'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text('Analyze'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Move history',
            style: compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
        ];

        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...controls,
            if (!collapsed) ...<Widget>[
              ...expandedOnlyControls,
              SizedBox(height: compact ? 120 : 220, child: history),
            ],
          ],
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF17231F).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF98743B).withValues(alpha: 0.72),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 18),
            child: SingleChildScrollView(child: content),
          ),
        );
      },
    );
  }
}

class _PanelActionButton extends StatelessWidget {
  const _PanelActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: IconTheme.merge(data: const IconThemeData(size: 18), child: icon),
      label: DefaultTextStyle.merge(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: label,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 50),
      ),
    );
  }
}

class GameModeLauncher extends StatelessWidget {
  const GameModeLauncher({
    required this.selected,
    required this.compact,
    required this.onChanged,
    super.key,
  });

  final GameMode selected;
  final bool compact;
  final ValueChanged<GameMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<_GameModeChoice> choices = <_GameModeChoice>[
      const _GameModeChoice(
        mode: GameMode.computer,
        icon: Icons.smart_toy_rounded,
        title: 'Play vs AI',
        subtitle: 'Challenge ChessVerseAI',
      ),
      const _GameModeChoice(
        mode: GameMode.daily,
        icon: Icons.local_fire_department_rounded,
        title: 'Daily Checkmate',
        subtitle: 'Finish a late-game puzzle',
      ),
      const _GameModeChoice(
        mode: GameMode.local,
        icon: Icons.groups_2_rounded,
        title: '2 Players',
        subtitle: 'Same-device match',
      ),
      const _GameModeChoice(
        mode: GameMode.online,
        icon: Icons.public_rounded,
        title: 'Online',
        subtitle: 'Matchmaking & reconnect',
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices
          .map((choice) {
            final bool active = selected == choice.mode;
            return SizedBox(
              width: compact ? 148 : 178,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(choice.mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: active
                          ? const <Color>[Color(0xFF2B2140), Color(0xFF6D4FD8)]
                          : <Color>[
                              const Color(0xFF211D24),
                              const Color(0xFF111C18).withValues(alpha: 0.92),
                            ],
                    ),
                    border: Border.all(
                      color: active
                          ? const Color(0xFFE2B458)
                          : const Color(0xFF7A6038).withValues(alpha: 0.55),
                    ),
                    boxShadow: <BoxShadow>[
                      if (active)
                        BoxShadow(
                          color: const Color(
                            0xFF6D4FD8,
                          ).withValues(alpha: 0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        choice.icon,
                        color: const Color(0xFFE2B458),
                        size: 22,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              choice.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              choice.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _GameModeChoice {
  const _GameModeChoice({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final GameMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
}

class DailyDifficultyChips extends StatelessWidget {
  const DailyDifficultyChips({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final DailyChallengeDifficulty selected;
  final ValueChanged<DailyChallengeDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DailyChallengeDifficulty.values
          .map((difficulty) {
            final bool active = selected == difficulty;
            return ChoiceChip(
              selected: active,
              avatar: Icon(
                Icons.emoji_events_outlined,
                size: 18,
                color: active ? Colors.black : const Color(0xFFE2B458),
              ),
              label: Text(difficulty.label),
              onSelected: (_) => onChanged(difficulty),
            );
          })
          .toList(growable: false),
    );
  }
}

class BoardThemeMenuItem extends StatelessWidget {
  const BoardThemeMenuItem({required this.palette, super.key});

  final BoardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            width: 34,
            height: 24,
            child: Row(
              children: <Widget>[
                Expanded(child: ColoredBox(color: palette.light)),
                Expanded(child: ColoredBox(color: palette.dark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(palette.label),
      ],
    );
  }
}

class PositionAnalysisSheet extends StatelessWidget {
  const PositionAnalysisSheet({
    required this.analysis,
    this.languageCode = 'en',
    super.key,
  });

  final PositionAnalysis analysis;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final String evaluation = analysis.evaluation == 0
        ? localizeLiveCoach('Equal', languageCode)
        : analysis.evaluation > 0
        ? '${CoachLocalizations(languageCode).source('White')} +${analysis.evaluation.toStringAsFixed(1)}'
        : '${CoachLocalizations(languageCode).source('Black')} +${analysis.evaluation.abs().toStringAsFixed(1)}';

    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewport) {
          final bool shortLandscape =
              viewport.maxWidth > viewport.maxHeight &&
              viewport.maxHeight < 500;
          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: viewport.maxHeight * 0.98,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFF17231F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFF8B7147)),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    shortLandscape ? 8 : 12,
                    20,
                    shortLandscape ? 10 : 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF786B58),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(height: shortLandscape ? 8 : 16),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.analytics_rounded,
                            color: Color(0xFFD6A84F),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              localizeLiveCoach('AI Coach', languageCode),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: coachExtraText('close', languageCode),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      SizedBox(height: shortLandscape ? 6 : 14),
                      AnalysisMetric(
                        icon: Icons.balance_rounded,
                        label: localizeLiveCoach('Evaluation', languageCode),
                        value: evaluation,
                      ),
                      AnalysisMetric(
                        icon: Icons.route_rounded,
                        label: localizeLiveCoach(
                          '${analysis.side} legal moves',
                          languageCode,
                        ),
                        value: '${analysis.legalMoves}',
                      ),
                      AnalysisMetric(
                        icon: Icons.gps_fixed_rounded,
                        label: localizeLiveCoach(
                          'Immediate captures',
                          languageCode,
                        ),
                        value: '${analysis.captures}',
                      ),
                      AnalysisMetric(
                        icon: Icons.auto_graph_rounded,
                        label: CoachLocalizations(
                          languageCode,
                        ).text('moveQuality'),
                        value: localizeLiveCoach(
                          analysis.quality,
                          languageCode,
                        ),
                      ),
                      AnalysisMetric(
                        icon: analysis.inCheck
                            ? Icons.warning_amber_rounded
                            : Icons.shield_outlined,
                        label: analysisDashboardText(
                          'kingSafety',
                          languageCode,
                        ),
                        value: localizeLiveCoach(
                          analysis.inCheck ? 'In check' : 'Safe',
                          languageCode,
                        ),
                      ),
                      SizedBox(height: shortLandscape ? 6 : 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFD6A84F,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: const Color(
                              0xFFD6A84F,
                            ).withValues(alpha: 0.48),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(shortLandscape ? 10 : 14),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFD6A84F),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  analysis.bestMove == null
                                      ? localizeLiveCoach(
                                          'No legal move',
                                          languageCode,
                                        )
                                      : '${CoachLocalizations(languageCode).text('recommended')}: ${analysis.bestMove}\n${localizeLiveCoach(analysis.coachLine, languageCode)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnalysisMetric extends StatelessWidget {
  const AnalysisMetric({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: const Color(0xFF63D2B8)),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
