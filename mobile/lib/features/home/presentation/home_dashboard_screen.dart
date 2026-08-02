import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

void _noOnlineAction() {}

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    required this.playerName,
    this.profilePhotoUrl,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    this.onOnlineGame = _noOnlineAction,
    required this.onAnalysis,
    required this.onPuzzles,
    required this.onSavedGames,
    required this.onLearnChess,
    required this.onProfile,
    this.onRankings = _noOnlineAction,
    required this.onSettings,
    super.key,
  });

  final String playerName;
  final String? profilePhotoUrl;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onOnlineGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onSavedGames;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onRankings;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 720;
            final bool desktopViewport = wide && constraints.maxHeight >= 600;
            final Widget content = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 920,
                  minWidth: wide ? 0 : constraints.maxWidth - 30,
                ),
                child: Column(
                  children: <Widget>[
                    _TopBar(
                      playerName: playerName,
                      profilePhotoUrl: profilePhotoUrl,
                      onProfile: onProfile,
                      onSettings: onSettings,
                    ),
                    SizedBox(height: wide ? 26 : 18),
                    const _BrandHero(),
                    SizedBox(height: wide ? 30 : 22),
                    const _LiveStats(),
                    const SizedBox(height: 18),
                    _GameModeGrid(
                      wide: wide,
                      onOnline: onOnlineGame,
                      onComputer: onPlayVsAi,
                      onFriends: onOnlineGame,
                      onPuzzles: onPuzzles,
                      onRankings: onRankings,
                      onSettings: onSettings,
                    ),
                    const SizedBox(height: 14),
                    _MoreActions(
                      onDaily: onDailyChallenge,
                      onLocal: onLocalGame,
                      onAnalysis: onAnalysis,
                      onSaved: onSavedGames,
                      onLearn: onLearnChess,
                    ),
                  ],
                ),
              ),
            );
            if (!wide) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: constraints.maxWidth - 30,
                      child: content,
                    ),
                  ),
                ),
              );
            }
            if (desktopViewport) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: constraints.maxWidth - 56,
                      child: content,
                    ),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
              child: content,
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.playerName,
    this.profilePhotoUrl,
    required this.onProfile,
    required this.onSettings,
  });

  final String playerName;
  final String? profilePhotoUrl;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF0D3553),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF2674A5)),
          ),
          child: profilePhotoUrl?.trim().isNotEmpty == true
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    profilePhotoUrl!,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Icon(Icons.emoji_events_rounded, color: Colors.white),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: InkWell(
            key: const ValueKey<String>('home-profile'),
            onTap: onProfile,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      color: Color(0xFF6DA9D0),
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey<String>('home-settings-top'),
          onPressed: onSettings,
          tooltip: 'Settings',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF35A6EA), Color(0xFF0A3657)],
            ),
            border: Border.all(color: const Color(0xFF78C8FA), width: 1.2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x552A9EE8),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/branding/app_icon.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        const SizedBox(height: 13),
        const Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: 'CHESSVERSE',
                style: TextStyle(color: Color(0xFFDDF2FF)),
              ),
              TextSpan(
                text: 'AI',
                style: TextStyle(color: AppColors.accentGold),
              ),
            ],
          ),
          semanticsLabel: 'ChessVerseAI',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            height: 1,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'CHOOSE YOUR NEXT MOVE',
          style: TextStyle(
            color: Color(0xFFA9C1D2),
            fontSize: 12,
            letterSpacing: 2.3,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LiveStats extends StatelessWidget {
  const _LiveStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xCC0B1B28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF24475E)),
      ),
      child: const Row(
        children: <Widget>[
          _StatItem(
            icon: Icons.language_rounded,
            value: 'Live',
            label: 'Global arena',
            color: Color(0xFF54D8B0),
          ),
          _StatDivider(),
          _StatItem(
            icon: Icons.bolt_rounded,
            value: 'Fast',
            label: 'Instant pairing',
            color: Color(0xFFF5C45B),
          ),
          _StatDivider(),
          _StatItem(
            icon: Icons.shield_outlined,
            value: 'Fair',
            label: 'Server validated',
            color: Color(0xFF78BFF0),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 7),
              Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7895A8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: const Color(0xFF244052));
  }
}

class _GameModeGrid extends StatelessWidget {
  const _GameModeGrid({
    required this.wide,
    required this.onOnline,
    required this.onComputer,
    required this.onFriends,
    required this.onPuzzles,
    required this.onRankings,
    required this.onSettings,
  });

  final bool wide;
  final VoidCallback onOnline;
  final VoidCallback onComputer;
  final VoidCallback onFriends;
  final VoidCallback onPuzzles;
  final VoidCallback onRankings;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final List<_ModeData> modes = <_ModeData>[
      _ModeData(
        keyName: 'play-online',
        icon: Icons.public_rounded,
        title: 'Play Online',
        subtitle: 'Find a live rival',
        colors: const <Color>[Color(0xFF116C69), Color(0xFF084541)],
        onTap: onOnline,
      ),
      _ModeData(
        keyName: 'play-computer',
        icon: Icons.psychology_alt_rounded,
        title: 'Play Computer',
        subtitle: 'Challenge the AI',
        colors: const <Color>[Color(0xFF17435A), Color(0xFF0B273A)],
        onTap: onComputer,
      ),
      _ModeData(
        keyName: 'play-friends',
        icon: Icons.group_rounded,
        title: 'Play with Friends',
        subtitle: 'Create or join room',
        colors: const <Color>[Color(0xFF347460), Color(0xFF174B3E)],
        onTap: onFriends,
      ),
      _ModeData(
        keyName: 'chess-puzzles',
        icon: Icons.extension_rounded,
        title: 'Chess Puzzles',
        subtitle: 'Sharpen your tactics',
        colors: const <Color>[Color(0xFF9A652D), Color(0xFF5A361A)],
        onTap: onPuzzles,
      ),
      _ModeData(
        keyName: 'rankings',
        icon: Icons.leaderboard_rounded,
        title: 'Rankings',
        subtitle: 'Stats and progress',
        colors: const <Color>[Color(0xFFD7B467), Color(0xFF9A6D2E)],
        onTap: onRankings,
      ),
      _ModeData(
        keyName: 'settings',
        icon: Icons.tune_rounded,
        title: 'Settings',
        subtitle: 'Sound and board',
        colors: const <Color>[Color(0xFFB89558), Color(0xFF735126)],
        onTap: onSettings,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: wide ? 1.85 : 1.38,
      ),
      itemBuilder: (BuildContext context, int index) =>
          _GameModeTile(data: modes[index]),
    );
  }
}

class _ModeData {
  const _ModeData({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
}

class _GameModeTile extends StatelessWidget {
  const _GameModeTile({required this.data});

  final _ModeData data;

  @override
  Widget build(BuildContext context) {
    const Color foreground = Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(data.keyName),
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.colors,
            ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: data.colors.last.withValues(alpha: 0.26),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(data.icon, color: foreground, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.72),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: foreground.withValues(alpha: 0.65),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreActions extends StatelessWidget {
  const _MoreActions({
    required this.onDaily,
    required this.onLocal,
    required this.onAnalysis,
    required this.onSaved,
    required this.onLearn,
  });

  final VoidCallback onDaily;
  final VoidCallback onLocal;
  final VoidCallback onAnalysis;
  final VoidCallback onSaved;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _SmallAction(
          icon: Icons.calendar_today_rounded,
          label: 'Daily',
          onTap: onDaily,
        ),
        _SmallAction(
          icon: Icons.swap_horiz_rounded,
          label: 'Local',
          onTap: onLocal,
        ),
        _SmallAction(
          icon: Icons.analytics_outlined,
          label: 'Analysis',
          onTap: onAnalysis,
        ),
        _SmallAction(
          icon: Icons.bookmark_outline_rounded,
          label: 'Saved',
          onTap: onSaved,
        ),
        _SmallAction(
          icon: Icons.school_outlined,
          label: 'Learn',
          onTap: onLearn,
        ),
      ],
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16, color: const Color(0xFF8BC8EF)),
      label: Text(label),
      labelStyle: const TextStyle(
        color: Color(0xFFC7DDEA),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color(0xCC0C2130),
      side: const BorderSide(color: Color(0xFF24485E)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
