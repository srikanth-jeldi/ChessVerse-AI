import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/local_game_archive.dart';
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
    required this.onPuzzles,
    required this.onSavedGames,
    required this.onLearnChess,
    required this.onProfile,
    required this.onSettings,
    super.key,
  });

  final String playerName;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onSavedGames;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final bool wide = AppBreakpoints.isTabletOrLarger(context);
    final DailyChallengeUiState challenge = DailyChallengeUiState.sample;
    final RewardSnapshot rewards = LocalGameArchive.rewards();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsivePage(
        child: wide
            ? _WideHomeLayout(
                playerName: playerName,
                challenge: challenge,
                rewards: rewards,
                onPlayVsAi: onPlayVsAi,
                onDailyChallenge: onDailyChallenge,
                onLocalGame: onLocalGame,
                onAnalysis: onAnalysis,
                onPuzzles: onPuzzles,
                onSavedGames: onSavedGames,
                onLearnChess: onLearnChess,
                onProfile: onProfile,
                onSettings: onSettings,
              )
            : _PhoneHomeLayout(
                playerName: playerName,
                challenge: challenge,
                rewards: rewards,
                onPlayVsAi: onPlayVsAi,
                onDailyChallenge: onDailyChallenge,
                onLocalGame: onLocalGame,
                onAnalysis: onAnalysis,
                onPuzzles: onPuzzles,
                onSavedGames: onSavedGames,
                onLearnChess: onLearnChess,
                onProfile: onProfile,
                onSettings: onSettings,
              ),
      ),
    );
  }
}

class _PhoneHomeLayout extends StatelessWidget {
  const _PhoneHomeLayout({
    required this.playerName,
    required this.challenge,
    required this.rewards,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onAnalysis,
    required this.onPuzzles,
    required this.onSavedGames,
    required this.onLearnChess,
    required this.onProfile,
    required this.onSettings,
  });

  final String playerName;
  final DailyChallengeUiState challenge;
  final RewardSnapshot rewards;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onSavedGames;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HomeHeader(
          playerName: playerName,
          onProfile: onProfile,
          onSettings: onSettings,
        ),
        const SizedBox(height: 20),
        RewardProgressCard(rewards: rewards),
        const SizedBox(height: 18),
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
          onPuzzles: onPuzzles,
          onSavedGames: onSavedGames,
          onLearnChess: onLearnChess,
          onProfile: onProfile,
          onSettings: onSettings,
        ),
      ],
    );
  }
}

class _WideHomeLayout extends StatelessWidget {
  const _WideHomeLayout({
    required this.playerName,
    required this.challenge,
    required this.rewards,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onAnalysis,
    required this.onPuzzles,
    required this.onSavedGames,
    required this.onLearnChess,
    required this.onProfile,
    required this.onSettings,
  });

  final String playerName;
  final DailyChallengeUiState challenge;
  final RewardSnapshot rewards;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onSavedGames;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HomeHeader(
          playerName: playerName,
          onProfile: onProfile,
          onSettings: onSettings,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Column(
                children: <Widget>[
                  RewardProgressCard(rewards: rewards),
                  const SizedBox(height: 18),
                  _HeroPlayCard(onPlayVsAi: onPlayVsAi),
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
        const SizedBox(height: 18),
        _QuickActionsGrid(
          onPlayVsAi: onPlayVsAi,
          onDailyChallenge: onDailyChallenge,
          onLocalGame: onLocalGame,
          onAnalysis: onAnalysis,
          onPuzzles: onPuzzles,
          onSavedGames: onSavedGames,
          onLearnChess: onLearnChess,
          onProfile: onProfile,
          onSettings: onSettings,
        ),
      ],
    );
  }
}

class RewardProgressCard extends StatelessWidget {
  const RewardProgressCard({required this.rewards, super.key});

  final RewardSnapshot rewards;

  @override
  Widget build(BuildContext context) {
    final int remainingXp = (rewards.nextLevelXp - rewards.xp)
        .clamp(0, rewards.nextLevelXp)
        .toInt();
    return ChessVerseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.accentGold.withValues(alpha: 0.22),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(Icons.military_tech_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ChessVerse Progress',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remainingXp == 0
                          ? 'Level ${rewards.level} ready'
                          : '$remainingXp XP to Level ${rewards.level + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _RewardMiniPill(
                icon: Icons.paid_rounded,
                label: '${rewards.coins}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: rewards.levelProgress,
              backgroundColor: const Color(0xFF222636),
              color: AppColors.accentGold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _RewardMiniPill(
                icon: Icons.bolt_rounded,
                label: 'Level ${rewards.level}',
              ),
              _RewardMiniPill(
                icon: Icons.local_fire_department_rounded,
                label: '${rewards.streak} day streak',
              ),
              _RewardMiniPill(
                icon: Icons.workspace_premium_rounded,
                label:
                    '${rewards.unlockedBadges}/${rewards.badges.length} badges',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardMiniPill extends StatelessWidget {
  const _RewardMiniPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF211D24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.accentGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.playerName,
    required this.onProfile,
    required this.onSettings,
  });

  final String playerName;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

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
          onPressed: onSettings,
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 8),
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
    required this.onPuzzles,
    required this.onSavedGames,
    required this.onLearnChess,
    required this.onProfile,
    required this.onSettings,
  });

  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onSavedGames;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final bool wide = AppBreakpoints.isTabletOrLarger(context);
    return GridView.count(
      crossAxisCount: wide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: wide ? 1.45 : 1.02,
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
        _ActionTile(
          icon: Icons.extension_rounded,
          title: 'Puzzles',
          subtitle: 'Tactics',
          onTap: onPuzzles,
        ),
        _ActionTile(
          icon: Icons.bookmark_rounded,
          title: 'Saved',
          subtitle: 'Games',
          onTap: onSavedGames,
        ),
        _ActionTile(
          icon: Icons.school_rounded,
          title: 'Learn',
          subtitle: 'Coach tips',
          onTap: onLearnChess,
        ),
        _ActionTile(
          icon: Icons.person_rounded,
          title: 'Profile',
          subtitle: 'Stats',
          onTap: onProfile,
        ),
        _ActionTile(
          icon: Icons.settings_rounded,
          title: 'Settings',
          subtitle: 'Prefs',
          onTap: onSettings,
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
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
