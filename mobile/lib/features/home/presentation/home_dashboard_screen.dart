import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/local_game_archive.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/desktop_app_sidebar.dart';
import '../../../core/widgets/coin_balance_badge.dart';
import '../../auth/data/auth_session_store.dart';
import '../../leaderboard/data/leaderboard_api.dart';
import '../../analysis/domain/player_learning_profile.dart';
import '../../notifications/presentation/notification_bell_button.dart';
import '../../social/data/community_api.dart';

void _noOnlineAction() {}

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    required this.playerName,
    this.profilePhotoUrl,
    this.onlinePlayerCount,
    this.coinBalance,
    this.activityGames,
    this.nextTournament,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    this.onOnlineGame = _noOnlineAction,
    this.onFriendsGame = _noOnlineAction,
    required this.onAnalysis,
    required this.onPuzzles,
    required this.onSavedGames,
    required this.onLearnChess,
    required this.onProfile,
    this.onRankings = _noOnlineAction,
    this.onCommunity = _noOnlineAction,
    this.onTournaments = _noOnlineAction,
    this.onNotifications = _noOnlineAction,
    this.onCoins = _noOnlineAction,
    required this.onSettings,
    this.showPrimaryNavigation = true,
    super.key,
  });

  final String playerName;
  final String? profilePhotoUrl;
  final int? onlinePlayerCount;
  final int? coinBalance;
  final List<SavedGameRecord>? activityGames;
  final TournamentDto? nextTournament;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onOnlineGame;
  final VoidCallback onFriendsGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onSavedGames;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onRankings;
  final VoidCallback onCommunity;
  final VoidCallback onTournaments;
  final VoidCallback onNotifications;
  final VoidCallback onCoins;
  final VoidCallback onSettings;
  final bool showPrimaryNavigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (AppBreakpoints.isTabletOrLarger(context) &&
                constraints.maxWidth >= 700) {
              return _WideHome(
                playerName: playerName,
                profilePhotoUrl: profilePhotoUrl,
                onlinePlayerCount: onlinePlayerCount,
                coinBalance: coinBalance,
                activityGames: activityGames,
                nextTournament: nextTournament,
                onPlayVsAi: onPlayVsAi,
                onDailyChallenge: onDailyChallenge,
                onLocalGame: onLocalGame,
                onOnlineGame: onOnlineGame,
                onFriendsGame: onFriendsGame,
                onAnalysis: onAnalysis,
                onPuzzles: onPuzzles,
                onLearnChess: onLearnChess,
                onProfile: onProfile,
                onRankings: onRankings,
                onCommunity: onCommunity,
                onTournaments: onTournaments,
                onNotifications: onNotifications,
                onCoins: onCoins,
                onSettings: onSettings,
                showPrimaryNavigation: showPrimaryNavigation,
              );
            }
            return _MobileHome(
              playerName: playerName,
              profilePhotoUrl: profilePhotoUrl,
              onlinePlayerCount: onlinePlayerCount,
              coinBalance: coinBalance,
              activityGames: activityGames,
              nextTournament: nextTournament,
              onPlayVsAi: onPlayVsAi,
              onDailyChallenge: onDailyChallenge,
              onLocalGame: onLocalGame,
              onOnlineGame: onOnlineGame,
              onFriendsGame: onFriendsGame,
              onAnalysis: onAnalysis,
              onPuzzles: onPuzzles,
              onSavedGames: onSavedGames,
              onLearnChess: onLearnChess,
              onProfile: onProfile,
              onRankings: onRankings,
              onCommunity: onCommunity,
              onTournaments: onTournaments,
              onNotifications: onNotifications,
              onCoins: onCoins,
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
    this.onlinePlayerCount,
    this.coinBalance,
    this.activityGames,
    this.nextTournament,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onLocalGame,
    required this.onOnlineGame,
    required this.onFriendsGame,
    required this.onAnalysis,
    required this.onPuzzles,
    required this.onSavedGames,
    required this.onLearnChess,
    required this.onProfile,
    required this.onRankings,
    required this.onCommunity,
    required this.onTournaments,
    required this.onNotifications,
    required this.onCoins,
    required this.onSettings,
    required this.showPrimaryNavigation,
  });

  final String playerName;
  final String? profilePhotoUrl;
  final int? onlinePlayerCount;
  final int? coinBalance;
  final List<SavedGameRecord>? activityGames;
  final TournamentDto? nextTournament;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onLocalGame;
  final VoidCallback onOnlineGame;
  final VoidCallback onFriendsGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onSavedGames;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onRankings;
  final VoidCallback onCommunity;
  final VoidCallback onTournaments;
  final VoidCallback onNotifications;
  final VoidCallback onCoins;
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
                      coinBalance: widget.coinBalance,
                      onProfile: widget.onProfile,
                      onSettings: widget.onSettings,
                      onNotifications: widget.onNotifications,
                      onCoins: widget.onCoins,
                    ),
                    const SizedBox(height: 8),
                    const _BrandHero(compact: true),
                    const SizedBox(height: 10),
                    _ProgressPulse(games: widget.activityGames),
                    const SizedBox(height: 10),
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
                          statusLabel: _onlineStatus(widget.onlinePlayerCount),
                          onTap: widget.onOnlineGame,
                        ),
                        _HomeHeroData(
                          title: 'Play Computer',
                          subtitle: 'Challenge ChessVerseAI at any level',
                          icon: Icons.computer_rounded,
                          buttonLabel: 'Choose Side',
                          asset: 'assets/backgrounds/home-computer-hero-v1.png',
                          onTap: widget.onPlayVsAi,
                        ),
                        _tournamentHero(
                          widget.nextTournament,
                          widget.onTournaments,
                        ),
                        _HomeHeroData(
                          title: 'Play with Friends',
                          subtitle: 'Create a private room or join with a code',
                          icon: Icons.groups_rounded,
                          buttonLabel: 'Open Rooms',
                          asset: 'assets/backgrounds/home-friends-hero-v1.png',
                          onTap: widget.onFriendsGame,
                        ),
                        _HomeHeroData(
                          title: 'Chess Puzzles',
                          subtitle: 'Train with 150 tactical challenges',
                          icon: Icons.extension_rounded,
                          buttonLabel: 'Solve Now',
                          asset: 'assets/backgrounds/home-puzzles-hero-v1.png',
                          onTap: widget.onPuzzles,
                        ),
                        _HomeHeroData(
                          title: 'Rankings',
                          subtitle: 'Track your ELO and global position',
                          icon: Icons.leaderboard_rounded,
                          buttonLabel: 'View Rankings',
                          asset: 'assets/backgrounds/home-rankings-hero-v1.png',
                          onTap: widget.onRankings,
                        ),
                        _HomeHeroData(
                          title: 'Settings',
                          subtitle:
                              'Personalize your board and game experience',
                          icon: Icons.tune_rounded,
                          buttonLabel: 'Open Settings',
                          asset: 'assets/backgrounds/home-settings-hero-v1.png',
                          onTap: widget.onSettings,
                        ),
                      ],
                      height: 340,
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
                            asset:
                                'assets/backgrounds/home-computer-hero-v1.png',
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
                            asset:
                                'assets/backgrounds/home-friends-hero-v1.png',
                            onTap: widget.onFriendsGame,
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
                          asset: 'assets/backgrounds/home-puzzles-hero-v1.png',
                          onTap: widget.onPuzzles,
                        ),
                        _MiniCard(
                          keyName: 'rankings',
                          icon: Icons.leaderboard_rounded,
                          label: 'Rankings',
                          color: const Color(0xFFF3B84F),
                          asset: 'assets/backgrounds/home-rankings-hero-v1.png',
                          onTap: widget.onRankings,
                        ),
                        _MiniCard(
                          keyName: 'community',
                          icon: Icons.groups_2_rounded,
                          label: 'Community',
                          color: const Color(0xFF55E1CF),
                          asset: 'assets/backgrounds/home-friends-hero-v1.png',
                          onTap: widget.onCommunity,
                        ),
                        _MiniCard(
                          keyName: 'analysis',
                          icon: Icons.trending_up_rounded,
                          label: 'Analysis',
                          color: const Color(0xFF3DA2FF),
                          asset: 'assets/backgrounds/home-analysis-hero-v1.png',
                          onTap: widget.onAnalysis,
                        ),
                        _MiniCard(
                          keyName: 'learn',
                          icon: Icons.school_rounded,
                          label: 'Learn',
                          color: const Color(0xFFA879F5),
                          asset: 'assets/backgrounds/home-learn-hero-v1.png',
                          onTap: widget.onLearnChess,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<int>(
                      valueListenable: LocalGameArchive.activityRevision,
                      builder: (_, __, ___) => _PersonalTrainingCard(
                        onTrain: widget.onPuzzles,
                        games: widget.activityGames,
                      ),
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

class _WideHome extends StatefulWidget {
  const _WideHome({
    required this.playerName,
    this.profilePhotoUrl,
    this.onlinePlayerCount,
    this.coinBalance,
    this.activityGames,
    this.nextTournament,
    required this.onPlayVsAi,
    required this.onDailyChallenge,
    required this.onOnlineGame,
    required this.onFriendsGame,
    required this.onLocalGame,
    required this.onAnalysis,
    required this.onPuzzles,
    required this.onLearnChess,
    required this.onProfile,
    required this.onRankings,
    required this.onCommunity,
    required this.onTournaments,
    required this.onNotifications,
    required this.onCoins,
    required this.onSettings,
    required this.showPrimaryNavigation,
  });

  final String playerName;
  final String? profilePhotoUrl;
  final int? onlinePlayerCount;
  final int? coinBalance;
  final List<SavedGameRecord>? activityGames;
  final TournamentDto? nextTournament;
  final VoidCallback onPlayVsAi;
  final VoidCallback onDailyChallenge;
  final VoidCallback onOnlineGame;
  final VoidCallback onFriendsGame;
  final VoidCallback onLocalGame;
  final VoidCallback onAnalysis;
  final VoidCallback onPuzzles;
  final VoidCallback onLearnChess;
  final VoidCallback onProfile;
  final VoidCallback onRankings;
  final VoidCallback onCommunity;
  final VoidCallback onTournaments;
  final VoidCallback onNotifications;
  final VoidCallback onCoins;
  final VoidCallback onSettings;
  final bool showPrimaryNavigation;

  @override
  State<_WideHome> createState() => _WideHomeState();
}

class _WideHomeState extends State<_WideHome> {
  final PageController _heroController = PageController();
  int _heroIndex = 0;

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (widget.showPrimaryNavigation)
          DesktopAppSidebar(
            selected: 'Home',
            onPlay: widget.onOnlineGame,
            onPuzzles: widget.onPuzzles,
            onLearn: widget.onLearnChess,
            onProfile: widget.onProfile,
            onAnalysis: widget.onAnalysis,
            onRankings: widget.onRankings,
            onSettings: widget.onSettings,
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
                          playerName: widget.playerName,
                          profilePhotoUrl: widget.profilePhotoUrl,
                          coinBalance: widget.coinBalance,
                          onProfile: widget.onProfile,
                          onSettings: widget.onSettings,
                          onNotifications: widget.onNotifications,
                          onCoins: widget.onCoins,
                          wide: true,
                        ),
                        SizedBox(height: compact ? 10 : 16),
                        _ProgressPulse(wide: true, games: widget.activityGames),
                        SizedBox(height: compact ? 10 : 16),
                        _HomeHeroCarousel(
                          controller: _heroController,
                          selectedIndex: _heroIndex,
                          onPageChanged: (int value) =>
                              setState(() => _heroIndex = value),
                          height: compact ? 272 : 305,
                          wide: true,
                          slides: <_HomeHeroData>[
                            _HomeHeroData(
                              title: 'Play Online',
                              subtitle:
                                  'Find a live opponent from around the world',
                              icon: Icons.public_rounded,
                              buttonLabel: 'Play Now',
                              asset:
                                  'assets/backgrounds/home-online-hero-v1.png',
                              statusLabel:
                                  _onlineStatus(widget.onlinePlayerCount),
                              onTap: widget.onOnlineGame,
                            ),
                            _HomeHeroData(
                              title: 'Play Computer',
                              subtitle: 'Challenge ChessVerseAI at any level',
                              icon: Icons.computer_rounded,
                              buttonLabel: 'Choose Side',
                              asset:
                                  'assets/backgrounds/home-computer-hero-v1.png',
                              onTap: widget.onPlayVsAi,
                            ),
                            _tournamentHero(
                              widget.nextTournament,
                              widget.onTournaments,
                            ),
                            _HomeHeroData(
                              title: 'Play with Friends',
                              subtitle:
                                  'Create a private room or join with a code',
                              icon: Icons.groups_rounded,
                              buttonLabel: 'Open Rooms',
                              asset:
                                  'assets/backgrounds/home-friends-hero-v1.png',
                              onTap: widget.onFriendsGame,
                            ),
                            _HomeHeroData(
                              title: 'Chess Puzzles',
                              subtitle: 'Train with 150 tactical challenges',
                              icon: Icons.extension_rounded,
                              buttonLabel: 'Solve Now',
                              asset:
                                  'assets/backgrounds/home-puzzles-hero-v1.png',
                              onTap: widget.onPuzzles,
                            ),
                            _HomeHeroData(
                              title: 'Rankings',
                              subtitle: 'Track your ELO and global position',
                              icon: Icons.leaderboard_rounded,
                              buttonLabel: 'View Rankings',
                              asset:
                                  'assets/backgrounds/home-rankings-hero-v1.png',
                              onTap: widget.onRankings,
                            ),
                            _HomeHeroData(
                              title: 'Settings',
                              subtitle:
                                  'Personalize your board and game experience',
                              icon: Icons.tune_rounded,
                              buttonLabel: 'Open Settings',
                              asset:
                                  'assets/backgrounds/home-settings-hero-v1.png',
                              onTap: widget.onSettings,
                            ),
                          ],
                        ),
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
                                asset:
                                    'assets/backgrounds/home-computer-hero-v1.png',
                                onTap: widget.onPlayVsAi,
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
                                asset:
                                    'assets/backgrounds/home-friends-hero-v1.png',
                                onTap: widget.onFriendsGame,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _MiniCard(
                                    keyName: 'chess-puzzles',
                                    icon: Icons.extension_rounded,
                                    label: 'Puzzles',
                                    subtitle: 'Sharpen your skills',
                                    color: AppColors.accentGold,
                                    asset:
                                        'assets/backgrounds/home-puzzles-hero-v1.png',
                                    onTap: widget.onPuzzles)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _MiniCard(
                                    keyName: 'rankings',
                                    icon: Icons.leaderboard_rounded,
                                    label: 'Rankings',
                                    subtitle: 'See stats & progress',
                                    color: const Color(0xFFF1B74D),
                                    asset:
                                        'assets/backgrounds/home-rankings-hero-v1.png',
                                    onTap: widget.onRankings)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _MiniCard(
                                    keyName: 'community',
                                    icon: Icons.groups_2_rounded,
                                    label: 'Community',
                                    subtitle: 'Friends, clubs & events',
                                    color: const Color(0xFF55E1CF),
                                    asset:
                                        'assets/backgrounds/home-friends-hero-v1.png',
                                    onTap: widget.onCommunity)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _MiniCard(
                                    keyName: 'analysis',
                                    icon: Icons.trending_up_rounded,
                                    label: 'Analysis',
                                    subtitle: 'Review your games',
                                    color: const Color(0xFF3DA2FF),
                                    asset:
                                        'assets/backgrounds/home-analysis-hero-v1.png',
                                    onTap: widget.onAnalysis)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _MiniCard(
                                    keyName: 'learn',
                                    icon: Icons.school_rounded,
                                    label: 'Learn',
                                    subtitle: 'Improve & grow',
                                    color: const Color(0xFFA879F5),
                                    asset:
                                        'assets/backgrounds/home-learn-hero-v1.png',
                                    onTap: widget.onLearnChess)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ValueListenableBuilder<int>(
                          valueListenable: LocalGameArchive.activityRevision,
                          builder: (_, __, ___) => _PersonalTrainingCard(
                            onTrain: widget.onPuzzles,
                            games: widget.activityGames,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _WideDashboardRow(
                          onDailyChallenge: widget.onDailyChallenge,
                          onPuzzles: widget.onPuzzles,
                          onRankings: widget.onRankings,
                          playerName: widget.playerName,
                          profilePhotoUrl: widget.profilePhotoUrl,
                          activityGames: widget.activityGames,
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

class _ProgressPulse extends StatelessWidget {
  const _ProgressPulse({this.wide = false, this.games});
  final bool wide;
  final List<SavedGameRecord>? games;

  @override
  Widget build(BuildContext context) {
    final RewardSnapshot rewards =
        games == null ? LocalGameArchive.rewards() : _rewardsForGames(games!);
    return Semantics(
      label:
          'Level ${rewards.level}, ${rewards.xp} XP, ${rewards.streak} day streak',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: wide ? 20 : 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xD90A1B2B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x664BDAC7)),
        ),
        child: Row(children: <Widget>[
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFE7B54D)),
          const SizedBox(width: 10),
          Text('LEVEL ${rewards.level}',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: rewards.levelProgress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFF263C4D),
                      color: const Color(0xFF54DECA)))),
          const SizedBox(width: 12),
          Text('${rewards.xp} XP',
              style: const TextStyle(
                  color: Color(0xFF54DECA), fontWeight: FontWeight.w800)),
          if (wide || rewards.streak > 0) ...<Widget>[
            const SizedBox(width: 12),
            const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFFF9B45), size: 19),
            Text('${rewards.streak}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ]),
      ),
    );
  }

  RewardSnapshot _rewardsForGames(List<SavedGameRecord> games) {
    final int wins = games.where((game) => game.playerOutcome == 'win').length;
    final int draws =
        games.where((game) => game.playerOutcome == 'draw').length;
    final int xp = games.length * 25 + wins * 45 + draws * 15;
    final int level = xp ~/ 120 + 1;
    return RewardSnapshot(
      xp: xp,
      coins: games.length * 8 + wins * 18,
      level: level,
      levelProgress: ((xp - (level - 1) * 120) / 120).clamp(0, 1),
      streak: 0,
      badges: const <RewardBadge>[],
    );
  }
}

class _PersonalTrainingCard extends StatelessWidget {
  const _PersonalTrainingCard({required this.onTrain, this.games});

  final VoidCallback onTrain;
  final List<SavedGameRecord>? games;

  @override
  Widget build(BuildContext context) {
    final List<SavedGameRecord> sourceGames = games ?? LocalGameArchive.games;
    final PlayerLearningProfile profile = PlayerLearningProfile.fromGames(
      sourceGames,
      cloudScores: LocalGameArchive.cloudWeaknessScores,
    );
    final bool activated = sourceGames.any(
      (SavedGameRecord game) => game.moveReviews.isNotEmpty,
    );
    final String focus =
        PlayerLearningProfile.labelFor(profile.primaryWeakness);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0C2E39), Color(0xFF091827)],
        ),
        border: Border.all(color: const Color(0x8059E4C8)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x2800D7C0), blurRadius: 24),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x2259E4C8),
              border: Border.all(color: const Color(0xFF59E4C8)),
            ),
            child: const Icon(Icons.psychology_alt_rounded,
                color: Color(0xFF59E4C8)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'TODAY’S AI TRAINING',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activated
                      ? '$focus • 60% targeted practice'
                      : 'Balanced starter sprint',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activated
                      ? profile.recommendationReason
                      : 'Complete an AI-reviewed game and tomorrow’s set will adapt to your recurring mistakes.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA8BAC7),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onTrain,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('TRAIN'),
          ),
        ],
      ),
    );
  }
}

class _WideDashboardRow extends StatefulWidget {
  const _WideDashboardRow({
    required this.onDailyChallenge,
    required this.onPuzzles,
    required this.onRankings,
    required this.playerName,
    this.profilePhotoUrl,
    this.activityGames,
  });

  final VoidCallback onDailyChallenge;
  final VoidCallback onPuzzles;
  final VoidCallback onRankings;
  final String playerName;
  final String? profilePhotoUrl;
  final List<SavedGameRecord>? activityGames;

  @override
  State<_WideDashboardRow> createState() => _WideDashboardRowState();
}

class _WideDashboardRowState extends State<_WideDashboardRow> {
  static const LeaderboardApi _leaderboardApi = LeaderboardApi();
  static const AuthSessionStore _sessionStore = AuthSessionStore();
  LeaderboardDto? _leaderboard;
  bool _loadingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshLeaderboard());
    LocalGameArchive.activityRevision.addListener(_handleActivityChange);
  }

  @override
  void dispose() {
    LocalGameArchive.activityRevision.removeListener(_handleActivityChange);
    super.dispose();
  }

  void _handleActivityChange() {
    if (!mounted) return;
    setState(() {});
    unawaited(_refreshLeaderboard());
  }

  Future<void> _refreshLeaderboard() async {
    try {
      final StoredAuthSession? session = await _sessionStore.read();
      if (session == null || session.token.isEmpty) {
        if (mounted) setState(() => _loadingLeaderboard = false);
        return;
      }
      final LeaderboardDto board = await _leaderboardApi.load(
        session.token,
        scope: 'global',
        size: 3,
      );
      if (mounted) {
        setState(() {
          _leaderboard = board;
          _loadingLeaderboard = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  List<SavedGameRecord> get _recentGames =>
      (widget.activityGames ?? LocalGameArchive.games)
          .take(3)
          .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints size) {
      final bool stack = size.maxWidth < 980;
      if (stack) {
        return Column(children: <Widget>[
          _DashboardPanel(
            title: 'Daily Puzzle',
            trailing: 'View all',
            onTap: widget.onPuzzles,
            child: _CompactDailyPuzzle(onTap: widget.onDailyChallenge),
          ),
          const SizedBox(height: 16),
          _DashboardPanel(
            title: 'Activity Feed',
            trailing: 'Live',
            child: _ActivityFeed(games: _recentGames),
          ),
          const SizedBox(height: 16),
          _DashboardPanel(
            title: 'Top Players',
            trailing: 'Global',
            onTap: widget.onRankings,
            child: _TopPlayersPreview(
              board: _leaderboard,
              loading: _loadingLeaderboard,
              playerName: widget.playerName,
              profilePhotoUrl: widget.profilePhotoUrl,
            ),
          ),
        ]);
      }
      final List<Widget> panels = <Widget>[
        Expanded(
          child: _DashboardPanel(
            title: 'Daily Puzzle',
            trailing: 'View all',
            onTap: widget.onPuzzles,
            child: Row(children: <Widget>[
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  image: const DecorationImage(
                    image: AssetImage(
                        'assets/backgrounds/home-puzzles-hero-v1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Find the best move',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    const Text('Today’s tactical challenge',
                        style:
                            TextStyle(color: Color(0xFF9EB5C7), fontSize: 12)),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: widget.onDailyChallenge,
                      child: const Text('Solve Puzzle'),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 16, height: 16),
        Expanded(
          child: _DashboardPanel(
            title: 'Activity Feed',
            trailing: 'Live',
            child: _ActivityFeed(games: _recentGames),
          ),
        ),
        const SizedBox(width: 16, height: 16),
        Expanded(
          child: _DashboardPanel(
            title: 'Top Players',
            trailing: 'Global',
            onTap: widget.onRankings,
            child: _TopPlayersPreview(
              board: _leaderboard,
              loading: _loadingLeaderboard,
              playerName: widget.playerName,
              profilePhotoUrl: widget.profilePhotoUrl,
            ),
          ),
        ),
      ];
      return SizedBox(
        height: 280,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: panels,
        ),
      );
    });
  }
}

class _CompactDailyPuzzle extends StatelessWidget {
  const _CompactDailyPuzzle({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset('assets/backgrounds/home-puzzles-hero-v1.png',
              width: 116, height: 116, fit: BoxFit.cover),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Find the best move',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              FilledButton(onPressed: onTap, child: const Text('Solve Puzzle')),
            ],
          ),
        ),
      ]);
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.trailing,
    required this.child,
    this.onTap,
  });
  final String title;
  final String trailing;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        height: 210,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xE60A1D2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1D3D55)),
        ),
        child: Column(children: <Widget>[
          Row(children: <Widget>[
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ),
            InkWell(
              onTap: onTap,
              child: Text(trailing,
                  style:
                      const TextStyle(color: Color(0xFF42A7FF), fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(child: child),
        ]),
      );
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(icon, color: const Color(0xFF45D7C2), size: 32),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8FA9BB), fontSize: 11)),
        ]),
      );
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.games});
  final List<SavedGameRecord> games;

  @override
  Widget build(BuildContext context) {
    final LocalGameStats stats = LocalGameArchive.stats();
    final List<_ActivityItem> items = <_ActivityItem>[
      ...games.map((SavedGameRecord game) {
        final String outcome = game.playerOutcome ?? 'untracked';
        final bool win = outcome == 'win';
        final bool draw = outcome == 'draw';
        return _ActivityItem(
          icon: win
              ? Icons.emoji_events_rounded
              : draw
                  ? Icons.handshake_rounded
                  : Icons.sports_esports_rounded,
          color: win
              ? const Color(0xFFF0B84B)
              : draw
                  ? const Color(0xFF58DFC9)
                  : const Color(0xFF8FA9BB),
          title: win
              ? 'Won ${game.mode} game'
              : draw
                  ? 'Drew ${game.mode} game'
                  : 'Completed ${game.mode} game',
          detail: _relativeActivityTime(game.playedAt),
        );
      }),
      if (stats.puzzlesSolved > 0)
        _ActivityItem(
          icon: Icons.extension_rounded,
          color: const Color(0xFFA879F5),
          title: '${stats.puzzlesSolved} puzzles solved',
          detail: 'Training progress',
        ),
      if (stats.dailyStreak > 0)
        _ActivityItem(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF7B49),
          title: '${stats.dailyStreak} day streak',
          detail: 'Daily challenge',
        ),
    ].take(3).toList(growable: false);
    if (items.isEmpty) {
      return const _EmptyDashboardState(
        icon: Icons.auto_graph_rounded,
        title: 'Your activity appears here',
        subtitle: 'Games, puzzles and achievements update automatically.',
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .map((_ActivityItem item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        Text(item.detail,
                            style: const TextStyle(
                                color: Color(0xFF8FA9BB), fontSize: 10)),
                      ],
                    ),
                  ),
                ]),
              ))
          .toList(growable: false),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
}

String _relativeActivityTime(DateTime playedAt) {
  final Duration elapsed = DateTime.now().difference(playedAt);
  if (elapsed.inMinutes < 1) return 'Just now';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return '${elapsed.inHours}h ago';
  return '${elapsed.inDays}d ago';
}

class _TopPlayersPreview extends StatelessWidget {
  const _TopPlayersPreview({
    required this.board,
    required this.loading,
    required this.playerName,
    this.profilePhotoUrl,
  });
  final LeaderboardDto? board;
  final bool loading;
  final String playerName;
  final String? profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int rank = 1; rank <= 3; rank++)
            _CompactRankingRow(
              rank: rank,
              name: 'Loading player…',
              rating: null,
              highlight: false,
            ),
          const SizedBox(height: 3),
          _CompactRankingRow(
            rank: 0,
            name: playerName,
            rating: null,
            highlight: true,
            photoUrl: profilePhotoUrl,
          ),
        ],
      );
    }
    final List<LeaderboardEntryDto> leaders =
        (board?.entries ?? const <LeaderboardEntryDto>[])
            .take(3)
            .toList(growable: false);
    final PlayerRatingDto? current = board?.you;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int index = 0; index < 3; index++)
          _CompactRankingRow(
            rank: index < leaders.length ? leaders[index].rank : index + 1,
            name: index < leaders.length
                ? leaders[index].displayName
                : 'Rank awaiting player',
            rating: index < leaders.length ? leaders[index].rating : null,
            highlight: false,
          ),
        const SizedBox(height: 3),
        _CompactRankingRow(
          rank: current?.globalRank ?? 0,
          name: current?.displayName ?? playerName,
          rating: current?.rating,
          highlight: true,
          photoUrl: profilePhotoUrl,
        ),
      ],
    );
  }
}

class _CompactRankingRow extends StatelessWidget {
  const _CompactRankingRow({
    required this.rank,
    required this.name,
    required this.rating,
    required this.highlight,
    this.photoUrl,
  });
  final int rank;
  final String name;
  final int? rating;
  final bool highlight;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFF12364E) : const Color(0x8A0E2940),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color:
                highlight ? const Color(0xFF45D7C2) : const Color(0xFF27465A),
          ),
        ),
        child: Row(children: <Widget>[
          SizedBox(
            width: 28,
            child: Text(rank > 0 ? '#$rank' : '—',
                style: TextStyle(
                    color: highlight
                        ? const Color(0xFF58DFC9)
                        : const Color(0xFFF0B84B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900)),
          ),
          if (highlight) ...<Widget>[
            _Avatar(photoUrl: photoUrl, size: 22),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(highlight ? 'YOU • $name' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          if (rating != null)
            Text('$rating',
                style: const TextStyle(
                    color: Color(0xFFC9D6DF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
        ]),
      );
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader(
      {required this.playerName,
      this.profilePhotoUrl,
      this.coinBalance,
      required this.onProfile,
      required this.onSettings,
      required this.onNotifications,
      required this.onCoins,
      this.wide = false});
  final String playerName;
  final String? profilePhotoUrl;
  final int? coinBalance;
  final VoidCallback onProfile;
  final VoidCallback onSettings;
  final VoidCallback onNotifications;
  final VoidCallback onCoins;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final Widget profile = InkWell(
      key: const ValueKey<String>('home-profile'),
      onTap: onProfile,
      borderRadius: BorderRadius.circular(999),
      child: _Avatar(
        photoUrl: profilePhotoUrl,
        size: wide ? 58 : 42,
        useSavedPlayerAvatar: true,
      ),
    );
    final Widget identity = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Welcome back,',
              style: TextStyle(
                  color: const Color(0xFF9FB6C8), fontSize: wide ? 15 : 12)),
          Text(playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: wide ? 22 : 17,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
    final Widget notifications = NotificationBellButton(
      key: const ValueKey<String>('home-notifications'),
      onPressed: onNotifications,
      filled: true,
    );
    final Widget settings = IconButton(
      key: const ValueKey<String>('home-settings-top'),
      onPressed: onSettings,
      tooltip: 'Settings',
      style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF102A40),
          foregroundColor: Colors.white),
      icon: const Icon(Icons.settings_rounded),
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              profile,
              const SizedBox(width: 12),
              identity,
              const SizedBox(width: 6),
              notifications,
              const SizedBox(width: 6),
              settings,
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: CoinBalanceBadge(
              balance: coinBalance,
              compact: true,
              onTap: onCoins,
            ),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        profile,
        const SizedBox(width: 12),
        identity,
        CoinBalanceBadge(
          balance: coinBalance,
          expandedLabel: true,
          onTap: onCoins,
        ),
        const SizedBox(width: 6),
        notifications,
        const SizedBox(width: 6),
        settings,
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
            width: compact ? 76 : 72, height: compact ? 76 : 72),
        const SizedBox(height: 4),
        _BrandWordmark(fontSize: compact ? 28 : 29),
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
      semanticsLabel: 'ChessVerseAI',
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
    this.statusLabel,
    this.countdownTarget,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onTap;
  final String? asset;
  final String? statusLabel;
  final DateTime? countdownTarget;
}

_HomeHeroData _tournamentHero(
  TournamentDto? tournament,
  VoidCallback onTap,
) {
  final String name = tournament?.name ?? 'Hyderabad Royal Cup';
  final String normalized = name.toLowerCase();
  final String asset = normalized.contains('tokyo')
      ? 'assets/backgrounds/tournament-tokyo-neon-masters-v1.png'
      : normalized.contains('dubai')
          ? 'assets/backgrounds/tournament-dubai-gold-open-v1.png'
          : normalized.contains('london')
              ? 'assets/backgrounds/tournament-london-classic-v1.png'
              : normalized.contains('new york')
                  ? 'assets/backgrounds/tournament-new-york-grand-final-v1.png'
                  : 'assets/backgrounds/tournament-hyderabad-royal-cup-v1.png';
  final String entry =
      tournament == null ? '' : ' • ${tournament.entryCoins} coins entry';
  return _HomeHeroData(
    title: name,
    subtitle: 'Compete in the World Chess Circuit$entry',
    icon: Icons.emoji_events_rounded,
    buttonLabel: tournament?.joined == true ? 'View My Event' : 'Register Now',
    asset: asset,
    statusLabel:
        tournament == null ? 'Open tournaments and upcoming events' : null,
    countdownTarget: tournament?.startsAt,
    onTap: onTap,
  );
}

String _onlineStatus(int? count) {
  if (count == null) return 'Checking live players…';
  if (count == 0) return 'No other players online right now';
  return '$count other ${count == 1 ? 'player' : 'players'} online';
}

class _HomeHeroCarousel extends StatelessWidget {
  const _HomeHeroCarousel({
    required this.controller,
    required this.selectedIndex,
    required this.onPageChanged,
    required this.slides,
    this.height = 260,
    this.wide = false,
  });
  final PageController controller;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;
  final List<_HomeHeroData> slides;
  final double height;
  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          SizedBox(
            height: height,
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
                    wide: wide,
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
          if (slides.length > 1) const SizedBox(height: 8),
          if (slides.length > 1)
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
  const _CarouselHero(
      {required this.data, required this.onNext, this.wide = false});
  final _HomeHeroData data;
  final VoidCallback onNext;
  final bool wide;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A91F2), width: 1.3),
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
            if (data.asset != null)
              Positioned.fill(
                left: wide ? 390 : 92,
                child: Image.asset(
                  data.asset!,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  opacity: const AlwaysStoppedAnimation<double>(.78),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xFF081F37),
                      Color(0xE608213C),
                      Color(0x30081727),
                    ],
                    stops: <double>[0, .48, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(wide ? 30 : 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: wide ? 430 : 205,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            data.icon,
                            color: const Color(0xFF48E3CB),
                            size: wide ? 35 : 30,
                          ),
                          SizedBox(width: wide ? 12 : 9),
                          Expanded(
                            child: Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: wide ? 40 : 28,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(data.subtitle,
                          maxLines: 2,
                          style: const TextStyle(
                              color: Color(0xFFC5D5E0), fontSize: 13)),
                      const Spacer(),
                      FilledButton.icon(
                        key: data.title == 'Play Online'
                            ? const ValueKey<String>('play-online')
                            : null,
                        onPressed: data.onTap,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                        label: Text(data.buttonLabel),
                      ),
                      if (data.statusLabel != null ||
                          data.countdownTarget != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: data.countdownTarget == null
                              ? Text('●  ${data.statusLabel}',
                                  style: const TextStyle(
                                      color: Color(0xFF65D8C2), fontSize: 10))
                              : _LiveTournamentCountdown(
                                  startsAt: data.countdownTarget!,
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: wide ? 22 : 14,
              top: wide ? 22 : 14,
              child: IconButton.filledTonal(
                key: const ValueKey<String>('home-hero-next'),
                tooltip: 'Next feature',
                onPressed: onNext,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xB20A2842),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            // Paint the frame last. Background artwork previously covered the
            // right and bottom edges on some carousel slides.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF2A91F2),
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _LiveTournamentCountdown extends StatefulWidget {
  const _LiveTournamentCountdown({required this.startsAt});
  final DateTime startsAt;

  @override
  State<_LiveTournamentCountdown> createState() =>
      _LiveTournamentCountdownState();
}

class _LiveTournamentCountdownState extends State<_LiveTournamentCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Duration remaining = widget.startsAt.difference(DateTime.now());
    final String label = remaining.isNegative
        ? 'STARTING SOON'
        : remaining.inDays > 0
            ? 'STARTS IN ${remaining.inDays}D ${remaining.inHours % 24}H'
            : 'STARTS IN ${remaining.inHours}H ${remaining.inMinutes % 60}M';
    return Text(
      '●  $label',
      key: const ValueKey<String>('home-tournament-countdown'),
      style: const TextStyle(color: Color(0xFF65D8C2), fontSize: 10),
    );
  }
}

// Retained as a compact fallback for embedded/snapshot surfaces.
// ignore: unused_element
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
      required this.asset,
      required this.onTap});
  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String asset;
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
            height: 164,
            padding: EdgeInsets.all(narrow ? 15 : 18),
            decoration: BoxDecoration(
                color: color.withValues(alpha: .76),
                image: DecorationImage(
                    image: AssetImage(asset),
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    opacity: .68),
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
      this.subtitle,
      required this.color,
      required this.asset,
      required this.onTap});
  final String keyName;
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final String asset;
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
          height: 164,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xDD0C2030),
              image: DecorationImage(
                  image: AssetImage(asset),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  opacity: .58),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: .35))),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB9CBD7),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ]),
        ),
      ),
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
  const _Avatar({
    this.photoUrl,
    required this.size,
    this.useSavedPlayerAvatar = false,
  });
  final String? photoUrl;
  final double size;
  final bool useSavedPlayerAvatar;
  @override
  Widget build(BuildContext context) {
    const List<IconData> playerIcons = <IconData>[
      Icons.person_rounded,
      Icons.psychology_rounded,
      Icons.sports_esports_rounded,
      Icons.workspace_premium_rounded,
      Icons.shield_rounded,
      Icons.auto_awesome_rounded,
    ];
    const List<Color> playerColors = <Color>[
      Color(0xFF1E88A8),
      Color(0xFF3E8E72),
      Color(0xFF8057B8),
      Color(0xFFB47A2B),
      Color(0xFF466A9A),
      Color(0xFF9A4F63),
    ];
    final int avatarIndex = LocalGameArchive.profileAvatar;
    return Semantics(
      label: useSavedPlayerAvatar
          ? 'Selected player avatar ${avatarIndex + 1}'
          : null,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: useSavedPlayerAvatar
                ? playerColors[avatarIndex]
                : const Color(0xFF124468),
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
                : useSavedPlayerAvatar
                    ? Icon(playerIcons[avatarIndex], color: Colors.white)
                    : const Icon(Icons.person_rounded, color: Colors.white)),
      ),
    );
  }
}
