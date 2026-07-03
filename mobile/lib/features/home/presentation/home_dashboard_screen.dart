import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../daily_challenge/domain/daily_challenge_models.dart';
import '../../daily_challenge/widgets/daily_challenge_launcher.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    required this.playerName,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onAnalysis,
    required this.onProfile,
    super.key,
  });

  final String playerName;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onAnalysis;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final bool wide = AppBreakpoints.isTabletOrLarger(context);
    final DailyChallengeUiState challenge = DailyChallengeUiState.sample;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsivePage(
        child: wide
            ? _WideHomeLayout(
                playerName: playerName,
                challenge: challenge,
                onPlayVsAi: onPlayVsAi,
                onDailyChallenge: onDailyChallenge,
                onLocalGame: onLocalGame,
                onAnalysis: onAnalysis,
                onProfile: onProfile,
              )
            : _PhoneHomeLayout(
                playerName: playerName,
                challenge: challenge,
                onPlayVsAi: onPlayVsAi,
                onDailyChallenge: onDailyChallenge,
                onLocalGame: onLocalGame,
                onAnalysis: onAnalysis,
                onProfile: onProfile,
              ),
      ),
    );
  }
}

class _PhoneHomeLayout extends StatelessWidget {
  const _PhoneHomeLayout({
    required this.playerName,
    required this.challenge,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onAnalysis,
    required this.onProfile,
  });

  final String playerName;
  final DailyChallengeUiState challenge;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onAnalysis;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HomeHeader(playerName: playerName, onProfile: onProfile),
        const SizedBox(height: 20),
        _HeroPlayCard(onPlayVsAi: onPlayVsAi),
        const SizedBox(height: 18),
        DailyChallengeLauncher(
          challenge: challenge,
          onStart: onDailyChallenge,
          onViewDetails: onDailyChallenge,
        ),
        const SizedBox(height: 18),
        _QuickActionsGrid(
          onPlayVsAi: onPlayVsAi,
          onDailyChallenge: onDailyChallenge,
          onLocalGame: onLocalGame,
          onAnalysis: onAnalysis,
        ),
      ],
    );
  }
}

class _WideHomeLayout extends StatelessWidget {
  const _WideHomeLayout({
    required this.playerName,
    required this.challenge,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onAnalysis,
    required this.onProfile,
  });

  final String playerName;
  final DailyChallengeUiState challenge;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onAnalysis;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HomeHeader(playerName: playerName, onProfile: onProfile),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Column(
                children: <Widget>[
                  _HeroPlayCard(onPlayVsAi: onPlayVsAi),
                  const SizedBox(height: 18),
                  _QuickActionsGrid(
                    onPlayVsAi: onPlayVsAi,
                    onDailyChallenge: onDailyChallenge,
                    onLocalGame: onLocalGame,
                    onAnalysis: onAnalysis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              flex: 5,
              child: DailyChallengeLauncher(
                challenge: challenge,
                onStart: onDailyChallenge,
                onViewDetails: onDailyChallenge,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.playerName, required this.onProfile});

  final String playerName;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Welcome back,',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                playerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 30,
                    ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onProfile,
          icon: const Icon(Icons.person_rounded),
          tooltip: 'Profile',
        ),
      ],
    );
  }
}

class _HeroPlayCard extends StatelessWidget {
  const _HeroPlayCard({required this.onPlayVsAi});

  final VoidCallback onPlayVsAi;

  @override
  Widget build(BuildContext context) {
    return ChessVerseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.psychology_alt_rounded, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            'Train with ChessVerse AI',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Play against adaptive AI levels, get hints, review mistakes, and improve every session.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          ChessVerseButton(
            label: 'Play vs AI',
            icon: Icons.play_arrow_rounded,
            onPressed: onPlayVsAi,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onAnalysis,
  });

  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onAnalysis;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: AppBreakpoints.isTabletOrLarger(context) ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.18,
      children: <Widget>[
        _ActionTile(
          icon: Icons.smart_toy_rounded,
          title: 'AI Game',
          subtitle: '10 levels',
          onTap: onPlayVsAi,
        ),
        _ActionTile(
          icon: Icons.emoji_events_rounded,
          title: 'Daily',
          subtitle: 'Checkmate',
          onTap: onDailyChallenge,
        ),
        _ActionTile(
          icon: Icons.people_alt_rounded,
          title: 'Local',
          subtitle: '2 players',
          onTap: onLocalGame,
        ),
        _ActionTile(
          icon: Icons.analytics_rounded,
          title: 'Analysis',
          subtitle: 'Review',
          onTap: onAnalysis,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChessVerseCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(icon, color: AppColors.accentGold),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
