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
    this.onProfile,
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
  final VoidCallback? onProfile;
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
      (icon: Icons.sports_esports_rounded, label: 'Play', onTap: onPlay),
      (icon: Icons.extension_rounded, label: 'Puzzles', onTap: onPuzzles),
      (icon: Icons.school_rounded, label: 'Learn', onTap: onLearn),
      (icon: Icons.person_rounded, label: 'Profile', onTap: onProfile),
      if (onFriends != null)
        (icon: Icons.groups_2_rounded, label: 'Community', onTap: onFriends),
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
              Flexible(
                child: Text('CHESSVERSE',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        color: Color(0xFFF5F7FA),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent)),
              ),
              Text('AI',
                  style: TextStyle(
                      color: Color(0xFFE9B84C),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent)),
            ],
          ),
          const SizedBox(height: 27),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                for (final item in items)
                  _DesktopNavItem(
                    icon: item.icon,
                    label: item.label,
                    selected: selected == item.label,
                    onTap: item.onTap,
                  ),
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
    final Color activeColor = AppColors.accentGold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? const Color(0xFF102C45) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: selected
              ? const BorderSide(color: Color(0xFFC28A24))
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
