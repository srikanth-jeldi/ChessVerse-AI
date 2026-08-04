import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared 258px desktop/tablet navigation used by the supplied web references.
class DesktopAppSidebar extends StatelessWidget {
  const DesktopAppSidebar({
    required this.selected,
    this.onHome,
    this.onPlay,
    this.onPuzzles,
    this.onLearn,
    this.onAnalysis,
    this.onRankings,
    this.onFriends,
    this.onEvents,
    this.onStore,
    this.onSettings,
    super.key,
  });

  final String selected;
  final VoidCallback? onHome;
  final VoidCallback? onPlay;
  final VoidCallback? onPuzzles;
  final VoidCallback? onLearn;
  final VoidCallback? onAnalysis;
  final VoidCallback? onRankings;
  final VoidCallback? onFriends;
  final VoidCallback? onEvents;
  final VoidCallback? onStore;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final List<({IconData icon, String label, VoidCallback? onTap})> items =
        <({IconData icon, String label, VoidCallback? onTap})>[
      (icon: Icons.home_rounded, label: 'Home', onTap: onHome),
      (icon: Icons.sports_martial_arts_rounded, label: 'Play', onTap: onPlay),
      (icon: Icons.extension_rounded, label: 'Puzzles', onTap: onPuzzles),
      (icon: Icons.menu_book_rounded, label: 'Learn', onTap: onLearn),
      (icon: Icons.trending_up_rounded, label: 'Analysis', onTap: onAnalysis),
      (icon: Icons.bar_chart_rounded, label: 'Rankings', onTap: onRankings),
      (icon: Icons.group_rounded, label: 'Friends', onTap: onFriends),
      (icon: Icons.calendar_month_rounded, label: 'Events', onTap: onEvents),
      (icon: Icons.shopping_cart_rounded, label: 'Store', onTap: onStore),
      (icon: Icons.settings_rounded, label: 'Settings', onTap: onSettings),
    ];
    return Container(
      width: 258,
      decoration: const BoxDecoration(
        color: Color(0xF2081929),
        border: Border(right: BorderSide(color: Color(0xFF1A3449))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 24),
      child: Column(
        children: <Widget>[
          Image.asset('assets/branding/app_icon.png', width: 88, height: 88),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('CHESSVERSE ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text('AI',
                  style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 27),
          for (final item in items)
            _DesktopNavItem(
              icon: item.icon,
              label: item.label,
              selected: selected == item.label,
              onTap: item.onTap,
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB77D1E)),
              color: const Color(0xB30A1723),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.workspace_premium_rounded,
                    color: AppColors.accentGold, size: 38),
                SizedBox(width: 12),
                Expanded(
                    child: Text('Upgrade to\nPremium',
                        style: TextStyle(
                            color: Color(0xFFFFCF55),
                            fontSize: 17,
                            height: 1.35,
                            fontWeight: FontWeight.w700))),
                Icon(Icons.chevron_right_rounded, color: AppColors.accentGold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool homeSelected = selected && label == 'Home';
    final Color activeColor =
        homeSelected ? const Color(0xFF4DA8FF) : AppColors.accentGold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected
            ? (homeSelected ? const Color(0xFF123E70) : const Color(0xFF102C45))
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: selected
              ? BorderSide(
                  color: homeSelected
                      ? const Color(0xFF2F91ED)
                      : const Color(0xFFC28A24))
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 15),
                Icon(icon,
                    size: 25,
                    color: selected ? activeColor : const Color(0xFF9DAFC2)),
                const SizedBox(width: 18),
                Text(label,
                    style: TextStyle(
                        color: selected ? activeColor : const Color(0xFFC4CFDC),
                        fontSize: 17,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
