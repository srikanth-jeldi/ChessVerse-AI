import 'package:flutter/material.dart';

import '../../../core/layout/responsive_page.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LocalGameStats stats = LocalGameArchive.stats();
    final RewardSnapshot rewards = LocalGameArchive.rewards();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ChessVerseCard(
              child: Row(
                children: <Widget>[
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(Icons.person_rounded, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Guest Player',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Preview account - local progress',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ChessVerseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.military_tech_rounded,
                        color: AppColors.accentGold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rewards',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _RewardChip(
                        icon: Icons.paid_rounded,
                        label: '${rewards.coins} coins',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Level ${rewards.level} • ${rewards.xp} XP',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
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
                      _RewardChip(
                        icon: Icons.local_fire_department_rounded,
                        label: '${rewards.streak} day streak',
                      ),
                      _RewardChip(
                        icon: Icons.workspace_premium_rounded,
                        label:
                            '${rewards.unlockedBadges}/${rewards.badges.length} badges',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Badges', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: rewards.badges
                  .map((RewardBadge badge) => _BadgeCard(badge: badge))
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            Text('Stats', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: <Widget>[
                _StatCard(
                    label: 'Games',
                    value: '${stats.gamesPlayed}',
                    icon: Icons.sports_esports_rounded),
                _StatCard(
                    label: 'Wins',
                    value: '${stats.wins}',
                    icon: Icons.emoji_events_rounded),
                _StatCard(
                    label: 'Draws',
                    value: '${stats.draws}',
                    icon: Icons.handshake_rounded),
                _StatCard(
                    label: 'Losses',
                    value: '${stats.losses}',
                    icon: Icons.close_rounded),
                _StatCard(
                    label: 'Daily streak',
                    value: '${stats.dailyStreak}',
                    icon: Icons.local_fire_department_rounded),
                const _StatCard(
                    label: 'Best AI',
                    value: 'Level 4',
                    icon: Icons.smart_toy_rounded),
                _StatCard(
                    label: 'Puzzles',
                    value: '${stats.puzzlesSolved}',
                    icon: Icons.extension_rounded),
                _StatCard(
                    label: 'Win rate',
                    value: '${stats.winRate}%',
                    icon: Icons.insights_rounded),
              ],
            ),
            const SizedBox(height: 18),
            ChessVerseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Account status',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'You are using preview guest mode. Sign in integration can save games, streaks, analysis history, and cloud progress later.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ChessVerseButton(
                    label: 'Sign in coming soon',
                    icon: Icons.login_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.icon, required this.label});

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

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final RewardBadge badge;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        badge.unlocked ? AppColors.accentGold : const Color(0xFFAAA69E);
    return ChessVerseCard(
      child: Opacity(
        opacity: badge.unlocked ? 1 : 0.54,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(badge.icon, style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Icon(
                  badge.unlocked
                      ? Icons.verified_rounded
                      : Icons.lock_outline_rounded,
                  color: accent,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  badge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: accent),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ChessVerseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(icon, color: AppColors.accentGold),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 3),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
