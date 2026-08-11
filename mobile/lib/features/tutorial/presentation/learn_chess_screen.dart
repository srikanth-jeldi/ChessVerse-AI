import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../analysis/domain/ai_review_report.dart';
import '../domain/academy_lesson.dart';
import 'interactive_academy_lesson_screen.dart';

class LearnChessScreen extends StatelessWidget {
  const LearnChessScreen({super.key});

  static const List<_Lesson> _lessons = <_Lesson>[
    _Lesson(
      icon: Icons.account_tree_rounded,
      title: 'Piece Basics',
      body: 'Learn how every piece moves and captures.',
      asset: 'assets/backgrounds/home-online-hero-v1.png',
      accent: Color(0xFF53D8C4),
      progress: 0.35,
      completed: '3 of 8 lessons',
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
      asset: 'assets/backgrounds/home-settings-hero-v1.png',
      accent: Color(0xFF4DA8FF),
      progress: 0.18,
      completed: '1 of 6 lessons',
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
      asset: 'assets/backgrounds/home-puzzles-hero-v1.png',
      accent: Color(0xFFE9B84C),
      progress: 0.08,
      completed: '1 of 12 lessons',
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
      asset: 'assets/backgrounds/home-rankings-hero-v1.png',
      accent: Color(0xFF9C6BFF),
      progress: 0,
      completed: '0 of 8 lessons',
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
  Widget build(BuildContext context) {
    final Size viewport = MediaQuery.sizeOf(context);
    final bool wide = AppBreakpoints.isTabletOrLarger(context);
    final bool compact = viewport.width < 520;
    final SavedGameRecord? latest =
        LocalGameArchive.games.isEmpty ? null : LocalGameArchive.games.first;
    final AiReviewReport? report = latest == null
        ? null
        : AiReviewReport.fromMoves(
            latest.moves,
            newestFirst: false,
            result: latest.result,
          );
    final AcademyLesson recommended = AcademyCatalog.forChapter(
      report?.recommendedLesson.split('•').last.trim() ?? 'How pawns move',
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
            _CoachHero(compact: compact),
            const SizedBox(height: 16),
            _PersonalizedPathCard(
              lesson: recommended,
              reason: report?.trainingFocus ??
                  'Start with piece movement, then the AI coach will adapt your path after every reviewed game.',
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
              itemCount: _lessons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // Phone cards need the same complete learning information as
                // tablet/web. A single column keeps the artwork, lesson count,
                // progress bar and action readable without clipping.
                crossAxisCount: wide ? 4 : (compact ? 1 : 2),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: wide ? 0.78 : (compact ? 1.22 : 0.78),
              ),
              itemBuilder: (BuildContext context, int index) =>
                  _LessonCard(lesson: _lessons[index]),
            ),
            const SizedBox(height: 24),
            const _CoachEvaluationPanel(),
          ],
        ),
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
                  colors: <Color>[Color(0xFF9C72FF), Color(0xFF2FD5C4)],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: pieceLessons
                .map((AcademyLesson item) => _PieceQuickLesson(lesson: item))
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
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(children: <Widget>[
            Image.asset(
              'assets/pieces/staunton_white_${name.toLowerCase()}.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: 3),
            Text(name,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800)),
          ]),
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
            image: AssetImage('assets/backgrounds/learn-academy-hero-v1.png'),
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
                          color: Color(0xFF53D8C4), size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text('AI-GUIDED TRAINING',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                color: Color(0xFF53D8C4),
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
  const _LessonCard({required this.lesson});
  final _Lesson lesson;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openLesson(context, lesson),
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
                        child:
                            Icon(lesson.icon, color: lesson.accent, size: 21),
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
                  Text(lesson.completed,
                      style: TextStyle(
                          color: lesson.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: lesson.progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFF263948),
                      valueColor: AlwaysStoppedAnimation<Color>(lesson.accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(lesson.progress == 0 ? 'START LESSON' : 'CONTINUE',
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
                          color: Color(0xFF9C6BFF)),
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

class _CourseScreen extends StatelessWidget {
  const _CourseScreen({required this.course});
  final _Lesson course;

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
                    Text(course.completed,
                        style: TextStyle(
                            color: course.accent, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: course.progress,
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
                final int completedCount =
                    (course.progress * course.chapters.length).floor();
                final bool done = index < completedCount;
                final bool active = index == completedCount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChessVerseCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InteractiveAcademyLessonScreen(
                            lesson: AcademyCatalog.forChapter(
                              course.chapters[index],
                            ),
                          ),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: course.accent.withValues(alpha: .16),
                        foregroundColor: course.accent,
                        child: done
                            ? const Icon(Icons.check_rounded)
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
                              : 'Learn the idea, then try a position'),
                      trailing: Icon(Icons.arrow_forward_rounded,
                          color: course.accent),
                    ),
                  ),
                );
              }),
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
    required this.progress,
    required this.completed,
    required this.chapters,
  });
  final IconData icon;
  final String title;
  final String body;
  final String asset;
  final Color accent;
  final double progress;
  final String completed;
  final List<String> chapters;
}
