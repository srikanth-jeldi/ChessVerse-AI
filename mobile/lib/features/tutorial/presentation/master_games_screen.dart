import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/academy_story_localizations.dart';
import '../../../core/audio/cloud_narration_service.dart';
import '../../../core/app_language.dart';
import '../../../core/desktop_navigation_bridge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../../core/widgets/coin_balance_badge.dart';
import '../../../core/widgets/desktop_app_sidebar.dart';
import '../data/academy_progress_store.dart';
import '../domain/master_game_lesson.dart';

enum _MasterNarrationState { stopped, playing, paused }

class MasterGamesScreen extends StatefulWidget {
  const MasterGamesScreen({super.key});

  @override
  State<MasterGamesScreen> createState() => _MasterGamesScreenState();
}

class _MasterGamesScreenState extends State<MasterGamesScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  String _languageCode = AppLanguageController.resolveCode(
    AppLanguageController.systemCode,
  );
  Set<String> _completed = <String>{};

  AcademyStoryLocalizations get _copy =>
      AcademyStoryLocalizations(_languageCode);

  @override
  void initState() {
    super.initState();
    AppLanguageController.effectiveLanguageChanges.addListener(
      _handleLanguageChange,
    );
    AppLanguageController.effectiveCode().then((String code) {
      if (mounted) setState(() => _languageCode = code);
    });
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final Set<String> completed = await _progressStore
          .readCompletedMasterGames();
      if (mounted) setState(() => _completed = completed);
    } on Object {
      // The catalog remains available if secure storage is unavailable.
    }
  }

  void _handleLanguageChange() {
    final String? code = AppLanguageController.effectiveLanguageChanges.value;
    if (code != null && mounted) setState(() => _languageCode = code);
  }

  @override
  void dispose() {
    AppLanguageController.effectiveLanguageChanges.removeListener(
      _handleLanguageChange,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AcademyStoryLocalizations copy = _copy;
    final Widget page = Scaffold(
      backgroundColor: const Color(0xFF06131F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(copy.text('master.title')),
            const Text(
              'Learn from legendary turning points.',
              style: TextStyle(color: Color(0xFF9DB4CA), fontSize: 11),
            ),
          ],
        ),
        actions: <Widget>[
          ValueListenableBuilder<int?>(
            valueListenable: DesktopNavigationBridge.coinBalance,
            builder: (BuildContext context, int? balance, _) =>
                CoinBalanceBadge(
                  balance: balance,
                  expandedLabel: MediaQuery.sizeOf(context).width >= 700,
                  onTap: () => DesktopNavigationBridge.open(context, 7),
                ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/master-games-hall-v1.webp'),
            fit: BoxFit.cover,
            opacity: .12,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                _MasterCatalogHero(copy: copy, completed: _completed),
                const SizedBox(height: 16),
                for (final MasterGameLesson lesson in MasterGameCatalog.lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MasterGameCard(
                      lesson: lesson,
                      copy: copy,
                      completed: _completed.contains(lesson.id),
                      onReturned: _loadProgress,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!kIsWeb || MediaQuery.sizeOf(context).width < 700) return page;
    return Scaffold(
      backgroundColor: const Color(0xFF06131F),
      body: Row(
        children: <Widget>[
          DesktopAppSidebar(
            selected: 'Learn',
            onHome: () => DesktopNavigationBridge.open(context, 0),
            onPlay: () => DesktopNavigationBridge.open(context, 1),
            onMyGames: () => DesktopNavigationBridge.open(context, 6),
            onPuzzles: () => DesktopNavigationBridge.open(context, 2),
            onLearn: () => DesktopNavigationBridge.open(context, 3),
            onProfile: () => DesktopNavigationBridge.open(context, 4),
            onFriends: () => DesktopNavigationBridge.open(context, 5),
            onCollection: () => DesktopNavigationBridge.open(context, 7),
          ),
          Expanded(child: page),
        ],
      ),
    );
  }
}

class _MasterCatalogHero extends StatelessWidget {
  const _MasterCatalogHero({required this.copy, required this.completed});

  final AcademyStoryLocalizations copy;
  final Set<String> completed;

  int get total => MasterGameCatalog.lessons.length;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool compact = constraints.maxWidth < 560;
      final Widget copyBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accentGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy.text('master.eyebrow'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            copy.text('master.title'),
            style: TextStyle(
              color: const Color(0xFFF5EBD5),
              fontFamily: 'serif',
              fontSize: compact ? 30 : 38,
              height: 1.04,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.text('master.intro'),
            maxLines: compact ? 4 : 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              for (int index = 0; index < total; index++) ...<Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  width: compact ? 18 : 24,
                  height: compact ? 18 : 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < completed.length
                        ? AppColors.accentGold
                        : const Color(0xFF0A1C31),
                    border: Border.all(
                      color: index < completed.length
                          ? const Color(0xFFFFE18A)
                          : const Color(0xFF5CAEFF),
                    ),
                    boxShadow: index < completed.length
                        ? const <BoxShadow>[
                            BoxShadow(color: Color(0x88E5B651), blurRadius: 10),
                          ]
                        : null,
                  ),
                ),
                if (index + 1 < total)
                  Expanded(
                    child: Container(height: 1, color: const Color(0x665CAEFF)),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${completed.length}/$total  MASTER MOMENTS',
            style: const TextStyle(
              color: Color(0xFF86D8FF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      );
      return Container(
        height: compact ? 340 : 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF63C8FF), width: 1.2),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x5540BFFF), blurRadius: 28),
            BoxShadow(color: Color(0x33E5B651), blurRadius: 18),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const Image(
                image: AssetImage(
                  'assets/backgrounds/master-games-hall-v1.webp',
                ),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color(0xF2081C30),
                      Color(0xD9081C30),
                      Color(0x33030B13),
                    ],
                    stops: <double>[0, .58, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 20 : 28,
                  24,
                  compact ? 34 : 260,
                  22,
                ),
                child: copyBlock,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MasterGameCard extends StatelessWidget {
  const _MasterGameCard({
    required this.lesson,
    required this.copy,
    required this.completed,
    required this.onReturned,
  });
  final MasterGameLesson lesson;
  final AcademyStoryLocalizations copy;
  final bool completed;
  final VoidCallback onReturned;

  _MasterGameVisual get _visual => switch (lesson.id) {
    'kasparov-topalov-1999' => const _MasterGameVisual(
      'assets/boards/collection/volcanic-obsidian-v1.webp',
      Color(0xFFFFB44A),
      Color(0xFF50251D),
    ),
    'aronian-anand-2013' => const _MasterGameVisual(
      'assets/boards/collection/emerald-arena-v1.webp',
      Color(0xFF63E6C2),
      Color(0xFF123F3D),
    ),
    'carlsen-nepomniachtchi-2021' => const _MasterGameVisual(
      'assets/boards/collection/frost-marble-v1.webp',
      Color(0xFFA9DCFF),
      Color(0xFF243B55),
    ),
    'morphy-opera-1858' => const _MasterGameVisual(
      'assets/boards/collection/royal-walnut-v1.webp',
      Color(0xFFFFCC73),
      Color(0xFF4A2B20),
    ),
    'byrne-fischer-1956' => const _MasterGameVisual(
      'assets/boards/collection/midnight-sapphire-v1.webp',
      Color(0xFF72B7FF),
      Color(0xFF172E5A),
    ),
    'kasparov-anand-1995-game10' => const _MasterGameVisual(
      'assets/boards/collection/ocean-teal-v1.webp',
      Color(0xFF5BE7EA),
      Color(0xFF123F55),
    ),
    'capablanca-marshall-1918' => const _MasterGameVisual(
      'assets/boards/collection/desert-gold-v1.webp',
      Color(0xFFFFD36B),
      Color(0xFF50351C),
    ),
    'anand-gelfand-2012-game8' => const _MasterGameVisual(
      'assets/boards/collection/amethyst-clash-v1.webp',
      Color(0xFFC9A0FF),
      Color(0xFF38245A),
    ),
    'kramnik-anand-2008-game3' => const _MasterGameVisual(
      'assets/boards/collection/celestial-silver-v1.webp',
      Color(0xFFE4ECF7),
      Color(0xFF344153),
    ),
    'carlsen-anand-2008' => const _MasterGameVisual(
      'assets/boards/collection/jade-dynasty-v1.webp',
      Color(0xFF80E6B1),
      Color(0xFF183E34),
    ),
    'fischer-spassky-1972-game6' => const _MasterGameVisual(
      'assets/boards/collection/azure-temple-v1.webp',
      Color(0xFF70C7FF),
      Color(0xFF173C62),
    ),
    _ => const _MasterGameVisual(
      'assets/boards/collection/rose-quartz-v1.webp',
      Color(0xFFFF9DC8),
      Color(0xFF512A45),
    ),
  };

  IconData get _icon => switch (lesson.id) {
    'kasparov-topalov-1999' => Icons.bolt_rounded,
    'aronian-anand-2013' => Icons.hub_rounded,
    'carlsen-nepomniachtchi-2021' => Icons.hourglass_bottom_rounded,
    'morphy-opera-1858' => Icons.local_fire_department_rounded,
    'byrne-fischer-1956' => Icons.auto_awesome_rounded,
    'kasparov-anand-1995-game10' => Icons.sports_mma_rounded,
    'capablanca-marshall-1918' => Icons.shield_rounded,
    _ => switch (lesson.style) {
      MasterThinkingStyle.attack => Icons.local_fire_department_rounded,
      MasterThinkingStyle.calculation => Icons.psychology_alt_rounded,
      MasterThinkingStyle.endurance => Icons.hourglass_bottom_rounded,
    },
  };

  String get _category => switch (lesson.id) {
    'kasparov-topalov-1999' => 'TACTICS',
    'aronian-anand-2013' => 'STRATEGY',
    'byrne-fischer-1956' => 'BRILLIANCE',
    'kasparov-anand-1995-game10' => 'DEFENSE',
    'capablanca-marshall-1918' => 'ENDGAME',
    _ => switch (lesson.style) {
      MasterThinkingStyle.attack => 'ATTACK',
      MasterThinkingStyle.calculation => 'CALCULATION',
      MasterThinkingStyle.endurance => 'ENDURANCE',
    },
  };

  @override
  Widget build(BuildContext context) {
    final _MasterGameVisual visual = _visual;
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    return ChessVerseCard(
      key: ValueKey<String>('master-game-${lesson.id}'),
      padding: EdgeInsets.zero,
      onTap: () async {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => _MasterGameStudyScreen(lesson: lesson, copy: copy),
          ),
        );
        onReturned();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 156),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: <Color>[visual.panel, const Color(0xFF071426)],
          ),
          border: Border.all(color: visual.accent.withValues(alpha: .82)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: visual.accent.withValues(alpha: .22),
              blurRadius: 22,
            ),
            const BoxShadow(color: Color(0x22000000), blurRadius: 14),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 88,
              constraints: const BoxConstraints(minHeight: 156),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    visual.panel.withValues(alpha: .98),
                    const Color(0xFF081B2A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(_icon, color: visual.accent, size: 30),
                  const SizedBox(height: 8),
                  FittedBox(
                    child: Text(
                      _category,
                      style: const TextStyle(
                        color: Color(0xFFEBD59E),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${lesson.moveNumber}',
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${lesson.white} vs ${lesson.black}',
                            style: const TextStyle(
                              color: Color(0xFFF5EBD5),
                              fontFamily: 'serif',
                              fontSize: 18,
                              height: 1.08,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (completed)
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF63D2B8),
                            size: 21,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lesson.event,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFBBD4ED)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lesson.year} · ${lesson.result}',
                      style: const TextStyle(color: Color(0xFF91B1CF)),
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x221AB6FF),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: const Color(0x66D6A84F)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        child: Text(
                          copy.text(
                            'master.pauseMeta',
                            values: <String, String>{
                              'move': '${lesson.moveNumber}',
                              'side': copy.text(
                                'master.side.${lesson.sideToMove.toLowerCase()}',
                              ),
                            },
                          ),
                          style: const TextStyle(
                            color: AppColors.accentGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: compact ? 72 : 220,
                  height: compact ? 112 : 136,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.asset(visual.asset, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              const Color(0xFF071426).withValues(alpha: .72),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: visual.accent),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: visual.accent.withValues(alpha: .35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterGameVisual {
  const _MasterGameVisual(this.asset, this.accent, this.panel);

  final String asset;
  final Color accent;
  final Color panel;
}

class _MasterGameStudyScreen extends StatefulWidget {
  const _MasterGameStudyScreen({required this.lesson, required this.copy});
  final MasterGameLesson lesson;
  final AcademyStoryLocalizations copy;

  @override
  State<_MasterGameStudyScreen> createState() => _MasterGameStudyScreenState();
}

class _MasterGameStudyScreenState extends State<_MasterGameStudyScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  late final CloudNarrationService _narrator;
  _MasterNarrationState _narrationState = _MasterNarrationState.stopped;
  String? _choice;

  String _lessonCopy(String field, String fallback) {
    final String key = 'master.${widget.lesson.id}.$field';
    final String localized = widget.copy.text(key);
    return localized == key ? fallback : localized;
  }

  @override
  void initState() {
    super.initState();
    _narrator = CloudNarrationService()
      ..onStateChanged = (CloudNarrationState state) =>
          _setNarrationState(switch (state) {
            CloudNarrationState.playing => _MasterNarrationState.playing,
            CloudNarrationState.paused => _MasterNarrationState.paused,
            CloudNarrationState.stopped => _MasterNarrationState.stopped,
          });
  }

  void _setNarrationState(_MasterNarrationState state) {
    if (mounted) setState(() => _narrationState = state);
  }

  Future<void> _toggleNarration() async {
    try {
      if (_narrationState == _MasterNarrationState.playing) {
        await _narrator.pause();
        return;
      }
      if (_narrationState == _MasterNarrationState.paused) {
        await _narrator.resume();
        return;
      }
      final MasterGameLesson lesson = widget.lesson;
      final String narration = <String>[
        _lessonCopy('question', lesson.question),
        if (_choice != null) _lessonCopy('idea', lesson.idea),
      ].join(' ');
      final bool started = await _narrator.speak(
        text: narration,
        language: widget.copy.code,
      );
      if (!started) _setNarrationState(_MasterNarrationState.stopped);
    } on Object {
      _setNarrationState(_MasterNarrationState.stopped);
    }
  }

  @override
  void dispose() {
    unawaited(_narrator.dispose());
    super.dispose();
  }

  Future<void> _complete() async {
    try {
      await _progressStore.markMasterGameCompleted(widget.lesson.id);
    } on Object {
      // The masterclass remains completable if secure storage is unavailable.
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: <Color>[
                Color(0xFF164956),
                Color(0xFF0A2232),
                Color(0xFF081522),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.accentGold),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x6659E4C8), blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Color(0x66EABF61), blurRadius: 30),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 48,
                  color: Color(0xFF071827),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.copy.text('master.complete'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.lesson.white} · ${widget.lesson.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF06131F).withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF63D2B8).withValues(alpha: .45),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.verified_rounded, color: Color(0xFF63D2B8)),
                    SizedBox(width: 10),
                    Text(
                      '1 / 1',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey<String>('master-completion-close'),
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(widget.copy.text('master.title')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final MasterGameLesson lesson = widget.lesson;
    final bool? correct = _choice == null ? null : lesson.isCorrect(_choice!);
    return Scaffold(
      backgroundColor: const Color(0xFF06131F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        title: Text('${lesson.white.split(' ').last} · ${lesson.year}'),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('master-narration'),
            tooltip: widget.copy.text(
              _narrationState == _MasterNarrationState.playing
                  ? 'ui.pause'
                  : 'ui.listen',
            ),
            onPressed: _toggleNarration,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Icon(
                _narrationState == _MasterNarrationState.playing
                    ? Icons.pause_circle_filled_rounded
                    : Icons.volume_up_rounded,
                key: ValueKey<_MasterNarrationState>(_narrationState),
                color: const Color(0xFF63D2B8),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _StoryStage(
                        lesson: lesson,
                        revealed: _choice != null,
                        copy: widget.copy,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFF1C5260),
                              Color(0xFF0A1B2C),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF63D2B8)
                                .withValues(alpha: .55),
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: Color(0x334CDCC1), blurRadius: 28),
                          ],
                        ),
                        child: _MasterPositionBoard(
                          lesson: lesson,
                          revealMove: _choice != null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ChessVerseCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              _lessonCopy('question', lesson.question),
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final String move in lesson.choices)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: OutlinedButton.icon(
                                  key: ValueKey<String>('master-choice-$move'),
                                  onPressed: _choice == null
                                      ? () => setState(() => _choice = move)
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: _choice == move
                                          ? (lesson.isCorrect(move)
                                                ? const Color(0xFF63D2B8)
                                                : const Color(0xFFFF8A72))
                                          : AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: Icon(
                                    _choice == move
                                        ? (lesson.isCorrect(move)
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded)
                                        : Icons.radio_button_unchecked_rounded,
                                  ),
                                  label: Text(
                                    move,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            if (correct != null) ...<Widget>[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: correct
                                        ? const <Color>[
                                            Color(0xFF153F4B),
                                            Color(0xFF0B2635),
                                          ]
                                        : const <Color>[
                                            Color(0xFF442A2C),
                                            Color(0xFF231A23),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: correct
                                        ? const Color(0xFF63D2B8)
                                        : const Color(0xFFFF8A72),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      correct
                                          ? Icons.lightbulb_rounded
                                          : Icons.psychology_alt_rounded,
                                      color: correct
                                          ? const Color(0xFF63D2B8)
                                          : const Color(0xFFFF8A72),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            correct
                                                ? widget.copy.text(
                                                    'master.correct',
                                                  )
                                                : widget.copy.text(
                                                    'master.wrong',
                                                  ),
                                            style: TextStyle(
                                              color: correct
                                                  ? const Color(0xFF63D2B8)
                                                  : const Color(0xFFFF8A72),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _lessonCopy('idea', lesson.idea),
                                            style: const TextStyle(
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _MasterMoveBreakdown(
                                lesson: lesson,
                                idea: _lessonCopy('idea', lesson.idea),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: lesson.continuation
                                    .map(
                                      (String move) => Chip(label: Text(move)),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _complete,
                                icon: const Icon(Icons.school_rounded),
                                label: Text(
                                  widget.copy.text('master.complete'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _MasterMoveBreakdown extends StatelessWidget {
  const _MasterMoveBreakdown({required this.lesson, required this.idea});
  final MasterGameLesson lesson;
  final String idea;

  @override
  Widget build(BuildContext context) {
    final String opponent = lesson.sideToMove == 'White'
        ? lesson.black
        : lesson.white;
    final List<String> line = lesson.continuation;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B6A9E)),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0C2943), Color(0xFF061526)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'CRYSTAL-CLEAR MOVE BREAKDOWN',
            style: TextStyle(
              color: Color(0xFFFFD56A),
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 13),
          _MasterDetailRow(
            icon: Icons.flag_outlined,
            title: 'The master’s plan',
            body: idea,
            color: const Color(0xFF62E3C2),
          ),
          const SizedBox(height: 11),
          _MasterDetailRow(
            icon: Icons.psychology_alt_outlined,
            title: 'Why ${lesson.answer}?',
            body:
                '${lesson.answer} fits the position because it begins the plan immediately and limits $opponent’s useful replies.',
            color: const Color(0xFFFFD56A),
          ),
          if (line.length > 1) ...<Widget>[
            const SizedBox(height: 11),
            _MasterDetailRow(
              icon: Icons.shield_outlined,
              title: '$opponent’s reply',
              body:
                  '${line[1]} is the recorded reply. Before choosing the master move, calculate this response first.',
              color: const Color(0xFFFF8A72),
            ),
          ],
          if (line.length > 2) ...<Widget>[
            const SizedBox(height: 11),
            _MasterDetailRow(
              icon: Icons.route_rounded,
              title: 'How the plan continues',
              body:
                  '${line.skip(2).join(' → ')}. Each following move keeps the original idea alive instead of starting an unrelated plan.',
              color: const Color(0xFF6FC5FF),
            ),
          ],
          const SizedBox(height: 11),
          _MasterDetailRow(
            icon: Icons.school_outlined,
            title: 'What you should remember',
            body: switch (lesson.style) {
              MasterThinkingStyle.attack => 'When the king is exposed, calculate checks, captures and threats before counting material.',
              MasterThinkingStyle.calculation => 'Compare candidate moves and calculate the opponent’s strongest reply—not the reply you hope for.',
              MasterThinkingStyle.endurance => 'Improve the position without allowing counterplay; patient pressure is also a concrete plan.',
            },
            color: const Color(0xFFB896FF),
          ),
        ],
      ),
    );
  }
}

class _MasterDetailRow extends StatelessWidget {
  const _MasterDetailRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MasterPositionBoard extends StatelessWidget {
  const _MasterPositionBoard({required this.lesson, required this.revealMove});

  final MasterGameLesson lesson;
  final bool revealMove;

  static const Map<String, String> _symbols = <String, String>{
    'K': '♔',
    'Q': '♕',
    'R': '♖',
    'B': '♗',
    'N': '♘',
    'P': '♙',
    'k': '♚',
    'q': '♛',
    'r': '♜',
    'b': '♝',
    'n': '♞',
    'p': '♟',
  };

  Offset _position(String square, double size) => Offset(
    (square.codeUnitAt(0) - 97) * size,
    (8 - int.parse(square[1])) * size,
  );

  Widget _pieceSymbol(String code, double size) {
    final bool white = code == code.toUpperCase();
    final String glyph = _symbols[code]!;
    final Color fill = white
        ? const Color(0xFFFFF4D0)
        : const Color(0xFF10243A);
    final Color outline = white
        ? const Color(0xFF8A5A12)
        : const Color(0xFFF4D998);
    return Semantics(
      label: white ? 'White chess piece' : 'Black chess piece',
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Text(
            glyph,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: size * .66,
              height: 1,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = outline,
            ),
          ),
          Text(
            glyph,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: size * .66,
              height: 1,
              color: fill,
              shadows: const <Shadow>[
                Shadow(color: Color(0x99000000), blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> pieces = MasterGameCatalog.piecesFromFen(
      lesson.fen,
    );
    final String moving = pieces[lesson.masterFrom]!;
    pieces.remove(lesson.masterFrom);
    if (revealMove) {
      pieces.remove(lesson.masterTo);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double size = constraints.maxWidth / 8;
                return Stack(
                  children: <Widget>[
                    for (int row = 0; row < 8; row++)
                      for (int col = 0; col < 8; col++)
                        Positioned(
                          left: col * size,
                          top: row * size,
                          width: size,
                          height: size,
                          child: ColoredBox(
                            color: (row + col).isEven
                                ? const Color(0xFFD8C5A7)
                                : const Color(0xFF6D4A32),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Text(
                                '${String.fromCharCode(97 + col)}${8 - row}',
                                style: const TextStyle(
                                  color: Color(0x9906131F),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    for (final MapEntry<String, String> piece in pieces.entries)
                      Positioned(
                        left: _position(piece.key, size).dx,
                        top: _position(piece.key, size).dy,
                        width: size,
                        height: size,
                        child: Center(child: _pieceSymbol(piece.value, size)),
                      ),
                    TweenAnimationBuilder<Offset>(
                      key: ValueKey<String>('${lesson.id}-$revealMove'),
                      tween: Tween<Offset>(
                        begin: _position(lesson.masterFrom, size),
                        end: _position(
                          revealMove ? lesson.masterTo : lesson.masterFrom,
                          size,
                        ),
                      ),
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeInOutCubic,
                      builder:
                          (
                            BuildContext context,
                            Offset offset,
                            Widget? child,
                          ) => Positioned(
                            left: offset.dx,
                            top: offset.dy,
                            width: size,
                            height: size,
                            child: child!,
                          ),
                      child: Center(child: _pieceSymbol(moving, size)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryStage extends StatelessWidget {
  const _StoryStage({
    required this.lesson,
    required this.revealed,
    required this.copy,
  });
  final MasterGameLesson lesson;
  final bool revealed;
  final AcademyStoryLocalizations copy;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 450),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFF123A48), Color(0xFF09192A)],
      ),
      border: Border.all(
        color: revealed ? const Color(0xFF63D2B8) : AppColors.accentGold,
      ),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x4459E4C8), blurRadius: 24),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          lesson.sourceLabel,
          style: const TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${lesson.white}\nvs ${lesson.black}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            const Icon(Icons.pause_circle_rounded, color: Color(0xFF63D2B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                copy.text(
                  'master.positionBefore',
                  values: <String, String>{'move': '${lesson.moveNumber}'},
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
