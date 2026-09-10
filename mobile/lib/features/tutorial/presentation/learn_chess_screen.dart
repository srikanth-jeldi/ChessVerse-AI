import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/chess_piece_appearance.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../analysis/domain/player_learning_profile.dart';
import '../data/academy_progress_store.dart';
import '../domain/academy_lesson.dart';
import 'academy_boss_challenge_screen.dart';
import 'interactive_academy_lesson_screen.dart';

class LearnChessScreen extends StatefulWidget {
  const LearnChessScreen({super.key});

  static const List<_Lesson> _lessons = <_Lesson>[
    _Lesson(
      icon: Icons.account_tree_rounded,
      title: 'Piece Basics',
      body: 'Learn how every piece moves and captures.',
      asset: 'assets/backgrounds/home-online-hero-v1.webp',
      accent: Color(0xFF59E4C8),
      chapters: <String>[
        'Meet the chessboard',
        'How pawns move',
        'Rooks and files',
        'Bishops and diagonals',
        'The knight jump',
        'Queen movement',
        'The king and legal moves',
        'Captures and piece value',
      ],
    ),
    _Lesson(
      icon: Icons.security_rounded,
      title: 'King Safety',
      body: 'Understand check, escape squares, and pins.',
      asset: 'assets/backgrounds/home-settings-hero-v1.webp',
      accent: AppColors.info,
      chapters: <String>[
        'Check and checkmate',
        'Escaping from check',
        'Castling safely',
        'Pins around the king',
        'Back-rank safety',
        'Building a king shelter',
      ],
    ),
    _Lesson(
      icon: Icons.bolt_rounded,
      title: 'Tactics',
      body: 'Forks, skewers, discovered attacks, and mates.',
      asset: 'assets/backgrounds/home-puzzles-hero-v1.webp',
      accent: Color(0xFFE9B84C),
      chapters: <String>[
        'Hanging pieces',
        'Double attacks',
        'Knight forks',
        'Pins',
        'Skewers',
        'Discovered attacks',
        'Removing the defender',
        'Deflection',
        'Decoy tactics',
        'Back-rank mates',
        'Mate in one',
        'Mate in two',
      ],
    ),
    _Lesson(
      icon: Icons.emoji_events_rounded,
      title: 'Endgames',
      body: 'Finish cleanly with rook, queen, and pawn endings.',
      asset: 'assets/backgrounds/home-rankings-hero-v1.webp',
      accent: AppColors.accentGold,
      chapters: <String>[
        'King and pawn basics',
        'The opposition',
        'Promoting a pawn',
        'Queen checkmates',
        'Rook ladder mate',
        'Rook and king mate',
        'Basic rook endings',
        'Drawing positions',
      ],
    ),
  ];

  @override
  State<LearnChessScreen> createState() => _LearnChessScreenState();
}

class _LearnChessScreenState extends State<LearnChessScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  Set<String> _completed = <String>{};
  Map<String, int> _mastery = <String, int>{};
  String? _placement;
  bool _assessmentOffered = false;
  List<String> _reviewDue = <String>[];
  int _learningStreak = 0;
  Set<String> _certificates = <String>{};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final Set<String> completed = await _progressStore.readCompleted();
      final Map<String, int> mastery = await _progressStore.readMastery();
      final String? placement = await _progressStore.readPlacement();
      final List<String> reviewDue = await _progressStore.readReviewDue();
      final int learningStreak = await _progressStore.readLearningStreak();
      final Set<String> certificates = await _progressStore.readCertificates();
      if (mounted) {
        setState(() {
          _completed = completed;
          _mastery = mastery;
          _placement = placement;
          _reviewDue = reviewDue;
          _learningStreak = learningStreak;
          _certificates = certificates;
        });
        if (placement == null && !_assessmentOffered) {
          _assessmentOffered = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _showPlacementAssessment(),
          );
        }
      }
    } on Object {
      // The academy remains usable when browser secure storage is restricted.
    }
  }

  Future<void> _showPlacementAssessment() async {
    if (!mounted) return;
    const List<({String question, List<String> options, int correct})>
        questions = <({String question, List<String> options, int correct})>[
      (
        question: 'A knight on g1 can jump directly to which square?',
        options: <String>['g3', 'f3', 'e2'],
        correct: 1,
      ),
      (
        question: 'Your king is in check. What must your next move do?',
        options: <String>['Attack the queen', 'Create a threat', 'End the check'],
        correct: 2,
      ),
      (
        question: 'Before choosing a tactic, what should you scan first?',
        options: <String>['Checks, captures, threats', 'Only pawn moves', 'The clock'],
        correct: 0,
      ),
    ];
    int index = 0;
    int score = 0;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final question = questions[index];
          return AlertDialog(
            backgroundColor: const Color(0xFF091C2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(children: <Widget>[
              Icon(Icons.auto_awesome_rounded, color: AppColors.accentGold),
              SizedBox(width: 10),
              Expanded(child: Text('FIND YOUR STARTING LEVEL')),
            ]),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Question ${index + 1} of ${questions.length}',
                      style: const TextStyle(
                        color: Color(0xFF59E4C8),
                        fontWeight: FontWeight.w900,
                      )),
                  const SizedBox(height: 10),
                  Text(question.question,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 16),
                  for (int option = 0;
                      option < question.options.length;
                      option++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: OutlinedButton(
                        onPressed: () async {
                          if (option == question.correct) score++;
                          if (index < questions.length - 1) {
                            setDialogState(() => index++);
                            return;
                          }
                          final String level =
                              score >= 2 ? 'intermediate' : 'beginner';
                          await _progressStore.writePlacement(level);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (mounted) setState(() => _placement = level);
                        },
                        child: Text(question.options[option]),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size viewport = MediaQuery.sizeOf(context);
    final bool wide = AppBreakpoints.isTabletOrLarger(context);
    final bool compact = viewport.width < 520;
    final PlayerLearningProfile learningProfile =
        PlayerLearningProfile.fromGames(
      LocalGameArchive.games,
      cloudScores: LocalGameArchive.cloudWeaknessScores,
    );
    final AcademyLesson recommended = _reviewDue.isNotEmpty
        ? AcademyCatalog.lessons.firstWhere(
            (AcademyLesson lesson) => lesson.id == _reviewDue.first,
          )
        : AcademyCatalog.forChapter(
            LocalGameArchive.games.isEmpty
                ? (_placement == 'intermediate'
                    ? 'Check and checkmate'
                    : 'How pawns move')
                : learningProfile.recommendedLesson,
          );
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: wide ? 72 : 62,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('LEARN CHESS',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text('Build skills one lesson at a time',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: const Color(0xE6071827),
      ),
      body: ResponsivePage(
        maxWidth: wide ? 1240 : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _AcademyProgressStrip(
              placement: _placement,
              stars: _mastery.values.fold<int>(0, (int a, int b) => a + b),
              completed: _completed.length,
            ),
            const SizedBox(height: 14),
            _AcademySkillMap(
              completed: _completed,
              certificates: _certificates,
            ),
            const SizedBox(height: 14),
            _CoachHero(compact: compact),
            const SizedBox(height: 16),
            _PersonalizedPathCard(
              lesson: recommended,
              reason: _reviewDue.isNotEmpty
                  ? 'Memory refresh due today. A short replay now keeps this pattern available in your next game.'
                  : LocalGameArchive.games.isEmpty
                  ? (_placement == 'intermediate'
                      ? 'Your placement shows solid piece knowledge. Start with king safety, then unlock tactical calculation.'
                      : 'Start with piece movement, then the AI coach will adapt your path after every reviewed game.')
                  : learningProfile.recommendationReason,
            ),
            const SizedBox(height: 14),
            _DailyAcademyMissionCard(
              reviewDue: _reviewDue,
              completed: _completed,
              streak: _learningStreak,
              onProgressChanged: _loadProgress,
            ),
            const SizedBox(height: 14),
            _WeeklyAiReportCard(
              profile: learningProfile,
              gamesReviewed: LocalGameArchive.games.length,
            ),
            const SizedBox(height: 14),
            const _LearningMethodCard(),
            const SizedBox(height: 24),
            const _SectionHeading(
              eyebrow: 'CHESS ACADEMY',
              title: 'Your lessons, in order',
              subtitle:
                  'Start with every coin, then learn king safety, tactics and checkmate.',
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: LearnChessScreen._lessons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // Phone cards need the same complete learning information as
                // tablet/web. A single column keeps the artwork, lesson count,
                // progress bar and action readable without clipping.
                crossAxisCount: wide ? 4 : (compact ? 1 : 2),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: wide ? 0.78 : (compact ? 1.22 : 0.78),
              ),
              itemBuilder: (BuildContext context, int index) => _LessonCard(
                lesson: LearnChessScreen._lessons[index],
                locked: index > (_placement == 'intermediate' ? 1 : 0) &&
                    LearnChessScreen._lessons
                        .take(index)
                        .expand((_Lesson course) => course.chapters)
                        .map(AcademyCatalog.forChapter)
                        .any((AcademyLesson lesson) =>
                            !_completed.contains(lesson.id)),
                completedLessonIds: _completed,
                onProgressChanged: _loadProgress,
              ),
            ),
            const SizedBox(height: 24),
            const _CoachEvaluationPanel(),
          ],
        ),
      ),
    );
  }
}

class _AcademyProgressStrip extends StatelessWidget {
  const _AcademyProgressStrip({
    required this.placement,
    required this.stars,
    required this.completed,
  });

  final String? placement;
  final int stars;
  final int completed;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Wrap(
          spacing: 18,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Icon(Icons.workspace_premium_rounded,
                color: AppColors.accentGold),
            Text(
              placement == 'intermediate'
                  ? 'INTERMEDIATE PATH'
                  : 'BEGINNER PATH',
              style: const TextStyle(
                color: Color(0xFF59E4C8),
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            _AcademyMetric(icon: Icons.star_rounded, value: '$stars stars'),
            _AcademyMetric(
              icon: Icons.bolt_rounded,
              value: '${stars * 25} XP',
            ),
            _AcademyMetric(
              icon: Icons.task_alt_rounded,
              value: '$completed mastered',
            ),
          ],
        ),
      );
}

class _AcademySkillMap extends StatelessWidget {
  const _AcademySkillMap({
    required this.completed,
    required this.certificates,
  });

  final Set<String> completed;
  final Set<String> certificates;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('YOUR CHESSVERSE SKILL MAP',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                )),
            const SizedBox(height: 4),
            const Text('Master the path from first move to confident finisher',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (int index = 0;
                      index < LearnChessScreen._lessons.length;
                      index++) ...<Widget>[
                    if (index > 0)
                      Container(
                        width: 34,
                        height: 3,
                        color: _courseComplete(index - 1)
                            ? const Color(0xFF59E4C8)
                            : const Color(0xFF263B55),
                      ),
                    _SkillNode(
                      title: LearnChessScreen._lessons[index].title,
                      icon: LearnChessScreen._lessons[index].icon,
                      accent: LearnChessScreen._lessons[index].accent,
                      progress: _courseProgress(index),
                      certified: certificates.contains(
                        LearnChessScreen._lessons[index].title
                            .toLowerCase()
                            .replaceAll(' ', '-'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  double _courseProgress(int index) {
    final _Lesson course = LearnChessScreen._lessons[index];
    final int done = course.chapters
        .map(AcademyCatalog.forChapter)
        .where((AcademyLesson lesson) => completed.contains(lesson.id))
        .length;
    return course.chapters.isEmpty ? 0 : done / course.chapters.length;
  }

  bool _courseComplete(int index) => _courseProgress(index) == 1;
}

class _SkillNode extends StatelessWidget {
  const _SkillNode({
    required this.title,
    required this.icon,
    required this.accent,
    required this.progress,
    required this.certified,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final double progress;
  final bool certified;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 128,
        child: Column(
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                SizedBox.square(
                  dimension: 62,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFF263B55),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                Positioned.fill(child: Icon(icon, color: accent, size: 28)),
                if (certified)
                  const Positioned(
                    right: -5,
                    top: -5,
                    child: Icon(Icons.verified_rounded,
                        color: AppColors.accentGold, size: 22),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('${(progress * 100).round()}%',
                style: TextStyle(color: accent, fontSize: 12)),
          ],
        ),
      );
}

class _DailyAcademyMissionCard extends StatelessWidget {
  const _DailyAcademyMissionCard({
    required this.reviewDue,
    required this.completed,
    required this.streak,
    required this.onProgressChanged,
  });

  final List<String> reviewDue;
  final Set<String> completed;
  final int streak;
  final VoidCallback onProgressChanged;

  @override
  Widget build(BuildContext context) {
    final List<AcademyLesson> mission = <AcademyLesson>[
      ...reviewDue.map(
        (String id) => AcademyCatalog.lessons.firstWhere(
          (AcademyLesson lesson) => lesson.id == id,
        ),
      ),
      ...AcademyCatalog.lessons.where(
        (AcademyLesson lesson) =>
            !completed.contains(lesson.id) && !reviewDue.contains(lesson.id),
      ),
    ].take(3).toList(growable: false);
    return ChessVerseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFFF8C42)),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('TODAY\'S MEMORY WORKOUT',
                      style: TextStyle(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      )),
                  Text('Three short lessons selected for lasting recall',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            Chip(
              avatar: const Icon(Icons.local_fire_department_rounded,
                  size: 17),
              label: Text('$streak day streak'),
            ),
          ]),
          const SizedBox(height: 13),
          for (int index = 0; index < mission.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0x4459E4C8)),
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0x2259E4C8),
                  foregroundColor: const Color(0xFF59E4C8),
                  child: Text('${index + 1}'),
                ),
                title: Text(mission[index].title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(reviewDue.contains(mission[index].id)
                    ? 'Review due · strengthen this memory'
                    : 'New skill · continue your learning path'),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => InteractiveAcademyLessonScreen(
                      lesson: mission[index],
                    ),
                  ));
                  onProgressChanged();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AcademyMetric extends StatelessWidget {
  const _AcademyMetric({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.accentGold),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
}

class _WeeklyAiReportCard extends StatelessWidget {
  const _WeeklyAiReportCard({
    required this.profile,
    required this.gamesReviewed,
  });

  final PlayerLearningProfile profile;
  final int gamesReviewed;

  @override
  Widget build(BuildContext context) {
    final int maxScore = profile.scores.values.fold<int>(
      1,
      (int current, int value) => value > current ? value : current,
    );
    return ChessVerseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.insights_rounded, color: AppColors.accentGold),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'WEEKLY AI IMPROVEMENT REPORT',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            gamesReviewed == 0
                ? 'Complete a game to activate your personal skill map.'
                : '$gamesReviewed recent games reviewed • strongest: '
                    '${PlayerLearningProfile.labelFor(profile.strongestSkill)} • '
                    'focus: ${PlayerLearningProfile.labelFor(profile.primaryWeakness)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ...ChessWeakness.values.map((ChessWeakness weakness) {
            final int score = profile.scoreFor(weakness);
            final double risk = gamesReviewed == 0 ? 0 : score / maxScore;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 112,
                    child: Text(
                      PlayerLearningProfile.labelFor(weakness),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: risk.clamp(0, 1),
                        backgroundColor: AppColors.border,
                        color: weakness == profile.primaryWeakness
                            ? AppColors.accentGold
                            : const Color(0xFF59E4C8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LearningMethodCard extends StatelessWidget {
  const _LearningMethodCard();

  @override
  Widget build(BuildContext context) => ChessVerseCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: const <Widget>[
            Expanded(
              child: _LearningStep(
                number: '1',
                title: 'WATCH',
                body: 'AI shows the move',
                icon: Icons.smart_display_rounded,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.accentGold),
            Expanded(
              child: _LearningStep(
                number: '2',
                title: 'PRACTICE',
                body: 'You repeat it',
                icon: Icons.touch_app_rounded,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.accentGold),
            Expanded(
              child: _LearningStep(
                number: '3',
                title: 'MASTER',
                body: 'AI corrects you',
                icon: Icons.workspace_premium_rounded,
              ),
            ),
          ],
        ),
      );
}

class _LearningStep extends StatelessWidget {
  const _LearningStep({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF123B52),
            child: Icon(icon, size: 19, color: const Color(0xFF59E4C8)),
          ),
          const SizedBox(height: 7),
          Text('$number. $title',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(body,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10, height: 1.2)),
        ],
      );
}

class _PersonalizedPathCard extends StatelessWidget {
  const _PersonalizedPathCard({required this.lesson, required this.reason});

  final AcademyLesson lesson;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final List<AcademyLesson> pieceLessons = <String>[
      'How pawns move',
      'Rooks and files',
      'Bishops and diagonals',
      'The knight jump',
      'Queen movement',
      'The king and legal moves',
    ].map(AcademyCatalog.forChapter).toList(growable: false);
    return ChessVerseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF123B52), Color(0xFF59E4C8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.route_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('YOUR AI LEARNING PATH',
                      style: TextStyle(
                        color: Color(0xFF59E4C8),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 4),
                  Text('Next: ${lesson.title}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: 'Start recommended lesson',
              onPressed: () => _openAcademyLesson(context, lesson),
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF263B55), height: 1),
          const SizedBox(height: 12),
          const Text('LEARN EVERY PIECE',
              style: TextStyle(
                color: AppColors.accentGold,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              )),
          const SizedBox(height: 9),
          Row(
            children: pieceLessons
                .map(
                  (AcademyLesson item) => Expanded(
                    child: _PieceQuickLesson(lesson: item),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

void _openAcademyLesson(BuildContext context, AcademyLesson lesson) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => InteractiveAcademyLessonScreen(lesson: lesson),
  ));
}

class _PieceQuickLesson extends StatelessWidget {
  const _PieceQuickLesson({required this.lesson});

  final AcademyLesson lesson;

  @override
  Widget build(BuildContext context) {
    final AcademyPiece piece = lesson.pieces[lesson.from]!;
    final String name = switch (piece.symbol) {
      'P' => 'Pawn',
      'R' => 'Rook',
      'B' => 'Bishop',
      'N' => 'Knight',
      'Q' => 'Queen',
      _ => 'King',
    };
    return Semantics(
      button: true,
      label: 'Learn $name',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openAcademyLesson(context, lesson),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 60,
                child: Center(
                  child: ValueListenableBuilder<ChessPieceAppearance>(
                    valueListenable: ChessPieceAppearanceController.current,
                    builder: (BuildContext context,
                        ChessPieceAppearance appearance, _) {
                      if (appearance.style == ChessPieceVisualStyle.classic2d) {
                        const Map<String, String> glyphs = <String, String>{
                          'Pawn': '\u2659',
                          'Rook': '\u2656',
                          'Knight': '\u2658',
                          'Bishop': '\u2657',
                          'Queen': '\u2655',
                          'King': '\u2654',
                        };
                        return Text(
                          glyphs[name]!,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 48,
                            height: 1,
                            color: Color(0xFFFFF4D0),
                          ),
                        );
                      }
                      Widget image = Image.asset(
                        'assets/pieces/staunton_white_${name.toLowerCase()}.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      );
                      if (appearance.style ==
                          ChessPieceVisualStyle.highContrast) {
                        image = ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFFFF0B8),
                            BlendMode.modulate,
                          ),
                          child: image,
                        );
                      }
                      return Transform.scale(
                        scale: switch (appearance.size) {
                          ChessPieceVisualSize.large => 1.05,
                          ChessPieceVisualSize.extraLarge => 1.18,
                          ChessPieceVisualSize.doubleExtraLarge => 1.30,
                        },
                        child: image,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                name,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF2F5F8),
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachHero extends StatelessWidget {
  const _CoachHero({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        height: compact ? 296 : 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF2C8FCA), width: 1.2),
          image: const DecorationImage(
            image: AssetImage('assets/backgrounds/learn-academy-hero-v1.webp'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x552374B8), blurRadius: 28),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(compact ? 20 : 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: <Color>[
                Color(0xF2071A2A),
                Color(0xC9071A2A),
                Color(0x05071A2A),
              ],
              stops: <double>[0, .48, .76],
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 260 : 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF59E4C8), size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text('AI-GUIDED TRAINING',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                color: Color(0xFF59E4C8),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('ChessVerseAI Coach',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 28 : 36,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    compact
                        ? 'Learn from every important move.'
                        : 'Understand every important move with clear, practical coaching.',
                    style: const TextStyle(
                        color: Color(0xFFC4D2DE), fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () =>
                        _openLesson(context, LearnChessScreen._lessons.first),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: const Color(0xFF07131E),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('CONTINUE LEARNING',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(
      {required this.eyebrow, required this.title, required this.subtitle});
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(eyebrow,
              style: const TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          Text(subtitle,
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.completedLessonIds,
    required this.onProgressChanged,
    required this.locked,
  });
  final _Lesson lesson;
  final Set<String> completedLessonIds;
  final Future<void> Function() onProgressChanged;
  final bool locked;

  int get completedCount => lesson.chapters.where((String chapter) {
        return completedLessonIds
            .contains(AcademyCatalog.forChapter(chapter).id);
      }).length;

  double get progress =>
      lesson.chapters.isEmpty ? 0 : completedCount / lesson.chapters.length;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            if (locked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Complete the previous academy stage to unlock this course.'),
                ),
              );
              return;
            }
            await _openLesson(context, lesson);
            await onProgressChanged();
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: lesson.accent.withValues(alpha: .65)),
              image: DecorationImage(
                image: AssetImage(lesson.asset),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x15031520),
                    Color(0xCC061622),
                    Color(0xFA061622),
                  ],
                  stops: <double>[.15, .58, 1],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xCC071A29),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(locked ? Icons.lock_rounded : lesson.icon,
                            color: lesson.accent, size: 21),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(lesson.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(lesson.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFFC2CFD9),
                          fontSize: 12,
                          height: 1.35)),
                  const SizedBox(height: 12),
                  Text(
                      locked
                          ? 'LOCKED • Finish the previous stage'
                          : '$completedCount of ${lesson.chapters.length} lessons',
                      style: TextStyle(
                          color: lesson.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFF263948),
                      valueColor: AlwaysStoppedAnimation<Color>(lesson.accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(progress == 0 ? 'START LESSON' : 'CONTINUE',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 11)),
                      Icon(Icons.arrow_forward_rounded,
                          color: lesson.accent, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _CoachEvaluationPanel extends StatelessWidget {
  const _CoachEvaluationPanel();

  @override
  Widget build(BuildContext context) => ChessVerseCard(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 22,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.psychology_alt_rounded,
                          color: AppColors.accentGold),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text('HOW THE AI COACH RESPONDS',
                            maxLines: 2,
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Every key move receives a clear quality label and a short improvement idea.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _QualityChip(label: 'Great', color: Color(0xFF63D2B8)),
                _QualityChip(label: 'Good', color: Color(0xFFD6A84F)),
                _QualityChip(label: 'Average', color: Color(0xFF8A8F9D)),
                _QualityChip(label: 'Bad', color: Color(0xFFE15F5F)),
              ],
            ),
          ],
        ),
      );
}

Future<void> _openLesson(BuildContext context, _Lesson lesson) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _CourseScreen(course: lesson),
    ));

class _QualityChip extends StatelessWidget {
  const _QualityChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: CircleAvatar(backgroundColor: color, radius: 6),
        label: Text(label),
        side: BorderSide(color: color.withValues(alpha: .55)),
        backgroundColor: color.withValues(alpha: .12),
      );
}

class _CourseScreen extends StatefulWidget {
  const _CourseScreen({required this.course});
  final _Lesson course;

  @override
  State<_CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<_CourseScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  Set<String> _completed = <String>{};
  Map<String, int> _mastery = <String, int>{};
  Set<String> _certificates = <String>{};

  _Lesson get course => widget.course;
  String get courseId => course.title.toLowerCase().replaceAll(' ', '-');

  int get completedCount => course.chapters.where((String chapter) {
        return _completed.contains(AcademyCatalog.forChapter(chapter).id);
      }).length;

  double get progress =>
      course.chapters.isEmpty ? 0 : completedCount / course.chapters.length;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final Set<String> completed = await _progressStore.readCompleted();
      final Map<String, int> mastery = await _progressStore.readMastery();
      final Set<String> certificates = await _progressStore.readCertificates();
      if (mounted) {
        setState(() {
          _completed = completed;
          _mastery = mastery;
          _certificates = certificates;
        });
      }
    } on Object {
      // Course navigation remains available without persistent storage.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF06131D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF071827),
          title: Row(
            children: <Widget>[
              Icon(course.icon, color: course.accent),
              const SizedBox(width: 10),
              Text(course.title,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        body: ResponsivePage(
          maxWidth: 980,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: course.accent.withValues(alpha: .65)),
                  image: DecorationImage(
                    image: AssetImage(course.asset),
                    fit: BoxFit.cover,
                    colorFilter: const ColorFilter.mode(
                        Color(0xB8061725), BlendMode.srcOver),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(course.body,
                        style: const TextStyle(
                            color: Color(0xFFD2DDE5),
                            fontSize: 17,
                            height: 1.4)),
                    const SizedBox(height: 16),
                    Text('$completedCount of ${course.chapters.length} lessons',
                        style: TextStyle(
                            color: course.accent, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(99),
                      backgroundColor: const Color(0xFF263948),
                      valueColor: AlwaysStoppedAnimation<Color>(course.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('COURSE LESSONS',
                  style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1)),
              const SizedBox(height: 12),
              ...List<Widget>.generate(course.chapters.length, (int index) {
                final AcademyLesson academyLesson =
                    AcademyCatalog.forChapter(course.chapters[index]);
                final bool done = _completed.contains(academyLesson.id);
                final bool active = !done && index == completedCount;
                final bool locked = !done && index > completedCount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChessVerseCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      onTap: locked
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      InteractiveAcademyLessonScreen(
                                    lesson: academyLesson,
                                  ),
                                ),
                              );
                              await _loadProgress();
                            },
                      leading: CircleAvatar(
                        backgroundColor: course.accent.withValues(alpha: .16),
                        foregroundColor: course.accent,
                        child: done
                            ? const Icon(Icons.check_rounded)
                            : locked
                                ? const Icon(Icons.lock_rounded, size: 18)
                                : Text('${index + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900)),
                      ),
                      title: Text(course.chapters[index],
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(active
                          ? 'Continue this lesson'
                          : done
                              ? 'Completed'
                              : locked
                                  ? 'Complete the previous lesson to unlock'
                                  : 'Learn the idea, then try a position'),
                      trailing: done
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ...List<Widget>.generate(
                                  3,
                                  (int star) => Icon(
                                    star < (_mastery[academyLesson.id] ?? 1)
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 17,
                                    color: AppColors.accentGold,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(Icons.arrow_forward_rounded,
                                    color: course.accent),
                              ],
                            )
                          : Icon(
                              locked
                                  ? Icons.lock_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              color: locked
                                  ? AppColors.textSecondary
                                  : course.accent,
                            ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              ChessVerseCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: course.accent.withValues(alpha: .14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _certificates.contains(courseId)
                            ? Icons.workspace_premium_rounded
                            : Icons.military_tech_rounded,
                        color: course.accent,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _certificates.contains(courseId)
                                ? 'MASTERY CERTIFICATE EARNED'
                                : 'FINAL MASTERY CHALLENGE',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            completedCount == course.chapters.length
                                ? 'Solve 3 no-hint positions and score at least 2.'
                                : 'Complete every lesson to unlock the course boss.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: completedCount != course.chapters.length
                          ? null
                          : () async {
                              final List<AcademyLesson> lessons = course.chapters
                                  .map(AcademyCatalog.forChapter)
                                  .toList(growable: false);
                              final List<AcademyLesson> challenge = <AcademyLesson>[
                                lessons.first,
                                lessons[lessons.length ~/ 2],
                                lessons.last,
                              ];
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => AcademyBossChallengeScreen(
                                    courseId: courseId,
                                    courseTitle: course.title,
                                    lessons: challenge,
                                    accent: course.accent,
                                  ),
                                ),
                              );
                              await _loadProgress();
                            },
                      child: Text(_certificates.contains(courseId)
                          ? 'VIEW'
                          : 'START'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Lesson {
  const _Lesson({
    required this.icon,
    required this.title,
    required this.body,
    required this.asset,
    required this.accent,
    required this.chapters,
  });
  final IconData icon;
  final String title;
  final String body;
  final String asset;
  final Color accent;
  final List<String> chapters;
}
