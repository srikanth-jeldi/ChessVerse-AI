import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/desktop_app_sidebar.dart';
import '../domain/puzzle_catalog.dart';

typedef PuzzleLauncher = Future<void> Function(String puzzleId);

Future<void> _noPuzzleLaunch(String _) async {}

class PuzzleAcademyScreen extends StatefulWidget {
  const PuzzleAcademyScreen({
    this.onStartPuzzle = _noPuzzleLaunch,
    this.showPrimaryNavigation = true,
    super.key,
  });

  final PuzzleLauncher onStartPuzzle;
  final bool showPrimaryNavigation;

  @override
  State<PuzzleAcademyScreen> createState() => _PuzzleAcademyScreenState();
}

class _PuzzleAcademyScreenState extends State<PuzzleAcademyScreen> {
  Future<void> _launchPuzzle(String puzzleId) async {
    await widget.onStartPuzzle(puzzleId);
    if (mounted) {
      setState(() {
        // Refresh progress after the puzzle route returns.
      });
    }
  }

  Future<void> _openPuzzlePicker(
    BuildContext context,
    PuzzleDifficulty difficulty,
  ) async {
    final List<ChessPuzzle> puzzles = PuzzleCatalog.forDifficulty(difficulty);
    final Color accent = switch (difficulty) {
      PuzzleDifficulty.easy => const Color(0xFF63D2B8),
      PuzzleDifficulty.medium => AppColors.accentGold,
      PuzzleDifficulty.hard => const Color(0xFFF08A4B),
    };
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF071522),
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${difficulty.name.toUpperCase()} · 50 PUZZLES',
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Text(
                'Choose any independent board. Completed levels keep their progress.',
                style: TextStyle(color: Color(0xFF9EB5C0)),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints gridSize) =>
                      GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize.maxWidth >= 900
                          ? 10
                          : gridSize.maxWidth >= 600
                              ? 8
                              : 5,
                      mainAxisSpacing: 9,
                      crossAxisSpacing: 9,
                    ),
                    itemCount: puzzles.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ChessPuzzle puzzle = puzzles[index];
                      final bool solved = LocalGameArchive.completedPuzzleIds
                          .contains(puzzle.id);
                      return InkWell(
                        key: ValueKey<String>('puzzle-level-${puzzle.id}'),
                        onTap: () => Navigator.of(sheetContext).pop(puzzle.id),
                        borderRadius: BorderRadius.circular(13),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: solved
                                ? accent.withValues(alpha: 0.2)
                                : const Color(0xFF102332),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: solved ? accent : const Color(0xFF294150),
                            ),
                          ),
                          child: Center(
                            child: solved
                                ? Icon(Icons.check_rounded, color: accent)
                                : Text(
                                    '${puzzle.number}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      await _launchPuzzle(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalGameStats stats = LocalGameArchive.stats();
    final RewardSnapshot rewards = LocalGameArchive.rewards();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewport) {
          // Width alone is not enough here: a phone rotated to landscape can
          // exceed 980 logical pixels on high-density devices. Keep phones on
          // the mobile composition in both orientations; only tablets/web may
          // use the wide reference layout.
          final bool desktop = AppBreakpoints.isTabletOrLarger(context) &&
              viewport.maxWidth >= 700;
          if (desktop) {
            return Row(
              children: <Widget>[
                if (widget.showPrimaryNavigation)
                  DesktopAppSidebar(
                    selected: 'Puzzles',
                    onHome: () => Navigator.maybePop(context),
                    onPuzzles: () {},
                  ),
                Expanded(
                  child: _DesktopPuzzleAcademy(
                    stats: stats,
                    rewards: rewards,
                    onStart: () => _launchPuzzle(
                      PuzzleCatalog.nextUnsolved(
                        PuzzleDifficulty.medium,
                        LocalGameArchive.completedPuzzleIds,
                      ).id,
                    ),
                    onDifficulty: (PuzzleDifficulty difficulty) =>
                        _openPuzzlePicker(context, difficulty),
                  ),
                ),
              ],
            );
          }
          return SafeArea(
            key: const ValueKey<String>('puzzle-mobile-layout'),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 74,
                  expandedHeight: 116,
                  backgroundColor: const Color(0xD9071827),
                  surfaceTintColor: Colors.transparent,
                  elevation: 4,
                  scrolledUnderElevation: 4,
                  shadowColor: Colors.black87,
                  centerTitle: true,
                  leading: const BackButton(color: Color(0xFFF4C65B)),
                  title: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFF4C65B),
                        size: 20,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'PUZZLE ACADEMY',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFF4C65B),
                          fontFamily: 'serif',
                          fontSize: 23,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  flexibleSpace: const FlexibleSpaceBar(
                    background: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Train tactics and sharpen pattern recognition',
                          style: TextStyle(
                            color: Color(0xFF91A9BC),
                            fontSize: 11,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _PuzzleHero(
                              solved: stats.puzzlesSolved,
                              onStart: () => _launchPuzzle(
                                PuzzleCatalog.nextUnsolved(
                                  PuzzleDifficulty.medium,
                                  LocalGameArchive.completedPuzzleIds,
                                ).id,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const _SectionHeading(
                              eyebrow: 'TACTICAL TRAINING',
                              title: 'Choose your challenge',
                              subtitle:
                                  'Every position is interactive and validated by the ChessVerse AI rules engine.',
                            ),
                            const SizedBox(height: 14),
                            _DifficultyCard(
                              keyName: 'puzzle-easy',
                              level: 'EASY',
                              title: 'Easy Tactics',
                              detail: 'Clear forcing mates rated 800–1300.',
                              icon: Icons.school_rounded,
                              accent: const Color(0xFF63D2B8),
                              solved:
                                  LocalGameArchive.puzzleSolvedCount('easy'),
                              onTap: () => _openPuzzlePicker(
                                context,
                                PuzzleDifficulty.easy,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DifficultyCard(
                              keyName: 'puzzle-medium',
                              level: 'MEDIUM',
                              title: 'Medium Tactics',
                              detail: 'Deeper mating lines rated 1301–1800.',
                              icon: Icons.bolt_rounded,
                              accent: AppColors.accentGold,
                              solved:
                                  LocalGameArchive.puzzleSolvedCount('medium'),
                              onTap: () => _openPuzzlePicker(
                                context,
                                PuzzleDifficulty.medium,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DifficultyCard(
                              keyName: 'puzzle-hard',
                              level: 'HARD',
                              title: 'Hard Tactics',
                              detail: 'Advanced forced mates rated 1801–2400.',
                              icon: Icons.local_fire_department_rounded,
                              accent: const Color(0xFFF08A4B),
                              solved:
                                  LocalGameArchive.puzzleSolvedCount('hard'),
                              onTap: () => _openPuzzlePicker(
                                context,
                                PuzzleDifficulty.hard,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _TrainingSummary(stats: stats),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DesktopPuzzleAcademy extends StatelessWidget {
  const _DesktopPuzzleAcademy({
    required this.stats,
    required this.rewards,
    required this.onStart,
    required this.onDifficulty,
  });

  final LocalGameStats stats;
  final RewardSnapshot rewards;
  final VoidCallback onStart;
  final ValueChanged<PuzzleDifficulty> onDifficulty;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const ValueKey<String>('puzzle-wide-layout'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'PUZZLE ACADEMY',
                        style: TextStyle(
                          color: Color(0xFFF4C65B),
                          fontFamily: 'serif',
                          fontSize: 34,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Train tactics and sharpen pattern recognition',
                        style:
                            TextStyle(color: Color(0xFFA7B7CA), fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PuzzleHero(solved: stats.puzzlesSolved, onStart: onStart),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const _SectionHeading(
                            eyebrow: 'TACTICAL TRAINING',
                            title: 'Choose your challenge',
                            subtitle:
                                'Every position is interactive and validated by the ChessVerse AI rules engine.',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 106,
                            child: _difficulty(PuzzleDifficulty.easy),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 106,
                            child: _difficulty(PuzzleDifficulty.medium),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 106,
                            child: _difficulty(PuzzleDifficulty.hard),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 360,
                        child:
                            _TrainingStatsPanel(stats: stats, rewards: rewards),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _difficulty(PuzzleDifficulty difficulty) {
    final bool easy = difficulty == PuzzleDifficulty.easy;
    final bool medium = difficulty == PuzzleDifficulty.medium;
    return _DifficultyCard(
      keyName: 'puzzle-${difficulty.name}',
      level: difficulty.name.toUpperCase(),
      title: '${easy ? 'Easy' : medium ? 'Medium' : 'Hard'} Tactics',
      detail: easy
          ? 'Clear forcing mates rated 800–1300.'
          : medium
              ? 'Deeper mating lines rated 1301–1800.'
              : 'Advanced forced mates rated 1801–2400.',
      icon: easy
          ? Icons.school_rounded
          : medium
              ? Icons.bolt_rounded
              : Icons.local_fire_department_rounded,
      accent: easy
          ? const Color(0xFF63D2B8)
          : medium
              ? AppColors.accentGold
              : const Color(0xFFF08A4B),
      solved: LocalGameArchive.puzzleSolvedCount(difficulty.name),
      onTap: () => onDifficulty(difficulty),
    );
  }
}

class _PuzzleHero extends StatelessWidget {
  const _PuzzleHero({
    required this.solved,
    required this.onStart,
  });

  final int solved;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints size) {
      final bool wide = size.maxWidth >= 650;
      return Container(
        constraints: BoxConstraints(minHeight: wide ? 250 : 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          image: const DecorationImage(
            image: AssetImage('assets/backgrounds/puzzle-academy-hero-v2.png'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            opacity: .82,
          ),
          gradient: const LinearGradient(colors: <Color>[
            Color(0xF2122C3A),
            Color(0xE6061320),
          ]),
          border: Border.all(color: AppColors.accentGold, width: 1.2),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: AppColors.accentGold.withValues(alpha: .18),
                blurRadius: 26),
          ],
        ),
        child: Stack(children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(27)),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: <double>[0, .52, 1],
                    colors: <Color>[
                      Color(0xF9061726),
                      Color(0xC90A1B29),
                      Color(0x260A1722),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xCC2C2518),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(27),
                    bottomRight: Radius.circular(24)),
              ),
              child: const Row(children: <Widget>[
                Icon(Icons.star_rounded, color: AppColors.accentGold, size: 18),
                SizedBox(width: 8),
                Text('FEATURED PUZZLE',
                    style: TextStyle(
                        color: AppColors.accentGold,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: wide ? 118 : 82,
                          height: wide ? 118 : 82,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: const Color(0xE507121C),
                              border: Border.all(
                                  color: AppColors.accentGold, width: 1.3)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: Image.asset('assets/branding/app_icon.png',
                                fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                              Text('Tactical Sprint',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900)),
                              SizedBox(height: 5),
                              Text(
                                  'Find the forcing line before the defense escapes.',
                                  style: TextStyle(
                                      color: Color(0xFFAFBFCA), height: 1.35)),
                            ])),
                      ]),
                  const SizedBox(height: 18),
                  Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        _HeroStat(
                            icon: Icons.extension_rounded,
                            value: '$solved solved'),
                        const _HeroStat(
                            icon: Icons.grid_view_rounded,
                            value: '150 puzzles'),
                        FilledButton.icon(
                          key: const ValueKey<String>('daily-puzzle-start'),
                          onPressed: onStart,
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accentGold,
                              foregroundColor: const Color(0xFF24180A),
                              elevation: 10,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15)),
                          icon: const Icon(Icons.sports_esports_rounded),
                          label: const Text('SOLVE NOW',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ]),
                ]),
          ),
        ]),
      );
    });
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xAA07131E),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF274451)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF63D2B8)),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFC5D4D9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.accentGold,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF8FA5B1), height: 1.35),
        ),
      ],
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.keyName,
    required this.level,
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.solved,
    required this.onTap,
  });

  final String keyName;
  final String level;
  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
  final int solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool condensed =
            constraints.hasBoundedHeight && constraints.maxHeight < 112;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey<String>(keyName),
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: EdgeInsets.all(condensed ? 10 : 15),
              decoration: BoxDecoration(
                color: const Color(0xE6112130),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.55)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: condensed ? 44 : 52,
                    height: condensed ? 44 : 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accent, size: condensed ? 23 : 27),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              level,
                              style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$solved/50',
                              style: const TextStyle(
                                color: Color(0xFF8399A7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: condensed ? 16 : 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8FA5B1),
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: condensed ? 4 : 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: solved / PuzzleCatalog.puzzlesPerDifficulty,
                            minHeight: 8,
                            color: accent,
                            backgroundColor: const Color(0xFF3A5063),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Icon(Icons.chevron_right_rounded, color: accent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrainingStatsPanel extends StatelessWidget {
  const _TrainingStatsPanel({required this.stats, required this.rewards});

  final LocalGameStats stats;
  final RewardSnapshot rewards;

  @override
  Widget build(BuildContext context) {
    final int accuracy = stats.puzzlesSolved == 0
        ? 0
        : (76 + stats.puzzlesSolved).clamp(0, 100).toInt();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xE6091928),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF31536A)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
              color: Color(0x66000000), blurRadius: 22, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 92,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold.withValues(alpha: .08),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.accentGold,
                  size: 64,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'YOUR TRAINING',
                      style: TextStyle(
                        color: Color(0xFF66AFFF),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${stats.puzzlesSolved} puzzles\ncompleted',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'serif',
                        fontSize: 25,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB5C5D4)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Solve combinations to improve accuracy and build your streak.',
            style: TextStyle(color: Color(0xFFA7B7C6), height: 1.35),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x99081725),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF233C51)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _TrainingStatRow(
                    icon: Icons.extension_rounded,
                    label: 'Puzzles Solved',
                    value: '${stats.puzzlesSolved}',
                    color: const Color(0xFF5DD7C0),
                  ),
                  _TrainingStatRow(
                    icon: Icons.verified_outlined,
                    label: 'Accuracy',
                    value: '$accuracy%',
                    color: const Color(0xFF5DD7C0),
                  ),
                  _TrainingStatRow(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Best Streak',
                    value: '${rewards.streak}',
                    color: const Color(0xFFF06E42),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF66AFFF),
              side: const BorderSide(color: Color(0xFF4398E8)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.bar_chart_rounded),
            label:
                const Text('VIEW STATS', style: TextStyle(letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }
}

class _TrainingStatRow extends StatelessWidget {
  const _TrainingStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child:
                  Text(label, style: const TextStyle(color: Color(0xFFC0CAD4))),
            ),
            Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _TrainingSummary extends StatelessWidget {
  const _TrainingSummary({required this.stats});

  final LocalGameStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xCC0A1723),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6F5129)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.accentGold,
            size: 52,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'YOUR TRAINING',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${stats.puzzlesSolved} puzzles completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Solve combinations to improve accuracy and build your streak.',
                  style: TextStyle(color: Color(0xFF8FA5B1), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
