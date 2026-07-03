import 'package:flutter/material.dart';

import '../../../core/layout/responsive_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          'Preview account · local progress',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              children: const <Widget>[
                _StatCard(label: 'Games', value: '12', icon: Icons.sports_esports_rounded),
                _StatCard(label: 'Wins', value: '7', icon: Icons.emoji_events_rounded),
                _StatCard(label: 'Draws', value: '2', icon: Icons.handshake_rounded),
                _StatCard(label: 'Losses', value: '3', icon: Icons.close_rounded),
                _StatCard(label: 'Daily streak', value: '5', icon: Icons.local_fire_department_rounded),
                _StatCard(label: 'Best AI', value: 'Level 4', icon: Icons.smart_toy_rounded),
                _StatCard(label: 'Puzzles', value: '18', icon: Icons.extension_rounded),
                _StatCard(label: 'Accuracy', value: '72%', icon: Icons.insights_rounded),
              ],
            ),
            const SizedBox(height: 18),
            ChessVerseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Account status', style: Theme.of(context).textTheme.titleLarge),
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
