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
    this.showPrimaryNavigation = true,
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
  final bool showPrimaryNavigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth >= 760) {
              return _WideHome(
                playerName: playerName,
                profilePhotoUrl: profilePhotoUrl,
                onPlayVsAi: onPlayVsAi,
                onOnlineGame: onOnlineGame,
                onAnalysis: onAnalysis,
                onPuzzles: onPuzzles,
                onLearnChess: onLearnChess,
                onProfile: onProfile,
                onRankings: onRankings,
                onSettings: onSettings,
                showPrimaryNavigation: showPrimaryNavigation,
              );
            }
            return _MobileHome(
              playerName: playerName,
              profilePhotoUrl: profilePhotoUrl,
              onPlayVsAi: onPlayVsAi,
              onDailyChallenge: onDailyChallenge,
              onLocalGame: onLocalGame,
              onOnlineGame: onOnlineGame,
              onAnalysis: onAnalysis,
              onPuzzles: onPuzzles,
              onSavedGames: onSavedGames,
              onLearnChess: onLearnChess,
              onProfile: onProfile,
              onRankings: onRankings,
              onSettings: onSettings,
              showPrimaryNavigation: showPrimaryNavigation,
            );
          },
        ),
      ),
    );
  }
}

class _MobileHome extends StatefulWidget {
  const _MobileHome({
    required this.playerName,
    this.profilePhotoUrl,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onOnlineGame,
    required this.onAnalysis,
    required this.onPuzzles,
    required this.onSavedGames,
    required this.onLearnChess,
    required this.onProfile,
    required this.onRankings,
    required this.onSettings,
    required this.showPrimaryNavigation,
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
  final bool showPrimaryNavigation;

  @override
  State<_MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<_MobileHome> {
  final PageController _heroController = PageController();
  int _heroIndex = 0;

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: <Widget>[
                    _PlayerHeader(
                      playerName: widget.playerName,
                      profilePhotoUrl: widget.profilePhotoUrl,
                      onProfile: widget.onProfile,
                      onSettings: widget.onSettings,
                    ),
                    const SizedBox(height: 14),
                    const _BrandHero(compact: true),
                    const SizedBox(height: 14),
                    _HomeHeroCarousel(
                      controller: _heroController,
                      selectedIndex: _heroIndex,
                      onPageChanged: (int value) =>
                          setState(() => _heroIndex = value),
                      slides: <_HomeHeroData>[
                        _HomeHeroData(
                          title: 'Play Online',
                          subtitle:
                              'Find a live opponent from around the world',
                          icon: Icons.public_rounded,
                          buttonLabel: 'Play Now',
                          asset: 'assets/backgrounds/home-online-hero-v1.png',
                          onTap: widget.onOnlineGame,
                        ),
                        _HomeHeroData(
                          title: 'Play Computer',
                          subtitle: 'Challenge the AI at any level',
                          icon: Icons.computer_rounded,
                          buttonLabel: 'Choose Side',
                          onTap: widget.onPlayVsAi,
                        ),
                        _HomeHeroData(
                          title: 'Play with Friends',
                          subtitle: 'Create a private room or join with a code',
                          icon: Icons.groups_rounded,
                          buttonLabel: 'Open Rooms',
                          onTap: widget.onOnlineGame,
                        ),
                        _HomeHeroData(
                          title: 'Chess Puzzles',
                          subtitle: 'Train with 150 tactical challenges',
                          icon: Icons.extension_rounded,
                          buttonLabel: 'Solve Now',
                          onTap: widget.onPuzzles,
                        ),
                        _HomeHeroData(
                          title: 'Rankings',
                          subtitle: 'Track your ELO and global position',
                          icon: Icons.leaderboard_rounded,
                          buttonLabel: 'View Rankings',
                          onTap: widget.onRankings,
                        ),
                        _HomeHeroData(
                          title: 'Settings',
                          subtitle:
                              'Customize sound, board and game experience',
                          icon: Icons.tune_rounded,
                          buttonLabel: 'Customize',
                          onTap: widget.onSettings,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _ActionCard(
                            keyName: 'play-computer',
                            icon: Icons.computer_rounded,
                            title: 'Play Computer',
                            subtitle: 'Challenge the AI',
                            color: const Color(0xFF143D58),
                            onTap: widget.onPlayVsAi,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            keyName: 'play-friends',
                            icon: Icons.groups_rounded,
                            title: 'Play with Friends',
                            subtitle: 'Create or join room',
                            color: const Color(0xFF15513F),
                            onTap: widget.onOnlineGame,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      childAspectRatio: .82,
                      children: <Widget>[
                        _MiniCard(
                          keyName: 'chess-puzzles',
                          icon: Icons.extension_rounded,
                          label: 'Puzzles',
                          color: AppColors.accentGold,
                          onTap: widget.onPuzzles,
                        ),
                        _MiniCard(
                          keyName: 'rankings',
                          icon: Icons.leaderboard_rounded,
                          label: 'Rankings',
                          color: const Color(0xFFF3B84F),
                          onTap: widget.onRankings,
                        ),
                        _MiniCard(
                          keyName: 'analysis',
                          icon: Icons.trending_up_rounded,
                          label: 'Analysis',
                          color: const Color(0xFF3DA2FF),
                          onTap: widget.onAnalysis,
                        ),
                        _MiniCard(
                          keyName: 'learn',
                          icon: Icons.school_rounded,
                          label: 'Learn',
                          color: const Color(0xFFA879F5),
                          onTap: widget.onLearnChess,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _SmallAction(
                            icon: Icons.calendar_today_rounded,
                            label: 'Daily',
                            onTap: widget.onDailyChallenge),
                        _SmallAction(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Local',
                            onTap: widget.onLocalGame),
                        _SmallAction(
                            icon: Icons.bookmark_outline_rounded,
                            label: 'Saved',
                            onTap: widget.onSavedGames),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.showPrimaryNavigation)
          _MobileNav(
            onPlay: widget.onOnlineGame,
            onPuzzles: widget.onPuzzles,
            onLearn: widget.onLearnChess,
            onProfile: widget.onProfile,
          ),
      ],
    );
  }
}

class _WideHome extends StatelessWidget {
  const _WideHome({
    required this.playerName,
    this.profilePhotoUrl,
    required this.onPlayVsAi,
    required this.onOnlineGame,
    required this.onAnalysis,
    required this.onPuzzles,
    required this.onLearnChess,
    required this.onProfile,
    required this.onRankings,
    required this.onSettings,
    required this.showPrimaryNavigation,
  });

  final String playerName;
  final String? profilePhotoUrl;
  final VoidCallback onPlayVsAi;
  final VoidCallback onOnlineGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onRankings;
  final VoidCallback onSettings;
  final bool showPrimaryNavigation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (showPrimaryNavigation)
          _SideRail(
            onPlay: onOnlineGame,
            onPuzzles: onPuzzles,
            onLearn: onLearnChess,
            onAnalysis: onAnalysis,
            onRankings: onRankings,
            onSettings: onSettings,
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxHeight < 680;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, compact ? 16 : 24, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1220),
                    child: Column(
                      children: <Widget>[
                        _PlayerHeader(
                          playerName: playerName,
                          profilePhotoUrl: profilePhotoUrl,
                          onProfile: onProfile,
                          onSettings: onSettings,
                        ),
                        SizedBox(height: compact ? 14 : 22),
                        _OnlineHero(onTap: onOnlineGame),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: _ActionCard(
                                keyName: 'play-computer',
                                icon: Icons.computer_rounded,
                                title: 'Play Computer',
                                subtitle: 'Challenge the AI at any level',
                                color: const Color(0xFF123B58),
                                onTap: onPlayVsAi,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: _ActionCard(
                                keyName: 'play-friends',
                                icon: Icons.groups_rounded,
                                title: 'Play with Friends',
                                subtitle: 'Create or join a room',
                                color: const Color(0xFF14513F),
                                onTap: onOnlineGame,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _MiniCard(
                                    keyName: 'chess-puzzles',
                                    icon: Icons.extension_rounded,
                                    label: 'Puzzles',
                                    color: AppColors.accentGold,
                                    onTap: onPuzzles)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _MiniCard(
                                    keyName: 'rankings',
                                    icon: Icons.leaderboard_rounded,
                                    label: 'Rankings',
                                    color: const Color(0xFFF1B74D),
                                    onTap: onRankings)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _MiniCard(
                                    keyName: 'analysis',
                                    icon: Icons.trending_up_rounded,
                                    label: 'Analysis',
                                    color: const Color(0xFF3DA2FF),
                                    onTap: onAnalysis)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _MiniCard(
                                    keyName: 'learn',
                                    icon: Icons.school_rounded,
                                    label: 'Learn',
                                    color: const Color(0xFFA879F5),
                                    onTap: onLearnChess)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader(
      {required this.playerName,
      this.profilePhotoUrl,
      required this.onProfile,
      required this.onSettings});
  final String playerName;
  final String? profilePhotoUrl;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        InkWell(
          key: const ValueKey<String>('home-profile'),
          onTap: onProfile,
          borderRadius: BorderRadius.circular(999),
          child: _Avatar(photoUrl: profilePhotoUrl, size: 48),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Welcome back,',
                  style: TextStyle(color: Color(0xFF9FB6C8), fontSize: 12)),
              Text(playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey<String>('home-settings-top'),
          onPressed: onSettings,
          tooltip: 'Settings',
          style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF102A40),
              foregroundColor: Colors.white),
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Image.asset('assets/branding/app_icon.png',
            width: compact ? 72 : 92, height: compact ? 72 : 92),
        const SizedBox(height: 6),
        const _BrandWordmark(fontSize: 31),
        const SizedBox(height: 4),
        const Text('CHOOSE YOUR NEXT MOVE',
            style: TextStyle(
                color: Color(0xFFA9C1D2),
                fontSize: 10,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({required this.fontSize});
  final double fontSize;
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: <InlineSpan>[
        const TextSpan(
            text: 'CHESSVERSE', style: TextStyle(color: Color(0xFFE6F4FF))),
        const TextSpan(text: ' '),
        const TextSpan(
            text: 'AI', style: TextStyle(color: AppColors.accentGold)),
      ]),
      semanticsLabel: 'ChessVerse AI',
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: fontSize,
          height: 1,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w900),
    );
  }
}

class _HomeHeroData {
  const _HomeHeroData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonLabel,
    required this.onTap,
    this.asset,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onTap;
  final String? asset;
}

class _HomeHeroCarousel extends StatelessWidget {
  const _HomeHeroCarousel({
    required this.controller,
    required this.selectedIndex,
    required this.onPageChanged,
    required this.slides,
  });
  final PageController controller;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;
  final List<_HomeHeroData> slides;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          SizedBox(
            height: 260,
            child: PageView.builder(
              key: const ValueKey<String>('home-hero-carousel'),
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: slides.length,
              itemBuilder: (BuildContext context, int index) {
                final _HomeHeroData slide = slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: _CarouselHero(
                    data: slide,
                    onNext: () => controller.animateToPage(
                      (index + 1) % slides.length,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(
              slides.length,
              (int index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selectedIndex == index ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selectedIndex == index
                      ? const Color(0xFF45D7C2)
                      : const Color(0xFF3B5668),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      );
}

class _CarouselHero extends StatelessWidget {
  const _CarouselHero({required this.data, required this.onNext});
  final _HomeHeroData data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          key: data.title == 'Play Online'
              ? const ValueKey<String>('play-online')
              : null,
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2A91F2), width: 1.3),
              image: data.asset == null
                  ? null
                  : DecorationImage(
                      image: AssetImage(data.asset!),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      opacity: .9,
                    ),
              gradient: LinearGradient(
                colors: <Color>[
                  const Color(0xFF0B3159),
                  data.icon == Icons.groups_rounded
                      ? const Color(0xFF104C40)
                      : const Color(0xFF071727),
                ],
              ),
            ),
            child: Stack(children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xE8081F37),
                        Color(0x7A08213C),
                        Color(0x10081727),
                      ],
                      stops: <double>[0, .5, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 205,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(data.icon,
                            color: const Color(0xFF48E3CB), size: 35),
                        const SizedBox(height: 10),
                        Text(data.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                height: 1,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(data.subtitle,
                            maxLines: 2,
                            style: const TextStyle(
                                color: Color(0xFFC5D5E0), fontSize: 13)),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: data.onTap,
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 17),
                          label: Text(data.buttonLabel),
                        ),
                        if (data.title == 'Play Online')
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text('●  Live matchmaking',
                                style: TextStyle(
                                    color: Color(0xFF65D8C2), fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: IconButton.filledTonal(
                  tooltip: 'Next',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _OnlineHero extends StatelessWidget {
  const _OnlineHero({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('play-online'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 310,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A91F2), width: 1.3),
            image: const DecorationImage(
              image: AssetImage('assets/backgrounds/home-online-hero-v1.png'),
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              opacity: .9,
            ),
            gradient: const LinearGradient(
                colors: <Color>[Color(0xFF0B3159), Color(0xFF071727)]),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                  color: Color(0x442A8EF0),
                  blurRadius: 24,
                  offset: Offset(0, 9))
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        Color(0xD9081F37),
                        Color(0x7A08213C),
                        Color(0x12081727),
                      ],
                      stops: <double>[0, .48, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.public_rounded,
                            color: Color(0xFF48E3CB), size: 38),
                        const SizedBox(height: 12),
                        Text('Play Online',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                height: 1,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        const Text('Find a live opponent from around the world',
                            style: TextStyle(
                                color: Color(0xFFC5D5E0), fontSize: 14)),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 11),
                          decoration: BoxDecoration(
                              color: const Color(0xFF145AA0),
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: const Color(0xFF55A9F4))),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text('Play Now',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(width: 18),
                                Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 18)
                              ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xC70A2948),
                    border: Border.all(color: const Color(0x553C9DF0)),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 27),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard(
      {required this.keyName,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});
  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints size) {
      final bool narrow = size.maxWidth < 230;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>(keyName),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: narrow ? 164 : 126,
            padding: EdgeInsets.all(narrow ? 15 : 18),
            decoration: BoxDecoration(
                color: color.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: .9))),
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(children: <Widget>[
                        _ActionIcon(icon: icon),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Color(0xFFC9D9E4), size: 19),
                      ]),
                      const Spacer(),
                      Text(title,
                          maxLines: 2,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              height: 1.05,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFFB9CBD7), fontSize: 11)),
                    ],
                  )
                : Row(children: <Widget>[
                    _ActionIcon(icon: icon),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                          Text(title,
                              maxLines: 2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFFB9CBD7), fontSize: 11))
                        ])),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFFC9D9E4), size: 18),
                  ]),
          ),
        ),
      );
    });
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: Colors.white, size: 30));
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard(
      {required this.keyName,
      required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final String keyName;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 126,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xDD0C2030),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: .35))),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800))
              ]),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail(
      {required this.onPlay,
      required this.onPuzzles,
      required this.onLearn,
      required this.onAnalysis,
      required this.onRankings,
      required this.onSettings});
  final VoidCallback onPlay;
  final VoidCallback onPuzzles;
  final VoidCallback onLearn;
  final VoidCallback onAnalysis;
  final VoidCallback onRankings;
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      decoration: const BoxDecoration(
          color: Color(0xE6071726),
          border: Border(right: BorderSide(color: Color(0xFF203A4D)))),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxHeight < 600;
          final List<Widget> items = <Widget>[
            Image.asset('assets/branding/app_icon.png',
                width: compact ? 52 : 78, height: compact ? 52 : 78),
            SizedBox(height: compact ? 6 : 10),
            _BrandWordmark(fontSize: compact ? 15 : 18),
            SizedBox(height: compact ? 14 : 28),
            const _RailItem(
                icon: Icons.home_rounded, label: 'Home', selected: true),
            _RailItem(
                icon: Icons.sports_esports_rounded,
                label: 'Play',
                onTap: onPlay),
            _RailItem(
                icon: Icons.extension_rounded,
                label: 'Puzzles',
                onTap: onPuzzles),
            _RailItem(
                icon: Icons.school_rounded, label: 'Learn', onTap: onLearn),
            _RailItem(
                icon: Icons.trending_up_rounded,
                label: 'Analysis',
                onTap: onAnalysis),
            _RailItem(
                icon: Icons.leaderboard_rounded,
                label: 'Rankings',
                onTap: onRankings),
            if (!compact) const Spacer(),
            _RailItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: onSettings),
          ];
          return compact
              ? SingleChildScrollView(child: Column(children: items))
              : Column(children: items);
        },
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem(
      {required this.icon,
      required this.label,
      this.onTap,
      this.selected = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
          color: selected ? const Color(0xFF103D70) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  child: Row(children: <Widget>[
                    Icon(icon,
                        color: selected
                            ? const Color(0xFF4DA9FF)
                            : const Color(0xFF9DB1C2),
                        size: 22),
                    const SizedBox(width: 15),
                    Text(label,
                        style: TextStyle(
                            color: selected
                                ? const Color(0xFFB9DEFF)
                                : const Color(0xFFB7C6D2),
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500))
                  ])))),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav(
      {required this.onPlay,
      required this.onPuzzles,
      required this.onLearn,
      required this.onProfile});
  final VoidCallback onPlay;
  final VoidCallback onPuzzles;
  final VoidCallback onLearn;
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xF20A1B2A),
          border: Border(top: BorderSide(color: Color(0xFF24465D)))),
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
      child: Row(children: <Widget>[
        const Expanded(
            child: _NavItem(
                icon: Icons.home_rounded, label: 'Home', selected: true)),
        Expanded(
            child: _NavItem(
                icon: Icons.sports_esports_rounded,
                label: 'Play',
                onTap: onPlay)),
        Expanded(
            child: _NavItem(
                icon: Icons.extension_rounded,
                label: 'Puzzles',
                onTap: onPuzzles)),
        Expanded(
            child: _NavItem(
                icon: Icons.school_rounded, label: 'Learn', onTap: onLearn)),
        Expanded(
            child: _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                onTap: onProfile)),
      ]),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.label,
      this.onTap,
      this.selected = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final Color color =
        selected ? const Color(0xFF42A7FF) : const Color(0xFF70899C);
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 9, fontWeight: FontWeight.w700))
            ])));
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl, required this.size});
  final String? photoUrl;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF124468),
          border: Border.all(color: const Color(0xFF49A8F5), width: 1.5),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x553C9FF0), blurRadius: 12)
          ]),
      child: ClipOval(
          child: photoUrl?.trim().isNotEmpty == true
              ? Image.network(photoUrl!,
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person_rounded, color: Colors.white))
              : const Icon(Icons.person_rounded, color: Colors.white)),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction(
      {required this.icon, required this.label, required this.onTap});
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
            fontWeight: FontWeight.w700),
        backgroundColor: const Color(0xCC0C2130),
        side: const BorderSide(color: Color(0xFF24485E)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)));
  }
}
