import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../daily_challenge/domain/daily_challenge_models.dart';
import '../../daily_challenge/widgets/daily_challenge_launcher.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    required this.playerName,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onOnlineGame,
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
  final VoidCallback onOnlineGame;
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
                onOnlineGame: onOnlineGame,
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
                onOnlineGame: onOnlineGame,
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
    required this.onOnlineGame,
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
  final VoidCallback onOnlineGame;
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
        _GameModeHub(
          onPlayVsAi: onPlayVsAi,
          onDailyChallenge: onDailyChallenge,
          onLocalGame: onLocalGame,
          onOnlineGame: onOnlineGame,
          onAnalysis: onAnalysis,
          onPuzzles: onPuzzles,
          onSavedGames: onSavedGames,
          onLearnChess: onLearnChess,
          onProfile: onProfile,
          onSettings: onSettings,
        ),
        const SizedBox(height: 18),
        RewardProgressCard(rewards: rewards),
        const SizedBox(height: 18),
        DailyChallengeLauncher(
          challenge: challenge,
          onStart: onDailyChallenge,
          onViewDetails: onDailyChallenge,
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
    required this.onOnlineGame,
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
  final VoidCallback onOnlineGame;
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
        _GameModeHub(
          onPlayVsAi: onPlayVsAi,
          onDailyChallenge: onDailyChallenge,
          onLocalGame: onLocalGame,
          onOnlineGame: onOnlineGame,
          onAnalysis: onAnalysis,
          onPuzzles: onPuzzles,
          onSavedGames: onSavedGames,
          onLearnChess: onLearnChess,
          onProfile: onProfile,
          onSettings: onSettings,
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: RewardProgressCard(rewards: rewards),
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

class _GameModeHub extends StatelessWidget {
  const _GameModeHub({
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onOnlineGame,
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
  final VoidCallback onOnlineGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onSavedGames;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final List<_GameMode> primaryModes = <_GameMode>[
      _GameMode(
        icon: Icons.public_rounded,
        title: 'Play Online',
        subtitle: 'Match with players',
        onTap: onOnlineGame,
      ),
      _GameMode(
        icon: Icons.smart_toy_rounded,
        title: 'Play with Computer',
        subtitle: '10 adaptive AI levels',
        onTap: onPlayVsAi,
      ),
      _GameMode(
        icon: Icons.people_alt_rounded,
        title: 'Play with Friends',
        subtitle: 'Pass & Play',
        onTap: onLocalGame,
      ),
      _GameMode(
        icon: Icons.local_fire_department_rounded,
        title: 'Daily Challenge',
        subtitle: 'A new puzzle every day',
        onTap: onDailyChallenge,
      ),
      _GameMode(
        icon: Icons.extension_rounded,
        title: 'Chess Puzzles',
        subtitle: 'Sharpen your tactics',
        onTap: onPuzzles,
      ),
      _GameMode(
        icon: Icons.leaderboard_rounded,
        title: 'Rankings',
        subtitle: 'Profile & progress',
        onTap: onProfile,
      ),
      _GameMode(
        icon: Icons.settings_rounded,
        title: 'Settings',
        subtitle: 'Sound, board & account',
        onTap: onSettings,
      ),
    ];
    final List<_GameMode> extraModes = <_GameMode>[
      _GameMode(
        icon: Icons.analytics_rounded,
        title: 'Analysis',
        subtitle: 'Review your games',
        onTap: onAnalysis,
      ),
      _GameMode(
        icon: Icons.bookmark_rounded,
        title: 'Saved Games',
        subtitle: 'Continue and review',
        onTap: onSavedGames,
      ),
      _GameMode(
        icon: Icons.school_rounded,
        title: 'Learn Chess',
        subtitle: 'Coach lessons',
        onTap: onLearnChess,
      ),
    ];

    return ChessVerseCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(Icons.sports_esports_rounded, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Choose your game',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pick a mode and start playing.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ModeGrid(modes: primaryModes, featured: true),
          const SizedBox(height: 18),
          Text('More ChessVerse',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _ModeGrid(modes: extraModes),
        ],
      ),
    );
  }
}

class _GameMode {
  const _GameMode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({required this.modes, this.featured = false});

  final List<_GameMode> modes;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 680
                ? 3
                : 2;
        final double tileWidth =
            (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: modes
              .map(
                (_GameMode mode) => SizedBox(
                  width: tileWidth,
                  child: _GameModeTile(mode: mode, featured: featured),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _GameModeTile extends StatelessWidget {
  const _GameModeTile({required this.mode, required this.featured});

  final _GameMode mode;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${mode.title}. ${mode.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: mode.onTap,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 126),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: featured
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          AppColors.primary.withValues(alpha: 0.82),
                          AppColors.primaryDark.withValues(alpha: 0.62),
                        ],
                      )
                    : null,
                color: featured
                    ? null
                    : AppColors.surfaceLight.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: featured
                      ? AppColors.accentGold.withValues(alpha: 0.72)
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(mode.icon, color: AppColors.accentGold, size: 27),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    mode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mode.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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
