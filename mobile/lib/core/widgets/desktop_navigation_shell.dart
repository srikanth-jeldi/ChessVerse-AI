import 'package:flutter/material.dart';

import '../desktop_navigation_bridge.dart';
import 'desktop_app_sidebar.dart';

/// Adds the shared app navigation around standalone screens on desktop/web.
/// Mobile keeps the screen's original navigation unchanged.
class DesktopNavigationShell extends StatelessWidget {
  const DesktopNavigationShell({
    required this.selected,
    required this.child,
    this.breakpoint = 700,
    super.key,
  });

  final String selected;
  final Widget child;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < breakpoint) return child;
    return Scaffold(
      body: Row(
        children: <Widget>[
          DesktopAppSidebar(
            selected: selected,
            onHome: () => DesktopNavigationBridge.open(context, 0),
            onPlay: () => DesktopNavigationBridge.open(context, 1),
            onPuzzles: () => DesktopNavigationBridge.open(context, 2),
            onLearn: () => DesktopNavigationBridge.open(context, 3),
            onProfile: () => DesktopNavigationBridge.open(context, 4),
            onFriends: () => DesktopNavigationBridge.open(context, 5),
            onMyGames: () => DesktopNavigationBridge.open(context, 6),
            onCollection: () => DesktopNavigationBridge.open(context, 7),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
