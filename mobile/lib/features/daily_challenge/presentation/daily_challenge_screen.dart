import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../domain/daily_challenge_models.dart';
import '../widgets/challenge_result_sheet.dart';
import '../widgets/daily_challenge_card.dart';
import '../widgets/difficulty_selector.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  DailyChallengeUiDifficulty _difficulty = DailyChallengeUiDifficulty.medium;
  bool _showResultPreview = false;

  DailyChallengeUiState get _challenge => DailyChallengeUiState(
        title: 'Find the forcing line',
        difficulty: _difficulty,
        streakDays: 5,
        completedToday: _showResultPreview,
        currentMove: _showResultPreview ? _difficulty.moveGoal : 1,
        bestTimeLabel: '01:42',
      );

  @override
  Widget build(BuildContext context) {
    final bool wide = AppBreakpoints.isTabletOrLarger(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Challenge'),
        actions: <Widget>[
          IconButton(
            onPressed: () => setState(() => _showResultPreview = !_showResultPreview),
            icon: Icon(
              _showResultPreview ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            ),
            tooltip: 'Toggle result preview',
          ),
        ],
      ),
      body: ResponsivePage(
        child: wide ? _WideLayout(challenge: _challenge, onDifficultyChanged: _changeDifficulty, onResultToggle: _toggleResult) : _PhoneLayout(challenge: _challenge, onDifficultyChanged: _changeDifficulty, onResultToggle: _toggleResult),
      ),
    );
  }

  void _changeDifficulty(DailyChallengeUiDifficulty difficulty) {
    setState(() {
      _difficulty = difficulty;
      _showResultPreview = false;
    });
  }

  void _toggleResult() {
    setState(() => _showResultPreview = !_showResultPreview);
  }
}

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({
    required this.challenge,
    required this.onDifficultyChanged,
    required this.onResultToggle,
  });

  final DailyChallengeUiState challenge;
  final ValueChanged<DailyChallengeUiDifficulty> onDifficultyChanged;
  final VoidCallback onResultToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DailyChallengeCard(
          challenge: challenge,
          onPlay: onResultToggle,
          onViewDetails: onResultToggle,
        ),
        const SizedBox(height: 20),
        Text('Choose difficulty', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        DailyChallengeDifficultySelector(
          selected: challenge.difficulty,
          onChanged: onDifficultyChanged,
        ),
        const SizedBox(height: 20),
        _RulesCard(challenge: challenge),
        if (challenge.completedToday) ...<Widget>[
          const SizedBox(height: 20),
          DailyChallengeResultSheet(
            challenge: challenge,
            onReview: onResultToggle,
            onShare: () {},
          ),
        ],
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.challenge,
    required this.onDifficultyChanged,
    required this.onResultToggle,
  });

  final DailyChallengeUiState challenge;
  final ValueChanged<DailyChallengeUiDifficulty> onDifficultyChanged;
  final VoidCallback onResultToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 6,
          child: DailyChallengeCard(
            challenge: challenge,
            onPlay: onResultToggle,
            onViewDetails: onResultToggle,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ChessVerseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Choose difficulty', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    DailyChallengeDifficultySelector(
                      selected: challenge.difficulty,
                      onChanged: onDifficultyChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _RulesCard(challenge: challenge),
              if (challenge.completedToday) ...<Widget>[
                const SizedBox(height: 18),
                DailyChallengeResultSheet(
                  challenge: challenge,
                  onReview: onResultToggle,
                  onShare: () {},
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.challenge});

  final DailyChallengeUiState challenge;

  @override
  Widget build(BuildContext context) {
    return ChessVerseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: AppColors.info),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'How it works',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RuleLine(text: 'Solve one tactical puzzle every day.'),
          _RuleLine(text: 'Only forcing moves keep the challenge alive.'),
          _RuleLine(text: 'Complete ${challenge.moveGoal} moves to protect your streak.'),
          const SizedBox(height: 12),
          Text(
            'Next integration step: connect this UI to the existing DailyChallenge game mode in main.dart without changing board logic.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
