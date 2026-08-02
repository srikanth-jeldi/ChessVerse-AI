import 'package:flutter/material.dart';

import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/puzzle_catalog.dart';

typedef PuzzleLauncher = Future<void> Function(String puzzleId);

Future<void> _noPuzzleLaunch(String _) async {}

class PuzzleAcademyScreen extends StatefulWidget {
  const PuzzleAcademyScreen({
    this.onStartPuzzle = _noPuzzleLaunch,
    super.key,
  });

  final PuzzleLauncher onStartPuzzle;

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
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                  ),
                  itemCount: puzzles.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ChessPuzzle puzzle = puzzles[index];
                    final bool solved =
                        LocalGameArchive.completedPuzzleIds.contains(puzzle.id);
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  pinned: true,
                  backgroundColor: const Color(0xD9071827),
                  surfaceTintColor: Colors.transparent,
                  elevation: 4,
                  scrolledUnderElevation: 4,
                  shadowColor: Colors.black87,
                  title: const Text(
                    'PUZZLE ACADEMY',
                    style: TextStyle(
                      color: Color(0xFFF6E7C2),
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
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
                            const SizedBox(height: 22),
                            const _SectionHeading(
                              eyebrow: 'TACTICAL TRAINING',
                              title: 'Choose your challenge',
                              subtitle:
                                  'Every position is interactive and validated by the ChessVerseAI rules engine.',
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
                            const SizedBox(height: 22),
                            _TrainingSummary(stats: stats),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF173A43), Color(0xFF091927)],
        ),
        border: Border.all(color: const Color(0xFF9A7133), width: 1.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: const Color(0xFF07121C),
                  border: Border.all(color: AppColors.accentGold),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/branding/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'FEATURED PUZZLE',
                      style: TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tactical Sprint',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Find the forcing line before the defense escapes.',
                      style: TextStyle(
                        color: Color(0xFF9EB5C0),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _HeroStat(icon: Icons.extension_rounded, value: '$solved solved'),
              _HeroStat(
                icon: Icons.grid_view_rounded,
                value: '150 puzzles',
              ),
              FilledButton.icon(
                key: const ValueKey<String>('daily-puzzle-start'),
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: const Color(0xFF24180A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'SOLVE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xE6112130),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 27),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: solved / PuzzleCatalog.puzzlesPerDifficulty,
                        minHeight: 5,
                        color: accent,
                        backgroundColor: const Color(0xFF263645),
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
  }
}

class _TrainingSummary extends StatelessWidget {
  const _TrainingSummary({required this.stats});

  final LocalGameStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCC0A1723),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6F5129)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.military_tech_rounded,
            color: AppColors.accentGold,
            size: 34,
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
                  'Solve combinations to earn XP, coins and streak rewards.',
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
