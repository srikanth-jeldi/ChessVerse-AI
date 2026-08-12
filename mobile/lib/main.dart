import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'core/audio/chess_sound_service.dart';
import 'core/auth/facebook_sdk_ready.dart';
import 'core/app_preferences.dart';
import 'core/chess_piece_appearance.dart';
import 'core/config/app_config.dart';
import 'core/local_game_archive.dart';
import 'core/notifications/daily_reminder_service.dart';
import 'core/widgets/chessverse_app_backdrop.dart';
import 'core/widgets/desktop_app_sidebar.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_session_store.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/engine/data/engine_api.dart';
import 'features/analysis/domain/ai_review_report.dart';
import 'features/analysis/presentation/analysis_screen.dart';
import 'features/analysis/presentation/adaptive_ai_review.dart';
import 'features/home/presentation/home_dashboard_screen.dart';
import 'features/library/presentation/reference_screens.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/online/data/online_match_api.dart';
import 'features/online/presentation/match_history_screen.dart';
import 'features/leaderboard/presentation/leaderboard_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/puzzles/domain/puzzle_catalog.dart';
import 'features/progress/data/cloud_progress_api.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/tutorial/presentation/learn_chess_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    try {
      await ensureFacebookSdkReady().timeout(const Duration(seconds: 8));
      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: AppConfig.facebookAppId,
        cookie: true,
        xfbml: true,
        version: 'v26.0',
      );
    } on Object {
      // Facebook can be unavailable because of tracking protection, an SDK
      // outage, or an inactive Meta app. It must never prevent ChessVerseAI
      // from starting; the login action reports its own recoverable error.
    }
  }
  await LocalGameArchive.init();
  unawaited(_restoreDailyReminder());
  AppConfig.validate();
  runApp(const ChessVerseApp());
}

class ChessVerseApp extends StatelessWidget {
  const ChessVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessVerseAI',
      debugShowCheckedModeBanner: false,
      theme: ChessVerseTheme.dark(),
      builder: (BuildContext context, Widget? child) {
        return ChessVerseAppBackdrop(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashGate(),
    );
  }
}

const List<NavigationDestination> _primaryNavigationDestinations =
    <NavigationDestination>[
  NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
  NavigationDestination(
      icon: Icon(Icons.sports_esports_rounded), label: 'Play'),
  NavigationDestination(icon: Icon(Icons.extension_rounded), label: 'Puzzles'),
  NavigationDestination(icon: Icon(Icons.school_rounded), label: 'Learn'),
  NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
];

const List<NavigationRailDestination> _primaryRailDestinations =
    <NavigationRailDestination>[
  NavigationRailDestination(
      icon: Icon(Icons.home_rounded), label: Text('Home')),
  NavigationRailDestination(
      icon: Icon(Icons.sports_esports_rounded), label: Text('Play')),
  NavigationRailDestination(
      icon: Icon(Icons.extension_rounded), label: Text('Puzzles')),
  NavigationRailDestination(
      icon: Icon(Icons.school_rounded), label: Text('Learn')),
  NavigationRailDestination(
      icon: Icon(Icons.person_rounded), label: Text('Profile')),
];

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const AuthApi _authApi = AuthApi();
  static const AuthSessionStore _sessionStore = AuthSessionStore();
  static const CloudProgressApi _cloudProgressApi = CloudProgressApi();
  Timer? _timer;
  bool _splashArtworkLoadingStarted = false;
  _RootStage _stage = _RootStage.splash;
  String _playerName = 'Guest Player';
  String? _username;
  String? _email;
  String? _photoUrl;
  bool _isGuest = true;
  bool _cloudSyncInFlight = false;
  bool _cloudSyncQueued = false;
  int? _onlinePlayerCount;
  int _primaryDestination = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_splashArtworkLoadingStarted) return;
    _splashArtworkLoadingStarted = true;
    final Size viewport = MediaQuery.sizeOf(context);
    // Match BrandedSplash exactly: every landscape surface preloads the wide
    // artwork, including phones rotated before or during app startup.
    final bool useWideArtwork = viewport.width > viewport.height ||
        (viewport.shortestSide >= 600 && viewport.width >= 720);
    final String artwork = useWideArtwork
        ? 'assets/branding/chessverse_king_dual_splash.jpg'
        : 'assets/branding/splash_screen_mobile_v2.jpg';
    unawaited(_preloadSplashAndStartTimer(artwork));
  }

  Future<void> _preloadSplashAndStartTimer(String artwork) async {
    try {
      await precacheImage(AssetImage(artwork), context);
    } catch (_) {
      // Continue with the code-rendered branding if an image decoder fails.
    }
    if (!mounted) return;
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() => _stage = _RootStage.loading);
        unawaited(_restoreSession());
      }
    });
  }

  Future<void> _restoreSession() async {
    StoredAuthSession? session;
    try {
      session = await _sessionStore.read();
    } on Object {
      // Browser privacy modes and damaged secure-storage state can reject the
      // read. Treat that exactly like a signed-out launch instead of leaving
      // the loading screen visible forever.
      try {
        await _sessionStore.clear();
      } on Object {
        // A failed cleanup is harmless; AuthScreen can still start.
      }
      if (mounted) setState(() => _stage = _RootStage.auth);
      return;
    }
    if (session == null) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _stage = _RootStage.onboarding);
      return;
    }

    final StoredAuthSession restoredSession = session;
    String playerName = restoredSession.displayName;
    String? username = restoredSession.username;
    String? email = restoredSession.email;
    String? photoUrl = restoredSession.photoUrl;
    bool isGuest = restoredSession.isGuest;
    try {
      final Map<String, dynamic> player =
          await _authApi.currentPlayer(restoredSession.token);
      playerName = _profileValue(player['displayName']) ??
          _profileValue(player['username']) ??
          playerName;
      username = _profileValue(player['username']) ?? username;
      email = _profileValue(player['email']) ?? email;
      photoUrl = _profileValue(player['photoUrl']) ?? photoUrl;
      isGuest = player['guest'] as bool? ?? isGuest;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _sessionStore.clear();
        if (mounted) setState(() => _stage = _RootStage.auth);
        return;
      }
      // A valid unexpired local session keeps the user signed in while the
      // network is temporarily unavailable.
    }
    if (!mounted) return;
    _enableCloudSync(restoredSession.token);
    setState(() {
      _playerName = playerName;
      _username = username;
      _email = email;
      _photoUrl = photoUrl;
      _isGuest = isGuest;
      _stage = _RootStage.home;
    });
    // Do not make active-match recovery wait for profile/progress sync. A
    // killed mobile process has a short server grace window and must reopen
    // its authoritative match as soon as the authenticated home route exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreActiveOnlineMatch(restoredSession.token));
    });
    unawaited(_syncCloudProgress(restoredSession.token));
    unawaited(_refreshOnlinePresence());
  }

  Future<void> _refreshOnlinePresence() async {
    try {
      final int count = await const OnlineMatchApi().onlinePlayerCount();
      if (mounted) setState(() => _onlinePlayerCount = count);
    } on OnlineMatchException {
      if (mounted) setState(() => _onlinePlayerCount = null);
    }
  }

  Future<void> _restoreActiveOnlineMatch(String token) async {
    try {
      final OnlineMatchDto match =
          await const OnlineMatchApi().reconnect(token);
      if (!mounted || _stage != _RootStage.home || !match.isActive) return;
      await _openGame(
        context,
        GameMode.online,
        initialOnlineMatch: match,
        initialAuthToken: token,
      );
    } on OnlineMatchException {
      // No active match (or temporary connectivity loss) is a normal startup
      // state. The home screen remains usable and manual reconnect still works.
    }
  }

  String? _profileValue(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (_stage) {
        _RootStage.splash => const BrandedSplash(
            key: ValueKey<String>('splash'),
          ),
        _RootStage.loading => const ChessVerseLoadingScreen(
            key: ValueKey<String>('loading'),
          ),
        _RootStage.onboarding => OnboardingScreen(
            key: const ValueKey<String>('onboarding'),
            onComplete: () => setState(() => _stage = _RootStage.auth),
          ),
        _RootStage.auth => AuthScreen(
            key: const ValueKey<String>('auth'),
            onAuthenticated: (ChessVerseAuthResult result) {
              setState(() {
                _playerName = result.playerName;
                _username = result.username;
                _email = result.email;
                _photoUrl = result.photoUrl;
                _isGuest = result.isGuest;
                _stage = _RootStage.home;
              });
              if (result.token != null) {
                _enableCloudSync(result.token!);
                unawaited(_syncCloudProgress(result.token!));
              }
              unawaited(_refreshOnlinePresence());
            },
          ),
        _RootStage.home => _buildPrimaryShell(context),
      },
    );
  }

  Widget _buildPrimaryShell(BuildContext context) {
    final List<Widget> destinations = <Widget>[
      HomeDashboardScreen(
        key: const ValueKey<String>('home'),
        playerName: _playerName,
        profilePhotoUrl: _photoUrl,
        onlinePlayerCount: _onlinePlayerCount,
        onPlayVsAi: () => _chooseSideAndOpen(context, GameMode.computer),
        onDailyChallenge: () => _openGame(context, GameMode.daily),
        onLocalGame: () => _chooseSideAndOpen(context, GameMode.local),
        onOnlineGame: () => _openOnlineGame(context),
        onAnalysis: () => _push(context, const AnalysisScreen()),
        onPuzzles: () => setState(() => _primaryDestination = 2),
        onSavedGames: () => _push(context, const MatchHistoryScreen()),
        onRankings: () => _push(
          context,
          LeaderboardScreen(
            profilePhotoUrl: _photoUrl,
            onHome: () => _closeSettingsAndSelect(context, 0),
            onPlay: () => _closeSettingsAndSelect(context, 1),
            onPuzzles: () => _closeSettingsAndSelect(context, 2),
            onLearn: () => _closeSettingsAndSelect(context, 3),
            onProfile: () => _closeSettingsAndSelect(context, 4),
          ),
        ),
        onLearnChess: () => setState(() => _primaryDestination = 3),
        onProfile: () => setState(() => _primaryDestination = 4),
        onSettings: () => _push(
          context,
          SettingsScreen(
            onLogout: () => _logout(context),
            onDeleteAccount: () => _deleteAccount(context),
            onHome: () => _closeSettingsAndSelect(context, 0),
            onPlay: () => _closeSettingsAndSelect(context, 1),
            onPuzzles: () => _closeSettingsAndSelect(context, 2),
            onLearn: () => _closeSettingsAndSelect(context, 3),
            onProfile: () => _closeSettingsAndSelect(context, 4),
          ),
        ),
        showPrimaryNavigation: false,
      ),
      _PlayDestination(
        onComputer: () => _chooseSideAndOpen(context, GameMode.computer),
        onOnline: () => _openOnlineGame(context),
        onLocal: () => _chooseSideAndOpen(context, GameMode.local),
        onDaily: () => _openGame(context, GameMode.daily),
      ),
      PuzzlesScreen(
        showPrimaryNavigation: false,
        onStartPuzzle: (String puzzleId) => _openGame(
          context,
          GameMode.puzzle,
          puzzleId: puzzleId,
        ),
      ),
      const LearnChessScreen(),
      ProfileScreen(
        playerName: _playerName,
        username: _username,
        email: _email,
        profilePhotoUrl: _photoUrl,
        isGuest: _isGuest,
        onSecureProgress: _isGuest ? () => _secureGuestProgress(context) : null,
        onUsernameChanged: (String value) {
          if (!mounted) return;
          setState(() => _username = value);
        },
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints size) {
        final bool genuineWideLayout =
            size.maxWidth >= 700 && size.maxHeight >= 600;
        final bool extendedRail = genuineWideLayout && size.maxWidth >= 900;
        final bool compactRail =
            genuineWideLayout && size.maxWidth >= 700 && !extendedRail;
        final bool useRail = extendedRail || compactRail;
        final Widget content = IndexedStack(
          index: _primaryDestination,
          children: destinations,
        );
        if (useRail) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(children: <Widget>[
              NavigationRail(
                selectedIndex: _primaryDestination,
                onDestinationSelected: (int value) =>
                    setState(() => _primaryDestination = value),
                labelType: extendedRail
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.selected,
                extended: extendedRail,
                minWidth: 72,
                minExtendedWidth: 232,
                groupAlignment: -0.72,
                indicatorColor: const Color(0xFF123E72),
                selectedIconTheme:
                    const IconThemeData(color: Color(0xFF55AFFF), size: 25),
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF78BFFF),
                  fontWeight: FontWeight.w800,
                ),
                unselectedIconTheme:
                    const IconThemeData(color: Color(0xFF8EA4B7), size: 24),
                unselectedLabelTextStyle:
                    const TextStyle(color: Color(0xFFB7C5D1)),
                backgroundColor: const Color(0xE6071727),
                leading: Padding(
                  padding: EdgeInsets.fromLTRB(
                    extendedRail ? 16 : 8,
                    extendedRail ? 18 : 10,
                    extendedRail ? 16 : 8,
                    extendedRail ? 28 : 12,
                  ),
                  child: Column(children: <Widget>[
                    ChessVerseMark(size: extendedRail ? 72 : 46),
                    if (extendedRail) const SizedBox(height: 8),
                    if (extendedRail)
                      const Text.rich(
                        TextSpan(children: <InlineSpan>[
                          TextSpan(
                              text: 'CHESSVERSE ',
                              style: TextStyle(color: Colors.white)),
                          TextSpan(
                              text: 'AI',
                              style: TextStyle(color: Color(0xFFE2AE49))),
                        ]),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                  ]),
                ),
                destinations: _primaryRailDestinations,
              ),
              const VerticalDivider(width: 1, color: Color(0xFF19354A)),
              Expanded(child: content),
            ]),
          );
        }
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _primaryDestination,
            onDestinationSelected: (int value) =>
                setState(() => _primaryDestination = value),
            backgroundColor: const Color(0xF2071A29),
            indicatorColor: const Color(0xFF124B77),
            destinations: _primaryNavigationDestinations,
          ),
        );
      },
    );
  }

  void _closeSettingsAndSelect(BuildContext context, int destination) {
    Navigator.of(context).pop();
    if (!mounted) return;
    setState(() => _primaryDestination = destination);
  }

  Future<void> _chooseSideAndOpen(BuildContext context, GameMode mode) async {
    final _GameLaunchChoice? choice =
        await showModalBottomSheet<_GameLaunchChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        PlayerSideChoice selected = PlayerSideChoice.white;
        double selectedAiLevel = 4;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) =>
              SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool shortLandscape =
                    constraints.maxWidth > constraints.maxHeight &&
                        constraints.maxHeight < 500;
                final bool wide = constraints.maxWidth >= 700 &&
                    MediaQuery.sizeOf(context).shortestSide >= 600;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.94,
                  ),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: wide ? 1180 : 720),
                    margin: EdgeInsets.all(wide ? 28 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xF5071626),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF334352)),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Colors.black54, blurRadius: 36),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 48 : 18,
                        shortLandscape ? 14 : 28,
                        wide ? 48 : 18,
                        shortLandscape ? 16 : 30,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.workspace_premium_rounded,
                              color: Color(0xFFE2AE49), size: 52),
                          Text(
                            'Choose Your Side',
                            style: TextStyle(
                              color: Color(0xFFFFF8ED),
                              fontSize: wide ? 42 : 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: shortLandscape ? 4 : 8),
                          Text(
                            mode == GameMode.local
                                ? 'Player 1 side for this match.'
                                : 'ChessVerseAI will take the opposite side.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: shortLandscape ? 10 : 24),
                          Row(
                            children: PlayerSideChoice.values.map((
                              PlayerSideChoice side,
                            ) {
                              final bool active = side == selected;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: InkWell(
                                    onTap: () =>
                                        setSheetState(() => selected = side),
                                    borderRadius: BorderRadius.circular(20),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: EdgeInsets.symmetric(
                                        vertical: shortLandscape
                                            ? 12
                                            : wide
                                                ? 30
                                                : 24,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? const Color(0xFF123B3C)
                                            : const Color(0xFF0A1927),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: active
                                              ? const Color(0xFF57DDC3)
                                              : const Color(0xFF39434A),
                                          width: active ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          _SideChoiceArtwork(
                                            side: side,
                                            size: shortLandscape
                                                ? 54
                                                : wide
                                                    ? 150
                                                    : 92,
                                            active: active,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(side.label,
                                              style: TextStyle(
                                                fontSize: wide ? 24 : 16,
                                                fontWeight: FontWeight.w900,
                                              )),
                                          if (wide) ...<Widget>[
                                            const SizedBox(height: 6),
                                            Text(
                                              side == PlayerSideChoice.random
                                                  ? 'Let us choose for you'
                                                  : 'You play as ${side.label}',
                                              style: TextStyle(
                                                color: active
                                                    ? const Color(0xFF63D2B8)
                                                    : const Color(0xFFAEC0D1),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (mode == GameMode.computer) ...<Widget>[
                            SizedBox(height: shortLandscape ? 8 : 18),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'AI LEVEL  •  ${aiProfileFor(selectedAiLevel.round()).name}',
                                style: const TextStyle(
                                  color: Color(0xFFE2AE49),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Slider(
                              key: const ValueKey<String>('computer-ai-level'),
                              value: selectedAiLevel,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: aiProfileFor(selectedAiLevel.round()).name,
                              onChanged: (double value) => setSheetState(
                                () => selectedAiLevel = value,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const <Widget>[
                                Text('New to Chess',
                                    style: TextStyle(fontSize: 12)),
                                Text('Grandmaster',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                          SizedBox(height: shortLandscape ? 10 : 22),
                          if (!shortLandscape)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                color: const Color(0x99101F2B),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFF5A4B2A)),
                              ),
                              child: const Text(
                                'Balanced match  •  Fair play  •  AI Opponent',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFC7D2DE)),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.of(context).pop(
                                _GameLaunchChoice(selected, selectedAiLevel),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                  'START AS ${selected.label.toUpperCase()}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    if (choice != null && context.mounted) {
      _openGame(
        context,
        mode,
        sideChoice: choice.side,
        aiLevel: choice.aiLevel,
      );
    }
  }

  Future<void> _openGame(
    BuildContext context,
    GameMode mode, {
    PlayerSideChoice sideChoice = PlayerSideChoice.white,
    double aiLevel = 4,
    DailyChallengeDifficulty? dailyDifficulty,
    String? puzzleId,
    OnlineMatchDto? initialOnlineMatch,
    String? initialAuthToken,
  }) {
    return _push(
      context,
      GameScreen(
        initiallySignedIn: true,
        // Computer games use the production Stockfish service. The game
        // already falls back to its offline move generator if the API is
        // unavailable, so genuine AI strength never sacrifices playability.
        useRemoteEngine: mode == GameMode.computer,
        initialGameMode: mode,
        initialPlayerName: _playerName,
        initialUsername: _username,
        initialEmail: _email,
        initialProfilePhotoUrl: _photoUrl,
        initiallyGuest: _isGuest,
        initialSideChoice: sideChoice,
        initialAiLevel: aiLevel,
        initialDailyDifficulty: dailyDifficulty,
        initialPuzzleId: puzzleId,
        initialOnlineMatch: initialOnlineMatch,
        initialAuthToken: initialAuthToken,
        onLogout: () => _logout(context),
      ),
    );
  }

  Future<void> _openOnlineGame(BuildContext context) async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (!context.mounted) return;
    if (session == null || session.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to play online.')),
      );
      return;
    }
    final OnlineMatchDto? match =
        await Navigator.of(context).push<OnlineMatchDto>(
      MaterialPageRoute<OnlineMatchDto>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF06131F),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFF0A2231), Color(0xFF040B13)],
              ),
            ),
            child: OnlineMatchmakingSheet(
              api: const OnlineMatchApi(),
              token: session.token,
            ),
          ),
        ),
      ),
    );
    if (match != null && context.mounted) {
      await _openGame(
        context,
        GameMode.online,
        initialOnlineMatch: match,
        initialAuthToken: session.token,
      );
    }
  }

  Future<void> _logout(BuildContext currentRouteContext) async {
    const AuthSessionStore sessionStore = AuthSessionStore();
    const AuthApi authApi = AuthApi();
    final StoredAuthSession? session = await sessionStore.read();
    if (session != null) {
      try {
        await authApi.logout(session.token);
      } on AuthApiException {
        // A local logout must still succeed if the remote session expired.
      }
    }
    await sessionStore.clear();
    LocalGameArchive.onCloudRelevantChange = null;
    if (!mounted) return;

    if (currentRouteContext.mounted &&
        Navigator.of(currentRouteContext).canPop()) {
      Navigator.of(currentRouteContext).pop();
    }
    setState(() {
      _playerName = 'ChessVerseAI Player';
      _username = null;
      _email = null;
      _isGuest = true;
      _stage = _RootStage.auth;
    });
  }

  Future<void> _deleteAccount(BuildContext currentRouteContext) async {
    final StoredAuthSession? session = await _sessionStore.read();
    if (session == null) {
      throw const AuthApiException('No signed-in account was found.');
    }
    await _authApi.deleteAccount(session.token);
    await _sessionStore.clear();
    LocalGameArchive.onCloudRelevantChange = null;
    if (!mounted) return;
    if (currentRouteContext.mounted) {
      Navigator.of(currentRouteContext)
          .popUntil((Route<dynamic> route) => route.isFirst);
    }
    setState(() {
      _playerName = 'ChessVerseAI Player';
      _username = null;
      _email = null;
      _photoUrl = null;
      _isGuest = true;
      _primaryDestination = 0;
      _stage = _RootStage.auth;
    });
  }

  Future<void> _secureGuestProgress(BuildContext currentRouteContext) async {
    final StoredAuthSession? session = await _sessionStore.read();
    if (session == null || !session.isGuest || !currentRouteContext.mounted) {
      return;
    }
    await Navigator.of(currentRouteContext).push(
      MaterialPageRoute<void>(
        builder: (BuildContext upgradeContext) => AuthScreen(
          guestUpgradeToken: session.token,
          onAuthenticated: (ChessVerseAuthResult result) {
            if (!mounted) return;
            setState(() {
              _playerName = result.playerName;
              _username = result.username;
              _email = result.email;
              _photoUrl = result.photoUrl;
              _isGuest = result.isGuest;
            });
            if (result.token != null) {
              _enableCloudSync(result.token!);
              unawaited(_syncCloudProgress(result.token!));
            }
            Navigator.of(upgradeContext).pop();
            ScaffoldMessenger.of(currentRouteContext).showSnackBar(
              const SnackBar(
                content: Text('Progress secured with Google successfully.'),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _push(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _enableCloudSync(String token) {
    LocalGameArchive.onCloudRelevantChange = () => _syncCloudProgress(token);
  }

  Future<void> _syncCloudProgress(String token) async {
    if (_cloudSyncInFlight) {
      _cloudSyncQueued = true;
      return;
    }
    _cloudSyncInFlight = true;
    try {
      final Map<String, dynamic> merged = await _cloudProgressApi.merge(
        token,
        LocalGameArchive.cloudSnapshot(),
      );
      await LocalGameArchive.mergeCloudSnapshot(merged);
    } on CloudProgressException {
      // Local progress stays authoritative until the next successful sync.
    } finally {
      _cloudSyncInFlight = false;
      if (_cloudSyncQueued) {
        _cloudSyncQueued = false;
        unawaited(_syncCloudProgress(token));
      }
    }
  }
}

enum _RootStage { splash, loading, onboarding, auth, home }

class BrandedSplash extends StatelessWidget {
  const BrandedSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02070D),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Landscape always gets the dedicated edge-to-edge composition.
          // Portrait phones retain the compact splash used on mobile.
          final Size viewport = MediaQuery.sizeOf(context);
          final bool phoneSized = viewport.shortestSide < 600;
          final bool landscape = viewport.width > viewport.height;
          final bool wide = landscape ||
              (!phoneSized &&
                  (constraints.maxWidth >= 720 || constraints.maxWidth <= 0));
          const String wideAsset =
              'assets/branding/chessverse_king_dual_splash.jpg';
          const String mobileAsset =
              'assets/branding/splash_screen_mobile_v2.jpg';
          if (!wide) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const Opacity(
                  opacity: 0.34,
                  child: Image(
                    image: AssetImage(mobileAsset),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                const Image(
                  key: ValueKey<String>('branded-splash-image'),
                  image: AssetImage(mobileAsset),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          const Color(0xFF02070D).withValues(alpha: 0.04),
                          Colors.transparent,
                          const Color(0xFF02070D).withValues(alpha: 0.20),
                          const Color(0xFF02070D).withValues(alpha: 0.96),
                        ],
                        stops: const <double>[0, 0.46, 0.70, 1],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 54),
                    child: Column(
                      children: <Widget>[
                        const Spacer(flex: 7),
                        ShaderMask(
                          shaderCallback: (Rect bounds) => const LinearGradient(
                            colors: <Color>[
                              Color(0xFFFFE2A0),
                              Color(0xFFF8F4E8),
                              Color(0xFF75C9FF),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'CHESSVERSEAI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'PLAY  •  LEARN  •  MASTER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 26),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const SizedBox(
                            width: 132,
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              backgroundColor: Color(0x332F8DFF),
                              color: Color(0xFFFFCE6A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF02070D).withValues(alpha: 0.64),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFFFCE6A)
                                  .withValues(alpha: 0.42),
                            ),
                          ),
                          child: const Text(
                            'Powered by EpitomeHub',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFD77D),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const Image(
                image: AssetImage(wideAsset),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0x1202070D),
                        Colors.transparent,
                        Color(0x2602070D),
                      ],
                      stops: <double>[0, 0.62, 1],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Kept as a lightweight code-only fallback for devices that cannot decode the
// high-resolution splash artwork.
// ignore: unused_element
class _MobilePremiumSplash extends StatelessWidget {
  const _MobilePremiumSplash();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.28),
          radius: 1.18,
          colors: <Color>[
            Color(0xFF0C5F5A),
            Color(0xFF081B33),
            Color(0xFF02070D),
          ],
          stops: <double>[0, 0.45, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _PremiumSplashBoardGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: Column(
                children: <Widget>[
                  const Spacer(flex: 2),
                  Container(
                    width: 126,
                    height: 126,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF0D1F37), Color(0xFF061018)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFE0B85E),
                        width: 1.4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(
                            0xFF63D2B8,
                          ).withValues(alpha: 0.34),
                          blurRadius: 52,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFFD6A84F,
                          ).withValues(alpha: 0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/branding/app_icon.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FittedBox(
                    child: Text(
                      'CHESSVERSEAI',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: const Color(0xFFF8F2E4),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Think • Move • Master',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFE0B85E),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 7,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFF2B160B),
                      border: Border.all(
                        color: const Color(0xFF795022).withValues(alpha: 0.7),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.76,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFFE0B85E),
                              Color(0xFF63D2B8),
                              Color(0xFF7C4DFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Text(
                    'Powered by EpitomeHub',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xCCF8F2E4),
                          letterSpacing: 0.8,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSplashBoardGlow extends StatelessWidget {
  const _PremiumSplashBoardGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.055,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 96,
          itemBuilder: (BuildContext context, int index) {
            final int row = index ~/ 8;
            final int col = index % 8;
            return ColoredBox(
              color: (row + col).isEven
                  ? const Color(0xFFDCC58A)
                  : const Color(0xFF063B35),
            );
          },
        ),
      ),
    );
  }
}

class ChessVerseLoadingScreen extends StatelessWidget {
  const ChessVerseLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02070D),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size viewport = MediaQuery.sizeOf(context);
          final bool wide =
              viewport.shortestSide >= 600 && constraints.maxWidth >= 800;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.05),
                    radius: 1.05,
                    colors: <Color>[
                      Color(0xFF0A5A50),
                      Color(0xFF071B22),
                      Color(0xFF02070D),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: wide
                    ? const _WideChessVerseLoadingPanel()
                    : const _MobileChessVerseLoadingPanel(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileChessVerseLoadingPanel extends StatelessWidget {
  const _MobileChessVerseLoadingPanel();

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).height < 700;
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding:
            EdgeInsets.symmetric(horizontal: 30, vertical: compact ? 18 : 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _LoadingLogo(size: compact ? 102 : 124),
              SizedBox(height: compact ? 22 : 30),
              const _LoadingBrand(centered: true),
              SizedBox(height: compact ? 40 : 64),
              const _LoadingProgress(centered: true),
              SizedBox(height: compact ? 22 : 34),
              const _MobileLoadingFeatures(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideChessVerseLoadingPanel extends StatelessWidget {
  const _WideChessVerseLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Container(
            constraints: const BoxConstraints(minHeight: 610),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xE6041018),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x66566D70), width: 2),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x6600B9A8), blurRadius: 48),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  left: 500,
                  child: Image.asset(
                    'assets/backgrounds/home-online-hero-v1.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Color(0xFF031019),
                          Color(0xF2031019),
                          Color(0x70031019),
                          Color(0x12031019),
                        ],
                        stops: <double>[0, .37, .62, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(68, 62, 68, 38),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          _LoadingLogo(size: 116),
                          SizedBox(width: 28),
                          _LoadingBrand(centered: false),
                        ],
                      ),
                      const SizedBox(height: 42),
                      const SizedBox(
                          width: 520, child: _LoadingProgress(centered: false)),
                      const SizedBox(height: 42),
                      const _LoadingFeatureStrip(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingLogo extends StatelessWidget {
  const _LoadingLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .08),
      decoration: BoxDecoration(
        color: const Color(0xE6071520),
        borderRadius: BorderRadius.circular(size * .25),
        border: Border.all(color: const Color(0xFFE0B85E), width: 1.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x554DE1C8), blurRadius: 42, spreadRadius: 5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .18),
        child: Image.asset('assets/branding/app_icon.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _LoadingBrand extends StatelessWidget {
  const _LoadingBrand({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          const TextSpan(
            children: <InlineSpan>[
              TextSpan(text: 'CHESSVERSE'),
              TextSpan(text: ' AI', style: TextStyle(color: Color(0xFFF2BF4D))),
            ],
          ),
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: const Color(0xFFF8F2E4),
            fontSize: centered ? 30 : 42,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: centered ? .4 : .8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Think  •  Move  •  Master',
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: const Color(0xFFE0B85E),
            fontSize: centered ? 16 : 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _LoadingProgress extends StatelessWidget {
  const _LoadingProgress({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Preparing your board',
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: const Color(0xFFF8F2E4),
            fontSize: centered ? 18 : 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 17),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            minHeight: 8,
            backgroundColor: Color(0x332F5757),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF59D4C1)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading pieces, puzzles, and your profile',
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: const Color(0xFFAAAEB5),
            fontSize: centered ? 14 : 17,
          ),
        ),
      ],
    );
  }
}

class _LoadingFeatureStrip extends StatelessWidget {
  const _LoadingFeatureStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xD9061822),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x443E6E72)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(
              child: _LoadingFeature(
                  icon: Icons.extension_rounded,
                  title: 'Smart Puzzles',
                  subtitle: 'Train your mind daily')),
          VerticalDivider(color: Color(0x445A7178)),
          Expanded(
              child: _LoadingFeature(
                  icon: Icons.emoji_events_outlined,
                  title: 'Compete',
                  subtitle: 'Challenge players worldwide')),
          VerticalDivider(color: Color(0x445A7178)),
          Expanded(
              child: _LoadingFeature(
                  icon: Icons.trending_up_rounded,
                  title: 'Track Progress',
                  subtitle: 'Improve and climb ranks')),
        ],
      ),
    );
  }
}

class _LoadingFeature extends StatelessWidget {
  const _LoadingFeature(
      {required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF59D4C1), size: 38),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                      const TextStyle(color: Color(0xFFADB7C1), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class ChessVerseTheme {
  static ThemeData dark() {
    const ink = Color(0xFF101014);
    const brass = Color(0xFFD6A84F);
    const mint = Color(0xFF63D2B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: brass,
        secondary: mint,
        surface: Color(0xFF1A1B20),
        onSurface: Color(0xFFF6F1E8),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xD9071827),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Color(0xFFF6F1E8),
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFF6F1E8),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFE6D8BC),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFC8C1B6),
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brass,
          foregroundColor: ink,
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF6F1E8),
          side: const BorderSide(color: Color(0xFF61553F)),
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFF6F1E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

enum BoardSkin { royalWalnut, jadeGlass, tournament, marble, sapphire }

enum GameMode { computer, daily, puzzle, local, online }

enum DailyChallengeDifficulty { easy, medium, hard }

String dailyChallengeDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

int dailyChallengePatternForDate(DateTime date) {
  final DateTime day = DateTime(date.year, date.month, date.day);
  final int rawPattern =
      day.difference(DateTime(2026)).inDays % dailyChallengeRotationLength;
  return rawPattern < 0
      ? rawPattern + dailyChallengeRotationLength
      : rawPattern;
}

const int dailyChallengeRotationLength = 49;

const List<String> dailyChallengeQueenFiles = <String>[
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
];

String dailyChallengeQueenFileForPattern(int pattern) {
  final int normalized = ((pattern % dailyChallengeQueenFiles.length) +
          dailyChallengeQueenFiles.length) %
      dailyChallengeQueenFiles.length;
  return dailyChallengeQueenFiles[normalized];
}

List<String> dailyChallengeSolutionFor(
  DailyChallengeDifficulty difficulty,
  int pattern,
) {
  final String file = dailyChallengeQueenFileForPattern(pattern);
  return switch (difficulty) {
    DailyChallengeDifficulty.easy => <String>[
        '${file}1${file}3',
        'a7a6',
        '${file}3h3',
        'a6a5',
        'h3h7',
      ],
    DailyChallengeDifficulty.medium => <String>[
        '${file}1${file}2',
        'a7a6',
        '${file}2${file}3',
        'a6a5',
        '${file}3h3',
        'b7b6',
        'h3h7',
      ],
    DailyChallengeDifficulty.hard => <String>[
        '${file}1${file}2',
        'a7a6',
        '${file}2${file}3',
        'a6a5',
        '${file}3h3',
        'b7b6',
        'h3h4',
        'b6b5',
        'h4h7',
      ],
  };
}

enum PlayerSideChoice { white, random, black }

class _GameLaunchChoice {
  const _GameLaunchChoice(this.side, this.aiLevel);

  final PlayerSideChoice side;
  final double aiLevel;
}

Future<void> _restoreDailyReminder() async {
  const AppPreferences preferences = AppPreferences();
  final bool enabled =
      await preferences.readBool('dailyReminder', fallback: false);
  if (enabled) await DailyReminderService.instance.enable();
}

class _MobileLoadingFeatures extends StatelessWidget {
  const _MobileLoadingFeatures();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _MobileLoadingFeature(Icons.extension_rounded, 'Puzzles'),
        _MobileLoadingFeature(Icons.emoji_events_outlined, 'Compete'),
        _MobileLoadingFeature(Icons.trending_up_rounded, 'Progress'),
      ],
    );
  }
}

class _MobileLoadingFeature extends StatelessWidget {
  const _MobileLoadingFeature(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF59D4C1), size: 26),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

extension PlayerSideChoiceDetails on PlayerSideChoice {
  String get label => switch (this) {
        PlayerSideChoice.white => 'White',
        PlayerSideChoice.random => 'Random',
        PlayerSideChoice.black => 'Black',
      };

  IconData get icon => switch (this) {
        PlayerSideChoice.white => Icons.circle_outlined,
        PlayerSideChoice.random => Icons.shuffle_rounded,
        PlayerSideChoice.black => Icons.circle,
      };
}

extension DailyChallengeDifficultyDetails on DailyChallengeDifficulty {
  String get label => switch (this) {
        DailyChallengeDifficulty.easy => 'Easy - mate in 3',
        DailyChallengeDifficulty.medium => 'Medium - mate in 4',
        DailyChallengeDifficulty.hard => 'Hard - mate in 5',
      };

  int get moveGoal => switch (this) {
        DailyChallengeDifficulty.easy => 3,
        DailyChallengeDifficulty.medium => 4,
        DailyChallengeDifficulty.hard => 5,
      };
}

class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.pattern,
    required this.setupMoves,
    required this.solution,
    this.initialFen,
    this.forcedPlayerMoves,
  });

  final String id;
  final String title;
  final DailyChallengeDifficulty difficulty;
  final int pattern;
  final List<String> setupMoves;
  final List<String> solution;
  final String? initialFen;
  final int? forcedPlayerMoves;

  int get playerMoveGoal => forcedPlayerMoves ?? difficulty.moveGoal;
}

class AiProfile {
  const AiProfile(
    this.name,
    this.elo,
    this.description, {
    required this.engineMoveProbability,
    required this.mistakeProbability,
  });

  final String name;
  final int elo;
  final String description;
  final double engineMoveProbability;
  final double mistakeProbability;
}

AiProfile aiProfileFor(int level) {
  return switch (level.clamp(1, 10)) {
    1 => const AiProfile('New to Chess', 600, 'Frequent human-like mistakes',
        engineMoveProbability: 0, mistakeProbability: .58),
    2 => const AiProfile(
        'Beginner', 850, 'Sees simple captures, still blunders',
        engineMoveProbability: .05, mistakeProbability: .44),
    3 => const AiProfile('Learner', 1100, 'Basic tactics and development',
        engineMoveProbability: .15, mistakeProbability: .32),
    4 => const AiProfile('Intermediate', 1400, 'Plans one or two ideas ahead',
        engineMoveProbability: .35, mistakeProbability: .23),
    5 => const AiProfile(
        'Club', 1600, 'Solid play with occasional inaccuracies',
        engineMoveProbability: .50, mistakeProbability: .17),
    6 => const AiProfile('Advanced', 1800, 'Finds tactical combinations',
        engineMoveProbability: .65, mistakeProbability: .11),
    7 => const AiProfile('Expert', 2000, 'Deep calculation and defense',
        engineMoveProbability: .78, mistakeProbability: .07),
    8 => const AiProfile('Candidate Master', 2200, 'Tournament strength',
        engineMoveProbability: .90, mistakeProbability: .035),
    9 => const AiProfile('Master', 2500, 'Elite engine pressure',
        engineMoveProbability: .97, mistakeProbability: .012),
    _ => const AiProfile('Grandmaster', 2900, 'Maximum challenge',
        engineMoveProbability: 1, mistakeProbability: 0),
  };
}

Duration aiThinkDelayFor(int level) => Duration(
      milliseconds: switch (level.clamp(1, 10)) {
        1 => 1250,
        2 => 1050,
        3 => 850,
        4 => 700,
        5 => 620,
        6 => 540,
        7 => 470,
        8 => 410,
        9 => 360,
        _ => 320,
      },
    );

class _SideChoiceArtwork extends StatelessWidget {
  const _SideChoiceArtwork({
    required this.side,
    required this.size,
    required this.active,
  });

  final PlayerSideChoice side;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color glow = side == PlayerSideChoice.white
        ? const Color(0xFF57DDC3)
        : const Color(0xFFDDAF4E);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            glow.withValues(alpha: active ? .36 : .2),
            const Color(0xFF081724),
          ],
        ),
        border: Border.all(color: glow.withValues(alpha: active ? .85 : .35)),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(color: glow.withValues(alpha: .24), blurRadius: 22)
              ]
            : const <BoxShadow>[],
      ),
      child: side == PlayerSideChoice.random
          ? Icon(Icons.shuffle_rounded, color: glow, size: size * .5)
          : Image.asset(
              side == PlayerSideChoice.white
                  ? 'assets/pieces/staunton_white_pawn.png'
                  : 'assets/pieces/staunton_black_pawn.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
    );
  }
}

class AiCandidate {
  const AiCandidate(this.from, this.to, this.score);

  final String from;
  final String to;
  final double score;
}

AiCandidate chooseAiCandidateForLevel(
  List<AiCandidate> sortedCandidates,
  int level,
  math.Random random, {
  AiCandidate? engineMove,
}) {
  assert(sortedCandidates.isNotEmpty);
  final int boundedLevel = level.clamp(1, 10);
  final AiProfile profile = aiProfileFor(boundedLevel);
  if (engineMove != null &&
      random.nextDouble() < profile.engineMoveProbability) {
    return engineMove;
  }

  // Beginner levels intentionally inspect a much wider set of legal moves.
  // This creates human-like inaccuracies instead of exposing Stockfish's
  // minimum UCI strength (which is already too strong for a new player).
  final double candidateFraction = switch (boundedLevel) {
    1 => 1.0,
    2 => .80,
    3 => .60,
    4 => .48,
    5 => .34,
    6 => .24,
    7 => .15,
    8 => .08,
    9 => .03,
    _ => .01,
  };
  final int poolSize = math.max(
    1,
    math.min(
      sortedCandidates.length,
      (sortedCandidates.length * candidateFraction).ceil(),
    ),
  );
  return sortedCandidates[random.nextInt(poolSize)];
}

class PositionAnalysis {
  const PositionAnalysis({
    required this.side,
    required this.evaluation,
    required this.material,
    required this.legalMoves,
    required this.captures,
    required this.bestMove,
    required this.quality,
    required this.coachLine,
    required this.inCheck,
  });

  final String side;
  final double evaluation;
  final int material;
  final int legalMoves;
  final int captures;
  final String? bestMove;
  final String quality;
  final String coachLine;
  final bool inCheck;
}

class BoardPalette {
  const BoardPalette({
    required this.label,
    required this.light,
    required this.dark,
    required this.frame,
    required this.accent,
  });

  final String label;
  final Color light;
  final Color dark;
  final Color frame;
  final Color accent;
}

const Map<BoardSkin, BoardPalette> boardPalettes = <BoardSkin, BoardPalette>{
  BoardSkin.royalWalnut: BoardPalette(
    label: 'Walnut',
    light: Color(0xFFE9D5B7),
    dark: Color(0xFF7A4F2A),
    frame: Color(0xFF342113),
    accent: Color(0xFFD6A84F),
  ),
  BoardSkin.jadeGlass: BoardPalette(
    label: 'Jade',
    light: Color(0xFFD8EEE1),
    dark: Color(0xFF2F7D66),
    frame: Color(0xFF12372E),
    accent: Color(0xFF63D2B8),
  ),
  BoardSkin.tournament: BoardPalette(
    label: 'Classic',
    light: Color(0xFFF0D9B5),
    dark: Color(0xFFB58863),
    frame: Color(0xFF30251E),
    accent: Color(0xFFE2B458),
  ),
  BoardSkin.marble: BoardPalette(
    label: 'Marble',
    light: Color(0xFFF2F0EA),
    dark: Color(0xFF667078),
    frame: Color(0xFF252A2D),
    accent: Color(0xFFB9E4EE),
  ),
  BoardSkin.sapphire: BoardPalette(
    label: 'Sapphire',
    light: Color(0xFFDCE7EA),
    dark: Color(0xFF28546A),
    frame: Color(0xFF142B35),
    accent: Color(0xFF60D6D0),
  ),
};

class ChessPiece {
  const ChessPiece(this.code, this.white);

  final String code;
  final bool white;
}

class GameSnapshot {
  const GameSnapshot({
    required this.pieces,
    required this.moves,
    required this.capturedWhite,
    required this.capturedBlack,
    required this.coachNote,
    required this.lastFromSquare,
    required this.lastToSquare,
    required this.lastCaptureSquare,
    required this.whiteSeconds,
    required this.blackSeconds,
  });

  final Map<String, ChessPiece> pieces;
  final List<String> moves;
  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;
  final String coachNote;
  final String? lastFromSquare;
  final String? lastToSquare;
  final String? lastCaptureSquare;
  final int whiteSeconds;
  final int blackSeconds;
}

int computerUndoSnapshotIndex(
  List<GameSnapshot> history, {
  required bool humanPlaysWhite,
}) {
  for (int index = history.length - 1; index >= 0; index--) {
    final bool whiteToMove = history[index].moves.length.isEven;
    if (whiteToMove == humanPlaysWhite) {
      return index;
    }
  }
  return -1;
}

class ParsedMove {
  const ParsedMove(this.from, this.to);

  final String from;
  final String to;
}

class SquarePosition {
  const SquarePosition(this.file, this.rank);

  final int file;
  final int rank;
}

class ChessRules {
  static SquarePosition positionOf(String square) {
    return SquarePosition(square.codeUnitAt(0) - 97, int.parse(square[1]));
  }

  static String squareOf(int file, int rank) {
    return '${String.fromCharCode(97 + file)}$rank';
  }

  static bool isInside(int file, int rank) {
    return file >= 0 && file < 8 && rank >= 1 && rank <= 8;
  }

  static List<String> legalTargets(
    String from,
    Map<String, ChessPiece> pieces,
  ) {
    return pseudoLegalTargets(from, pieces);
  }

  static List<String> safeLegalTargets(
    String from,
    Map<String, ChessPiece> pieces,
  ) {
    final ChessPiece? piece = pieces[from];
    if (piece == null) {
      return <String>[];
    }

    return pseudoLegalTargets(from, pieces).where((String target) {
      if (pieces[target]?.code == 'K') {
        return false;
      }
      final Map<String, ChessPiece> next = applyMove(from, target, pieces);
      return !isKingInCheck(piece.white, next);
    }).toList();
  }

  static List<String> pseudoLegalTargets(
    String from,
    Map<String, ChessPiece> pieces,
  ) {
    final ChessPiece? piece = pieces[from];
    if (piece == null) {
      return <String>[];
    }

    return switch (piece.code) {
      'P' => _pawnTargets(from, piece, pieces),
      'N' => _jumpTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 2),
          SquarePosition(2, 1),
          SquarePosition(2, -1),
          SquarePosition(1, -2),
          SquarePosition(-1, -2),
          SquarePosition(-2, -1),
          SquarePosition(-2, 1),
          SquarePosition(-1, 2),
        ]),
      'B' => _rayTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 1),
          SquarePosition(1, -1),
          SquarePosition(-1, 1),
          SquarePosition(-1, -1),
        ]),
      'R' => _rayTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 0),
          SquarePosition(-1, 0),
          SquarePosition(0, 1),
          SquarePosition(0, -1),
        ]),
      'Q' => _rayTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 0),
          SquarePosition(-1, 0),
          SquarePosition(0, 1),
          SquarePosition(0, -1),
          SquarePosition(1, 1),
          SquarePosition(1, -1),
          SquarePosition(-1, 1),
          SquarePosition(-1, -1),
        ]),
      'K' => _jumpTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 0),
          SquarePosition(-1, 0),
          SquarePosition(0, 1),
          SquarePosition(0, -1),
          SquarePosition(1, 1),
          SquarePosition(1, -1),
          SquarePosition(-1, 1),
          SquarePosition(-1, -1),
        ]),
      _ => <String>[],
    };
  }

  static bool hasAnySafeMove(bool white, Map<String, ChessPiece> pieces) {
    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white == white &&
          safeLegalTargets(entry.key, pieces).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static bool isCheckmate(bool white, Map<String, ChessPiece> pieces) {
    return isKingInCheck(white, pieces) && !hasAnySafeMove(white, pieces);
  }

  static bool isStalemate(bool white, Map<String, ChessPiece> pieces) {
    return !isKingInCheck(white, pieces) && !hasAnySafeMove(white, pieces);
  }

  static bool isKingInCheck(bool white, Map<String, ChessPiece> pieces) {
    String? kingSquare;
    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white == white && entry.value.code == 'K') {
        kingSquare = entry.key;
        break;
      }
    }
    if (kingSquare == null) {
      return false;
    }

    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white != white &&
          attacksSquare(entry.key, kingSquare, pieces)) {
        return true;
      }
    }
    return false;
  }

  static bool attacksSquare(
    String from,
    String target,
    Map<String, ChessPiece> pieces,
  ) {
    final ChessPiece? piece = pieces[from];
    if (piece == null) {
      return false;
    }

    if (piece.code == 'P') {
      final SquarePosition origin = positionOf(from);
      final SquarePosition attacked = positionOf(target);
      final int direction = piece.white ? 1 : -1;
      return attacked.rank == origin.rank + direction &&
          (attacked.file - origin.file).abs() == 1;
    }

    return pseudoLegalTargets(from, pieces).contains(target);
  }

  static Map<String, ChessPiece> applyMove(
    String from,
    String target,
    Map<String, ChessPiece> pieces,
  ) {
    final Map<String, ChessPiece> next = Map<String, ChessPiece>.from(pieces);
    final ChessPiece? piece = next.remove(from);
    if (piece != null) {
      next[target] = piece;
    }
    return next;
  }

  static List<String> _pawnTargets(
    String from,
    ChessPiece piece,
    Map<String, ChessPiece> pieces,
  ) {
    final SquarePosition origin = positionOf(from);
    final int direction = piece.white ? 1 : -1;
    final int startRank = piece.white ? 2 : 7;
    final List<String> targets = <String>[];
    final int oneRank = origin.rank + direction;

    if (isInside(origin.file, oneRank)) {
      final String oneStep = squareOf(origin.file, oneRank);
      if (!pieces.containsKey(oneStep)) {
        targets.add(oneStep);

        final int twoRank = origin.rank + direction * 2;
        final String twoStep = squareOf(origin.file, twoRank);
        if (origin.rank == startRank &&
            isInside(origin.file, twoRank) &&
            !pieces.containsKey(twoStep)) {
          targets.add(twoStep);
        }
      }
    }

    for (final int fileDelta in <int>[-1, 1]) {
      final int targetFile = origin.file + fileDelta;
      final int targetRank = origin.rank + direction;
      if (!isInside(targetFile, targetRank)) {
        continue;
      }
      final String target = squareOf(targetFile, targetRank);
      final ChessPiece? occupant = pieces[target];
      if (occupant != null && occupant.white != piece.white) {
        targets.add(target);
      }
    }

    return targets;
  }

  static List<String> _jumpTargets(
    String from,
    ChessPiece piece,
    Map<String, ChessPiece> pieces,
    List<SquarePosition> deltas,
  ) {
    final SquarePosition origin = positionOf(from);
    final List<String> targets = <String>[];

    for (final SquarePosition delta in deltas) {
      final int file = origin.file + delta.file;
      final int rank = origin.rank + delta.rank;
      if (!isInside(file, rank)) {
        continue;
      }
      final String target = squareOf(file, rank);
      final ChessPiece? occupant = pieces[target];
      if (occupant == null || occupant.white != piece.white) {
        targets.add(target);
      }
    }

    return targets;
  }

  static List<String> _rayTargets(
    String from,
    ChessPiece piece,
    Map<String, ChessPiece> pieces,
    List<SquarePosition> directions,
  ) {
    final SquarePosition origin = positionOf(from);
    final List<String> targets = <String>[];

    for (final SquarePosition direction in directions) {
      int file = origin.file + direction.file;
      int rank = origin.rank + direction.rank;

      while (isInside(file, rank)) {
        final String target = squareOf(file, rank);
        final ChessPiece? occupant = pieces[target];
        if (occupant == null) {
          targets.add(target);
        } else {
          if (occupant.white != piece.white) {
            targets.add(target);
          }
          break;
        }
        file += direction.file;
        rank += direction.rank;
      }
    }

    return targets;
  }
}

class _PlayDestination extends StatelessWidget {
  const _PlayDestination({
    required this.onComputer,
    required this.onOnline,
    required this.onLocal,
    required this.onDaily,
  });
  final VoidCallback onComputer;
  final VoidCallback onOnline;
  final VoidCallback onLocal;
  final VoidCallback onDaily;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: wide ? 96 : null,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('PLAY',
                style:
                    TextStyle(letterSpacing: 1.8, fontWeight: FontWeight.w900)),
            Text('Choose your battle mode',
                style: TextStyle(
                    color: Color(0xFFAEC0D1),
                    fontSize: 15,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        centerTitle: !wide,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 18, 16, wide ? 28 : 18, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 1320 : 1100),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints size) =>
                  GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 4 : 1,
                mainAxisSpacing: wide ? 18 : 14,
                crossAxisSpacing: wide ? 16 : 14,
                childAspectRatio: wide ? .56 : 2.25,
                children: <Widget>[
                  _PlayModeCard(
                    icon: Icons.public_rounded,
                    title: 'Play Online',
                    subtitle: 'Find a live rival worldwide',
                    color: const Color(0xFF0F6B61),
                    asset: 'assets/backgrounds/home-online-hero-v1.png',
                    onTap: onOnline,
                  ),
                  _PlayModeCard(
                    icon: Icons.computer_rounded,
                    title: 'Play Computer',
                    subtitle: 'Challenge the ChessVerse AI',
                    color: const Color(0xFF174A69),
                    asset: 'assets/backgrounds/play-computer-card-v2.png',
                    onTap: onComputer,
                  ),
                  _PlayModeCard(
                    icon: Icons.groups_rounded,
                    title: 'Local Match',
                    subtitle: 'Two players on one board',
                    color: const Color(0xFF25664F),
                    asset: 'assets/backgrounds/local-match-card-v2.png',
                    onTap: onLocal,
                  ),
                  _PlayModeCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Daily Challenge',
                    subtitle: 'Solve today’s featured position',
                    color: const Color(0xFF8A5A21),
                    asset: 'assets/backgrounds/daily-challenge-card-v2.png',
                    onTap: onDaily,
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

class _PlayModeCard extends StatelessWidget {
  const _PlayModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.asset,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final bool desktopCard = MediaQuery.sizeOf(context).width >= 900;
    final Alignment imageAlignment =
        title == 'Play Online' ? const Alignment(0.5, 0) : Alignment.center;
    return Card(
      color: const Color(0xFF071827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: color.withValues(alpha: .8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            image: asset == null
                ? null
                : DecorationImage(
                    image: AssetImage(asset!),
                    fit: BoxFit.cover,
                    alignment: imageAlignment,
                    opacity: desktopCard ? .82 : .28,
                  ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                color.withValues(alpha: .36),
                const Color(0xEE071827),
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 430;
              final bool tall = constraints.maxHeight > constraints.maxWidth;
              if (tall) {
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0x08000000),
                        Color(0x18000000),
                        Color(0xF2071727),
                      ],
                      stops: <double>[0, .46, .72],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 27,
                              backgroundColor: const Color(0xD3071A2A),
                              child: Icon(icon, color: color, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title.toUpperCase(),
                                maxLines: 2,
                                style: const TextStyle(
                                  color: Color(0xFFFFF8ED),
                                  fontSize: 22,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          maxLines: 3,
                          style: const TextStyle(
                            color: Color(0xFFC5D5E0),
                            fontSize: 16,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .34),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                title == 'Daily Challenge'
                                    ? 'Solve Now'
                                    : title == 'Local Match'
                                        ? 'Start Match'
                                        : title == 'Play Computer'
                                            ? 'Start Game'
                                            : 'Play Now',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 24,
                  vertical: compact ? 12 : 18,
                ),
                child: Row(children: <Widget>[
                  CircleAvatar(
                    radius: compact ? 29 : 34,
                    backgroundColor: const Color(0xB3071A2A),
                    child: Icon(icon, color: color, size: compact ? 29 : 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Color(0xFFFFF8ED),
                                fontSize: compact ? 22 : 26,
                                height: 1.05,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFC5D5E0),
                              fontSize: compact ? 13 : 14,
                              height: 1.2,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: color, size: 34),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    this.initiallySignedIn = false,
    this.useRemoteEngine = true,
    this.initialGameMode = GameMode.computer,
    this.initialPlayerName,
    this.initialUsername,
    this.initialEmail,
    this.initialProfilePhotoUrl,
    this.initiallyGuest = true,
    this.initialSideChoice = PlayerSideChoice.white,
    this.initialAiLevel = 4,
    this.initialDailyDifficulty,
    this.initialPuzzleId,
    this.initialOnlineMatch,
    this.initialAuthToken,
    this.onlineApi,
    this.onLogout,
    super.key,
  });

  final bool initiallySignedIn;
  final bool useRemoteEngine;
  final GameMode initialGameMode;
  final String? initialPlayerName;
  final String? initialUsername;
  final String? initialEmail;
  final String? initialProfilePhotoUrl;
  final bool initiallyGuest;
  final PlayerSideChoice initialSideChoice;
  final double initialAiLevel;
  final DailyChallengeDifficulty? initialDailyDifficulty;
  final String? initialPuzzleId;
  final OnlineMatchDto? initialOnlineMatch;
  final String? initialAuthToken;
  final OnlineMatchApi? onlineApi;
  final Future<void> Function()? onLogout;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const AuthApi _authApi = AuthApi();
  static const AuthSessionStore _sessionStore = AuthSessionStore();
  static const EngineApi _engineApi = EngineApi();
  OnlineMatchApi get _onlineApi => widget.onlineApi ?? const OnlineMatchApi();
  static const AppPreferences _preferences = AppPreferences();
  final math.Random _random = math.Random();
  AudioPlayer? _warningPlayer;
  final List<String> _moves = <String>[];
  final List<ChessPiece> _capturedWhite = <ChessPiece>[];
  final List<ChessPiece> _capturedBlack = <ChessPiece>[];
  final List<GameSnapshot> _history = <GameSnapshot>[];
  Timer? _clockTimer;
  Timer? _moveQualityTimer;
  Timer? _aiWatchdogTimer;
  Timer? _turnReminderTimer;
  Timer? _onlinePollTimer;
  WebSocketChannel? _onlineChannel;
  StreamSubscription<dynamic>? _onlineSocketSubscription;
  Timer? _onlineSocketReconnectTimer;
  Timer? _onlineHeartbeatTimer;
  Timer? _onlineResultPresentationTimer;
  OnlineMatchDto? _onlineMatch;
  String? _handledDrawOfferKey;
  String? _archivedOnlineMatchId;
  String? _joiningRematchId;
  int _onlineConnectedPlayers = 0;
  bool _onlineSocketConnected = false;
  bool _onlineSubmitting = false;
  String? _onlineCelebrationMatchId;
  String? _selectedSquare;
  String? _lastFromSquare;
  String? _lastToSquare;
  String? _lastCaptureSquare;
  ChessPiece? _lastMovedPiece;
  ChessPiece? _lastCapturedPiece;
  String? _lastPlayerMove;
  String? _lastPlayerCoachNote;
  String? _moveQualityText;
  int _hintStage = 0;
  String? _coachArrowFrom;
  String? _coachArrowTo;
  int _coachRequestEpoch = 0;
  double _engineEvaluationPawns = 0;
  final List<int> _playerMoveScores = <int>[];
  final List<String> _importantMistakes = <String>[];
  String? _turningPoint;
  String _coachNote = 'Select a coin to see legal moves.';
  BoardSkin _skin = BoardSkin.royalWalnut;
  GameMode _gameMode = GameMode.computer;
  double _aiLevel = 4;
  bool _aiThinking = false;
  int _aiMoveEpoch = 0;
  bool _coachEnabled = true;
  bool _humanPlaysWhite = true;
  int _whiteSeconds = 10 * 60;
  int _blackSeconds = 10 * 60;
  bool _signedIn = false;
  String? _authToken;
  bool _awaitingCode = false;
  bool _authLoading = false;
  bool _authHasError = false;
  bool _registerMode = true;
  String _authUsername = '';
  String _authDisplayName = '';
  String _authIdentity = '';
  String _authPassword = '';
  String _authCode = '';
  String _authMessage =
      'Create an account to save games, ratings and coach history.';
  String _whitePlayerName = 'Guest Player';
  String _blackPlayerName = 'ChessVerseAI';
  String? _whitePlayerPhotoUrl;
  String? _blackPlayerPhotoUrl;
  String? _gameResultTitle;
  String? _gameResultDetail;
  bool _resultVisible = true;
  bool _checkWarningActive = false;
  bool _resultSaved = false;
  bool _soundEnabled = true;
  bool _showCoordinates = true;
  bool _showMoveHints = true;
  bool _turnBannerVisible = true;
  bool _boardTouchedThisTurn = false;
  bool _landscapeCoachCollapsed = true;
  DailyChallengeDifficulty _dailyDifficulty = DailyChallengeDifficulty.medium;
  late DailyChallenge _dailyChallenge;
  bool _dailyCompletedToday = false;
  int _dailyPlyIndex = 0;
  bool _puzzleExplorationMode = false;
  late ChessPuzzle _activePuzzle;

  bool get _isTacticsMode =>
      _gameMode == GameMode.daily || _gameMode == GameMode.puzzle;

  static const Map<String, ChessPiece> _initialPieces = <String, ChessPiece>{
    'a8': ChessPiece('R', false),
    'b8': ChessPiece('N', false),
    'c8': ChessPiece('B', false),
    'd8': ChessPiece('Q', false),
    'e8': ChessPiece('K', false),
    'f8': ChessPiece('B', false),
    'g8': ChessPiece('N', false),
    'h8': ChessPiece('R', false),
    'a7': ChessPiece('P', false),
    'b7': ChessPiece('P', false),
    'c7': ChessPiece('P', false),
    'd7': ChessPiece('P', false),
    'e7': ChessPiece('P', false),
    'f7': ChessPiece('P', false),
    'g7': ChessPiece('P', false),
    'h7': ChessPiece('P', false),
    'a2': ChessPiece('P', true),
    'b2': ChessPiece('P', true),
    'c2': ChessPiece('P', true),
    'd2': ChessPiece('P', true),
    'e2': ChessPiece('P', true),
    'f2': ChessPiece('P', true),
    'g2': ChessPiece('P', true),
    'h2': ChessPiece('P', true),
    'a1': ChessPiece('R', true),
    'b1': ChessPiece('N', true),
    'c1': ChessPiece('B', true),
    'd1': ChessPiece('Q', true),
    'e1': ChessPiece('K', true),
    'f1': ChessPiece('B', true),
    'g1': ChessPiece('N', true),
    'h1': ChessPiece('R', true),
  };

  late Map<String, ChessPiece> _pieces = Map<String, ChessPiece>.from(
    _initialPieces,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadGamePreferences());
    WidgetsBinding.instance.addObserver(this);
    _dailyDifficulty =
        widget.initialDailyDifficulty ?? DailyChallengeDifficulty.medium;
    _activePuzzle = PuzzleCatalog.byId(widget.initialPuzzleId ?? 'medium-001');
    if (widget.initialPuzzleId != null) {
      _dailyDifficulty = switch (_activePuzzle.difficulty) {
        PuzzleDifficulty.easy => DailyChallengeDifficulty.easy,
        PuzzleDifficulty.medium => DailyChallengeDifficulty.medium,
        PuzzleDifficulty.hard => DailyChallengeDifficulty.hard,
      };
    }
    _dailyChallenge = widget.initialGameMode == GameMode.puzzle
        ? _challengeForPuzzle(_activePuzzle)
        : _challengeForToday(_dailyDifficulty);
    _dailyCompletedToday = LocalGameArchive.isDailyChallengeComplete(
      _dailyChallenge.id,
    );
    _gameMode = widget.initialGameMode;
    _aiLevel = widget.initialAiLevel.clamp(1, 10).toDouble();
    _humanPlaysWhite = switch (widget.initialSideChoice) {
      PlayerSideChoice.white => true,
      PlayerSideChoice.black => false,
      PlayerSideChoice.random => _random.nextBool(),
    };
    if (_isTacticsMode) {
      _humanPlaysWhite = true;
    }
    _pieces = _isTacticsMode
        ? _dailyStartingPosition(_dailyChallenge)
        : Map<String, ChessPiece>.from(_initialPieces);
    _signedIn = widget.initiallySignedIn;
    final String playerName = widget.initialPlayerName != null &&
            widget.initialPlayerName!.trim().isNotEmpty
        ? widget.initialPlayerName!.trim()
        : widget.initiallySignedIn
            ? 'Guest Player'
            : 'Guest Player';
    if (widget.initialPlayerName != null &&
        widget.initialPlayerName!.trim().isNotEmpty) {
      _whitePlayerName = playerName;
    } else if (widget.initiallySignedIn) {
      _whitePlayerName = 'Guest Player';
    }
    _whitePlayerPhotoUrl = widget.initialProfilePhotoUrl;
    _applyPlayerSideNames(playerName);
    if (_gameMode == GameMode.daily) {
      _applyDailyCompletionState();
      if (!_dailyCompletedToday) {
        _coachNote =
            'Move any legal white coin. Checkmate in ${_dailyChallenge.playerMoveGoal} moves.';
      }
    }
    if (_gameMode == GameMode.puzzle) {
      _coachNote =
          '${_activePuzzle.title}: checkmate in ${_dailyChallenge.playerMoveGoal} moves.';
    }
    if (_gameMode == GameMode.computer && !_humanPlaysWhite) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAiMove());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _restartTurnReminder());
    if (_gameMode == GameMode.online &&
        widget.initialOnlineMatch != null &&
        widget.initialAuthToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _beginOnlineMatch(
              widget.initialOnlineMatch!, widget.initialAuthToken!);
        }
      });
    } else if (_gameMode == GameMode.online) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_showOnlineMatchmakingInfo());
        }
      });
    }
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (_gameResultTitle != null) {
        if (_gameMode == GameMode.daily &&
            _gameResultTitle!.toLowerCase().contains('challenge complete')) {
          final String unlockMessage = _dailyUnlockMessage();
          if (_gameResultDetail != unlockMessage) {
            setState(() {
              _gameResultDetail = unlockMessage;
              _coachNote = unlockMessage;
            });
          }
        }
        return;
      }
      setState(() {
        final OnlineMatchDto? online = _onlineMatch;
        if (_gameMode == GameMode.online) {
          if (online == null || !online.isActive) return;
          if (online.whiteToMove) {
            _whiteSeconds = math.max(0, _whiteSeconds - 1);
          } else {
            _blackSeconds = math.max(0, _blackSeconds - 1);
          }
          return;
        }
        if (_moves.isEmpty) return;
        if (_moves.length.isEven) {
          _whiteSeconds = math.max(0, _whiteSeconds - 1);
        } else {
          _blackSeconds = math.max(0, _blackSeconds - 1);
        }
        if (_gameMode != GameMode.online &&
            (_whiteSeconds == 0 || _blackSeconds == 0)) {
          _gameResultTitle = _whiteSeconds == 0 ? 'Black wins' : 'White wins';
          _gameResultDetail = 'Victory on time';
          _delayLocalResultOverlay();
          _coachNote = '$_gameResultTitle. $_gameResultDetail.';
          _archiveFinishedGame();
          unawaited(ChessSoundService.instance.victory());
        }
      });
    });
  }

  Future<void> _loadGamePreferences() async {
    final List<Object> values = await Future.wait<Object>(<Future<Object>>[
      _preferences.readBool('sound', fallback: true),
      _preferences.readBool('hints', fallback: true),
      _preferences.readBool('coach', fallback: true),
      _preferences.readBool('coordinates', fallback: true),
      _preferences.readString('boardTheme', fallback: 'Royal Walnut'),
      _preferences.readString('pieceStyle', fallback: 'Premium 3D'),
      _preferences.readString('pieceSize', fallback: 'Large'),
    ]);
    if (!mounted) return;
    final String boardTheme = values[4] as String;
    ChessPieceAppearanceController.current.value = ChessPieceAppearance(
      style: ChessPieceAppearanceController.styleFromLabel(values[5] as String),
      size: ChessPieceAppearanceController.sizeFromLabel(values[6] as String),
    );
    setState(() {
      _soundEnabled = values[0] as bool;
      _showMoveHints = values[1] as bool;
      _coachEnabled = values[2] as bool;
      _showCoordinates = values[3] as bool;
      _skin = switch (boardTheme) {
        'Jade Glass' => BoardSkin.jadeGlass,
        'Tournament' => BoardSkin.tournament,
        'Marble' => BoardSkin.marble,
        'Sapphire' => BoardSkin.sapphire,
        _ => BoardSkin.royalWalnut,
      };
    });
    ChessSoundService.instance.enabled = _soundEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _moveQualityTimer?.cancel();
    _aiWatchdogTimer?.cancel();
    _turnReminderTimer?.cancel();
    _onlinePollTimer?.cancel();
    unawaited(_onlineSocketSubscription?.cancel());
    unawaited(_onlineChannel?.sink.close());
    _onlineSocketReconnectTimer?.cancel();
    _onlineHeartbeatTimer?.cancel();
    _onlineResultPresentationTimer?.cancel();
    final AudioPlayer? warningPlayer = _warningPlayer;
    if (warningPlayer != null) {
      unawaited(warningPlayer.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _gameMode == GameMode.online &&
        _onlineMatch != null &&
        _authToken != null) {
      _resumeOnlineSession();
    } else if (state != AppLifecycleState.resumed) {
      _onlineHeartbeatTimer?.cancel();
      unawaited(_onlineChannel?.sink.close());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Online matchmaking is opened immediately after this route is created.
    // Do not build the local chess position underneath it: on slower phones
    // and during the route transition that board used to flash behind the
    // Online/Friends screen for a frame.
    if (_gameMode == GameMode.online && _onlineMatch == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF06131F),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF0A2231), Color(0xFF040B13)],
            ),
          ),
          child: SizedBox.expand(),
        ),
      );
    }
    final BoardPalette palette = boardPalettes[_skin]!;
    final bool sideToMoveWhite =
        _gameMode == GameMode.online && _onlineMatch != null
            ? _onlineMatch!.whiteToMove
            : _moves.length.isEven;
    final bool sideInCheck = ChessRules.isKingInCheck(sideToMoveWhite, _pieces);
    final String? checkedKingSquare =
        sideInCheck ? _kingSquare(sideToMoveWhite) : null;
    final Set<String> legalTargets = !_showMoveHints || _selectedSquare == null
        ? <String>{}
        : _legalTargetsFor(_selectedSquare!).toSet();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF193128),
          image: DecorationImage(
            image: const AssetImage(
              'assets/backgrounds/grandmaster-table-v1.webp',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              const Color(0xFF10251E).withValues(alpha: 0.28),
              BlendMode.multiply,
            ),
          ),
        ),
        child: SafeArea(
          left: false,
          right: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool landscape =
                  constraints.maxWidth > constraints.maxHeight;
              // Landscape phones have enough horizontal room for the original
              // large-board + side-panel layout. Keeping them in the compact
              // portrait column makes the board too small to play comfortably.
              // Switch layout exactly once when orientation changes. A second
              // width breakpoint during Android's rotation animation made the
              // board briefly jump sideways before reaching its final place.
              final bool wide =
                  constraints.maxWidth >= 980 && constraints.maxHeight >= 600;
              final bool compactLandscape = landscape && !wide;
              const EdgeInsets pagePadding = EdgeInsets.zero;
              final double availableHeight =
                  constraints.maxHeight - pagePadding.vertical;
              final bool roomyLandscape = wide && constraints.maxHeight >= 690;
              // A regular laptop viewport does not have enough vertical room
              // for the online player rails, a useful board, and the 126px
              // history dock at the same time. Keep the dock for genuinely
              // tall desktop windows; move history remains available from the
              // controls on shorter web screens.
              final bool showWideDock = wide && constraints.maxHeight >= 900;
              final double mobileHeaderHeight = wide
                  ? 0
                  : compactLandscape
                      ? 48
                      : 58;
              final double widePanelWidth = math.min(
                410,
                math.max(320, constraints.maxWidth * 0.30),
              );
              final double wideHeaderHeight = roomyLandscape ? 78 : 54;
              final double wideDockHeight = showWideDock ? 126 : 0;
              final double portraitPanelMinimum = landscape ? 64 : 145;
              final bool showOnlineArena =
                  _gameMode == GameMode.online && _onlineMatch != null;
              // Phone landscape uses compact rails over the board. Reserving
              // the portrait rail height here used to shrink the playable
              // board to little more than half of the available height.
              final double arenaRailsHeight =
                  showOnlineArena && !compactLandscape ? 136 : 0;
              final double boardWidth = wide
                  ? constraints.maxWidth -
                      pagePadding.horizontal -
                      widePanelWidth -
                      24
                  : compactLandscape
                      ? constraints.maxWidth *
                          (_landscapeCoachCollapsed ? 0.94 : 0.68)
                      : constraints.maxWidth - pagePadding.horizontal;
              final double boardHeight = wide
                  ? availableHeight -
                      wideHeaderHeight -
                      wideDockHeight -
                      arenaRailsHeight -
                      18
                  : compactLandscape
                      ? availableHeight - mobileHeaderHeight - 4
                      : availableHeight -
                          mobileHeaderHeight -
                          portraitPanelMinimum -
                          arenaRailsHeight -
                          18;
              final double boardDimension =
                  math.max(0, math.min(boardWidth, boardHeight));

              final Widget board = ChessBoard(
                pieces: _pieces,
                selectedSquare: _selectedSquare,
                legalTargets: legalTargets,
                lastFromSquare: _lastFromSquare,
                lastToSquare: _lastToSquare,
                lastCaptureSquare: _lastCaptureSquare,
                lastMovedPiece: _lastMovedPiece,
                lastCapturedPiece: _lastCapturedPiece,
                moveSequence: _moves.length,
                checkedKingSquare: checkedKingSquare,
                decisiveSquare:
                    _gameResultDetail == 'Checkmate' ? _lastToSquare : null,
                fallenKingSquare: _gameResultDetail == 'Checkmate'
                    ? (_kingSquare(sideToMoveWhite) ??
                        (_lastCapturedPiece?.code == 'K'
                            ? _lastCaptureSquare
                            : null))
                    : null,
                fallenKingWhite: sideToMoveWhite,
                coachArrowFrom: _coachArrowFrom,
                coachArrowTo: _coachArrowTo,
                flipped: _shouldFlipBoard(sideToMoveWhite),
                showCoordinates: _showCoordinates,
                palette: palette,
                onSquareTap: _handleSquareTap,
              );
              final Widget arenaBoard = showOnlineArena
                  ? _OnlineArenaBoard(
                      board: BoardStage(palette: palette, child: board),
                      flipped: _shouldFlipBoard(sideToMoveWhite),
                      whiteName: _whitePlayerName,
                      blackName: _blackPlayerName,
                      whitePhotoUrl: _whitePlayerPhotoUrl,
                      blackPhotoUrl: _blackPlayerPhotoUrl,
                      whiteClock: _formatClock(_whiteSeconds),
                      blackClock: _formatClock(_blackSeconds),
                      activeColor:
                          _onlineMatch?.activeColor.toLowerCase() ?? 'white',
                      matchActive: _onlineMatch?.isActive ?? false,
                      socketConnected: _onlineSocketConnected,
                      connectedPlayers: _onlineConnectedPlayers,
                      compactOverlay: compactLandscape,
                    )
                  : BoardStage(palette: palette, child: board);

              final Widget studioCoach = _StudioCoachPanel(
                gameMode: _gameMode,
                activeColor: _gameMode == GameMode.computer
                    ? (sideToMoveWhite == _humanPlaysWhite && !_aiThinking
                        ? 'YOUR TURN'
                        : 'AI TURN')
                    : _gameMode == GameMode.online && _onlineMatch != null
                        ? (_onlineStatusText(_onlineMatch!))
                        : _moves.length.isEven
                            ? 'PLAYER 1 • WHITE'
                            : 'PLAYER 2 • BLACK',
                aiThinking: _aiThinking,
                coachEnabled: _coachEnabled,
                coachNote: _lastPlayerCoachNote ?? _coachNote,
                evaluationPawns: _engineEvaluationPawns,
                lastMove: _lastPlayerMove,
                lastMoveOwner: _lastPlayerMove == null ? null : 'Your move',
                dailyProgress: _dailyPlayerMovesCompleted,
                dailyGoal: _dailyChallenge.playerMoveGoal,
                canUndo: _gameMode != GameMode.online &&
                    _gameResultTitle == null &&
                    _history.isNotEmpty,
                hintLabel: switch (_hintStage) {
                  1 => 'Direction',
                  2 => 'Exact move',
                  _ => 'Piece hint',
                },
                analyzeLabel:
                    _moveQualityText == null ? 'Analyze' : 'Why weak?',
                onHint: _showHint,
                onAnalyze: _showAnalysis,
                onTryAgain: _gameMode == GameMode.online
                    ? () => unawaited(
                          _refreshOnlineMatch(forceBoardReplay: true),
                        )
                    : _confirmNewGame,
                onUndo: _undo,
                puzzleComplete: _gameMode == GameMode.puzzle &&
                    _gameResultTitle == 'Puzzle complete',
                onNextPuzzle: _startNextPuzzle,
                onBackToAcademy: () => Navigator.of(context).pop(),
              );
              final bool yourTurn = switch (_gameMode) {
                GameMode.computer =>
                  sideToMoveWhite == _humanPlaysWhite && !_aiThinking,
                GameMode.online => _onlineMatch != null &&
                    _onlineMatch!.activeColor.toLowerCase() ==
                        _onlineMatch!.yourColor.toLowerCase(),
                _ => true,
              };
              return Padding(
                padding: pagePadding,
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    wide ? 'landscape-game-layout' : 'portrait-game-layout',
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (wide)
                        Padding(
                          padding: EdgeInsets.only(
                            right: MediaQuery.viewPaddingOf(context).right,
                          ),
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                height: wideHeaderHeight,
                                child: _GameStudioHeader(
                                  gameMode: _gameMode,
                                  playerName: _whitePlayerName,
                                  soundEnabled: _soundEnabled,
                                  onSoundChanged: _setSoundEnabled,
                                  onHome: () => Navigator.of(context).pop(),
                                  onDailyChallenge: _openDailyChallenge,
                                  onProfile: _openProfile,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    8,
                                    18,
                                    8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: SizedBox(
                                            width: boardDimension,
                                            height: boardDimension +
                                                arenaRailsHeight,
                                            child: arenaBoard,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      SizedBox(
                                        key: const ValueKey<String>(
                                          'landscape-ai-coach',
                                        ),
                                        width: widePanelWidth,
                                        child: studioCoach,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (showWideDock)
                                SizedBox(
                                  height: wideDockHeight,
                                  child: _GameStudioDock(
                                    moves: _moves,
                                    capturedWhite: _capturedWhite,
                                    capturedBlack: _capturedBlack,
                                    onMoveHistory: _showMoveHistory,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else if (compactLandscape)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SizedBox(
                              height: mobileHeaderHeight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  child: CompactHeader(
                                    onHome: () => Navigator.of(context).pop(),
                                    onProfile: _openProfile,
                                    onReset: _confirmNewGame,
                                    onLogout: _logout,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Expanded(
                                      flex: _landscapeCoachCollapsed ? 20 : 15,
                                      child: Center(
                                        child: SizedBox(
                                          width: boardDimension,
                                          height:
                                              boardDimension + arenaRailsHeight,
                                          child: arenaBoard,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (!_landscapeCoachCollapsed)
                                      Expanded(
                                        flex: 6,
                                        child: ClipRect(
                                          child: FittedBox(
                                            key: const ValueKey<String>(
                                              'compact-landscape-ai-coach',
                                            ),
                                            fit: BoxFit.contain,
                                            alignment: Alignment.topCenter,
                                            child: SizedBox(
                                              width: 390,
                                              height: 560,
                                              child: studioCoach,
                                            ),
                                          ),
                                        ),
                                      ),
                                    SizedBox(
                                      width: 42,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: IconButton.filledTonal(
                                          key: const ValueKey<String>(
                                            'landscape-coach-toggle',
                                          ),
                                          tooltip: _landscapeCoachCollapsed
                                              ? 'Show AI Coach'
                                              : 'Maximize board',
                                          onPressed: () => setState(() {
                                            _landscapeCoachCollapsed =
                                                !_landscapeCoachCollapsed;
                                          }),
                                          icon: Icon(
                                            _landscapeCoachCollapsed
                                                ? Icons.psychology_alt_rounded
                                                : Icons.fullscreen_rounded,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            CompactHeader(
                              onHome: () => Navigator.of(context).pop(),
                              onProfile: _openProfile,
                              onReset: _confirmNewGame,
                              onLogout: _logout,
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: SizedBox(
                                width: boardDimension,
                                height: boardDimension + arenaRailsHeight,
                                child: arenaBoard,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              key: const ValueKey<String>('mobile-ai-coach'),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                                child: studioCoach,
                              ),
                            ),
                          ],
                        ),
                      if (_signedIn &&
                          _gameResultTitle == null &&
                          yourTurn &&
                          _turnBannerVisible)
                        Positioned(
                          top: wide ? wideHeaderHeight + 12 : 66,
                          left: wide ? 24 : 12,
                          right: wide ? widePanelWidth + 42 : 12,
                          child: const _TurnBanner(),
                        ),
                      if (!_signedIn)
                        Positioned.fill(
                          child: AuthOverlay(
                            registerMode: _registerMode,
                            awaitingCode: _awaitingCode,
                            message: _authMessage,
                            hasError: _authHasError,
                            onModeChanged: _setAuthMode,
                            onUsernameChanged: (String value) {
                              _authUsername = value.trim();
                            },
                            onDisplayNameChanged: (String value) {
                              _authDisplayName = value.trim();
                            },
                            onIdentityChanged: (String value) {
                              _authIdentity = value.trim();
                            },
                            onPasswordChanged: (String value) {
                              _authPassword = value;
                            },
                            onCodeChanged: (String value) {
                              _authCode = value.trim();
                            },
                            onSubmit: _submitAuth,
                            onContinueDefault: _continueAsDefaultPlayer,
                            onFacebookLogin: _showFacebookSetupMessage,
                            onForgotPassword: _showPasswordResetDialog,
                            onResendCode: _resendVerificationCode,
                            onBackFromCode: () => setState(() {
                              _awaitingCode = false;
                              _authCode = '';
                              _authMessage =
                                  'Update your details or request a new code.';
                            }),
                            loading: _authLoading,
                          ),
                        ),
                      if (_signedIn &&
                          _gameMode == GameMode.online &&
                          _onlineMatch?.isActive == true &&
                          _onlineMatch?.opponentDisconnected == true)
                        Positioned(
                          top: wide ? wideHeaderHeight + 12 : 68,
                          left: wide ? 28 : 16,
                          right: wide ? widePanelWidth + 42 : 16,
                          child: OnlineReconnectCountdown(
                            secondsRemaining:
                                _onlineMatch!.disconnectSecondsRemaining,
                          ),
                        ),
                      if (_signedIn &&
                          _gameResultTitle != null &&
                          _resultVisible)
                        Positioned.fill(
                          child: GameResultOverlay(
                            title: _resultDisplayTitle(),
                            detail: _gameResultDetail ?? 'Game complete',
                            scoreLabel: _resultScoreLabel(),
                            accuracy: _playerAccuracy,
                            turningPoint: _turningPoint,
                            onNewGame: _gameMode == GameMode.online
                                ? _startFreshOnlineGame
                                : _gameMode == GameMode.puzzle
                                    ? _startNextPuzzle
                                    : _reset,
                            newGameLabel: _gameMode == GameMode.puzzle
                                ? 'Next puzzle'
                                : null,
                            onRematch: _gameMode == GameMode.online
                                ? _requestOnlineRematch
                                : null,
                            onDismiss: () => setState(() {
                              _resultVisible = false;
                            }),
                            onReview: () {
                              setState(() => _resultVisible = false);
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _showAiReview(),
                              );
                            },
                          ),
                        ),
                      if (_signedIn &&
                          _gameResultTitle != null &&
                          !_resultVisible &&
                          !_gameResultTitle!.toLowerCase().contains('draw') &&
                          !_gameResultTitle!
                              .toLowerCase()
                              .contains('challenge missed'))
                        Positioned.fill(
                          child: OnlineVictoryCelebration(
                            winnerAtTop: true,
                            title: _resultDisplayTitle(),
                            showTitle: true,
                          ),
                        ),
                      if (_moveQualityText != null &&
                          _gameMode == GameMode.computer &&
                          _gameResultTitle == null)
                        Positioned(
                          left: wide ? 22 : 18,
                          right: wide ? widePanelWidth + 30 : 18,
                          bottom: 18,
                          child: IgnorePointer(
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF16171C,
                                  ).withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFD6A84F,
                                    ).withValues(alpha: 0.72),
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.32),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.psychology_alt_rounded,
                                        color: Color(0xFFD6A84F),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _moveQualityText!,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFFF6F1E8),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          playerName: widget.initialPlayerName ?? _whitePlayerName,
          username: widget.initialUsername,
          email: widget.initialEmail,
          isGuest: widget.initiallyGuest,
        ),
      ),
    );
  }

  void _setAuthMode(bool registerMode) {
    setState(() {
      _registerMode = registerMode;
      _awaitingCode = false;
      _authHasError = false;
      _authMessage = registerMode
          ? 'Create an account to save games, ratings and coach history.'
          : 'Welcome back. Sign in with your user id and password.';
    });
  }

  void _continueAsDefaultPlayer() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _authToken = null;
      _whitePlayerName = 'Guest Player';
      _signedIn = true;
      _authLoading = false;
      _authHasError = false;
      _awaitingCode = false;
      _coachNote =
          'Guest Player mode is ready. Create an account later to save progress.';
    });
  }

  Future<void> _showFacebookSetupMessage() async {
    setState(() {
      _authLoading = true;
      _authHasError = false;
      _authMessage = 'Opening Facebook securely...';
    });
    try {
      if (kIsWeb) await ensureFacebookSdkReady();
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: const <String>['email', 'public_profile'],
      );
      if (result.status == LoginStatus.cancelled) {
        if (mounted) {
          setState(() => _authMessage = 'Facebook sign-in was cancelled.');
        }
        return;
      }
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw AuthApiException(
          result.message ?? 'Facebook sign-in failed. Please try again.',
        );
      }
      final Map<String, dynamic> response = await _authApi.post(
        'facebook',
        <String, String>{
          'accessToken': result.accessToken!.tokenString,
        },
      );
      if (!mounted) return;
      await _completeLogin(response);
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _authHasError = true;
          _authMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _authHasError = true;
          _authMessage = 'Facebook sign-in failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  Future<void> _resendVerificationCode() async {
    if (_authLoading || _authIdentity.isEmpty) {
      return;
    }
    setState(() {
      _authLoading = true;
      _authHasError = false;
      _authMessage = 'Requesting a new verification code...';
    });
    try {
      final Map<String, dynamic> response = await _authApi.post(
        'resend-verification',
        <String, String>{'email': _authIdentity},
      );
      if (!mounted) return;
      final String baseMessage =
          response['message'] as String? ?? 'A new code has been sent.';
      final String? developmentCode = response['developmentCode'] as String?;
      setState(() {
        _authMessage = developmentCode == null
            ? baseMessage
            : '$baseMessage Local test code: $developmentCode';
      });
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _authHasError = true;
          _authMessage = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _authLoading = false);
      }
    }
  }

  Future<void> _showPasswordResetDialog() async {
    final TextEditingController emailController = TextEditingController(
      text: _authIdentity.contains('@') ? _authIdentity : '',
    );
    final TextEditingController codeController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool codeSent = false;
        bool loading = false;
        bool hasError = false;
        String message =
            'Enter your verified email to receive a password reset code.';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> submit() async {
              final String email = emailController.text.trim();
              final String code = codeController.text.trim();
              final String password = passwordController.text;
              if (email.isEmpty ||
                  (codeSent &&
                      (!RegExp(r'^\d{6}$').hasMatch(code) ||
                          password.length < 8))) {
                setDialogState(() {
                  hasError = true;
                  message = codeSent
                      ? 'Enter the six-digit code and an 8+ character password.'
                      : 'Enter your verified email address.';
                });
                return;
              }

              setDialogState(() {
                loading = true;
                hasError = false;
                message = codeSent
                    ? 'Updating your password...'
                    : 'Sending a secure reset code...';
              });
              try {
                final Map<String, dynamic> response = await _authApi.post(
                  codeSent ? 'password/reset' : 'password/forgot',
                  codeSent
                      ? <String, String>{
                          'email': email,
                          'code': code,
                          'newPassword': password,
                        }
                      : <String, String>{'email': email},
                );
                if (!dialogContext.mounted) return;
                if (codeSent) {
                  Navigator.of(dialogContext).pop();
                  if (!mounted) return;
                  setState(() {
                    _registerMode = false;
                    _awaitingCode = false;
                    _authIdentity = email;
                    _authHasError = false;
                    _authMessage =
                        'Password updated. Sign in with your new password.';
                  });
                } else {
                  final String baseMessage = response['message'] as String? ??
                      'If the account exists, a reset code was sent.';
                  final String? developmentCode =
                      response['developmentCode'] as String?;
                  setDialogState(() {
                    codeSent = true;
                    message = developmentCode == null
                        ? baseMessage
                        : '$baseMessage Local test code: $developmentCode';
                  });
                }
              } on AuthApiException catch (error) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    hasError = true;
                    message = error.message;
                  });
                }
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => loading = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Reset password'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(message),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        enabled: !codeSent && !loading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Verified email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (codeSent) ...<Widget>[
                        const SizedBox(height: 12),
                        TextField(
                          controller: codeController,
                          enabled: !loading,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Six-digit reset code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: passwordController,
                          enabled: !loading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'New password',
                            helperText: 'At least 8 characters',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (hasError) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          message,
                          style: const TextStyle(color: Color(0xFFFF7774)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: Text(codeSent ? 'Update password' : 'Send reset code'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitAuth() async {
    if (_authLoading) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (_registerMode &&
        !_awaitingCode &&
        (_authUsername.isEmpty ||
            _authDisplayName.isEmpty ||
            _authIdentity.isEmpty ||
            _authPassword.length < 8)) {
      setState(() {
        _authHasError = true;
        _authMessage =
            'Enter a user id, display name, valid email and an 8+ character password.';
      });
      return;
    }
    if (_awaitingCode && !RegExp(r'^\d{6}$').hasMatch(_authCode)) {
      setState(() {
        _authHasError = true;
        _authMessage = 'Enter the six-digit code sent to your email.';
      });
      return;
    }
    if (!_registerMode && (_authIdentity.isEmpty || _authPassword.isEmpty)) {
      setState(() {
        _authHasError = true;
        _authMessage = 'Enter your user id and password.';
      });
      return;
    }

    setState(() {
      _authLoading = true;
      _authHasError = false;
      _authMessage = _awaitingCode
          ? 'Verifying your code...'
          : _registerMode
              ? 'Sending a secure verification code...'
              : 'Signing you in...';
    });

    try {
      if (_registerMode && !_awaitingCode) {
        final Map<String, dynamic> response =
            await _authApi.post('register', <String, String>{
          'username': _authUsername,
          'displayName': _authDisplayName,
          'email': _authIdentity,
          'password': _authPassword,
        });
        if (!mounted) return;
        setState(() {
          _awaitingCode = true;
          _authHasError = false;
          final String baseMessage = response['message'] as String? ??
              'Verification code sent. Check your inbox.';
          final String? developmentCode =
              response['developmentCode'] as String?;
          _authMessage = developmentCode == null
              ? baseMessage
              : '$baseMessage Local test code: $developmentCode';
        });
      } else if (_awaitingCode) {
        final Map<String, dynamic> response = await _authApi.post(
          'verify-email',
          <String, String>{'email': _authIdentity, 'code': _authCode},
        );
        if (!mounted) return;
        await _completeLogin(response);
      } else {
        final Map<String, dynamic> response = await _authApi.post(
          'login',
          <String, String>{
            'identity': _authIdentity,
            'password': _authPassword,
          },
        );
        if (!mounted) return;
        await _completeLogin(response);
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _authHasError = true;
          _authMessage = switch (error.message) {
            'That user id is already taken.' =>
              'User ID "$_authUsername" is already taken. Choose another User ID or select Login.',
            _ => error.message,
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() => _authLoading = false);
      }
    }
  }

  Future<void> _completeLogin(Map<String, dynamic> response) async {
    final String token = response['token'] as String? ?? '';
    final DateTime? expiresAt = DateTime.tryParse(
      response['expiresAt'] as String? ?? '',
    );
    final Map<String, dynamic>? player =
        response['player'] as Map<String, dynamic>?;
    final String displayName =
        player?['displayName'] as String? ?? _authIdentity;
    if (token.isEmpty || expiresAt == null) {
      throw const AuthApiException('The server returned an invalid session.');
    }

    await _sessionStore.write(
      StoredAuthSession(
        token: token,
        expiresAt: expiresAt,
        displayName: displayName,
      ),
    );
    if (!mounted) return;
    setState(() {
      _authToken = token;
      _whitePlayerName = displayName;
      _signedIn = true;
      _awaitingCode = false;
      _authHasError = false;
      _authCode = '';
      _authPassword = '';
      _coachNote = 'Welcome $displayName. Your game is ready.';
    });
  }

  Future<void> _logout() async {
    final Future<void> Function()? onLogout = widget.onLogout;
    if (onLogout != null) {
      await onLogout();
      return;
    }

    final String? token = _authToken;
    if (token != null) {
      await _authApi.logout(token);
    }
    await _sessionStore.clear();
    if (!mounted) return;
    setState(() {
      _authToken = null;
      _signedIn = false;
      _registerMode = false;
      _awaitingCode = false;
      _authHasError = false;
      _authIdentity = '';
      _authPassword = '';
      _authMessage = 'Session closed securely. Sign in to continue.';
      _whitePlayerName = 'Player';
    });
  }

  void _changeGameMode(GameMode mode) {
    if (mode == GameMode.online) {
      _showOnlineMatchmakingInfo();
      return;
    }
    _onlinePollTimer?.cancel();
    _onlineMatch = null;
    setState(() {
      _gameMode = mode;
      if (_isTacticsMode) {
        _humanPlaysWhite = true;
      }
      _applyPlayerSideNames(_playerDisplayName);
    });
    _reset();
  }

  void _openDailyChallenge() {
    if (_gameMode == GameMode.daily) {
      _confirmNewGame();
      return;
    }
    _changeGameMode(GameMode.daily);
  }

  String get _playerDisplayName {
    final String trimmed = widget.initialPlayerName?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return widget.initiallySignedIn ? 'Guest Player' : _whitePlayerName;
  }

  void _applyPlayerSideNames(String playerName) {
    switch (_gameMode) {
      case GameMode.computer:
        _whitePlayerName = _humanPlaysWhite ? playerName : 'ChessVerseAI';
        _blackPlayerName = _humanPlaysWhite ? 'ChessVerseAI' : playerName;
      case GameMode.daily:
      case GameMode.puzzle:
        _whitePlayerName = 'Guest Player';
        _blackPlayerName = 'Puzzle Defense';
      case GameMode.local:
        _whitePlayerName = 'Player 1 • White';
        _blackPlayerName = 'Player 2 • Black';
      case GameMode.online:
        _whitePlayerName = playerName;
        _blackPlayerName = 'Online Rival';
    }
  }

  bool _shouldFlipBoard(bool sideToMoveWhite) {
    if (_gameMode == GameMode.computer || _gameMode == GameMode.online) {
      return !_humanPlaysWhite;
    }
    if (_gameMode == GameMode.local) {
      // Pass-and-play remains White-at-bottom for the whole match. Rotating
      // after every move makes coordinates and piece positions disorienting.
      return false;
    }
    return false;
  }

  int get _dailyPlayerMovesCompleted => (_dailyPlyIndex + 1) ~/ 2;

  bool _isLegalMove(String from, String to, {bool? whiteToMove}) {
    final ChessPiece? piece = _pieces[from];
    if (piece == null) {
      return false;
    }
    if (whiteToMove != null && piece.white != whiteToMove) {
      return false;
    }
    try {
      return _legalTargetsFor(from).contains(to);
    } catch (_) {
      return false;
    }
  }

  bool _hasAnyLegalMove(bool white) {
    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white == white &&
          _legalTargetsFor(entry.key).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _isCheckmateFor(bool white) {
    return ChessRules.isKingInCheck(white, _pieces) && !_hasAnyLegalMove(white);
  }

  bool _isStalemateFor(bool white) {
    return !ChessRules.isKingInCheck(white, _pieces) &&
        !_hasAnyLegalMove(white);
  }

  String _moveFeedback({
    required ChessPiece piece,
    required String from,
    required String to,
    required ChessPiece? captured,
    required bool castleMove,
  }) {
    final bool givesCheck = ChessRules.isKingInCheck(!piece.white, _pieces);
    final SquarePosition target = ChessRules.positionOf(to);
    final bool central = target.file >= 2 &&
        target.file <= 5 &&
        target.rank >= 3 &&
        target.rank <= 6;
    if (givesCheck && captured != null) {
      return 'Amazing step - check with material gain.';
    }
    if (givesCheck || castleMove || captured?.code == 'Q') {
      return 'Superb step - strong chess idea.';
    }
    if (captured != null || central) {
      return 'Good step - useful improvement.';
    }
    if (piece.code == 'K' && !castleMove) {
      return 'Not good step - king safety first.';
    }
    return 'Average step - playable, but look for more pressure.';
  }

  void _scheduleMoveQualityDismiss() {
    _moveQualityTimer?.cancel();
    _moveQualityTimer = Timer(const Duration(milliseconds: 2300), () {
      if (mounted) {
        setState(() => _moveQualityText = null);
      }
    });
  }

  String _resultScoreLabel() {
    if (_gameMode == GameMode.online) {
      final String authoritative = _onlineMatch?.perspectiveScoreLabel ?? '';
      if (authoritative.isNotEmpty) return authoritative;
    }
    final String lowerTitle = (_gameResultTitle ?? '').toLowerCase();
    if (lowerTitle.contains('draw')) {
      return '1/2 - 1/2';
    }
    if (lowerTitle.contains('challenge complete')) {
      return '1 - 0';
    }
    if (lowerTitle.contains('challenge missed')) {
      return 'Not solved';
    }
    final bool whiteWon = lowerTitle.startsWith('white');
    final bool blackWon = lowerTitle.startsWith('black');
    if (!whiteWon && !blackWon) {
      return '1 - 0';
    }
    final bool userWon = _humanPlaysWhite ? whiteWon : blackWon;
    return userWon ? '1 - 0' : '0 - 1';
  }

  String _resultDisplayTitle() {
    final String title = _gameResultTitle ?? 'Game complete';
    final String lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('draw') ||
        lowerTitle.contains('challenge complete') ||
        _gameMode != GameMode.computer) {
      return title;
    }
    final bool whiteWon = lowerTitle.startsWith('white');
    final bool blackWon = lowerTitle.startsWith('black');
    if (!whiteWon && !blackWon) {
      return title;
    }
    final bool userWon = _humanPlaysWhite ? whiteWon : blackWon;
    return userWon ? 'You win' : 'ChessVerseAI wins';
  }

  DailyChallenge _challengeForToday(DailyChallengeDifficulty difficulty) {
    final DateTime today = DateTime.now();
    final int pattern = dailyChallengePatternForDate(today);
    final String date = dailyChallengeDateKey(today);
    final String title = switch (pattern % dailyChallengeQueenFiles.length) {
      0 => 'Royal Net',
      1 => 'Back Rank Spark',
      2 => 'Moonlight Mate',
      3 => 'Golden File',
      4 => 'Corner Storm',
      5 => 'Bishop Beacon',
      _ => 'Queen Flight',
    };
    return DailyChallenge(
      id: '$date-${difficulty.name}-p$pattern-freeplay-v7',
      title: '$title - ${difficulty.label}',
      difficulty: difficulty,
      pattern: pattern,
      setupMoves: _dailySetupLine(difficulty, pattern),
      solution: _dailySolutionLine(difficulty, pattern),
    );
  }

  DailyChallenge _challengeForPuzzle(ChessPuzzle puzzle) {
    final DailyChallengeDifficulty difficulty = switch (puzzle.difficulty) {
      PuzzleDifficulty.easy => DailyChallengeDifficulty.easy,
      PuzzleDifficulty.medium => DailyChallengeDifficulty.medium,
      PuzzleDifficulty.hard => DailyChallengeDifficulty.hard,
    };
    return DailyChallenge(
      id: puzzle.id,
      title: puzzle.title,
      difficulty: difficulty,
      pattern: puzzle.number - 1,
      setupMoves: const <String>[],
      solution: puzzle.solution,
      initialFen: puzzle.fen,
      forcedPlayerMoves: puzzle.playerMoveGoal,
    );
  }

  List<String> _dailySetupLine(
    DailyChallengeDifficulty difficulty,
    int pattern,
  ) {
    // Daily Checkmate starts from a composed late-game board, not a full
    // opening. Setup moves are intentionally empty so the player sees only the
    // puzzle position.
    return const <String>[];
  }

  List<String> _dailySolutionLine(
    DailyChallengeDifficulty difficulty,
    int pattern,
  ) {
    return dailyChallengeSolutionFor(difficulty, pattern);
  }

  Map<String, ChessPiece> _dailyStartingPosition(DailyChallenge challenge) {
    if (_gameMode == GameMode.puzzle && challenge.initialFen != null) {
      return _piecesFromFen(challenge.initialFen!);
    }
    final String queenFile =
        dailyChallengeQueenFileForPattern(challenge.pattern);
    final Map<String, ChessPiece> base = <String, ChessPiece>{
      // White mating force. Keep the king on f4 so the puzzle starts from a
      // legal position: f6 is attacked by the black g7 pawn, which made the
      // challenge feel locked because every normal move was rejected.
      'f4': const ChessPiece('K', true),
      '${queenFile}1': const ChessPiece('Q', true),
      // c2 protects h7. When today's queen starts on the c-file, b1 supplies
      // the same diagonal support without blocking the queen lift.
      if (queenFile == 'c')
        'b1': const ChessPiece('B', true)
      else
        'c2': const ChessPiece('B', true),
      'h2': const ChessPiece('P', true),
      'b4': const ChessPiece('P', true),
      if (queenFile != 'g') 'g2': const ChessPiece('P', true),
      // Black king is boxed by its own pawns; the final Qxh7# is protected
      // by the bishop on c2. Keeping d3 empty also leaves the queen's
      // a3-to-h3 forcing route unobstructed.
      'h8': const ChessPiece('K', false),
      'h7': const ChessPiece('P', false),
      'g7': const ChessPiece('P', false),
      'a7': const ChessPiece('P', false),
      'b7': const ChessPiece('P', false),
      'e6': const ChessPiece('P', false),
    };
    if (_gameMode != GameMode.puzzle) {
      // Daily challenge keeps its 49-day visual rotation.
      const List<Map<String, bool>> dailyScenery = <Map<String, bool>>[
        <String, bool>{'d2': true},
        <String, bool>{'f2': true, 'd7': false},
        <String, bool>{'e2': true, 'c7': false},
        <String, bool>{'f2': true, 'f7': false},
        <String, bool>{'d2': true, 'c6': false},
        <String, bool>{'e2': true, 'd7': false},
        <String, bool>{'d2': true, 'e7': false, 'f2': true},
      ];
      final int sceneryIndex =
          (challenge.pattern ~/ dailyChallengeQueenFiles.length) %
              dailyScenery.length;
      for (final MapEntry<String, bool> entry
          in dailyScenery[sceneryIndex].entries) {
        base[entry.key] = ChessPiece('P', entry.value);
      }
    }
    // Decorative pieces must never occupy today's queen travel squares.
    base.remove('${queenFile}2');
    base.remove('${queenFile}3');
    return base;
  }

  Map<String, ChessPiece> _piecesFromFen(String fen) {
    final String board = fen.trim().split(RegExp(r'\s+')).first;
    final List<String> ranks = board.split('/');
    if (ranks.length != 8) {
      throw StateError('Invalid curated puzzle FEN: $fen');
    }
    final Map<String, ChessPiece> pieces = <String, ChessPiece>{};
    const String files = 'abcdefgh';
    for (int rankIndex = 0; rankIndex < 8; rankIndex++) {
      int fileIndex = 0;
      for (final int rune in ranks[rankIndex].runes) {
        final String token = String.fromCharCode(rune);
        final int? empty = int.tryParse(token);
        if (empty != null) {
          fileIndex += empty;
          continue;
        }
        if (fileIndex >= 8 || !'prnbqkPRNBQK'.contains(token)) {
          throw StateError('Invalid curated puzzle FEN: $fen');
        }
        final bool white = token == token.toUpperCase();
        pieces['${files[fileIndex]}${8 - rankIndex}'] =
            ChessPiece(token.toUpperCase(), white);
        fileIndex++;
      }
      if (fileIndex != 8) {
        throw StateError('Invalid curated puzzle FEN: $fen');
      }
    }
    return pieces;
  }

  void _applyDailyCompletionState() {
    if (!_dailyCompletedToday || _gameMode != GameMode.daily) {
      return;
    }
    _gameResultTitle = 'Challenge complete';
    _gameResultDetail = _dailyUnlockMessage();
    _resultVisible = true;
    _coachNote = _dailyUnlockMessage();
  }

  void _completeDailyChallenge() {
    final bool firstCompletion = !_dailyCompletedToday;
    if (firstCompletion) {
      _dailyCompletedToday = true;
      LocalGameArchive.markDailyChallengeComplete(_dailyChallenge.id);
    }
    _gameResultTitle = 'Challenge complete';
    _gameResultDetail = _dailyUnlockMessage();
    _resultVisible = true;
    _coachNote =
        "Brilliant! Today's ${_dailyDifficulty.label.toLowerCase()} challenge is complete. "
        '${_dailyUnlockMessage()}';
    if (firstCompletion) {
      _archiveFinishedGame();
      unawaited(ChessSoundService.instance.checkmate());
    }
  }

  void _completePuzzle() {
    final bool firstCompletion =
        !LocalGameArchive.isPuzzleComplete(_activePuzzle.id);
    if (firstCompletion) {
      LocalGameArchive.markPuzzleSolved(_activePuzzle.id);
    }
    _gameResultTitle = 'Puzzle complete';
    _gameResultDetail =
        '${_activePuzzle.title} solved. Continue with the next puzzle anytime.';
    _resultVisible = true;
    _coachNote =
        'Brilliant! ${_activePuzzle.title} complete — no daily waiting limit.';
    if (firstCompletion) {
      _archiveFinishedGame();
      unawaited(ChessSoundService.instance.checkmate());
    }
  }

  String _dailyUnlockMessage() {
    final Duration remaining = LocalGameArchive.dailyChallengeRemaining;
    if (remaining == Duration.zero) {
      return 'A new Daily Checkmate is ready.';
    }
    final int hours = remaining.inHours;
    final int minutes = remaining.inMinutes.remainder(60);
    final int seconds = remaining.inSeconds.remainder(60);
    return 'Daily Checkmate complete. Next challenge unlocks in '
        '$hours ${hours == 1 ? 'hour' : 'hours'} '
        '$minutes ${minutes == 1 ? 'minute' : 'minutes'} '
        '$seconds ${seconds == 1 ? 'second' : 'seconds'}.';
  }

  void _handleSquareTap(String square) {
    // Hint/Analyze results belong to one exact board position. Invalidate
    // in-flight work before processing a touch so a late engine response
    // cannot paint an old move on the current board.
    _coachRequestEpoch++;
    _dismissTurnReminder();
    if (_coachArrowFrom != null || _coachArrowTo != null) {
      setState(() {
        _coachArrowFrom = null;
        _coachArrowTo = null;
      });
    }
    if (_gameResultTitle != null || _aiThinking) {
      return;
    }
    final OnlineMatchDto? onlineMatch = _onlineMatch;
    if (_gameMode == GameMode.online) {
      if (onlineMatch == null || !onlineMatch.isActive) {
        setState(() => _coachNote = 'Waiting for an online opponent.');
        return;
      }
      if (_onlineSubmitting) {
        return;
      }
      if (!onlineMatch.isYourTurn) {
        setState(() => _coachNote = _onlineStatusText(onlineMatch));
        return;
      }
    }
    if (_isTacticsMode && _dailyPlyIndex.isOdd) {
      _scheduleDailyReply();
      return;
    }
    String? promotionSquare;
    bool? promotionWhite;
    bool moveCommitted = false;
    bool puzzleWrongMove = false;
    String? onlineUci;
    int? onlineExpectedPly;
    String? engineReviewFen;
    String? engineReviewMove;

    setState(() {
      final bool whitesTurn =
          _gameMode == GameMode.online && onlineMatch != null
              ? onlineMatch.whiteToMove
              : _moves.length.isEven;
      if (_gameMode == GameMode.online && whitesTurn != _humanPlaysWhite) {
        _coachNote = 'Waiting for your opponent to move.';
        return;
      }
      if (_gameMode == GameMode.computer && whitesTurn != _humanPlaysWhite) {
        _coachNote = 'ChessVerseAI is calculating its reply.';
        return;
      }
      if (_selectedSquare == null) {
        final ChessPiece? piece = _pieces[square];
        if (piece == null) {
          _coachNote = 'Choose one of your coins first.';
          unawaited(ChessSoundService.instance.error());
          return;
        }
        if (piece.white != whitesTurn) {
          _coachNote = '${whitesTurn ? 'White' : 'Black'} to move.';
          unawaited(ChessSoundService.instance.error());
          return;
        }
        final List<String> targets = _legalTargetsFor(square);
        if (targets.isEmpty) {
          _coachNote = '${piece.code} has no legal target from $square.';
          unawaited(ChessSoundService.instance.error());
        } else {
          _selectedSquare = square;
          final String suffix = targets.length == 1 ? '' : 's';
          _coachNote =
              '${piece.code} from $square has ${targets.length} option$suffix.';
          unawaited(ChessSoundService.instance.tap());
        }
        return;
      }

      if (_selectedSquare == square) {
        _selectedSquare = null;
        unawaited(ChessSoundService.instance.tap());
        return;
      }

      final List<String> legalTargets = _legalTargetsFor(_selectedSquare!);
      if (!legalTargets.contains(square)) {
        _coachNote = 'That move is blocked. Pick a highlighted square.';
        _selectedSquare = null;
        unawaited(ChessSoundService.instance.error());
        return;
      }

      final String from = _selectedSquare!;
      if (_gameMode == GameMode.puzzle &&
          !_puzzleExplorationMode &&
          _dailyPlyIndex < _dailyChallenge.solution.length) {
        final String expected =
            _dailyChallenge.solution[_dailyPlyIndex].toLowerCase();
        if (!expected.startsWith('$from$square')) {
          // Every chess-legal move is playable. Leaving the curated line
          // starts exploration mode, where the defense continues replying.
          puzzleWrongMove = true;
          _puzzleExplorationMode = true;
        }
      }
      if (_gameMode == GameMode.computer && widget.useRemoteEngine) {
        engineReviewFen = _toFen();
        engineReviewMove = '$from$square';
      }
      _saveSnapshot();
      _lastFromSquare = from;
      _lastToSquare = square;
      _lastCaptureSquare = null;
      final bool castleMove = _isCastleMove(from, square);
      final String? enPassantCaptureSquare = _enPassantCaptureSquare(
        from,
        square,
      );
      final ChessPiece? piece = _pieces.remove(from);
      if (piece != null) {
        final ChessPiece? captured = enPassantCaptureSquare == null
            ? _pieces[square]
            : _pieces.remove(enPassantCaptureSquare);
        _lastMovedPiece = piece;
        _lastCapturedPiece = captured;
        if (captured != null) {
          if (captured.white) {
            _capturedWhite.add(captured);
          } else {
            _capturedBlack.add(captured);
          }
          _lastCaptureSquare = square;
        }
        _pieces[square] = piece;
        moveCommitted = true;
        if (castleMove) {
          _moveCastlingRook(square, piece.white);
        }
        final String move = castleMove
            ? (square.startsWith('g') ? 'O-O' : 'O-O-O')
            : enPassantCaptureSquare != null
                ? '$from x $square e.p.'
                : captured == null
                    ? '$from$square'
                    : '$from x $square';
        _moves.insert(0, move);
        if (_gameMode == GameMode.online) {
          final bool promotes = piece.code == 'P' &&
              ((piece.white && square.endsWith('8')) ||
                  (!piece.white && square.endsWith('1')));
          onlineUci = '$from$square${promotes ? 'q' : ''}';
          onlineExpectedPly = onlineMatch?.plyCount;
          if (promotes) {
            _pieces[square] = ChessPiece('Q', piece.white);
          }
        }
        unawaited(
          ChessSoundService.instance.pieceMove(
            piece.code,
            capture: captured != null,
          ),
        );
        if (_isTacticsMode && (!puzzleWrongMove || _puzzleExplorationMode)) {
          _dailyPlyIndex++;
        }
        final String moveFeedback = _moveFeedback(
          piece: piece,
          from: from,
          to: square,
          captured: captured,
          castleMove: castleMove,
        );
        if (_gameMode == GameMode.computer) {
          final int score = _scoreForMoveFeedback(moveFeedback);
          _playerMoveScores.add(score);
          if (score < 60) {
            _turningPoint = '$move — $moveFeedback';
            _recordImportantMistake('$move • $moveFeedback');
          }
        }
        if (_gameMode == GameMode.computer) {
          _moveQualityText = _scoreForMoveFeedback(moveFeedback) < 60
              ? '$moveFeedback Tap “Why is this weak?” in AI Coach to understand the safer plan.'
              : null;
        }
        _hintStage = 0;
        _lastPlayerMove = move;
        _coachNote = castleMove
            ? '${piece.white ? 'White' : 'Black'} castles ${square.startsWith('g') ? 'king side' : 'queen side'}.'
            : _coachMoveExplanation(
                piece: piece,
                from: from,
                to: square,
                captured: captured,
              );
        if (_gameMode != GameMode.online &&
            piece.code == 'P' &&
            ((piece.white && square.endsWith('8')) ||
                (!piece.white && square.endsWith('1')))) {
          promotionSquare = square;
          promotionWhite = piece.white;
          _coachNote = 'Choose a promotion coin for $square.';
        } else {
          _coachNote = _gameStateNote(!piece.white, fallback: _coachNote);
          if (_gameResultTitle == null) {
            _coachNote = '$moveFeedback $_coachNote';
          }
          _lastPlayerCoachNote = _coachNote;
          if (_gameMode == GameMode.puzzle && puzzleWrongMove) {
            // The curated objective no longer decides terminal state once the
            // player branches. Continue as a normal legal chess position.
            _gameResultTitle = null;
            _gameResultDetail = null;
            _resultVisible = false;
            _coachNote =
                'Legal move played. Exploration mode started; the defense will reply. '
                'Tap Try again anytime to return to the puzzle line.';
            _lastPlayerCoachNote = _coachNote;
            unawaited(ChessSoundService.instance.error());
          } else if (_isTacticsMode && !_puzzleExplorationMode) {
            final bool opponentMated = _isCheckmateFor(!piece.white);
            if (opponentMated) {
              if (_gameMode == GameMode.daily) {
                _completeDailyChallenge();
              } else {
                _completePuzzle();
              }
            } else if (_dailyPlayerMovesCompleted >=
                _dailyChallenge.playerMoveGoal) {
              _coachNote =
                  'The move limit ended before checkmate. This is not a loss. '
                  'Review the board, find the forcing checks first, then try again.';
              _gameResultTitle = 'Challenge missed';
              _gameResultDetail =
                  'No checkmate within ${_dailyChallenge.playerMoveGoal} moves. '
                  '${_gameMode == GameMode.daily ? 'Your daily attempt is still available.' : 'Try this puzzle again whenever you are ready.'}';
              _resultVisible = true;
            }
          }
        }
      }
      _selectedSquare = null;
    });

    if (promotionSquare != null && promotionWhite != null) {
      _showPromotionPicker(
        promotionSquare!,
        promotionWhite!,
      ).then((_) => _scheduleAiMove());
    } else if (moveCommitted) {
      if (engineReviewFen != null && engineReviewMove != null) {
        unawaited(
          _reviewPlayerMoveWithEngine(engineReviewFen!, engineReviewMove!),
        );
      }
      if (_moveQualityText != null) {
        _scheduleMoveQualityDismiss();
      }
      if (_gameMode == GameMode.online &&
          onlineUci != null &&
          onlineExpectedPly != null) {
        unawaited(_submitOnlineMove(onlineUci!, onlineExpectedPly!));
      } else {
        _scheduleAiMove();
      }
      if (_gameMode == GameMode.local) {
        _restartTurnReminder();
      }
    }
  }

  void _dismissTurnReminder() {
    _boardTouchedThisTurn = true;
    _turnReminderTimer?.cancel();
    if (_turnBannerVisible && mounted) {
      setState(() => _turnBannerVisible = false);
    }
  }

  void _restartTurnReminder() {
    _turnReminderTimer?.cancel();
    _boardTouchedThisTurn = false;
    if (!mounted || _gameResultTitle != null) return;
    setState(() => _turnBannerVisible = true);
    _scheduleTurnReminderStep(showing: true);
  }

  void _scheduleTurnReminderStep({required bool showing}) {
    _turnReminderTimer = Timer(
      showing ? const Duration(milliseconds: 1800) : const Duration(seconds: 5),
      () {
        if (!mounted || _boardTouchedThisTurn || _gameResultTitle != null) {
          return;
        }
        setState(() => _turnBannerVisible = !showing);
        _scheduleTurnReminderStep(showing: !showing);
      },
    );
  }

  Future<void> _reviewPlayerMoveWithEngine(
    String fen,
    String playedMove,
  ) async {
    try {
      final Map<String, dynamic> engine = await _engineApi.analyze(
        fen: fen,
        level: math.max(5, _aiLevel.round()),
      );
      if (!mounted) return;
      final String bestMove = engine['bestMove'] as String? ?? '';
      if (bestMove.length < 4) return;
      final bool best = bestMove.toLowerCase() == playedMove.toLowerCase();
      final String recommendation =
          '${bestMove.substring(0, 2)} to ${bestMove.substring(2, 4)}';
      final int cp = (engine['evaluationCp'] as num?)?.toInt() ?? 0;
      setState(() {
        _engineEvaluationPawns = cp / 100;
        // Post-move review is textual. Board arrows are reserved for an
        // explicit Hint/Analyze request so a completed move never leaves two
        // competing motion trails on the board.
        _coachArrowFrom = null;
        _coachArrowTo = null;
        if (_playerMoveScores.isNotEmpty) {
          _playerMoveScores[_playerMoveScores.length - 1] = best ? 100 : 68;
        }
        _moveQualityText = best
            ? null
            : 'Weak move alert • $recommendation was safer. Tap Analyze to see why.';
        if (!best) {
          _turningPoint ??= '$playedMove — $recommendation was stronger.';
          _recordImportantMistake(
            '$playedMove • Prefer $recommendation. '
            '${_engineEvaluationExplanation(engine, _moves.length.isOdd)}',
          );
        }
      });
      if (!best) _scheduleMoveQualityDismiss();
    } on EngineApiException {
      // Keep the immediate on-device coach feedback when analysis is offline.
    }
  }

  int _scoreForMoveFeedback(String feedback) {
    if (feedback.startsWith('Amazing')) return 96;
    if (feedback.startsWith('Superb')) return 90;
    if (feedback.startsWith('Good')) return 82;
    if (feedback.startsWith('Not good')) return 48;
    return 68;
  }

  void _recordImportantMistake(String message) {
    _importantMistakes.remove(message);
    _importantMistakes.insert(0, message);
    if (_importantMistakes.length > 3) {
      _importantMistakes.removeLast();
    }
  }

  int? get _playerAccuracy {
    if (_playerMoveScores.isEmpty) return null;
    final int total = _playerMoveScores.fold<int>(0, (int a, int b) => a + b);
    return (total / _playerMoveScores.length).round().clamp(0, 100);
  }

  String? _kingSquare(bool white) {
    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.code == 'K' && entry.value.white == white) {
        return entry.key;
      }
    }
    return null;
  }

  void _scheduleAiMove() {
    if (_isTacticsMode) {
      _scheduleDailyReply();
      return;
    }
    final bool aiPlaysWhite = !_humanPlaysWhite;
    final bool aiTurn = _moves.length.isEven == aiPlaysWhite;
    if (_gameMode != GameMode.computer ||
        !aiTurn ||
        _gameResultTitle != null ||
        _aiThinking) {
      return;
    }

    final int requestEpoch = ++_aiMoveEpoch;
    _aiWatchdogTimer?.cancel();
    setState(() {
      _aiThinking = true;
      _selectedSquare = null;
      _coachNote =
          '${aiProfileFor(_aiLevel.round()).name} AI is calculating...';
    });
    Future<void>.delayed(
      aiThinkDelayFor(_aiLevel.round()),
      () => _performAiMove(requestEpoch),
    );
    _aiWatchdogTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted ||
          requestEpoch != _aiMoveEpoch ||
          !_aiThinking ||
          _gameResultTitle != null) {
        return;
      }
      final bool stillAiTurn = _moves.length.isEven == aiPlaysWhite;
      setState(() {
        _aiThinking = false;
        _coachNote = stillAiTurn
            ? 'AI reply recovered. Calculating again...'
            : 'Your turn.';
      });
      if (stillAiTurn) _scheduleAiMove();
    });
  }

  void _scheduleDailyReply() {
    if (_dailyPlyIndex.isEven || _gameResultTitle != null || _aiThinking) {
      return;
    }
    setState(() {
      _aiThinking = true;
      _selectedSquare = null;
      _coachNote = 'Puzzle defense is replying...';
    });
    Future<void>.delayed(const Duration(milliseconds: 520), _performDailyReply);
  }

  void _performDailyReply() {
    if (!mounted || !_isTacticsMode || !_aiThinking || _dailyPlyIndex.isEven) {
      return;
    }
    final List<AiCandidate> replies = <AiCandidate>[];
    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white) {
        continue;
      }
      for (final String target in _legalTargetsFor(entry.key)) {
        final ChessPiece? captured = _pieces[target];
        final double captureScore = captured == null
            ? 0
            : <String, double>{
                  'P': 1,
                  'N': 3.2,
                  'B': 3.3,
                  'R': 5,
                  'Q': 9,
                }[captured.code] ??
                0;
        replies.add(
          AiCandidate(
            entry.key,
            target,
            captureScore * 10 + _random.nextDouble(),
          ),
        );
      }
    }
    if (replies.isEmpty) {
      setState(() {
        _aiThinking = false;
        _coachNote = _gameStateNote(
          false,
          fallback: 'Black has no legal reply.',
        );
      });
      return;
    }
    replies.sort((AiCandidate a, AiCandidate b) => b.score.compareTo(a.score));
    AiCandidate reply = replies.first;
    if (!_puzzleExplorationMode &&
        _dailyPlyIndex < _dailyChallenge.solution.length) {
      final String plannedMove = _dailyChallenge.solution[_dailyPlyIndex];
      if (plannedMove.length >= 4) {
        final String plannedFrom = plannedMove.substring(0, 2);
        final String plannedTo = plannedMove.substring(2, 4);
        for (final AiCandidate candidate in replies) {
          if (candidate.from == plannedFrom && candidate.to == plannedTo) {
            reply = candidate;
            break;
          }
        }
      }
    }
    final String from = reply.from;
    final String to = reply.to;

    setState(() {
      _saveSnapshot();
      _lastFromSquare = from;
      _lastToSquare = to;
      _lastCaptureSquare = null;
      final ChessPiece piece = _pieces.remove(from)!;
      final ChessPiece? captured = _pieces[to];
      _lastMovedPiece = piece;
      _lastCapturedPiece = captured;
      if (captured != null) {
        captured.white
            ? _capturedWhite.add(captured)
            : _capturedBlack.add(captured);
        _lastCaptureSquare = to;
      }
      _pieces[to] = piece;
      _moves.insert(0, captured == null ? '$from$to' : '$from x $to');
      unawaited(
        ChessSoundService.instance.pieceMove(
          piece.code,
          capture: captured != null,
        ),
      );
      _dailyPlyIndex++;
      _aiThinking = false;
      _coachNote = _gameStateNote(
        true,
        fallback:
            '${_dailyChallenge.playerMoveGoal - _dailyPlayerMovesCompleted} move(s) remain. Find checkmate.',
      );
    });
    _restartTurnReminder();
  }

  Future<void> _performAiMove(int requestEpoch) async {
    final bool aiPlaysWhite = !_humanPlaysWhite;
    final bool aiTurn = _moves.length.isEven == aiPlaysWhite;
    if (!mounted ||
        _gameMode != GameMode.computer ||
        _gameResultTitle != null ||
        !_aiThinking ||
        !aiTurn ||
        requestEpoch != _aiMoveEpoch) {
      return;
    }

    AiCandidate? engineMove;
    final int level = _aiLevel.round();
    // Stockfish's UCI_LimitStrength floor is still club-player strength.
    // Keep levels 1-3 on the deliberately imperfect local selector.
    if (widget.useRemoteEngine && level >= 4) {
      try {
        final Map<String, dynamic> response = await _engineApi.bestMove(
          fen: _toFen(),
          level: _aiLevel.round(),
        );
        final String uci = response['move'] as String? ?? '';
        if (uci.length >= 4) {
          final String from = uci.substring(0, 2);
          final String to = uci.substring(2, 4);
          if (_isLegalMove(from, to, whiteToMove: aiPlaysWhite)) {
            engineMove = AiCandidate(from, to, 1000);
          }
        }
      } on Object {
        // Malformed, timed-out, and unavailable engine responses all fall
        // back locally so the board can never remain stuck on "AI turn".
      }
    }

    final bool aiStillTurn = _moves.length.isEven == aiPlaysWhite;
    if (!mounted ||
        _gameMode != GameMode.computer ||
        _gameResultTitle != null ||
        !_aiThinking ||
        !aiStillTurn ||
        requestEpoch != _aiMoveEpoch) {
      return;
    }

    final List<AiCandidate> candidates = <AiCandidate>[];
    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white != aiPlaysWhite) {
        continue;
      }
      for (final String target in _legalTargetsFor(entry.key)) {
        final ChessPiece? captured = _pieces[target];
        final SquarePosition targetPosition = ChessRules.positionOf(target);
        final double centerBonus = 3.5 -
            (targetPosition.file - 3.5).abs() +
            3.5 -
            (targetPosition.rank - 4.5).abs();
        final double captureScore = captured == null
            ? 0
            : <String, double>{
                  'P': 1,
                  'N': 3.2,
                  'B': 3.3,
                  'R': 5,
                  'Q': 9,
                  'K': 100,
                }[captured.code] ??
                0;
        candidates.add(
          AiCandidate(
            entry.key,
            target,
            captureScore * 10 + centerBonus + _random.nextDouble(),
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      _aiWatchdogTimer?.cancel();
      setState(() {
        _aiThinking = false;
        _coachNote = _gameStateNote(
          aiPlaysWhite,
          fallback: 'ChessVerseAI has no legal move.',
        );
      });
      return;
    }

    candidates.sort(
      (AiCandidate a, AiCandidate b) => b.score.compareTo(a.score),
    );
    final AiCandidate move = chooseAiCandidateForLevel(
      candidates,
      level,
      _random,
      engineMove: engineMove,
    );
    final bool stockfishPowered = engineMove != null;

    _aiWatchdogTimer?.cancel();
    setState(() {
      _saveSnapshot();
      _lastFromSquare = move.from;
      _lastToSquare = move.to;
      _lastCaptureSquare = null;
      final bool castleMove = _isCastleMove(move.from, move.to);
      final String? enPassantCaptureSquare = _enPassantCaptureSquare(
        move.from,
        move.to,
      );
      final ChessPiece piece = _pieces.remove(move.from)!;
      final ChessPiece? captured = enPassantCaptureSquare == null
          ? _pieces[move.to]
          : _pieces.remove(enPassantCaptureSquare);
      _lastMovedPiece = piece;
      _lastCapturedPiece = captured;
      if (captured != null) {
        captured.white
            ? _capturedWhite.add(captured)
            : _capturedBlack.add(captured);
        _lastCaptureSquare = move.to;
      }
      _pieces[move.to] = piece;
      if (castleMove) {
        _moveCastlingRook(move.to, piece.white);
      }
      if (piece.code == 'P' &&
          ((piece.white && move.to.endsWith('8')) ||
              (!piece.white && move.to.endsWith('1')))) {
        _pieces[move.to] = ChessPiece('Q', piece.white);
      }
      final String notation = castleMove
          ? (move.to.startsWith('g') ? 'O-O' : 'O-O-O')
          : captured == null
              ? '${move.from}${move.to}'
              : '${move.from} x ${move.to}';
      _moves.insert(0, notation);
      unawaited(
        ChessSoundService.instance.pieceMove(
          piece.code,
          capture: captured != null,
        ),
      );
      final String action = captured == null
          ? '${piece.code} moves to ${move.to}.'
          : '${piece.code} captures ${captured.code} on ${move.to}.';
      _coachNote = _gameStateNote(
        !piece.white,
        fallback: '${stockfishPowered ? 'Stockfish' : 'Offline AI'}: $action',
      );
      _aiThinking = false;
    });
    _restartTurnReminder();
  }

  String _toFen() {
    final List<String> ranks = <String>[];
    for (int rank = 8; rank >= 1; rank--) {
      int empty = 0;
      final StringBuffer row = StringBuffer();
      for (int file = 0; file < 8; file++) {
        final String square = '${String.fromCharCode(97 + file)}$rank';
        final ChessPiece? piece = _pieces[square];
        if (piece == null) {
          empty++;
          continue;
        }
        if (empty > 0) {
          row.write(empty);
          empty = 0;
        }
        row.write(piece.white ? piece.code : piece.code.toLowerCase());
      }
      if (empty > 0) {
        row.write(empty);
      }
      ranks.add(row.toString());
    }

    final String side = _moves.length.isEven ? 'w' : 'b';
    final String castling = _fenCastlingRights();
    final String enPassant = _fenEnPassantSquare();
    final int fullMove = _moves.length ~/ 2 + 1;
    return '${ranks.join('/')} $side $castling $enPassant 0 $fullMove';
  }

  String _fenCastlingRights() {
    final StringBuffer rights = StringBuffer();
    if (_pieces['e1']?.code == 'K' &&
        _pieces['e1']?.white == true &&
        !_hasMovedFrom('e1')) {
      if (_pieces['h1']?.code == 'R' &&
          _pieces['h1']?.white == true &&
          !_hasMovedFrom('h1')) {
        rights.write('K');
      }
      if (_pieces['a1']?.code == 'R' &&
          _pieces['a1']?.white == true &&
          !_hasMovedFrom('a1')) {
        rights.write('Q');
      }
    }
    if (_pieces['e8']?.code == 'K' &&
        _pieces['e8']?.white == false &&
        !_hasMovedFrom('e8')) {
      if (_pieces['h8']?.code == 'R' &&
          _pieces['h8']?.white == false &&
          !_hasMovedFrom('h8')) {
        rights.write('k');
      }
      if (_pieces['a8']?.code == 'R' &&
          _pieces['a8']?.white == false &&
          !_hasMovedFrom('a8')) {
        rights.write('q');
      }
    }
    return rights.isEmpty ? '-' : rights.toString();
  }

  String _fenEnPassantSquare() {
    if (_moves.isEmpty) {
      return '-';
    }
    final ParsedMove? last = _parseMove(_moves.first);
    if (last == null || _pieces[last.to]?.code != 'P') {
      return '-';
    }
    final int fromRank = int.parse(last.from.substring(1));
    final int toRank = int.parse(last.to.substring(1));
    if ((fromRank - toRank).abs() != 2) {
      return '-';
    }
    return '${last.to.substring(0, 1)}${(fromRank + toRank) ~/ 2}';
  }

  List<String> _legalTargetsFor(String square) {
    final ChessPiece? piece = _pieces[square];
    if (piece == null) {
      return <String>[];
    }

    final Set<String> targets = ChessRules.safeLegalTargets(
      square,
      _pieces,
    ).toSet();
    targets.addAll(_castlingTargets(square, piece));
    targets.addAll(_enPassantTargets(square, piece));
    return targets.toList();
  }

  List<String> _castlingTargets(String from, ChessPiece piece) {
    if (piece.code != 'K' || _hasMovedFrom(from)) {
      return <String>[];
    }

    final String rank = piece.white ? '1' : '8';
    if (from != 'e$rank' || ChessRules.isKingInCheck(piece.white, _pieces)) {
      return <String>[];
    }

    final List<String> targets = <String>[];
    if (_canCastle(
      white: piece.white,
      rookFrom: 'h$rank',
      emptySquares: <String>['f$rank', 'g$rank'],
      kingPath: <String>['f$rank', 'g$rank'],
    )) {
      targets.add('g$rank');
    }
    if (_canCastle(
      white: piece.white,
      rookFrom: 'a$rank',
      emptySquares: <String>['b$rank', 'c$rank', 'd$rank'],
      kingPath: <String>['d$rank', 'c$rank'],
    )) {
      targets.add('c$rank');
    }

    return targets;
  }

  bool _canCastle({
    required bool white,
    required String rookFrom,
    required List<String> emptySquares,
    required List<String> kingPath,
  }) {
    final ChessPiece? rook = _pieces[rookFrom];
    if (rook == null ||
        rook.code != 'R' ||
        rook.white != white ||
        _hasMovedFrom(rookFrom)) {
      return false;
    }

    for (final String square in emptySquares) {
      if (_pieces.containsKey(square)) {
        return false;
      }
    }

    for (final String square in kingPath) {
      final Map<String, ChessPiece> next = ChessRules.applyMove(
        white ? 'e1' : 'e8',
        square,
        _pieces,
      );
      if (ChessRules.isKingInCheck(white, next)) {
        return false;
      }
    }
    return true;
  }

  List<String> _enPassantTargets(String from, ChessPiece piece) {
    if (piece.code != 'P' || _moves.isEmpty) {
      return <String>[];
    }

    final ParsedMove? lastMove = _parseMove(_moves.first);
    if (lastMove == null) {
      return <String>[];
    }

    final ChessPiece? movedPiece = _pieces[lastMove.to];
    if (movedPiece == null ||
        movedPiece.code != 'P' ||
        movedPiece.white == piece.white) {
      return <String>[];
    }

    final SquarePosition fromPosition = ChessRules.positionOf(lastMove.from);
    final SquarePosition toPosition = ChessRules.positionOf(lastMove.to);
    if ((fromPosition.rank - toPosition.rank).abs() != 2) {
      return <String>[];
    }

    final SquarePosition pawnPosition = ChessRules.positionOf(from);
    final int requiredRank = piece.white ? 5 : 4;
    if (pawnPosition.rank != requiredRank ||
        (pawnPosition.file - toPosition.file).abs() != 1 ||
        pawnPosition.rank != toPosition.rank) {
      return <String>[];
    }

    final String target = ChessRules.squareOf(
      toPosition.file,
      pawnPosition.rank + (piece.white ? 1 : -1),
    );
    final Map<String, ChessPiece> next = Map<String, ChessPiece>.from(_pieces)
      ..remove(from)
      ..remove(lastMove.to);
    next[target] = piece;

    return ChessRules.isKingInCheck(piece.white, next)
        ? <String>[]
        : <String>[target];
  }

  bool _isCastleMove(String from, String to) {
    final ChessPiece? piece = _pieces[from];
    return piece != null &&
        piece.code == 'K' &&
        from.startsWith('e') &&
        (to.startsWith('g') || to.startsWith('c'));
  }

  void _moveCastlingRook(String kingTarget, bool white) {
    final String rank = white ? '1' : '8';
    if (kingTarget == 'g$rank') {
      final ChessPiece? rook = _pieces.remove('h$rank');
      if (rook != null) {
        _pieces['f$rank'] = rook;
      }
    } else if (kingTarget == 'c$rank') {
      final ChessPiece? rook = _pieces.remove('a$rank');
      if (rook != null) {
        _pieces['d$rank'] = rook;
      }
    }
  }

  String? _enPassantCaptureSquare(String from, String to) {
    final ChessPiece? piece = _pieces[from];
    if (piece == null || piece.code != 'P' || _pieces.containsKey(to)) {
      return null;
    }

    final SquarePosition fromPosition = ChessRules.positionOf(from);
    final SquarePosition toPosition = ChessRules.positionOf(to);
    if ((fromPosition.file - toPosition.file).abs() != 1) {
      return null;
    }

    final String captureSquare = ChessRules.squareOf(
      toPosition.file,
      fromPosition.rank,
    );
    final ChessPiece? captured = _pieces[captureSquare];
    if (captured == null ||
        captured.code != 'P' ||
        captured.white == piece.white) {
      return null;
    }
    return captureSquare;
  }

  bool _hasMovedFrom(String square) {
    for (final String move in _moves) {
      final ParsedMove? parsed = _parseMove(move);
      if (parsed?.from == square) {
        return true;
      }
    }
    return false;
  }

  ParsedMove? _parseMove(String move) {
    if (move.startsWith('O-O')) {
      return null;
    }

    final String cleaned =
        move.replaceAll(' x ', '').replaceAll(' e.p.', '').split('=').first;
    if (cleaned.length < 4) {
      return null;
    }
    return ParsedMove(cleaned.substring(0, 2), cleaned.substring(2, 4));
  }

  void _reset() {
    if (_gameMode == GameMode.online && _onlineMatch != null) {
      unawaited(_refreshOnlineMatch(forceBoardReplay: true));
      return;
    }
    final DailyChallenge challenge = _gameMode == GameMode.puzzle
        ? _challengeForPuzzle(_activePuzzle)
        : _challengeForToday(_dailyDifficulty);
    final bool completedToday = LocalGameArchive.isDailyChallengeComplete(
      challenge.id,
    );
    if (_isTacticsMode) {
      _humanPlaysWhite = true;
    }
    final Map<String, ChessPiece> resetPieces = _isTacticsMode
        ? _dailyStartingPosition(challenge)
        : Map<String, ChessPiece>.from(_initialPieces);
    _aiWatchdogTimer?.cancel();
    _aiMoveEpoch++;
    setState(() {
      _applyPlayerSideNames(_playerDisplayName);
      _dailyChallenge = challenge;
      _dailyCompletedToday = completedToday;
      _dailyPlyIndex = 0;
      _puzzleExplorationMode = false;
      _pieces = resetPieces;
      _moves.clear();
      _capturedWhite.clear();
      _capturedBlack.clear();
      _history.clear();
      _lastFromSquare = null;
      _lastToSquare = null;
      _lastCaptureSquare = null;
      _lastMovedPiece = null;
      _lastCapturedPiece = null;
      _lastPlayerMove = null;
      _lastPlayerCoachNote = null;
      _moveQualityText = null;
      _coachArrowFrom = null;
      _coachArrowTo = null;
      _engineEvaluationPawns = 0;
      _playerMoveScores.clear();
      _importantMistakes.clear();
      _turningPoint = null;
      _whiteSeconds = 10 * 60;
      _blackSeconds = 10 * 60;
      _selectedSquare = null;
      _aiThinking = false;
      _coachNote = _gameMode == GameMode.daily
          ? completedToday
              ? _dailyUnlockMessage()
              : 'Move any legal white coin. Checkmate in ${challenge.playerMoveGoal} moves.'
          : _gameMode == GameMode.puzzle
              ? '${_activePuzzle.title}: checkmate in ${challenge.playerMoveGoal} moves.'
              : 'Select a coin to see legal moves.';
      _gameResultTitle = completedToday && _gameMode == GameMode.daily
          ? 'Challenge complete'
          : null;
      _gameResultDetail = completedToday && _gameMode == GameMode.daily
          ? _dailyUnlockMessage()
          : null;
      _resultVisible = true;
      _resultSaved = false;
      _checkWarningActive = false;
    });
    _restartTurnReminder();
    if (_gameMode == GameMode.computer && !_humanPlaysWhite) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scheduleAiMove();
        }
      });
    }
  }

  void _startNextPuzzle() {
    final ChessPuzzle? next = PuzzleCatalog.nextAfter(_activePuzzle.id);
    _activePuzzle =
        next ?? PuzzleCatalog.forDifficulty(_activePuzzle.difficulty).first;
    _dailyDifficulty = switch (_activePuzzle.difficulty) {
      PuzzleDifficulty.easy => DailyChallengeDifficulty.easy,
      PuzzleDifficulty.medium => DailyChallengeDifficulty.medium,
      PuzzleDifficulty.hard => DailyChallengeDifficulty.hard,
    };
    _reset();
  }

  Future<void> _confirmNewGame() async {
    if (_gameMode == GameMode.online && _onlineMatch?.status == 'FINISHED') {
      await _startFreshOnlineGame();
      return;
    }
    if (_moves.isEmpty && _gameResultTitle == null) {
      _reset();
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Start new game?'),
        content: const Text(
          'Current board will be cleared. Finished games are saved automatically.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('New game'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _reset();
    }
  }

  void _setSoundEnabled(bool value) {
    setState(() => _soundEnabled = value);
    ChessSoundService.instance.enabled = value;
  }

  void _archiveFinishedGame() {
    if (_resultSaved || _gameResultTitle == null) {
      return;
    }
    _resultSaved = true;
    LocalGameArchive.addGame(
      SavedGameRecord(
        mode: switch (_gameMode) {
          GameMode.computer => 'Play vs AI',
          GameMode.daily => 'Daily Checkmate',
          GameMode.puzzle => 'Puzzle Academy',
          GameMode.local => '2 Players',
          GameMode.online => 'Online',
        },
        result: _gameResultTitle!,
        detail: _gameResultDetail ?? 'Game complete',
        moves: List<String>.from(_moves.reversed),
        playedAt: DateTime.now(),
        whitePlayer: _whitePlayerName,
        blackPlayer: _blackPlayerName,
      ),
    );
  }

  void _showMoveHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => MoveHistorySheet(moves: _moves),
    );
  }

  void _showAiReview() {
    final AiReviewReport report = AiReviewReport.fromMoves(
      _moves,
      result: _gameResultTitle,
      knownAccuracy: _playerAccuracy,
      knownTurningPoint: _turningPoint,
      knownMistakes: _importantMistakes.reversed.toList(growable: false),
    );
    showAdaptiveAiReview(context, report: report);
  }

  void _saveSnapshot() {
    if (_gameMode == GameMode.online) {
      return;
    }
    _history.add(
      GameSnapshot(
        pieces: Map<String, ChessPiece>.from(_pieces),
        moves: List<String>.from(_moves),
        capturedWhite: List<ChessPiece>.from(_capturedWhite),
        capturedBlack: List<ChessPiece>.from(_capturedBlack),
        coachNote: _coachNote,
        lastFromSquare: _lastFromSquare,
        lastToSquare: _lastToSquare,
        lastCaptureSquare: _lastCaptureSquare,
        whiteSeconds: _whiteSeconds,
        blackSeconds: _blackSeconds,
      ),
    );
    if (_history.length > 80) {
      _history.removeAt(0);
    }
  }

  void _undo() {
    // A finished result is authoritative. Undo must never reopen a won,
    // checkmated, drawn, or completed challenge.
    if (_gameResultTitle != null) return;
    if (_gameMode == GameMode.online) {
      setState(() {
        _selectedSquare = null;
        _coachNote =
            'Online moves are final. Syncing the authoritative match...';
      });
      unawaited(_refreshOnlineMatch(forceBoardReplay: true));
      return;
    }
    if (_history.isEmpty) {
      return;
    }

    // In computer mode restore the newest snapshot where it is the human's
    // turn. This works both while AI is thinking (one ply to undo) and after
    // its reply (two plies), without leaving an unscheduled AI turn.
    final int snapshotIndex = _gameMode == GameMode.computer
        ? computerUndoSnapshotIndex(
            _history,
            humanPlaysWhite: _humanPlaysWhite,
          )
        : (_isTacticsMode && _history.length >= 2
            ? _history.length - 2
            : _history.length - 1);
    if (snapshotIndex < 0) return;
    _aiMoveEpoch++;
    _aiWatchdogTimer?.cancel();
    setState(() {
      final GameSnapshot snapshot = _history[snapshotIndex];
      _history.removeRange(snapshotIndex, _history.length);
      _pieces = Map<String, ChessPiece>.from(snapshot.pieces);
      _moves
        ..clear()
        ..addAll(snapshot.moves);
      if (_isTacticsMode) {
        _dailyPlyIndex = _moves.length;
      }
      _capturedWhite
        ..clear()
        ..addAll(snapshot.capturedWhite);
      _capturedBlack
        ..clear()
        ..addAll(snapshot.capturedBlack);
      _lastFromSquare = snapshot.lastFromSquare;
      _lastToSquare = snapshot.lastToSquare;
      _lastCaptureSquare = snapshot.lastCaptureSquare;
      _lastMovedPiece = null;
      _lastCapturedPiece = null;
      _lastPlayerMove = null;
      _lastPlayerCoachNote = null;
      _whiteSeconds = snapshot.whiteSeconds;
      _blackSeconds = snapshot.blackSeconds;
      _selectedSquare = null;
      _aiThinking = false;
      _gameResultTitle = null;
      _gameResultDetail = null;
      _resultVisible = true;
      _checkWarningActive = ChessRules.isKingInCheck(
        _moves.length.isEven,
        _pieces,
      );
      _coachNote = 'Move undone. ${snapshot.coachNote}';
    });
  }

  Future<void> _showHint() async {
    final bool whiteToMove = _isTacticsMode ? true : _moves.length.isEven;
    final int hintStage = (_hintStage % 3) + 1;
    setState(() => _hintStage = hintStage);
    if (_gameMode == GameMode.computer && widget.useRemoteEngine) {
      final int requestEpoch = ++_coachRequestEpoch;
      final String requestedFen = _toFen();
      try {
        setState(() => _coachNote = 'Stockfish is finding your best plan…');
        final Map<String, dynamic> engine = await _engineApi.analyze(
          fen: requestedFen,
          level: math.max(4, _aiLevel.round()),
        );
        if (!mounted ||
            requestEpoch != _coachRequestEpoch ||
            requestedFen != _toFen()) {
          return;
        }
        final String move = engine['bestMove'] as String? ?? '';
        if (move.length >= 4) {
          final String from = move.substring(0, 2);
          final String to = move.substring(2, 4);
          setState(() {
            _selectedSquare = hintStage >= 1 ? from : null;
            _coachArrowFrom = hintStage == 3 ? from : null;
            _coachArrowTo = hintStage == 3 ? to : null;
            final int cp = (engine['evaluationCp'] as num?)?.toInt() ?? 0;
            _engineEvaluationPawns = cp / 100;
            _coachNote = _progressiveHintText(
              stage: hintStage,
              from: from,
              to: to,
              explanation: _engineEvaluationExplanation(engine, whiteToMove),
            );
          });
          return;
        }
      } on EngineApiException {
        // Continue with the always-available local hint below.
      }
    }
    String? bestFrom;
    List<String> bestTargets = <String>[];

    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white != whiteToMove) {
        continue;
      }
      final List<String> targets = _legalTargetsFor(entry.key);
      if (targets.length > bestTargets.length) {
        bestFrom = entry.key;
        bestTargets = targets;
      }
    }

    setState(() {
      _selectedSquare = bestFrom;
      if (bestFrom == null) {
        _coachNote = 'No legal moves found.';
      } else {
        final int remaining =
            _dailyChallenge.playerMoveGoal - _dailyPlayerMovesCompleted;
        final String bestTo = bestTargets.first;
        _coachArrowFrom = hintStage == 3 ? bestFrom : null;
        _coachArrowTo = hintStage == 3 ? bestTo : null;
        _coachNote = _progressiveHintText(
          stage: hintStage,
          from: bestFrom,
          to: bestTo,
          explanation: _isTacticsMode
              ? '$remaining move(s) remain. Look for forcing checks first.'
              : 'Compare checks, captures, and threats before moving.',
        );
      }
    });
  }

  String _progressiveHintText({
    required int stage,
    required String from,
    required String to,
    required String explanation,
  }) {
    final ChessPiece? piece = _pieces[from];
    final String name = piece == null ? 'piece' : pieceName(piece.code);
    final SquarePosition target = ChessRules.positionOf(to);
    final String direction =
        target.file >= 4 ? 'toward the king side' : 'toward the queen side';
    final bool simpleLanguage = _aiLevel <= 3;
    return switch (stage) {
      1 => simpleLanguage
          ? 'Hint 1/3 • Start with the $name on $from.'
          : 'Piece hint 1/3 • Candidate: $name on $from. Check its forcing options.',
      2 => simpleLanguage
          ? 'Hint 2/3 • Move that $name $direction.'
          : 'Direction hint 2/3 • Improve the $name $direction and challenge the centre.',
      _ => simpleLanguage
          ? 'Hint 3/3 • Try $from → $to. $explanation'
          : 'Exact move 3/3 • Calculate $from → $to. $explanation',
    };
  }

  Future<void> _showAnalysis() async {
    final bool whiteToMove = _moves.length.isEven;
    PositionAnalysis analysis = _analyzePosition(whiteToMove);
    if (_gameMode == GameMode.computer && widget.useRemoteEngine) {
      final int requestEpoch = ++_coachRequestEpoch;
      final String requestedFen = _toFen();
      try {
        setState(() => _coachNote = 'Running Stockfish position analysis…');
        final Map<String, dynamic> engine = await _engineApi.analyze(
          fen: requestedFen,
          level: math.max(5, _aiLevel.round()),
        );
        if (!mounted ||
            requestEpoch != _coachRequestEpoch ||
            requestedFen != _toFen()) {
          return;
        }
        final String best = engine['bestMove'] as String? ?? '';
        final int cp = (engine['evaluationCp'] as num?)?.toInt() ?? 0;
        final int? mate = (engine['mateIn'] as num?)?.toInt();
        final List<dynamic> pv =
            engine['principalVariation'] as List<dynamic>? ?? <dynamic>[];
        analysis = PositionAnalysis(
          side: whiteToMove ? 'White' : 'Black',
          evaluation: mate == null
              ? (whiteToMove ? cp : -cp) / 100
              : (mate > 0 ? 99 : -99),
          material: analysis.material,
          legalMoves: analysis.legalMoves,
          captures: analysis.captures,
          bestMove: best.length >= 4
              ? '${best.substring(0, 2)} to ${best.substring(2, 4)}'
              : analysis.bestMove,
          quality: mate == null
              ? 'Stockfish depth ${engine['depth']}'
              : 'Forced mate',
          coachLine: '${_engineEvaluationExplanation(engine, whiteToMove)} '
              '${pv.isEmpty ? '' : 'Plan: ${pv.take(5).join(' → ')}.'}',
          inCheck: analysis.inCheck,
        );
        if (best.length >= 4) {
          setState(() {
            _coachArrowFrom = best.substring(0, 2);
            _coachArrowTo = best.substring(2, 4);
            _engineEvaluationPawns = (whiteToMove ? cp : -cp) / 100;
          });
        }
      } on EngineApiException {
        // The local analysis remains useful while the engine is offline.
      }
    }

    setState(() {
      _coachNote = analysis.bestMove == null
          ? 'Analysis complete. No legal move is available.'
          : 'Coach recommends ${analysis.bestMove} for ${analysis.side}.';
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          PositionAnalysisSheet(analysis: analysis),
    );
  }

  PositionAnalysis _analyzePosition(bool whiteToMove) {
    int legalMoveCount = 0;
    int captureCount = 0;
    AiCandidate? bestMove;

    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white != whiteToMove) {
        continue;
      }
      for (final String target in _legalTargetsFor(entry.key)) {
        legalMoveCount++;
        if (_pieces[target] != null) {
          captureCount++;
        }
        final AiCandidate candidate = AiCandidate(
          entry.key,
          target,
          _analysisMoveScore(entry.key, target, entry.value),
        );
        if (bestMove == null || candidate.score > bestMove.score) {
          bestMove = candidate;
        }
      }
    }

    int material = 0;
    for (final ChessPiece piece in _pieces.values) {
      final int value = _pieceValue(piece.code);
      material += piece.white ? value : -value;
    }

    final double evaluation =
        material + (whiteToMove ? legalMoveCount : -legalMoveCount) * 0.03;
    final double bestScore = bestMove?.score ?? 0;
    final String quality = bestMove == null
        ? 'No move'
        : bestScore >= 14
            ? 'Best move'
            : bestScore >= 7
                ? 'Good move'
                : bestScore >= 3
                    ? 'Ordinary move'
                    : 'Quiet move';
    final String coachLine = bestMove == null
        ? 'No legal move is available in this position.'
        : bestScore >= 14
            ? 'This move creates a strong tactical threat or wins material.'
            : bestScore >= 7
                ? 'This is a healthy move: it improves the position and keeps pressure.'
                : bestScore >= 3
                    ? 'Playable, but keep looking for forcing checks, captures, or threats.'
                    : 'Safe but quiet. A sharper move may exist if you calculate forcing lines.';
    return PositionAnalysis(
      side: whiteToMove ? 'White' : 'Black',
      evaluation: evaluation,
      material: material,
      legalMoves: legalMoveCount,
      captures: captureCount,
      bestMove: bestMove == null ? null : '${bestMove.from} to ${bestMove.to}',
      quality: quality,
      coachLine: coachLine,
      inCheck: ChessRules.isKingInCheck(whiteToMove, _pieces),
    );
  }

  double _analysisMoveScore(String from, String target, ChessPiece piece) {
    final ChessPiece? captured = _pieces[target];
    final SquarePosition position = ChessRules.positionOf(target);
    final double center =
        7 - (position.file - 3.5).abs() - (position.rank - 4.5).abs();
    final double capture = captured == null
        ? 0
        : _pieceValue(captured.code) * 10 - _pieceValue(piece.code) * 0.2;
    final Map<String, ChessPiece> next = ChessRules.applyMove(
      from,
      target,
      _pieces,
    );
    final bool givesCheck = ChessRules.isKingInCheck(!piece.white, next);
    return capture + center + (givesCheck ? 6 : 0);
  }

  int _pieceValue(String code) {
    return switch (code) {
      'P' => 1,
      'N' => 3,
      'B' => 3,
      'R' => 5,
      'Q' => 9,
      _ => 0,
    };
  }

  Future<void> _showOnlineMatchmakingInfo() async {
    String? token = _authToken;
    token ??= (await _sessionStore.read())?.token;
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to play online and reconnect matches.'),
        ),
      );
      return;
    }
    final OnlineMatchDto? match =
        await Navigator.of(context).push<OnlineMatchDto>(
      MaterialPageRoute<OnlineMatchDto>(
        fullscreenDialog: true,
        builder: (BuildContext context) => Scaffold(
          backgroundColor: const Color(0xFF06131F),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFF0A2231), Color(0xFF040B13)],
              ),
            ),
            child: OnlineMatchmakingSheet(
              api: _onlineApi,
              token: token!,
            ),
          ),
        ),
      ),
    );
    if (match != null && mounted) {
      _beginOnlineMatch(match, token);
    } else if (mounted &&
        _gameMode == GameMode.online &&
        _onlineMatch == null) {
      Navigator.of(context).maybePop();
    }
  }

  void _beginOnlineMatch(OnlineMatchDto match, String token) {
    final bool newMatch = _onlineMatch?.id != match.id;
    _onlinePollTimer?.cancel();
    unawaited(_onlineSocketSubscription?.cancel());
    unawaited(_onlineChannel?.sink.close());
    setState(() {
      _authToken = token;
      _onlineMatch = match;
      _gameMode = GameMode.online;
      _humanPlaysWhite = match.yourColor.toLowerCase() == 'white';
      _whitePlayerName = match.whitePlayerName ?? 'White player';
      _blackPlayerName = match.blackPlayerName ?? 'Black player';
      _whitePlayerPhotoUrl = match.whitePlayerPhotoUrl ??
          (_humanPlaysWhite ? widget.initialProfilePhotoUrl : null);
      _blackPlayerPhotoUrl = match.blackPlayerPhotoUrl ??
          (!_humanPlaysWhite ? widget.initialProfilePhotoUrl : null);
      _coachNote = _onlineStatusText(match);
      if (newMatch) {
        _onlineResultPresentationTimer?.cancel();
        _onlineCelebrationMatchId = null;
        _gameResultTitle = null;
        _gameResultDetail = null;
        _resultVisible = false;
        _resultSaved = false;
        _selectedSquare = null;
        _lastFromSquare = null;
        _lastToSquare = null;
        _lastCaptureSquare = null;
        _handledDrawOfferKey = null;
        _onlineConnectedPlayers = 0;
        _onlineSocketConnected = false;
      }
    });
    // A restored/reconnected match must always replay its authoritative move
    // list. `_onlineMatch` was just assigned above, so the normal same-board
    // fast path would otherwise leave a fresh local board at the start
    // position while showing the server's clocks and turn.
    _rebuildFromOnline(match, forceBoardReplay: true);
    _onlinePollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_refreshOnlineMatch()),
    );
    _connectOnlineSocket(token, match.id);
  }

  void _connectOnlineSocket(String token, String matchId) {
    _onlineSocketReconnectTimer?.cancel();
    _onlineHeartbeatTimer?.cancel();
    try {
      final WebSocketChannel channel =
          _onlineApi.openMatchChannel(token, matchId);
      _onlineChannel = channel;
      _onlineHeartbeatTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) {
          try {
            channel.sink.add('{"type":"heartbeat"}');
          } on Object {
            // Stream callbacks schedule the reconnect path.
          }
        },
      );
      _onlineSocketSubscription = channel.stream.listen(
        (dynamic event) {
          _handleOnlineSocketEvent(event);
          unawaited(_refreshOnlineMatch());
        },
        onError: (_) => _scheduleOnlineSocketReconnect(token, matchId),
        onDone: () => _scheduleOnlineSocketReconnect(token, matchId),
        cancelOnError: true,
      );
    } on Object {
      _scheduleOnlineSocketReconnect(token, matchId);
    }
  }

  void _scheduleOnlineSocketReconnect(String token, String matchId) {
    if (!mounted || _onlineMatch?.id != matchId) return;
    setState(() => _onlineSocketConnected = false);
    _onlineHeartbeatTimer?.cancel();
    _onlineSocketReconnectTimer?.cancel();
    _onlineSocketReconnectTimer = Timer(
      const Duration(seconds: 3),
      () => _connectOnlineSocket(token, matchId),
    );
  }

  String _onlineStatusText(OnlineMatchDto match) {
    if (match.status == 'FINISHED') {
      return _onlineResultDetail(match);
    }
    if (!match.isActive) {
      return 'Room ${match.roomCode}: waiting for your opponent.';
    }
    if (match.opponentDisconnected) {
      return 'Opponent left. You win in ${match.disconnectSecondsRemaining}s if they do not reconnect.';
    }
    if (_onlineConnectedPlayers == 1) {
      return 'Opponent connection lost. Waiting for reconnect...';
    }
    if (match.drawOfferedByColor != null) {
      final bool yours = match.drawOfferedByColor!.toLowerCase() ==
          match.yourColor.toLowerCase();
      if (yours) return 'Draw offer sent. Waiting for your opponent.';
      return 'Your opponent offered a draw.';
    }
    final bool yourTurn =
        match.activeColor.toLowerCase() == match.yourColor.toLowerCase();
    return yourTurn
        ? 'Your turn (${match.yourColor}).'
        : 'Waiting for ${match.activeColor} to move.';
  }

  Future<void> _refreshOnlineMatch({
    bool forceBoardReplay = false,
  }) async {
    final OnlineMatchDto? current = _onlineMatch;
    final String? token = _authToken;
    if (current == null || token == null || _onlineSubmitting) return;
    try {
      final OnlineMatchDto latest =
          await _onlineApi.getMatch(token, current.id);
      if (!mounted) return;
      _rebuildFromOnline(
        latest,
        forceBoardReplay: forceBoardReplay,
      );
    } on OnlineMatchException catch (error) {
      if (!mounted) return;
      setState(() => _coachNote = 'Reconnect pending: ${error.message}');
    }
  }

  void _rebuildFromOnline(
    OnlineMatchDto match, {
    bool forceBoardReplay = false,
  }) {
    final OnlineMatchDto? previous = _onlineMatch;
    final bool sameBoard = !forceBoardReplay &&
        previous != null &&
        previous.id == match.id &&
        previous.plyCount == match.plyCount &&
        previous.whitePlayerName == match.whitePlayerName &&
        previous.blackPlayerName == match.blackPlayerName;
    if (sameBoard) {
      setState(() {
        _onlineMatch = match;
        _whiteSeconds = (match.whiteTimeMs / 1000).ceil();
        _blackSeconds = (match.blackTimeMs / 1000).ceil();
        _coachNote = _onlineStatusText(match);
      });
      _applyOnlineLifecycle(match);
      return;
    }
    final Map<String, ChessPiece> board =
        Map<String, ChessPiece>.from(_initialPieces);
    final List<String> history = <String>[];
    final List<ChessPiece> capturedWhite = <ChessPiece>[];
    final List<ChessPiece> capturedBlack = <ChessPiece>[];
    ChessPiece? replayLastMovedPiece;
    ChessPiece? replayLastCapturedPiece;
    String? replayLastCaptureSquare;
    for (final OnlineMoveDto remoteMove in match.moves) {
      final String uci = remoteMove.uci.toLowerCase();
      if (uci.length < 4) continue;
      final String from = uci.substring(0, 2);
      final String to = uci.substring(2, 4);
      ChessPiece? piece = board.remove(from);
      if (piece == null) continue;
      ChessPiece? captured = board.remove(to);
      if (piece.code == 'P' && captured == null && from[0] != to[0]) {
        final String enPassantSquare = '${to[0]}${from[1]}';
        captured = board.remove(enPassantSquare);
      }
      if (captured != null) {
        (captured.white ? capturedWhite : capturedBlack).add(captured);
      }
      if (piece.code == 'K' &&
          (from.codeUnitAt(0) - to.codeUnitAt(0)).abs() == 2) {
        final bool kingSide = to.startsWith('g');
        final String rookFrom = '${kingSide ? 'h' : 'a'}${from[1]}';
        final String rookTo = '${kingSide ? 'f' : 'd'}${from[1]}';
        final ChessPiece? rook = board.remove(rookFrom);
        if (rook != null) board[rookTo] = rook;
      }
      if (uci.length >= 5) {
        piece = ChessPiece(uci[4].toUpperCase(), piece.white);
      }
      board[to] = piece;
      replayLastMovedPiece = piece;
      replayLastCapturedPiece = captured;
      replayLastCaptureSquare = captured == null ? null : to;
      history.insert(
        0,
        captured == null ? '$from$to' : '$from x $to',
      );
    }
    setState(() {
      _onlineMatch = match;
      _pieces = board;
      _moves
        ..clear()
        ..addAll(history);
      _capturedWhite
        ..clear()
        ..addAll(capturedWhite);
      _capturedBlack
        ..clear()
        ..addAll(capturedBlack);
      _history.clear();
      _whitePlayerName = match.whitePlayerName ?? 'White player';
      _blackPlayerName = match.blackPlayerName ?? 'Black player';
      _whitePlayerPhotoUrl = match.whitePlayerPhotoUrl ??
          (_humanPlaysWhite ? widget.initialProfilePhotoUrl : null);
      _blackPlayerPhotoUrl = match.blackPlayerPhotoUrl ??
          (!_humanPlaysWhite ? widget.initialProfilePhotoUrl : null);
      _whiteSeconds = (match.whiteTimeMs / 1000).ceil();
      _blackSeconds = (match.blackTimeMs / 1000).ceil();
      _coachNote = _onlineStatusText(match);
      _selectedSquare = null;
      if (match.moves.isEmpty) {
        _lastFromSquare = null;
        _lastToSquare = null;
        _lastCaptureSquare = null;
        _lastMovedPiece = null;
        _lastCapturedPiece = null;
      } else {
        final String lastUci = match.moves.last.uci.toLowerCase();
        _lastFromSquare = lastUci.length >= 4 ? lastUci.substring(0, 2) : null;
        _lastToSquare = lastUci.length >= 4 ? lastUci.substring(2, 4) : null;
        _lastCaptureSquare = replayLastCaptureSquare;
        _lastMovedPiece = replayLastMovedPiece;
        _lastCapturedPiece = replayLastCapturedPiece;
      }
    });
    _applyOnlineLifecycle(match);
    if (match.status == 'ACTIVE' && match.moves.isNotEmpty) {
      final bool sideToMoveWhite = match.whiteToMove;
      final String stateNote = _gameStateNote(
        sideToMoveWhite,
        fallback: _onlineStatusText(match),
      );
      if (mounted) {
        setState(() => _coachNote = stateNote);
      }
    }
  }

  void _resumeOnlineSession() {
    final OnlineMatchDto? match = _onlineMatch;
    final String? token = _authToken;
    if (match == null || token == null) return;
    _onlineSubmitting = false;
    _onlineSocketReconnectTimer?.cancel();
    _onlineHeartbeatTimer?.cancel();
    unawaited(_onlineSocketSubscription?.cancel());
    unawaited(_onlineChannel?.sink.close());
    _onlinePollTimer?.cancel();
    _onlinePollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_refreshOnlineMatch()),
    );
    unawaited(_refreshOnlineMatch(forceBoardReplay: true));
    _connectOnlineSocket(token, match.id);
  }

  Future<void> _startFreshOnlineGame() async {
    _onlinePollTimer?.cancel();
    _onlineSocketReconnectTimer?.cancel();
    _onlineHeartbeatTimer?.cancel();
    await _onlineSocketSubscription?.cancel();
    await _onlineChannel?.sink.close();
    if (!mounted) return;
    setState(() {
      _onlineMatch = null;
      _onlineSubmitting = false;
      _onlineConnectedPlayers = 0;
      _onlineSocketConnected = false;
      _selectedSquare = null;
      _lastFromSquare = null;
      _lastToSquare = null;
      _lastCaptureSquare = null;
      _gameResultTitle = null;
      _gameResultDetail = null;
      _resultVisible = false;
      _resultSaved = false;
      _handledDrawOfferKey = null;
      _joiningRematchId = null;
      _onlineResultPresentationTimer?.cancel();
      _onlineCelebrationMatchId = null;
      _coachNote = 'Choose how you want to start your next online match.';
    });
    await _showOnlineMatchmakingInfo();
  }

  Future<void> _submitOnlineMove(String uci, int expectedPly) async {
    final OnlineMatchDto? current = _onlineMatch;
    final String? token = _authToken;
    if (current == null || token == null || _onlineSubmitting) return;
    setState(() {
      _onlineSubmitting = true;
      _coachNote = 'Sending $uci to your opponent...';
    });
    try {
      final OnlineMatchDto latest = await _onlineApi.submitMove(
        token,
        current.id,
        uci: uci,
        expectedPly: expectedPly,
      );
      if (!mounted) return;
      _rebuildFromOnline(latest);
    } on OnlineMatchException catch (error) {
      if (!mounted) return;
      setState(() {
        _onlineSubmitting = false;
        _coachNote = 'Move not accepted: ${error.message}';
      });
      await _refreshOnlineMatch(forceBoardReplay: true);
    } finally {
      if (mounted) {
        setState(() => _onlineSubmitting = false);
      }
    }
  }

  void _handleOnlineSocketEvent(dynamic event) {
    if (event is! String) return;
    try {
      final Object? decoded = jsonDecode(event);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      if (mounted && !_onlineSocketConnected) {
        setState(() => _onlineSocketConnected = true);
      }
      if (decoded['type'] != 'presence.updated') return;
      final int connected = (decoded['connectedPlayers'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() {
        _onlineConnectedPlayers = connected;
        _onlineSocketConnected = true;
        if (_onlineMatch?.isActive == true && connected < 2) {
          _coachNote = 'Opponent connection lost. Waiting for reconnect...';
        }
      });
    } on FormatException {
      // Ignore non-JSON socket frames; polling remains the source of truth.
    }
  }

  Future<void> _respondOnlineDraw(bool accept) async {
    final OnlineMatchDto? match = _onlineMatch;
    final String? token = _authToken;
    if (match == null || token == null) return;
    try {
      _rebuildFromOnline(
        await _onlineApi.respondDraw(token, match.id, accept: accept),
      );
    } on OnlineMatchException catch (error) {
      if (mounted) setState(() => _coachNote = error.message);
    }
  }

  Future<void> _requestOnlineRematch() async {
    final OnlineMatchDto? match = _onlineMatch;
    final String? token = _authToken;
    if (match == null || token == null || match.status != 'FINISHED') return;
    setState(() {
      _resultVisible = false;
      _coachNote = 'Rematch requested. Waiting for your opponent...';
    });
    try {
      final OnlineMatchDto next =
          await _onlineApi.requestRematch(token, match.id);
      if (!mounted) return;
      if (next.id != match.id) {
        _beginOnlineMatch(next, token);
      } else {
        _rebuildFromOnline(next);
      }
    } on OnlineMatchException catch (error) {
      if (mounted) setState(() => _coachNote = error.message);
    }
  }

  void _applyOnlineLifecycle(OnlineMatchDto match) {
    final String? rematchId = match.rematchMatchId;
    if (rematchId != null &&
        rematchId != match.id &&
        _joiningRematchId != rematchId) {
      _joiningRematchId = rematchId;
      final String? token = _authToken;
      if (token != null) {
        unawaited(_joinCreatedRematch(token, rematchId));
      }
      return;
    }
    if (match.status == 'FINISHED') {
      final String result = match.result ?? '1/2-1/2';
      final bool userWhite = match.yourColor.toLowerCase() == 'white';
      final bool userWon =
          (result == '1-0' && userWhite) || (result == '0-1' && !userWhite);
      final bool draw = result == '1/2-1/2';
      final bool firstPresentation = _archivedOnlineMatchId != match.id;
      final bool decisive = result == '1-0' || result == '0-1';
      setState(() {
        _gameResultTitle = draw
            ? 'Draw'
            : userWon
                ? 'You win'
                : 'Opponent wins';
        _gameResultDetail = _onlineResultDetail(match);
        if (firstPresentation) {
          // Keep the decisive move visible. The celebration occupies the
          // winner's side of the board first; the score/action popup follows
          // after the player has had time to identify the final move.
          _resultVisible = false;
          _onlineCelebrationMatchId = match.id;
        }
        _coachNote = _onlineResultDetail(match);
      });
      if (firstPresentation) {
        _onlineResultPresentationTimer?.cancel();
        _onlineResultPresentationTimer = Timer(
          const Duration(seconds: 10),
          () {
            if (!mounted || _onlineCelebrationMatchId != match.id) return;
            setState(() {
              _resultVisible = true;
            });
          },
        );
        if (decisive) {
          unawaited(ChessSoundService.instance.victory());
        } else {
          unawaited(ChessSoundService.instance.draw());
        }
      }
      if (_archivedOnlineMatchId != match.id) {
        _archivedOnlineMatchId = match.id;
        _archiveFinishedGame();
      }
      return;
    }
    final String? offeredBy = match.drawOfferedByColor;
    if (offeredBy == null ||
        offeredBy.toLowerCase() == match.yourColor.toLowerCase()) {
      return;
    }
    final String key = '${match.id}:$offeredBy:${match.plyCount}';
    if (_handledDrawOfferKey == key) return;
    _handledDrawOfferKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _onlineMatch?.id != match.id) return;
      final bool? accept = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Draw offer'),
          content: const Text('Your opponent is offering a draw.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Accept draw'),
            ),
          ],
        ),
      );
      if (accept != null) await _respondOnlineDraw(accept);
    });
  }

  Future<void> _joinCreatedRematch(String token, String rematchId) async {
    try {
      final OnlineMatchDto rematch =
          await _onlineApi.getMatch(token, rematchId);
      if (!mounted || _joiningRematchId != rematchId) return;
      _joiningRematchId = null;
      _beginOnlineMatch(rematch, token);
    } on OnlineMatchException catch (error) {
      if (!mounted) return;
      _joiningRematchId = null;
      setState(
          () => _coachNote = 'Rematch reconnect pending: ${error.message}');
    }
  }

  String _onlineResultDetail(OnlineMatchDto match) {
    final String reason = switch (match.resultReason) {
      'CHECKMATE' => 'Checkmate',
      'RESIGNATION' => 'Match ended by resignation',
      'TIMEOUT' => 'Match ended on time',
      'STALEMATE' => 'Stalemate',
      'DRAW_AGREEMENT' => 'Draw agreed',
      'OPPONENT_LEFT' => 'Opponent left the match',
      'BOTH_DISCONNECTED' => 'Both players disconnected',
      _ => 'Online match complete',
    };
    final int? ratingDelta =
        match.ratingBefore == null || match.ratingAfter == null
            ? null
            : match.ratingAfter! - match.ratingBefore!;
    final String ratingText = ratingDelta == null
        ? ''
        : ' • ELO ${ratingDelta >= 0 ? '+' : ''}$ratingDelta';
    final bool userWhite = match.yourColor.toUpperCase() == 'WHITE';
    final bool userWon = (match.result == '1-0' && userWhite) ||
        (match.result == '0-1' && !userWhite);
    final int coinsEarned = userWon ? 26 : 8;
    return '${match.result ?? ''} • $reason$ratingText • Coins +$coinsEarned';
  }

  Future<void> _showPromotionPicker(String square, bool white) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191A1F),
          title: const Text('Promote pawn'),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <String>['Q', 'R', 'B', 'N'].map((String code) {
              return PromotionChoice(
                piece: ChessPiece(code, white),
                onSelected: () {
                  setState(() {
                    _pieces[square] = ChessPiece(code, white);
                    _moves[0] = '${_moves.first}=$code';
                    _coachNote = _gameStateNote(
                      !white,
                      fallback: 'Pawn promoted to $code on $square.',
                    );
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _gameStateNote(bool sideToMoveWhite, {required String fallback}) {
    final bool inCheck = ChessRules.isKingInCheck(sideToMoveWhite, _pieces);
    // Terminal results must use the exact same legal-move source as the board.
    // This includes castling and en passant, which the stateless ChessRules
    // helpers cannot infer without this game's move history.
    final bool checkmate = _isCheckmateFor(sideToMoveWhite);
    final bool stalemate = _isStalemateFor(sideToMoveWhite);
    final String side = sideToMoveWhite ? 'White' : 'Black';

    if (inCheck && !_checkWarningActive) {
      _checkWarningActive = true;
      unawaited(ChessSoundService.instance.check());
      unawaited(_playCheckWarning());
    } else if (!inCheck) {
      _checkWarningActive = false;
    }

    if (checkmate) {
      if (_isTacticsMode && !sideToMoveWhite) {
        if (_gameMode == GameMode.daily) {
          _completeDailyChallenge();
          return 'Checkmate. Daily challenge complete.';
        }
        _completePuzzle();
        return 'Checkmate. Puzzle complete.';
      }
      _gameResultTitle = '${sideToMoveWhite ? 'Black' : 'White'} wins';
      _gameResultDetail = 'Checkmate';
      _delayLocalResultOverlay();
      _archiveFinishedGame();
      unawaited(ChessSoundService.instance.checkmate());
      return 'Checkmate. $_gameResultTitle.';
    }
    if (stalemate) {
      _gameResultTitle = 'Draw';
      _gameResultDetail = 'Stalemate';
      _delayLocalResultOverlay();
      _archiveFinishedGame();
      unawaited(ChessSoundService.instance.draw());
      return 'Stalemate. No legal move for $side.';
    }
    if (inCheck) {
      return '$side is in check.';
    }
    return fallback;
  }

  void _delayLocalResultOverlay() {
    _onlineResultPresentationTimer?.cancel();
    _resultVisible = false;
    _onlineResultPresentationTimer = Timer(
      const Duration(seconds: 10),
      () {
        if (!mounted || _gameMode == GameMode.online) return;
        setState(() => _resultVisible = true);
      },
    );
  }

  String _coachMoveExplanation({
    required ChessPiece piece,
    required String from,
    required String to,
    required ChessPiece? captured,
  }) {
    final String pieceName = switch (piece.code) {
      'P' => 'Pawn',
      'N' => 'Knight',
      'B' => 'Bishop',
      'R' => 'Rook',
      'Q' => 'Queen',
      'K' => 'King',
      _ => 'Piece',
    };
    final bool givesCheck = ChessRules.isKingInCheck(!piece.white, _pieces);
    final SquarePosition target = ChessRules.positionOf(to);
    final bool controlsCenter = target.file >= 2 &&
        target.file <= 5 &&
        target.rank >= 3 &&
        target.rank <= 6;
    final String sourceSquare = from.toLowerCase();
    final String targetSquare = to.toLowerCase();
    final String action = captured == null
        ? '$pieceName moved from $sourceSquare to $targetSquare.'
        : '$pieceName captured ${_pieceName(captured.code)} on $targetSquare.';
    final String piecePurpose = switch (piece.code) {
      'P' => controlsCenter
          ? 'The pawn claims central space and opens lines for your pieces.'
          : 'The pawn changes the structure; check the squares it now protects.',
      'N' =>
        'The knight attacks in an L-shape; inspect its new forks and protected squares.',
      'B' => 'The bishop opens a diagonal; trace it until the first blocker.',
      'R' =>
        'The rook works on ranks and files; look for an open file or king pressure.',
      'Q' =>
        'The queen creates threats in several directions; verify it cannot be chased.',
      'K' =>
        'The king move changes king safety; recheck every enemy check on the new square.',
      _ => 'Compare the checks, captures, and threats created by the move.',
    };
    if (givesCheck && captured != null) {
      return '$action Strong forcing move: it wins material and checks the king, so the opponent must respond to the check. $piecePurpose';
    }
    if (givesCheck) {
      return '$action This is a forcing check. Now calculate every legal king escape, capture, and blocking move. $piecePurpose';
    }
    if (captured != null) {
      return '$action Before the next move, compare the traded piece values and check whether the capturing piece is protected. $piecePurpose';
    }
    if (controlsCenter) {
      return '$action $piecePurpose Central control gives your pieces more space and mobility.';
    }
    return '$action $piecePurpose Next, look for a check, capture, or direct threat.';
  }

  String _pieceName(String code) => switch (code) {
        'P' => 'a pawn',
        'N' => 'a knight',
        'B' => 'a bishop',
        'R' => 'a rook',
        'Q' => 'the queen',
        'K' => 'the king',
        _ => 'a piece',
      };

  Future<void> _playCheckWarning() async {
    if (!ChessSoundService.instance.enabled) {
      return;
    }
    try {
      final AudioPlayer player = _warningPlayer ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource('audio/check-warning.wav'), volume: 0.72);
    } catch (_) {
      // A muted device or browser policy should never interrupt the game.
    }
  }

  String _engineEvaluationExplanation(
    Map<String, dynamic> engine,
    bool _,
  ) {
    final int? mate = (engine['mateIn'] as num?)?.toInt();
    if (mate != null) {
      return mate > 0
          ? 'There is a forced checkmate in $mate.'
          : 'You must defend against checkmate in ${mate.abs()}.';
    }
    final int cp = (engine['evaluationCp'] as num?)?.toInt() ?? 0;
    final double pawns = cp.abs() / 100;
    if (cp.abs() < 25) return 'The position is approximately balanced.';
    final String side = cp > 0 ? 'the side to move' : 'the defending side';
    return 'Stockfish estimates a ${pawns.toStringAsFixed(1)} pawn advantage for $side.';
  }

  String _formatClock(int seconds) {
    final int safeSeconds = math.max(0, seconds);
    final int minutes = safeSeconds ~/ 60;
    final int remainder = safeSeconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}

class CompactHeader extends StatelessWidget {
  const CompactHeader({
    required this.onHome,
    required this.onProfile,
    required this.onReset,
    required this.onLogout,
    super.key,
  });

  final VoidCallback onHome;
  final VoidCallback onProfile;
  final VoidCallback onReset;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          key: const ValueKey<String>('mobile-back-to-home'),
          tooltip: 'Back to Home',
          onPressed: onHome,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const ChessVerseMark(size: 36),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            const TextSpan(
              children: <InlineSpan>[
                TextSpan(text: 'ChessVerse '),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(color: Color(0xFFEABF61)),
                ),
              ],
            ),
            semanticsLabel: 'ChessVerseAI',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: onProfile,
          icon: const Icon(Icons.person_rounded),
        ),
        IconButton(
          tooltip: 'Reset board',
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class ChessVerseMark extends StatelessWidget {
  const ChessVerseMark({this.size = 38, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/branding/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'ChessVerseAI logo',
      ),
    );
  }
}

class BoardStage extends StatelessWidget {
  const BoardStage({required this.palette, required this.child, super.key});

  final BoardPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.62),
            blurRadius: 38,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.24),
            blurRadius: 26,
            spreadRadius: -4,
            offset: const Offset(-5, -7),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                Colors.white.withValues(alpha: 0.22),
                palette.frame,
              ),
              Color.alphaBlend(
                palette.accent.withValues(alpha: 0.18),
                palette.frame,
              ),
              Color.alphaBlend(
                Colors.black.withValues(alpha: 0.42),
                palette.frame,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1.4,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: palette.accent.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(padding: const EdgeInsets.all(1), child: child),
          ),
        ),
      ),
    );
  }
}

class ChessBoard extends StatefulWidget {
  const ChessBoard({
    required this.pieces,
    required this.selectedSquare,
    required this.legalTargets,
    required this.lastFromSquare,
    required this.lastToSquare,
    required this.lastCaptureSquare,
    this.lastMovedPiece,
    this.lastCapturedPiece,
    required this.moveSequence,
    required this.checkedKingSquare,
    required this.decisiveSquare,
    this.fallenKingSquare,
    this.fallenKingWhite,
    required this.coachArrowFrom,
    required this.coachArrowTo,
    required this.flipped,
    required this.showCoordinates,
    required this.palette,
    required this.onSquareTap,
    super.key,
  });

  final Map<String, ChessPiece> pieces;
  final String? selectedSquare;
  final Set<String> legalTargets;
  final String? lastFromSquare;
  final String? lastToSquare;
  final String? lastCaptureSquare;
  final ChessPiece? lastMovedPiece;
  final ChessPiece? lastCapturedPiece;
  final int moveSequence;
  final String? checkedKingSquare;
  final String? decisiveSquare;
  final String? fallenKingSquare;
  final bool? fallenKingWhite;
  final String? coachArrowFrom;
  final String? coachArrowTo;
  final bool flipped;
  final bool showCoordinates;
  final BoardPalette palette;
  final ValueChanged<String> onSquareTap;

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  Timer? _animationTimer;
  String? _activeMoveToken;

  String? _moveToken(ChessBoard board) {
    final ChessPiece? moved = board.lastMovedPiece;
    if (board.lastFromSquare == null ||
        board.lastToSquare == null ||
        moved == null) {
      return null;
    }
    final ChessPiece? captured = board.lastCapturedPiece;
    return '${board.moveSequence}:${board.lastFromSquare}:'
        '${board.lastToSquare}:${moved.white}:${moved.code}:'
        '${captured?.white}:${captured?.code}';
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _activeMoveToken = null;
  }

  void _startAnimation(String token) {
    _animationTimer?.cancel();
    setState(() => _activeMoveToken = token);
    _animationTimer = Timer(
      Duration(
        milliseconds: widget.lastCapturedPiece == null ? 400 : 520,
      ),
      () {
        if (!mounted || _activeMoveToken != token) {
          return;
        }
        setState(() => _activeMoveToken = null);
      },
    );
  }

  @override
  void didUpdateWidget(covariant ChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? oldToken = _moveToken(oldWidget);
    final String? newToken = _moveToken(widget);
    if (newToken == null) {
      _stopAnimation();
    } else if (newToken != oldToken) {
      _startAnimation(newToken);
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, ChessPiece> pieces = widget.pieces;
    final String? selectedSquare = widget.selectedSquare;
    final Set<String> legalTargets = widget.legalTargets;
    final String? lastFromSquare = widget.lastFromSquare;
    final String? lastToSquare = widget.lastToSquare;
    final String? lastCaptureSquare = widget.lastCaptureSquare;
    final ChessPiece? lastMovedPiece = widget.lastMovedPiece;
    final ChessPiece? lastCapturedPiece = widget.lastCapturedPiece;
    final int moveSequence = widget.moveSequence;
    final String? checkedKingSquare = widget.checkedKingSquare;
    final String? decisiveSquare = widget.decisiveSquare;
    final bool flipped = widget.flipped;
    final bool showCoordinates = widget.showCoordinates;
    final BoardPalette palette = widget.palette;
    final ValueChanged<String> onSquareTap = widget.onSquareTap;
    final bool moveAnimating =
        _activeMoveToken != null && _activeMoveToken == _moveToken(widget);

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: <Widget>[
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 64,
              itemBuilder: (BuildContext context, int index) {
                final int row = index ~/ 8;
                final int col = index % 8;
                final int file = flipped ? 7 - col : col;
                final int rank = flipped ? row + 1 : 8 - row;
                final String square = '${String.fromCharCode(97 + file)}$rank';
                final bool dark = (row + col).isOdd;
                final bool selected = square == selectedSquare;
                final bool kingFallen = square == widget.fallenKingSquare;
                // A checkmating move must leave the losing king visible.  Do
                // not let the short destination-piece animation hide it, and
                // recover gracefully from older saved positions that removed
                // the king instead of ending on checkmate.
                final ChessPiece? boardPiece = pieces[square];
                final ChessPiece? piece = kingFallen
                    ? (boardPiece ??
                        ChessPiece('K', widget.fallenKingWhite ?? true))
                    : moveAnimating && square == lastToSquare
                        ? null
                        : boardPiece;
                final bool legalTarget = legalTargets.contains(square);
                final bool captureTarget =
                    legalTarget && piece != null && square != selectedSquare;
                final bool lastMoveSquare =
                    square == lastFromSquare || square == lastToSquare;
                final bool lastCapture = square == lastCaptureSquare;
                final bool checkedKing = square == checkedKingSquare;
                final bool decisiveMove = square == decisiveSquare;
                return BoardSquare(
                  key: ValueKey<String>('square-$square'),
                  square: square,
                  dark: dark,
                  selected: selected,
                  legalTarget: legalTarget,
                  captureTarget: captureTarget,
                  lastMoveSquare: lastMoveSquare,
                  lastCapture: lastCapture,
                  checkedKing: checkedKing,
                  decisiveMove: decisiveMove,
                  kingFallen: kingFallen,
                  palette: palette,
                  piece: piece,
                  showRank: showCoordinates && col == 0,
                  showFile: showCoordinates && row == 7,
                  onTap: () => onSquareTap(square),
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.10),
                        blurRadius: 18,
                        spreadRadius: -6,
                        offset: const Offset(-8, -8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        spreadRadius: -6,
                        offset: const Offset(8, 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (lastFromSquare != null &&
                lastToSquare != null &&
                (widget.coachArrowFrom == null || widget.coachArrowTo == null))
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>(
                      'move-trail-$lastFromSquare-$lastToSquare-$flipped',
                    ),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 560),
                    curve: Curves.easeOutCubic,
                    builder:
                        (BuildContext context, double progress, Widget? child) {
                      return CustomPaint(
                        painter: LastMoveTrailPainter(
                          from: lastFromSquare,
                          to: lastToSquare,
                          flipped: flipped,
                          progress: progress,
                          accent: palette.accent,
                          // Keep the latest move visible until the next move.
                          // The old fade made the arrow look like a brief flash.
                          fadeOut: false,
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (widget.coachArrowFrom != null && widget.coachArrowTo != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LastMoveTrailPainter(
                      from: widget.coachArrowFrom!,
                      to: widget.coachArrowTo!,
                      flipped: flipped,
                      progress: 1,
                      accent: const Color(0xFF57E0C3),
                      fadeOut: false,
                    ),
                  ),
                ),
              ),
            if (moveAnimating &&
                lastFromSquare != null &&
                lastToSquare != null &&
                lastMovedPiece != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: MoveAndCaptureOverlay(
                    key: ValueKey<String>(
                      'move-overlay-$lastFromSquare-$lastToSquare-'
                      '${lastMovedPiece.white}-${lastMovedPiece.code}-'
                      '${lastCapturedPiece?.code}-$moveSequence',
                    ),
                    from: lastFromSquare,
                    to: lastToSquare,
                    flipped: flipped,
                    movedPiece: lastMovedPiece,
                    capturedPiece: lastCapturedPiece,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LastMoveTrailPainter extends CustomPainter {
  const LastMoveTrailPainter({
    required this.from,
    required this.to,
    required this.flipped,
    required this.progress,
    required this.accent,
    this.fadeOut = false,
  });

  final String from;
  final String to;
  final bool flipped;
  final double progress;
  final Color accent;
  final bool fadeOut;

  Offset _center(String square, Size size) {
    final int file = square.codeUnitAt(0) - 97;
    final int rank = int.parse(square.substring(1));
    final int col = flipped ? 7 - file : file;
    final int row = flipped ? rank - 1 : 8 - rank;
    final double cell = size.shortestSide / 8;
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double drawProgress =
        fadeOut ? (progress / 0.68).clamp(0.0, 1.0) : progress.clamp(0.0, 1.0);
    final double opacity = fadeOut && progress > 0.68
        ? ((1 - progress) / 0.32).clamp(0.0, 1.0)
        : 1;
    if (opacity <= 0) return;

    final Offset start = _center(from, size);
    final Offset target = _center(to, size);
    final Offset end = Offset.lerp(start, target, drawProgress)!;
    final double cell = size.shortestSide / 8;
    final Offset delta = end - start;
    final double distance = delta.distance;
    if (distance < 1) {
      return;
    }

    final Offset direction = delta / distance;
    final double pieceClearance = cell * 0.27;
    final Offset visualStart = start + direction * pieceClearance;
    final Offset visualEnd = end - direction * pieceClearance;
    if ((visualEnd - visualStart).distance < cell * 0.18) {
      return;
    }
    final Offset mid = Offset.lerp(visualStart, visualEnd, 0.5)!;
    final double bend = math.min(cell * 0.22, distance * 0.12);
    final Offset normal = Offset(-direction.dy, direction.dx);
    final Offset control = mid + normal * bend;
    final Path trail = Path()
      ..moveTo(visualStart.dx, visualStart.dy)
      ..quadraticBezierTo(control.dx, control.dy, visualEnd.dx, visualEnd.dy);
    final Paint glow = Paint()
      ..color = accent.withValues(alpha: 0.34 * opacity)
      ..strokeWidth = cell * 0.19
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.32 * opacity)
      ..strokeWidth = cell * 0.14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final Paint line = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.82 * opacity),
          accent.withValues(alpha: 0.9 * opacity),
          Colors.white.withValues(alpha: 0.7 * opacity),
        ],
      ).createShader(Rect.fromPoints(visualStart, visualEnd))
      ..strokeWidth = cell * 0.075
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(trail, shadow);
    canvas.drawPath(trail, glow);
    canvas.drawPath(trail, line);
    canvas.drawCircle(
      start,
      cell * 0.11 * drawProgress,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.045
        ..shader = line.shader,
    );
    canvas.drawCircle(
      target,
      cell * 0.24 * progress,
      Paint()
        ..color = accent.withValues(alpha: 0.12 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(LastMoveTrailPainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.flipped != flipped ||
        oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.fadeOut != fadeOut;
  }
}

class MoveAndCaptureOverlay extends StatelessWidget {
  const MoveAndCaptureOverlay({
    required this.from,
    required this.to,
    required this.flipped,
    required this.movedPiece,
    this.capturedPiece,
    super.key,
  });

  final String from;
  final String to;
  final bool flipped;
  final ChessPiece movedPiece;
  final ChessPiece? capturedPiece;

  Offset _topLeft(String square, double cell) {
    final int file = square.codeUnitAt(0) - 97;
    final int rank = int.parse(square.substring(1));
    final int col = flipped ? 7 - file : file;
    final int row = flipped ? rank - 1 : 8 - rank;
    return Offset(col * cell, row * cell);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cell = constraints.maxWidth / 8;
        final Offset start = _topLeft(from, cell);
        final Offset target = _topLeft(to, cell);
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: capturedPiece == null ? 360 : 430),
          curve: Curves.easeInOutCubic,
          builder: (BuildContext context, double progress, Widget? child) {
            final Offset travel = Offset.lerp(start, target, progress)!;
            final double lift = -math.sin(math.pi * progress) * cell * 0.42;
            final double hitDirection = target.dx >= start.dx ? 1 : -1;
            // The victim stays at the target only until impact, then is
            // knocked away quickly instead of lingering over the new board.
            final double impactProgress =
                ((progress - 0.30) / 0.70).clamp(0.0, 1.0);
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  key: ValueKey<String>(
                    'moving-piece-${movedPiece.white}-${movedPiece.code}',
                  ),
                  left: travel.dx,
                  top: travel.dy + lift,
                  width: cell,
                  height: cell,
                  child: Transform.rotate(
                    angle: math.sin(math.pi * progress) * 0.12,
                    child: ChessCoin(
                      piece: movedPiece,
                      selected: false,
                      accent: const Color(0xFFFFD166),
                    ),
                  ),
                ),
                if (capturedPiece != null && impactProgress < 0.999)
                  Positioned(
                    key: ValueKey<String>(
                      'captured-piece-${capturedPiece!.white}-'
                      '${capturedPiece!.code}',
                    ),
                    left: target.dx,
                    top: target.dy,
                    width: cell,
                    height: cell,
                    child: Opacity(
                      opacity: (1 - impactProgress).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(
                          hitDirection * cell * 0.88 * impactProgress,
                          -math.sin(math.pi * impactProgress) * cell * 1.25 +
                              cell * 0.95 * impactProgress * impactProgress,
                        ),
                        child: Transform.rotate(
                          angle: hitDirection * impactProgress * math.pi * 1.65,
                          child: ChessCoin(
                            piece: capturedPiece!,
                            selected: false,
                            accent: const Color(0xFFFF3158),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class BoardSquare extends StatelessWidget {
  const BoardSquare({
    required this.square,
    required this.dark,
    required this.selected,
    required this.legalTarget,
    required this.captureTarget,
    required this.lastMoveSquare,
    required this.lastCapture,
    required this.checkedKing,
    required this.decisiveMove,
    this.kingFallen = false,
    required this.palette,
    required this.showRank,
    required this.showFile,
    required this.onTap,
    this.piece,
    super.key,
  });

  final String square;
  final bool dark;
  final bool selected;
  final bool legalTarget;
  final bool captureTarget;
  final bool lastMoveSquare;
  final bool lastCapture;
  final bool checkedKing;
  final bool decisiveMove;
  final bool kingFallen;
  final BoardPalette palette;
  final bool showRank;
  final bool showFile;
  final VoidCallback onTap;
  final ChessPiece? piece;

  @override
  Widget build(BuildContext context) {
    final Color base = dark ? palette.dark : palette.light;
    final Color coordinateColor = dark
        ? palette.light.withValues(alpha: 0.72)
        : palette.dark.withValues(alpha: 0.72);

    final Color squareColor = checkedKing
        ? Color.alphaBlend(
            const Color(0xFFE11D48).withValues(alpha: 0.76),
            base,
          )
        : decisiveMove
            ? Color.alphaBlend(palette.accent.withValues(alpha: 0.62), base)
            : lastCapture
                ? Color.alphaBlend(
                    const Color(0xFFE11D48).withValues(alpha: 0.62),
                    base,
                  )
                : selected
                    ? Color.alphaBlend(
                        palette.accent.withValues(alpha: 0.55), base)
                    : lastMoveSquare
                        ? Color.alphaBlend(
                            const Color(0xFFFFFFFF).withValues(alpha: 0.26),
                            base,
                          )
                        : base;

    return InkWell(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: selected ||
                  legalTarget ||
                  lastCapture ||
                  checkedKing ||
                  decisiveMove
              ? 1
              : 0,
        ),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double glow, Widget? child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: dark ? 0.10 : 0.22),
                    squareColor,
                  ),
                  squareColor,
                  Color.alphaBlend(
                    Colors.black.withValues(alpha: dark ? 0.18 : 0.08),
                    squareColor,
                  ),
                ],
                stops: const <double>[0, 0.48, 1],
              ),
              border: Border.all(
                color: selected
                    ? const Color(0xFFF8E7B0)
                    : (dark ? Colors.black : Colors.white).withValues(
                        alpha: 0.08,
                      ),
                width: selected ? 3 : 1,
              ),
              boxShadow: <BoxShadow>[
                if (legalTarget)
                  BoxShadow(
                    color: const Color(
                      0xFFBDE6FF,
                    ).withValues(alpha: 0.72 * glow),
                    blurRadius: 22,
                    spreadRadius: 4,
                  ),
                if (lastCapture || captureTarget)
                  BoxShadow(
                    color: const Color(
                      0xFFFF1744,
                    ).withValues(alpha: 0.55 * glow),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                if (checkedKing)
                  BoxShadow(
                    color: const Color(
                      0xFFFF1744,
                    ).withValues(alpha: 0.9 * glow),
                    blurRadius: 28,
                    spreadRadius: 5,
                  ),
                if (decisiveMove)
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.8 * glow),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: child,
          );
        },
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: dark ? 0.045 : 0.09),
                        Colors.transparent,
                        Colors.black.withValues(alpha: dark ? 0.10 : 0.045),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 5,
              left: 6,
              child: Text(
                showRank ? square.substring(1) : '',
                style: TextStyle(
                  color: coordinateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 4,
              child: Text(
                showFile ? square.substring(0, 1) : '',
                style: TextStyle(
                  color: coordinateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack,
                scale: legalTarget && piece == null ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: RadialGradient(
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.92),
                        const Color(0xFFCBEAFF).withValues(alpha: 0.72),
                        const Color(0xFF6DBDFF).withValues(alpha: 0.28),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF8EDBFF).withValues(alpha: 0.72),
                        blurRadius: 24,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.42),
                        blurRadius: 8,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: const SizedBox(width: 28, height: 28),
                ),
              ),
            ),
            if (captureTarget)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFF1744),
                        width: 4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(
                            0xFFFF1744,
                          ).withValues(alpha: 0.72),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (checkedKing)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFD1D8),
                        width: 4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.48),
                          blurRadius: 9,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: piece == null
                  ? const SizedBox.shrink()
                  : TweenAnimationBuilder<double>(
                      key: ValueKey<String>('king-fall-$square-$kingFallen'),
                      tween: Tween<double>(begin: 0, end: kingFallen ? 1 : 0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOutBack,
                      builder:
                          (BuildContext context, double fall, Widget? child) {
                        return Transform.translate(
                          offset: Offset(0, fall * 9),
                          child: Transform.rotate(
                            alignment: Alignment.bottomCenter,
                            angle:
                                (piece!.white ? 1 : -1) * math.pi * .48 * fall,
                            child: child,
                          ),
                        );
                      },
                      child: ChessCoin(
                        key: ValueKey<String>(
                          '$square-${piece!.white}-${piece!.code}',
                        ),
                        piece: piece!,
                        selected: selected,
                        accent: palette.accent,
                      ),
                    ),
            ),
            if (lastCapture)
              Positioned.fill(
                child: IgnorePointer(
                  child: CaptureBurst(
                    key: ValueKey<String>(
                      'capture-burst-$square-${piece?.white}-${piece?.code}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CaptureBurst extends StatelessWidget {
  const CaptureBurst({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double progress, Widget? child) {
        return CustomPaint(painter: CaptureBurstPainter(progress));
      },
    );
  }
}

class CaptureBurstPainter extends CustomPainter {
  const CaptureBurstPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double extent = math.min(size.width, size.height);
    final double fade = (1 - progress).clamp(0, 1);
    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = extent * (0.08 - progress * 0.035)
      ..color = const Color(0xFFFFD166).withValues(alpha: fade * 0.95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, extent * (0.12 + progress * 0.38), glow);

    final Paint slash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = extent * 0.07
      ..color = const Color(0xFFFF3158).withValues(alpha: fade * 0.9);
    final double slashLength = extent * (0.18 + progress * 0.34);
    canvas.drawLine(
      center + Offset(-slashLength, slashLength) * 0.55,
      center + Offset(slashLength, -slashLength) * 0.55,
      slash,
    );

    final Paint particle = Paint()
      ..color = const Color(0xFFFFE6A7).withValues(alpha: fade);
    for (int index = 0; index < 10; index++) {
      final double angle = (math.pi * 2 * index / 10) + 0.22;
      final double distance = extent * (0.12 + progress * 0.52);
      final Offset point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        point,
        extent * (0.018 + (index.isEven ? 0.012 : 0)),
        particle,
      );
    }
  }

  @override
  bool shouldRepaint(CaptureBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ChessCoin extends StatelessWidget {
  const ChessCoin({
    required this.piece,
    required this.selected,
    required this.accent,
    super.key,
  });

  final ChessPiece piece;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChessPieceAppearance>(
      valueListenable: ChessPieceAppearanceController.current,
      builder: (BuildContext context, ChessPieceAppearance appearance, _) {
        return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          final double size = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final bool classic2d =
              appearance.style == ChessPieceVisualStyle.classic2d;
          final double pieceSize = size *
              (appearance.size == ChessPieceVisualSize.extraLarge
                  ? (classic2d ? 1.44 : 1.58)
                  : (classic2d ? 1.31 : 1.43));
          final double silhouetteScale = switch (piece.code) {
            'K' => 1.00,
            'Q' => .98,
            'N' => .96,
            'B' => .94,
            'R' => .91,
            _ => .88,
          };

          return AnimatedRotation(
            turns: selected ? -0.012 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              scale: selected ? 1.13 : 1,
              curve: Curves.easeOutBack,
              child: SizedBox(
                width: pieceSize,
                height: pieceSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      bottom: pieceSize * 0.08,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              (piece.white
                                      ? const Color(0xFFFFF0C8)
                                      : const Color(0xFF5D6674))
                                  .withValues(alpha: 0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: SizedBox(
                          width: pieceSize * 0.72,
                          height: pieceSize * 0.34,
                        ),
                      ),
                    ),
                    if (!classic2d)
                      Positioned(
                        bottom: pieceSize * 0.045,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(pieceSize),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.48),
                                blurRadius: pieceSize * 0.07,
                                spreadRadius: pieceSize * 0.012,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: pieceSize * 0.11,
                                offset: Offset(0, pieceSize * 0.08),
                              ),
                              if (selected)
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.68),
                                  blurRadius: pieceSize * 0.2,
                                  spreadRadius: pieceSize * 0.06,
                                ),
                            ],
                          ),
                          child: SizedBox(
                            width: pieceSize * 0.42,
                            height: pieceSize * 0.035,
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: Offset(0, selected ? -pieceSize * 0.035 : 0),
                      child: Transform.scale(
                        scale: silhouetteScale,
                        child: _pieceVisual(appearance, pieceSize),
                      ),
                    ),
                    Positioned(
                      top: pieceSize * 0.11,
                      left: pieceSize * 0.25,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: piece.white ? 0.2 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(pieceSize),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.22),
                                blurRadius: pieceSize * 0.09,
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: pieceSize * 0.13,
                            height: pieceSize * 0.035,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _pieceVisual(ChessPieceAppearance appearance, double pieceSize) {
    final String label =
        '${piece.white ? 'White' : 'Black'} ${pieceName(piece.code)}';
    if (appearance.style == ChessPieceVisualStyle.classic2d) {
      final String solidGlyph = switch (piece.code) {
        'K' => '♚',
        'Q' => '♛',
        'R' => '♜',
        'B' => '♝',
        'N' => '♞',
        _ => '♟',
      };
      final Color fill =
          piece.white ? const Color(0xFFFFD98A) : const Color(0xFF10243A);
      final Color outline =
          piece.white ? const Color(0xFF15283D) : const Color(0xFFE7C67E);
      return Semantics(
        label: label,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Text(
              solidGlyph,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: pieceSize * .82,
                height: 1,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = math.max(1.8, pieceSize * .035)
                  ..color = outline,
              ),
            ),
            Text(
              solidGlyph,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: pieceSize * .82,
                height: 1,
                color: fill,
                shadows: <Shadow>[
                  Shadow(
                    color: Colors.black.withValues(alpha: .42),
                    blurRadius: pieceSize * .035,
                    offset: Offset(0, pieceSize * .018),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final Widget image = Image.asset(
      pieceAsset(piece),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: label,
    );
    if (appearance.style == ChessPieceVisualStyle.highContrast) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          piece.white ? const Color(0xFFFFF0B8) : const Color(0xFF89BFFF),
          BlendMode.modulate,
        ),
        child: image,
      );
    }
    return image;
  }
}

String pieceAsset(ChessPiece piece) {
  return 'assets/pieces/staunton_${piece.white ? 'white' : 'black'}_${pieceName(piece.code)}.png';
}

String pieceName(String code) {
  return switch (code) {
    'K' => 'king',
    'Q' => 'queen',
    'R' => 'rook',
    'B' => 'bishop',
    'N' => 'knight',
    _ => 'pawn',
  };
}

String pieceGlyph(ChessPiece piece) {
  if (piece.white) {
    return switch (piece.code) {
      'K' => '\u2654',
      'Q' => '\u2655',
      'R' => '\u2656',
      'B' => '\u2657',
      'N' => '\u2658',
      _ => '\u2659',
    };
  }
  return switch (piece.code) {
    'K' => '\u265A',
    'Q' => '\u265B',
    'R' => '\u265C',
    'B' => '\u265D',
    'N' => '\u265E',
    _ => '\u265F',
  };
}

class CoinRingPainter extends CustomPainter {
  const CoinRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2;
    final Paint ring = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * 0.08);
    canvas.drawCircle(center, radius * 0.68, ring);

    final Paint tick = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = math.max(1, radius * 0.035)
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 18; i++) {
      final double angle = i * math.pi / 9;
      final Offset start = Offset(
        center.dx + math.cos(angle) * radius * 0.82,
        center.dy + math.sin(angle) * radius * 0.82,
      );
      final Offset end = Offset(
        center.dx + math.cos(angle) * radius * 0.9,
        center.dy + math.sin(angle) * radius * 0.9,
      );
      canvas.drawLine(start, end, tick);
    }
  }

  @override
  bool shouldRepaint(CoinRingPainter oldDelegate) => oldDelegate.color != color;
}

class PieceSculpturePainter extends CustomPainter {
  const PieceSculpturePainter({required this.light, required this.accent});

  final bool light;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Color body =
        light ? const Color(0xFFF7E9C9) : const Color(0xFF252A32);
    final Color edge =
        light ? const Color(0xFFC09035) : const Color(0xFF68707D);
    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          light ? Colors.white : const Color(0xFF505763),
          body,
          light ? const Color(0xFFD8B56C) : const Color(0xFF16191F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final Paint edgePaint = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.035);

    final RRect base = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.66, w * 0.64, h * 0.18),
      Radius.circular(w * 0.12),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.18, h * 0.72, w * 0.64, h * 0.18),
      shadow,
    );
    canvas.drawRRect(base, bodyPaint);
    canvas.drawRRect(base, edgePaint);

    final Path stem = Path()
      ..moveTo(w * 0.38, h * 0.68)
      ..quadraticBezierTo(w * 0.32, h * 0.46, w * 0.43, h * 0.32)
      ..lineTo(w * 0.57, h * 0.32)
      ..quadraticBezierTo(w * 0.68, h * 0.46, w * 0.62, h * 0.68)
      ..close();
    canvas.drawPath(stem, shadow);
    canvas.drawPath(stem, bodyPaint);
    canvas.drawPath(stem, edgePaint);

    canvas.drawCircle(Offset(w * 0.5, h * 0.26), w * 0.16, bodyPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.26), w * 0.16, edgePaint);
    canvas.drawCircle(
      Offset(w * 0.43, h * 0.18),
      w * 0.035,
      Paint()..color = Colors.white.withValues(alpha: light ? 0.86 : 0.28),
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.3,
      Paint()
        ..color = accent.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035,
    );
  }

  @override
  bool shouldRepaint(PieceSculpturePainter oldDelegate) {
    return oldDelegate.light != light || oldDelegate.accent != accent;
  }
}

class PromotionChoice extends StatelessWidget {
  const PromotionChoice({
    required this.piece,
    required this.onSelected,
    super.key,
  });

  final ChessPiece piece;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: FilledButton(
        onPressed: onSelected,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: const Color(0xFF242128),
          foregroundColor: const Color(0xFFF6F1E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 48,
              height: 48,
              child: ChessCoin(
                piece: piece,
                selected: false,
                accent: const Color(0xFFD6A84F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              piece.code,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameStudioHeader extends StatelessWidget {
  const _GameStudioHeader({
    required this.gameMode,
    required this.playerName,
    required this.soundEnabled,
    required this.onSoundChanged,
    required this.onHome,
    required this.onDailyChallenge,
    required this.onProfile,
  });

  final GameMode gameMode;
  final String playerName;
  final bool soundEnabled;
  final ValueChanged<bool> onSoundChanged;
  final VoidCallback onHome;
  final VoidCallback onDailyChallenge;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 1050;
    final String title = switch (gameMode) {
      GameMode.daily => 'Daily Challenge',
      GameMode.puzzle => 'Puzzle Academy',
      GameMode.computer => 'AI Training',
      GameMode.local => 'Local Match',
      GameMode.online => 'Online Battle',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071425).withValues(alpha: 0.96),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFB47A2B)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: <Widget>[
            if (compact)
              IconButton.outlined(
                key: const ValueKey<String>('desktop-back-to-home'),
                tooltip: 'Back to Home',
                onPressed: onHome,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            else
              OutlinedButton.icon(
                key: const ValueKey<String>('desktop-back-to-home'),
                onPressed: onHome,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Home'),
              ),
            SizedBox(width: compact ? 10 : 16),
            Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/branding/app_icon.png',
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                  ),
                ),
                if (!compact) ...<Widget>[
                  const SizedBox(width: 12),
                  const Text(
                    'ChessVerseAI',
                    style: TextStyle(
                      color: Color(0xFFF2C46D),
                      fontFamily: 'serif',
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: onDailyChallenge,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFFF2C46D),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFF2C46D),
                            fontFamily: 'serif',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!compact)
                          const Text(
                            'Tap for today\'s challenge',
                            style: TextStyle(
                              color: Color(0xFFC7C1B8),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            IconButton.outlined(
              tooltip: soundEnabled ? 'Mute sounds' : 'Enable sounds',
              onPressed: () => onSoundChanged(!soundEnabled),
              icon: Icon(
                soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
              ),
            ),
            const SizedBox(width: 14),
            if (compact)
              IconButton.outlined(
                tooltip: 'Profile',
                onPressed: onProfile,
                icon: const Icon(Icons.person_rounded),
              )
            else
              OutlinedButton.icon(
                onPressed: onProfile,
                icon: const CircleAvatar(
                  radius: 15,
                  backgroundColor: Color(0xFF63D2B8),
                  child: Icon(Icons.person_rounded, size: 19),
                ),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    playerName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameStudioDock extends StatelessWidget {
  const _GameStudioDock({
    required this.moves,
    required this.capturedWhite,
    required this.capturedBlack,
    required this.onMoveHistory,
  });

  final List<String> moves;
  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;
  final VoidCallback onMoveHistory;

  @override
  Widget build(BuildContext context) {
    final List<String> recentMoves = moves.take(8).toList().reversed.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StudioDockCard(
              child: InkWell(
                onTap: onMoveHistory,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Icon(Icons.format_list_bulleted_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Move history',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: recentMoves.isEmpty
                            ? const Text(
                                'Your moves will appear here.',
                                style: TextStyle(color: Color(0xFF9FA8B8)),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: recentMoves.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, int index) => Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index == recentMoves.length - 1
                                        ? const Color(0xFF63D2B8)
                                        : const Color(0xFF111C30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF33415B),
                                    ),
                                  ),
                                  child: Text(
                                    recentMoves[index],
                                    style: TextStyle(
                                      color: index == recentMoves.length - 1
                                          ? const Color(0xFF061421)
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _StudioDockCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: CapturedMaterial(
                  capturedWhite: capturedWhite,
                  capturedBlack: capturedBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioDockCard extends StatelessWidget {
  const _StudioDockCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071425).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9D6B2A)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StudioCoachPanel extends StatelessWidget {
  const _StudioCoachPanel({
    required this.gameMode,
    required this.activeColor,
    required this.aiThinking,
    required this.coachEnabled,
    required this.coachNote,
    required this.evaluationPawns,
    required this.lastMove,
    required this.lastMoveOwner,
    required this.dailyProgress,
    required this.dailyGoal,
    required this.canUndo,
    required this.hintLabel,
    required this.analyzeLabel,
    required this.onHint,
    required this.onAnalyze,
    required this.onTryAgain,
    required this.onUndo,
    required this.puzzleComplete,
    required this.onNextPuzzle,
    required this.onBackToAcademy,
  });

  final GameMode gameMode;
  final String activeColor;
  final bool aiThinking;
  final bool coachEnabled;
  final String coachNote;
  final double evaluationPawns;
  final String? lastMove;
  final String? lastMoveOwner;
  final int dailyProgress;
  final int dailyGoal;
  final bool canUndo;
  final String hintLabel;
  final String analyzeLabel;
  final VoidCallback onHint;
  final VoidCallback onAnalyze;
  final VoidCallback onTryAgain;
  final VoidCallback onUndo;
  final bool puzzleComplete;
  final VoidCallback onNextPuzzle;
  final VoidCallback onBackToAcademy;

  @override
  Widget build(BuildContext context) {
    final String modeLabel = switch (gameMode) {
      GameMode.daily => 'DAILY CHALLENGE',
      GameMode.puzzle => 'PUZZLE TRAINING',
      GameMode.computer => 'AI TRAINING • 3-LEVEL HINTS • GAME REVIEW',
      GameMode.local => 'LOCAL MATCH',
      GameMode.online => 'ONLINE BATTLE',
    };
    final String goal = switch (gameMode) {
      GameMode.daily => 'Checkmate in $dailyGoal',
      GameMode.puzzle => 'Checkmate in $dailyGoal',
      GameMode.computer => 'Find the strongest move',
      GameMode.local => 'Outplay your opponent',
      GameMode.online => 'Play a live opponent',
    };
    final int progress =
        (gameMode == GameMode.daily || gameMode == GameMode.puzzle)
            ? dailyProgress.clamp(0, dailyGoal)
            : (lastMove == null ? 0 : 1);
    final int goalSteps =
        (gameMode == GameMode.daily || gameMode == GameMode.puzzle)
            ? dailyGoal
            : 3;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool hasBoundedHeight = constraints.hasBoundedHeight;
        final bool compact = constraints.maxHeight < 560;
        final Widget coachMessageCard = _CoachInsightCard(
          icon: Icons.psychology_alt_rounded,
          accent: const Color(0xFF9C6CFF),
          alignStart: true,
          child: SingleChildScrollView(
            child: Text(
              coachEnabled
                  ? coachNote
                  : 'Turn Coach on in Game controls for live move explanations.',
              style: const TextStyle(
                color: Color(0xFFF2EDE4),
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF061527).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(compact ? 14 : 22),
            border: Border.all(color: const Color(0xFFB47A2B)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (puzzleComplete)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onBackToAcademy,
                            icon: const Icon(Icons.school_rounded),
                            label: const Text('Puzzle Academy'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onNextPuzzle,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Next puzzle'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'AI Coach ✦',
                                style: TextStyle(
                                  color: const Color(0xFF63D2B8),
                                  fontFamily: 'serif',
                                  fontSize: compact ? 23 : 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                modeLabel,
                                style: const TextStyle(
                                  color: Color(0xFFE2B458),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: gameMode == GameMode.online
                              ? 'Undo is unavailable in online games'
                              : 'Undo move',
                          onPressed: canUndo ? onUndo : null,
                          icon: const Icon(Icons.undo_rounded),
                        ),
                      ],
                    ),
                  SizedBox(height: compact ? 8 : 14),
                  _CoachInsightCard(
                    icon: Icons.track_changes_rounded,
                    accent: const Color(0xFF63D2B8),
                    child: Text(
                      'Goal: $goal',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  if (compact)
                    hasBoundedHeight
                        ? Expanded(child: coachMessageCard)
                        : SizedBox(height: 112, child: coachMessageCard)
                  else
                    SizedBox(height: 84, child: coachMessageCard),
                  if (!compact) ...<Widget>[
                    const SizedBox(height: 10),
                    _CoachInsightCard(
                      icon: Icons.workspace_premium_rounded,
                      accent: const Color(0xFF63D2B8),
                      child: Text(
                        aiThinking
                            ? 'ChessVerseAI is calculating…'
                            : lastMove == null
                                ? 'Select a piece to begin'
                                : '${lastMoveOwner ?? 'Last move'}: $lastMove',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF63D2B8),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    hasBoundedHeight
                        ? Expanded(
                            child: _CoachInsightCard(
                              icon: Icons.chat_bubble_rounded,
                              accent: const Color(0xFF63D2B8),
                              alignStart: true,
                              child: SingleChildScrollView(
                                child: Text(
                                  coachEnabled
                                      ? coachNote
                                      : 'Turn Coach on from Game controls to receive move-by-move explanations.',
                                  style: TextStyle(
                                    color: const Color(0xFFF2EDE4),
                                    fontFamily: 'serif',
                                    fontSize: compact ? 14 : 16,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 160,
                            child: _CoachInsightCard(
                              icon: Icons.chat_bubble_rounded,
                              accent: const Color(0xFF63D2B8),
                              alignStart: true,
                              child: SingleChildScrollView(
                                child: Text(
                                  coachEnabled
                                      ? coachNote
                                      : 'Turn Coach on from Game controls to receive move-by-move explanations.',
                                  style: TextStyle(
                                    color: const Color(0xFFF2EDE4),
                                    fontFamily: 'serif',
                                    fontSize: compact ? 14 : 16,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                  if (!compact) ...<Widget>[
                    const SizedBox(height: 10),
                    _CoachProgress(
                      progress: progress,
                      goal: goalSteps,
                    ),
                    const SizedBox(height: 10),
                    _CoachEvaluation(
                      activeColor: activeColor,
                      evaluationPawns: evaluationPawns,
                    ),
                  ],
                  SizedBox(height: compact ? 8 : 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onHint,
                          icon: const Icon(Icons.tips_and_updates_outlined),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(hintLabel, maxLines: 1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onAnalyze,
                          icon: const Icon(Icons.visibility_outlined),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(analyzeLabel, maxLines: 1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onTryAgain,
                          icon: Icon(
                            gameMode == GameMode.online
                                ? Icons.sync_rounded
                                : Icons.refresh_rounded,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              gameMode == GameMode.online
                                  ? 'Sync'
                                  : 'Try again',
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CoachInsightCard extends StatelessWidget {
  const _CoachInsightCard({
    required this.icon,
    required this.accent,
    required this.child,
    this.alignStart = false,
  });

  final IconData icon;
  final Color accent;
  final Widget child;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C622D)),
      ),
      child: Row(
        crossAxisAlignment:
            alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: accent, size: 25),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CoachProgress extends StatelessWidget {
  const _CoachProgress({required this.progress, required this.goal});

  final int progress;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final int safeGoal = math.max(goal, 1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C622D)),
      ),
      child: Row(
        children: <Widget>[
          const Text(
            'Step progress',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress / safeGoal,
                backgroundColor: const Color(0xFF27344A),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF63D2B8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$progress/$safeGoal',
            style: const TextStyle(
              color: Color(0xFF63D2B8),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachEvaluation extends StatelessWidget {
  const _CoachEvaluation({
    required this.activeColor,
    required this.evaluationPawns,
  });

  final String activeColor;
  final double evaluationPawns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C622D)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            evaluationPawns == 0
                ? 'Evaluation 0.0'
                : 'Evaluation ${evaluationPawns > 0 ? '+' : ''}${evaluationPawns.toStringAsFixed(1)}',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF202B3D),
                    Color(0xFF3D4B62),
                    Color(0xFF63D2B8),
                    Color(0xFF202B3D),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '$activeColor to move',
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF63D2B8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineConnectionBanner extends StatelessWidget {
  const _OnlineConnectionBanner({
    required this.reconnecting,
    required this.opponentAway,
  });

  final bool reconnecting;
  final bool opponentAway;

  @override
  Widget build(BuildContext context) {
    final bool healthy = !reconnecting && !opponentAway;
    final Color color =
        healthy ? const Color(0xFF63D2B8) : const Color(0xFFE5B856);
    final String label = reconnecting
        ? 'Reconnecting to match…'
        : opponentAway
            ? 'Opponent offline — waiting for reconnect'
            : 'Both players online';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (reconnecting)
            SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.7, color: color),
            )
          else
            Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineArenaBoard extends StatelessWidget {
  const _OnlineArenaBoard({
    required this.board,
    required this.flipped,
    required this.whiteName,
    required this.blackName,
    required this.whitePhotoUrl,
    required this.blackPhotoUrl,
    required this.whiteClock,
    required this.blackClock,
    required this.activeColor,
    required this.matchActive,
    required this.socketConnected,
    required this.connectedPlayers,
    this.compactOverlay = false,
  });

  final Widget board;
  final bool flipped;
  final String whiteName;
  final String blackName;
  final String? whitePhotoUrl;
  final String? blackPhotoUrl;
  final String whiteClock;
  final String blackClock;
  final String activeColor;
  final bool matchActive;
  final bool socketConnected;
  final int connectedPlayers;
  final bool compactOverlay;

  @override
  Widget build(BuildContext context) {
    final Widget white = _OnlinePlayerRail(
      name: whiteName,
      photoUrl: whitePhotoUrl,
      clock: whiteClock,
      active: matchActive && activeColor == 'white',
      pieceColor: Colors.white,
      compact: compactOverlay,
    );
    final Widget black = _OnlinePlayerRail(
      name: blackName,
      photoUrl: blackPhotoUrl,
      clock: blackClock,
      active: matchActive && activeColor == 'black',
      pieceColor: const Color(0xFF171717),
      compact: compactOverlay,
    );
    if (compactOverlay) {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          board,
          Positioned(
            left: 6,
            right: 6,
            top: 6,
            height: 38,
            child: flipped ? white : black,
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            height: 38,
            child: flipped ? black : white,
          ),
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: _OnlineConnectionBanner(
                reconnecting: !socketConnected,
                opponentAway: socketConnected && connectedPlayers < 2,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        SizedBox(
          height: 28,
          child: Center(
            child: _OnlineConnectionBanner(
              reconnecting: !socketConnected,
              opponentAway: socketConnected && connectedPlayers < 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(height: 48, child: flipped ? white : black),
        const SizedBox(height: 4),
        Expanded(child: board),
        const SizedBox(height: 4),
        SizedBox(height: 48, child: flipped ? black : white),
      ],
    );
  }
}

class _OnlinePlayerRail extends StatelessWidget {
  const _OnlinePlayerRail({
    required this.name,
    required this.photoUrl,
    required this.clock,
    required this.active,
    required this.pieceColor,
    this.compact = false,
  });

  final String name;
  final String? photoUrl;
  final String clock;
  final bool active;
  final Color pieceColor;
  final bool compact;

  String get initials {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'CV';
    return words.take(2).map((String word) => word[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final String? usablePhoto = photoUrl != null && photoUrl!.trim().isNotEmpty
        ? photoUrl!.trim()
        : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF173A35) : const Color(0xFF111C1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? const Color(0xFF63D2B8) : const Color(0xFF755A32),
          width: active ? 1.6 : 1,
        ),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF63D2B8).withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        children: <Widget>[
          ClipOval(
            child: SizedBox.square(
              dimension: compact ? 26 : 34,
              child: usablePhoto == null
                  ? _AvatarInitials(initials: initials)
                  : Image.network(
                      usablePhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AvatarInitials(initials: initials),
                    ),
            ),
          ),
          SizedBox(width: compact ? 5 : 8),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: pieceColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB9914E)),
            ),
          ),
          SizedBox(width: compact ? 5 : 7),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFFF4ECDD),
                fontSize: compact ? 12 : null,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 3 : 5,
            ),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF63D2B8) : const Color(0xFF24272A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              clock,
              style: TextStyle(
                color: active ? const Color(0xFF071A17) : Colors.white,
                fontSize: compact ? 14 : 18,
                fontWeight: FontWeight.w900,
                fontFeatures: const <ui.FontFeature>[
                  ui.FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF1F7E72), Color(0xFF493481)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.compact,
    required this.collapsible,
    required this.expanded,
    required this.whitePlayerName,
    required this.blackPlayerName,
    required this.activeColor,
    required this.gameMode,
    required this.aiLevel,
    required this.aiThinking,
    required this.coachEnabled,
    required this.moves,
    required this.capturedWhite,
    required this.capturedBlack,
    required this.coachNote,
    required this.whiteClock,
    required this.blackClock,
    required this.skin,
    required this.onSkinChanged,
    required this.onGameModeChanged,
    required this.dailyDifficulty,
    required this.dailyProgress,
    required this.dailyGoal,
    required this.dailyMistakes,
    required this.onDailyDifficultyChanged,
    required this.onAiLevelChanged,
    required this.onCoachChanged,
    required this.onNewGameRequested,
    required this.onResign,
    required this.onOfferDraw,
    required this.onMoveHistory,
    required this.onUndo,
    required this.onHint,
    required this.onAnalyze,
    required this.soundEnabled,
    required this.showCoordinates,
    required this.showMoveHints,
    required this.onSoundChanged,
    required this.onShowCoordinatesChanged,
    required this.onShowMoveHintsChanged,
    required this.onEditBlackPlayer,
    required this.onToggleExpanded,
    required this.onLogout,
    required this.canUndo,
    super.key,
  });

  final bool compact;
  final bool collapsible;
  final bool expanded;
  final String whitePlayerName;
  final String blackPlayerName;
  final String activeColor;
  final GameMode gameMode;
  final int aiLevel;
  final bool aiThinking;
  final bool coachEnabled;
  final List<String> moves;
  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;
  final String coachNote;
  final String whiteClock;
  final String blackClock;
  final BoardSkin skin;
  final ValueChanged<BoardSkin> onSkinChanged;
  final ValueChanged<GameMode> onGameModeChanged;
  final DailyChallengeDifficulty dailyDifficulty;
  final int dailyProgress;
  final int dailyGoal;
  final int dailyMistakes;
  final ValueChanged<DailyChallengeDifficulty> onDailyDifficultyChanged;
  final ValueChanged<double> onAiLevelChanged;
  final ValueChanged<bool> onCoachChanged;
  final VoidCallback onNewGameRequested;
  final VoidCallback onResign;
  final VoidCallback onOfferDraw;
  final VoidCallback onMoveHistory;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onAnalyze;
  final bool soundEnabled;
  final bool showCoordinates;
  final bool showMoveHints;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onShowCoordinatesChanged;
  final ValueChanged<bool> onShowMoveHintsChanged;
  final VoidCallback onEditBlackPlayer;
  final VoidCallback onToggleExpanded;
  final VoidCallback onLogout;
  final bool canUndo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final AiProfile aiProfile = aiProfileFor(aiLevel);
        final bool collapsed = collapsible && !expanded;
        final bool collapsedRail = constraints.maxWidth < 310;
        final Widget history = moves.isEmpty
            ? const EmptyMoveState()
            : ListView.separated(
                itemCount: moves.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final bool whiteMove = (moves.length - 1 - index).isEven;
                  final String move = moves[index];
                  return ListTile(
                    dense: true,
                    minLeadingWidth: 32,
                    leading: Text('${moves.length - index}.'),
                    title: Row(
                      children: <Widget>[
                        Expanded(child: Text(move)),
                        MoveQualityBadge(move: move),
                      ],
                    ),
                    subtitle: Text(
                      moveCoachNoteForMove(move, whiteMove),
                      maxLines: 3,
                      overflow: TextOverflow.fade,
                    ),
                  );
                },
              );

        if (collapsedRail) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF17231F).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF98743B).withValues(alpha: 0.72),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      key: const ValueKey<String>('game-controls-handle'),
                      onTap: onToggleExpanded,
                      borderRadius: BorderRadius.circular(8),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.tune_rounded, size: 30),
                            SizedBox(height: 8),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                'GAME CONTROLS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Icon(Icons.chevron_left_rounded, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New game',
                    onPressed: onNewGameRequested,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    tooltip: 'Undo move',
                    onPressed: canUndo ? onUndo : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }

        final List<Widget> controls = <Widget>[
          if (collapsible)
            Semantics(
              button: true,
              label:
                  expanded ? 'Collapse game controls' : 'Expand game controls',
              child: InkWell(
                key: const ValueKey<String>('game-controls-handle'),
                onTap: onToggleExpanded,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.drag_handle_rounded, size: 28),
                      const SizedBox(width: 6),
                      Text(
                        expanded ? 'Less controls' : 'More controls',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  switch (gameMode) {
                    GameMode.computer => 'Solo Challenge',
                    GameMode.daily => 'Daily Checkmate',
                    GameMode.puzzle => 'Puzzle Training',
                    GameMode.local => 'Pass & Play',
                    GameMode.online => 'Online Battle',
                  },
                  style: compact
                      ? Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          )
                      : Theme.of(context).textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'New game',
                onPressed: onNewGameRequested,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Undo move',
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              if (!compact)
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GameModeLauncher(
            selected: gameMode,
            compact: compact,
            onChanged: onGameModeChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusPill(
                icon: Icons.auto_awesome_rounded,
                label: coachEnabled ? 'Coach on' : 'Coach off',
              ),
              if (gameMode == GameMode.computer)
                StatusPill(
                  icon: aiThinking
                      ? Icons.hourglass_top_rounded
                      : Icons.speed_rounded,
                  label: aiThinking ? 'Thinking' : aiProfile.name,
                ),
              if (gameMode == GameMode.daily || gameMode == GameMode.puzzle)
                StatusPill(
                  icon: Icons.local_fire_department_rounded,
                  label: '$dailyProgress/$dailyGoal solved',
                ),
              StatusPill(icon: Icons.memory_rounded, label: activeColor),
            ],
          ),
          if (gameMode == GameMode.local) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey<String>('rename-player-two'),
              onPressed: onEditBlackPlayer,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: Text('Player 2: $blackPlayerName'),
            ),
          ],
          if (gameMode == GameMode.daily) ...<Widget>[
            const SizedBox(height: 10),
            DailyDifficultyChips(
              selected: dailyDifficulty,
              onChanged: onDailyDifficultyChanged,
            ),
            if (dailyMistakes > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '$dailyMistakes attempt${dailyMistakes == 1 ? '' : 's'} missed - keep calculating',
                style: const TextStyle(color: Color(0xFFE2B458)),
              ),
            ],
          ],
          if (collapsed) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: MatchClock(label: whitePlayerName, value: whiteClock),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MatchClock(label: blackPlayerName, value: blackClock),
                ),
              ],
            ),
          ],
          if (collapsed) const SizedBox(height: 10),
        ];

        final List<Widget> expandedOnlyControls = <Widget>[
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              SizedBox(
                width: compact ? 116 : 132,
                child: _PanelActionButton(
                  onPressed: onMoveHistory,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('History'),
                ),
              ),
              SizedBox(
                width: compact ? 100 : 118,
                child: _PanelActionButton(
                  onPressed: onOfferDraw,
                  icon: const Icon(Icons.handshake_rounded),
                  label: const Text('Draw'),
                ),
              ),
              SizedBox(
                width: compact ? 108 : 124,
                child: _PanelActionButton(
                  onPressed: onResign,
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Resign'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: MatchClock(label: whitePlayerName, value: whiteClock),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MatchClock(label: blackPlayerName, value: blackClock),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CoachInsight(note: coachNote, enabled: coachEnabled),
          if (!compact) ...<Widget>[
            const SizedBox(height: 18),
            CapturedMaterial(
              capturedWhite: capturedWhite,
              capturedBlack: capturedBlack,
            ),
          ],
          const SizedBox(height: 18),
          Text('Board', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<BoardSkin>(
            key: const ValueKey<String>('board-theme-menu'),
            initialValue: skin,
            decoration: const InputDecoration(
              labelText: 'Board theme',
              prefixIcon: Icon(Icons.palette_outlined),
              border: OutlineInputBorder(),
            ),
            items: boardPalettes.entries
                .map(
                  (MapEntry<BoardSkin, BoardPalette> entry) =>
                      DropdownMenuItem<BoardSkin>(
                    value: entry.key,
                    child: BoardThemeMenuItem(palette: entry.value),
                  ),
                )
                .toList(),
            onChanged: (BoardSkin? selectedSkin) {
              if (selectedSkin != null) {
                onSkinChanged(selectedSkin);
              }
            },
          ),
          if (gameMode == GameMode.computer) ...<Widget>[
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${aiProfile.name} - Level $aiLevel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '~${aiProfile.elo} Elo',
                  style: const TextStyle(
                    color: Color(0xFF63D2B8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              aiProfile.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              value: aiLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${aiProfile.name} - ~${aiProfile.elo} Elo',
              onChanged: onAiLevelChanged,
            ),
          ],
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: coachEnabled,
              onChanged: onCoachChanged,
              title: const Text('AI coach'),
              secondary: const Icon(Icons.psychology_alt_rounded),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: soundEnabled,
              onChanged: onSoundChanged,
              title: const Text('Sound effects'),
              secondary: const Icon(Icons.volume_up_rounded),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: showCoordinates,
              onChanged: onShowCoordinatesChanged,
              title: const Text('Show coordinates'),
              secondary: const Icon(Icons.grid_4x4_rounded),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: showMoveHints,
              onChanged: onShowMoveHintsChanged,
              title: const Text('Move hints'),
              secondary: const Icon(Icons.lightbulb_outline_rounded),
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.view_in_ar_rounded),
            title: Text('Piece theme'),
            subtitle: Text('Staunton 3D active - more themes coming soon'),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onHint,
                  icon: const Icon(Icons.psychology_alt_rounded),
                  label: const Text('Hint'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text('Analyze'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Move history',
            style: compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
        ];

        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...controls,
            if (!collapsed) ...<Widget>[
              ...expandedOnlyControls,
              SizedBox(height: compact ? 120 : 220, child: history),
            ],
          ],
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF17231F).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF98743B).withValues(alpha: 0.72),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 18),
            child: SingleChildScrollView(child: content),
          ),
        );
      },
    );
  }
}

class _PanelActionButton extends StatelessWidget {
  const _PanelActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: IconTheme.merge(data: const IconThemeData(size: 18), child: icon),
      label: DefaultTextStyle.merge(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: label,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 50),
      ),
    );
  }
}

class GameModeLauncher extends StatelessWidget {
  const GameModeLauncher({
    required this.selected,
    required this.compact,
    required this.onChanged,
    super.key,
  });

  final GameMode selected;
  final bool compact;
  final ValueChanged<GameMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<_GameModeChoice> choices = <_GameModeChoice>[
      const _GameModeChoice(
        mode: GameMode.computer,
        icon: Icons.smart_toy_rounded,
        title: 'Play vs AI',
        subtitle: 'Challenge ChessVerseAI',
      ),
      const _GameModeChoice(
        mode: GameMode.daily,
        icon: Icons.local_fire_department_rounded,
        title: 'Daily Checkmate',
        subtitle: 'Finish a late-game puzzle',
      ),
      const _GameModeChoice(
        mode: GameMode.local,
        icon: Icons.groups_2_rounded,
        title: '2 Players',
        subtitle: 'Same-device match',
      ),
      const _GameModeChoice(
        mode: GameMode.online,
        icon: Icons.public_rounded,
        title: 'Online',
        subtitle: 'Matchmaking & reconnect',
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices.map((choice) {
        final bool active = selected == choice.mode;
        return SizedBox(
          width: compact ? 148 : 178,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(choice.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: active
                      ? const <Color>[Color(0xFF2B2140), Color(0xFF6D4FD8)]
                      : <Color>[
                          const Color(0xFF211D24),
                          const Color(0xFF111C18).withValues(alpha: 0.92),
                        ],
                ),
                border: Border.all(
                  color: active
                      ? const Color(0xFFE2B458)
                      : const Color(0xFF7A6038).withValues(alpha: 0.55),
                ),
                boxShadow: <BoxShadow>[
                  if (active)
                    BoxShadow(
                      color: const Color(
                        0xFF6D4FD8,
                      ).withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    choice.icon,
                    color: const Color(0xFFE2B458),
                    size: 22,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          choice.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          choice.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _GameModeChoice {
  const _GameModeChoice({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final GameMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
}

class DailyDifficultyChips extends StatelessWidget {
  const DailyDifficultyChips({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final DailyChallengeDifficulty selected;
  final ValueChanged<DailyChallengeDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DailyChallengeDifficulty.values.map((difficulty) {
        final bool active = selected == difficulty;
        return ChoiceChip(
          selected: active,
          avatar: Icon(
            Icons.emoji_events_outlined,
            size: 18,
            color: active ? Colors.black : const Color(0xFFE2B458),
          ),
          label: Text(difficulty.label),
          onSelected: (_) => onChanged(difficulty),
        );
      }).toList(growable: false),
    );
  }
}

class BoardThemeMenuItem extends StatelessWidget {
  const BoardThemeMenuItem({required this.palette, super.key});

  final BoardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            width: 34,
            height: 24,
            child: Row(
              children: <Widget>[
                Expanded(child: ColoredBox(color: palette.light)),
                Expanded(child: ColoredBox(color: palette.dark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(palette.label),
      ],
    );
  }
}

class PositionAnalysisSheet extends StatelessWidget {
  const PositionAnalysisSheet({required this.analysis, super.key});

  final PositionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final String evaluation = analysis.evaluation == 0
        ? 'Equal'
        : analysis.evaluation > 0
            ? 'White +${analysis.evaluation.toStringAsFixed(1)}'
            : 'Black +${analysis.evaluation.abs().toStringAsFixed(1)}';

    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewport) {
          final bool shortLandscape = viewport.maxWidth > viewport.maxHeight &&
              viewport.maxHeight < 500;
          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: viewport.maxHeight * 0.98,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFF17231F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFF8B7147)),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    shortLandscape ? 8 : 12,
                    20,
                    shortLandscape ? 10 : 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF786B58),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(height: shortLandscape ? 8 : 16),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.analytics_rounded,
                            color: Color(0xFFD6A84F),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'AI Agent Coach',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close analysis',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      SizedBox(height: shortLandscape ? 6 : 14),
                      AnalysisMetric(
                        icon: Icons.balance_rounded,
                        label: 'Evaluation',
                        value: evaluation,
                      ),
                      AnalysisMetric(
                        icon: Icons.route_rounded,
                        label: '${analysis.side} legal moves',
                        value: '${analysis.legalMoves}',
                      ),
                      AnalysisMetric(
                        icon: Icons.gps_fixed_rounded,
                        label: 'Immediate captures',
                        value: '${analysis.captures}',
                      ),
                      AnalysisMetric(
                        icon: Icons.auto_graph_rounded,
                        label: 'Move quality',
                        value: analysis.quality,
                      ),
                      AnalysisMetric(
                        icon: analysis.inCheck
                            ? Icons.warning_amber_rounded
                            : Icons.shield_outlined,
                        label: 'King safety',
                        value: analysis.inCheck ? 'In check' : 'Safe',
                      ),
                      SizedBox(height: shortLandscape ? 6 : 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFD6A84F).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color:
                                const Color(0xFFD6A84F).withValues(alpha: 0.48),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(shortLandscape ? 10 : 14),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFD6A84F),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  analysis.bestMove == null
                                      ? 'No legal move'
                                      : 'Recommended: ${analysis.bestMove}\n${analysis.coachLine}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnalysisMetric extends StatelessWidget {
  const AnalysisMetric({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: const Color(0xFF63D2B8)),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class OnlineMatchmakingSheet extends StatefulWidget {
  const OnlineMatchmakingSheet({
    required this.api,
    required this.token,
    super.key,
  });

  final OnlineMatchApi api;
  final String token;

  @override
  State<OnlineMatchmakingSheet> createState() => _OnlineMatchmakingSheetState();
}

class _OnlineMatchmakingSheetState extends State<OnlineMatchmakingSheet> {
  static const int _randomSearchLimitSeconds = 20;
  final TextEditingController _roomController = TextEditingController();
  Timer? _pollTimer;
  Timer? _elapsedTimer;
  Timer? _foundTimer;
  Timer? _socketReconnectTimer;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  OnlineMatchDto? _match;
  OnlineMatchDto? _foundMatch;
  bool _loading = false;
  bool _randomSearch = false;
  int _elapsedSeconds = 0;
  String? _error;

  @override
  void dispose() {
    final OnlineMatchDto? waiting = _match;
    if (waiting != null && !waiting.isActive) {
      unawaited(
        widget.api
            .cancelWaiting(widget.token, waiting.id)
            .catchError((Object _) => waiting),
      );
    }
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    _foundTimer?.cancel();
    _socketReconnectTimer?.cancel();
    unawaited(_socketSubscription?.cancel());
    unawaited(_channel?.sink.close());
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<OnlineMatchDto> Function() operation, {
    bool randomSearch = false,
  }) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _randomSearch = randomSearch;
      _error = null;
    });
    try {
      final OnlineMatchDto match = await operation();
      if (!mounted) return;
      _accept(match);
    } on OnlineMatchException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _accept(OnlineMatchDto match) {
    if (match.isActive) {
      if (_foundMatch != null) return;
      _pollTimer?.cancel();
      _elapsedTimer?.cancel();
      unawaited(_socketSubscription?.cancel());
      unawaited(_channel?.sink.close());
      _socketReconnectTimer?.cancel();
      setState(() {
        _foundMatch = match;
        _match = match;
      });
      _foundTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) Navigator.of(context).pop(match);
      });
      return;
    }
    final bool sameWaitingMatch = _match?.id == match.id;
    setState(() {
      _match = match;
      if (!sameWaitingMatch) {
        _elapsedSeconds = 0;
      }
    });
    // A poll only refreshes the waiting-match snapshot. Restarting these
    // resources on every two-second poll prevents the one-second elapsed
    // clock from advancing normally and repeatedly tears down a healthy
    // WebSocket connection.
    if (sameWaitingMatch) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_poll()),
    );
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_randomSearch && _elapsedSeconds >= _randomSearchLimitSeconds) {
        unawaited(_expireRandomSearch(match));
      }
    });
    _openSocket(match);
  }

  Future<void> _expireRandomSearch(OnlineMatchDto waiting) async {
    if (!_randomSearch || _match?.id != waiting.id || _foundMatch != null) {
      return;
    }
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    _socketReconnectTimer?.cancel();
    await _socketSubscription?.cancel();
    await _channel?.sink.close();
    try {
      await widget.api.cancelWaiting(widget.token, waiting.id);
    } on OnlineMatchException {
      // The lobby may already have expired server-side.
    }
    if (!mounted || _match?.id != waiting.id || _foundMatch != null) return;
    setState(() {
      _match = null;
      _randomSearch = false;
      _loading = false;
      _elapsedSeconds = 0;
      _error =
          'No active rival found in 20 seconds. Try again or play ChessVerseAI.';
    });
  }

  void _openSocket(OnlineMatchDto match) {
    _socketReconnectTimer?.cancel();
    unawaited(_socketSubscription?.cancel());
    unawaited(_channel?.sink.close());
    try {
      final WebSocketChannel channel =
          widget.api.openMatchChannel(widget.token, match.id);
      _channel = channel;
      _socketSubscription = channel.stream.listen(
        (_) => unawaited(_poll()),
        onError: (_) => _scheduleSocketReconnect(match),
        onDone: () => _scheduleSocketReconnect(match),
        cancelOnError: true,
      );
    } on Object {
      _scheduleSocketReconnect(match);
    }
  }

  void _scheduleSocketReconnect(OnlineMatchDto match) {
    if (!mounted || _match?.id != match.id || _foundMatch != null) return;
    _socketReconnectTimer?.cancel();
    _socketReconnectTimer = Timer(
      const Duration(seconds: 3),
      () => _openSocket(match),
    );
  }

  Future<void> _poll() async {
    final OnlineMatchDto? current = _match;
    if (current == null) return;
    try {
      final OnlineMatchDto latest =
          await widget.api.getMatch(widget.token, current.id);
      if (!mounted) return;
      _accept(latest);
    } on OnlineMatchException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _cancelWaiting() async {
    final OnlineMatchDto? waiting = _match;
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    unawaited(_socketSubscription?.cancel());
    unawaited(_channel?.sink.close());
    _socketReconnectTimer?.cancel();
    if (waiting != null) {
      try {
        await widget.api.cancelWaiting(widget.token, waiting.id);
      } on OnlineMatchException {
        // Closing the lobby remains responsive if connectivity disappeared.
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool wideLayout = size.width >= 900 && size.height >= 600;
    final double maxWidth = wideLayout ? 1180 : math.min(560, size.width - 20);
    final double maxHeight = size.height * (wideLayout ? 0.94 : 0.96);
    final OnlineMatchDto? found = _foundMatch;

    if (wideLayout && found == null && _match == null) {
      return _buildDesktopLobby(context);
    }

    if (found != null) {
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _OpponentFoundView(match: found),
          ),
        ),
      );
    }

    final OnlineMatchDto? waiting = _match;
    if (waiting != null && !waiting.isActive) {
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: math.min(maxWidth, 460)),
            child: _MatchSearchingView(
              randomSearch: _randomSearch,
              roomCode: waiting.roomCode,
              elapsedSeconds: _elapsedSeconds,
              onCopyCode: () {
                Clipboard.setData(ClipboardData(text: waiting.roomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied')),
                );
              },
              onCancel: () => unawaited(_cancelWaiting()),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF071725), Color(0xFF04111D)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF1B3149)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wideLayout ? 28 : 18,
                wideLayout ? 22 : 18,
                wideLayout ? 28 : 18,
                wideLayout ? 24 : 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: wideLayout ? 58 : 44,
                        height: wideLayout ? 58 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0B2530),
                          border: Border.all(color: const Color(0xFF38D5B6)),
                        ),
                        child: Icon(
                          Icons.castle_rounded,
                          size: wideLayout ? 34 : 26,
                          color: const Color(0xFF63D2B8),
                        ),
                      ),
                      SizedBox(width: wideLayout ? 18 : 12),
                      Expanded(
                        child: Text(
                          'Online 2 Players',
                          style: (wideLayout
                                  ? Theme.of(context).textTheme.headlineMedium
                                  : Theme.of(context).textTheme.headlineSmall)
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: wideLayout ? 2 : 8),
                  const Text(
                    'Play online with a random opponent or invite a friend to a private room.',
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFFF6B6B)),
                    ),
                  ],
                  SizedBox(height: wideLayout ? 22 : 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/backgrounds/online-matchmaking-hero-v1.png',
                        ),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        opacity: .78,
                      ),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xD9051B35), Color(0x77071936)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF2F9CFF),
                        width: 1.4,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Color(0x442F9CFF), blurRadius: 20),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: wideLayout ? 230 : 18,
                        vertical: wideLayout ? 30 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.travel_explore_rounded,
                                color: Color(0xFFD6A84F),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Random Match',
                                  style: (wideLayout
                                          ? Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                          : Theme.of(context)
                                              .textTheme
                                              .titleLarge)
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              if (_loading)
                                const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'We’ll find a player for you from around the world.',
                          ),
                          SizedBox(height: wideLayout ? 18 : 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: wideLayout ? 280 : 210,
                              height: wideLayout ? 52 : 46,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: wideLayout ? 17 : 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                onPressed: _loading
                                    ? null
                                    : () => _run(
                                          () => widget.api
                                              .randomMatch(widget.token),
                                          randomSearch: true,
                                        ),
                                icon: Icon(
                                  Icons.bolt_rounded,
                                  size: wideLayout ? 22 : 20,
                                ),
                                label: const Text('Find Match'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF081D2A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF267D72)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(wideLayout ? 22 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF0A2630),
                                  border: Border.all(
                                    color: const Color(0xFF267D72),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.group_rounded,
                                  color: Color(0xFF55D5C0),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  'Play with Friend',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_match == null)
                            const Text(
                              'Create a private room or join one using a room code.',
                            )
                          else ...<Widget>[
                            SelectableText(
                              _match!.roomCode,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: const Color(0xFFD6A84F),
                                    letterSpacing: 2,
                                    fontSize: wideLayout ? 30 : null,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Waiting for opponent… this screen reconnects automatically.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _match!.roomCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invite code copied'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copy invite code'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _roomController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Enter room code',
                      hintText: 'e.g. ABCD1234',
                      suffixIcon: Icon(Icons.copy_rounded),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _run(
                                  () => widget.api.createRoom(widget.token),
                                ),
                        icon: const Icon(Icons.group_add_rounded),
                        label: const Text('Create Room'),
                      ),
                      FilledButton.icon(
                        onPressed:
                            _loading || _roomController.text.trim().isEmpty
                                ? null
                                : () => _run(
                                      () => widget.api.joinRoom(
                                        widget.token,
                                        _roomController.text,
                                      ),
                                    ),
                        icon: const Icon(Icons.sports_esports_rounded),
                        label: const Text('Join Room'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _loading
                        ? null
                        : () => _run(
                              () => widget.api.reconnect(widget.token),
                            ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF081725),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF233B51)),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(
                            Icons.sync_rounded,
                            color: Color(0xFF3CA6FF),
                            size: 32,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Reconnect',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text('Reconnect to your last game.'),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF081725),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF233B51)),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF43D6C1),
                          size: 32,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Moves are validated by ChessVerse AI servers.\n'
                            'Active matches restore after an app restart.',
                            style: TextStyle(
                              color: Color(0xFFAAAFC0),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLobby(BuildContext context) {
    const Color teal = Color(0xFF45D7C3);
    const Color gold = Color(0xFFF0B93F);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool compactDesktop = MediaQuery.sizeOf(context).width < 1250;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF03111F),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1A3449)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: <Widget>[
            DesktopAppSidebar(
              selected: 'Play',
              onHome: () => Navigator.of(context).pop(),
              onPlay: () {},
              onPuzzles: () => Navigator.of(context).pop(),
              onLearn: () => Navigator.of(context).pop(),
              onAnalysis: () => Navigator.of(context).pop(),
              onRankings: () => Navigator.of(context).pop(),
              onFriends: () {},
              onEvents: () {},
              onStore: () {},
              onSettings: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(compactDesktop ? 24 : 38,
                    compactDesktop ? 22 : 30, compactDesktop ? 24 : 42, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF082431),
                            border: Border.all(color: teal),
                          ),
                          child: const Icon(Icons.sports_martial_arts_rounded,
                              color: teal, size: 43),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Online 2 Players',
                                  style: textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 38)),
                              const SizedBox(height: 8),
                              const Text(
                                'Play online with a random opponent or invite a friend to a private room.',
                                style: TextStyle(
                                    color: Color(0xFFB8C3D1), fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF0A1A2B),
                              padding: const EdgeInsets.all(16)),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 30),
                        ),
                      ],
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Color(0xFFFF6B6B))),
                    ],
                    const SizedBox(height: 28),
                    Container(
                      height: 288,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage(
                              'assets/backgrounds/online-matchmaking-hero-v1.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                            color: const Color(0xFF2F9CFF), width: 1.6),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Color(0x442F9CFF), blurRadius: 18),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(compactDesktop ? 175 : 305,
                            38, compactDesktop ? 28 : 410, 30),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: compactDesktop ? 360 : 455,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Random Match',
                                    maxLines: 1,
                                    style: textTheme.headlineMedium?.copyWith(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 12),
                                const Text(
                                  'We’ll find a player for you\nfrom around the world.',
                                  style: TextStyle(
                                      color: Color(0xFFC8D1DD),
                                      fontSize: 20,
                                      height: 1.45),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: compactDesktop ? 250 : 290,
                                  height: 54,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: gold,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    onPressed: _loading
                                        ? null
                                        : () => _run(
                                            () => widget.api
                                                .randomMatch(widget.token),
                                            randomSearch: true),
                                    icon: const Icon(
                                      Icons.bolt_rounded,
                                      size: 24,
                                    ),
                                    label: const Text('Find Match'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 280,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xD9071A29),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF267D72)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(children: <Widget>[
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFF267D72)),
                                    ),
                                    child: const Icon(Icons.group_rounded,
                                        color: teal, size: 38),
                                  ),
                                  const SizedBox(width: 20),
                                  const Text('Play with Friend',
                                      style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900)),
                                ]),
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.only(left: 88),
                                  child: Text(
                                    'Create a private room or join\none using a room code.',
                                    style: TextStyle(
                                        color: Color(0xFFB8C3D1),
                                        fontSize: 18,
                                        height: 1.4),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                TextField(
                                  controller: _roomController,
                                  onChanged: (_) => setState(() {}),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter room code',
                                    hintText: 'e.g. ABCD1234',
                                    suffixIcon: Icon(Icons.copy_rounded),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          const VerticalDivider(color: Color(0xFF244257)),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  width: double.infinity,
                                  height: 76,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Color(0xFF23D8C2)),
                                      textStyle: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    onPressed: _loading
                                        ? null
                                        : () => _run(() => widget.api
                                            .createRoom(widget.token)),
                                    icon: const Icon(Icons.person_add_rounded,
                                        color: teal, size: 32),
                                    label: const Text('Create Room'),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 76,
                                  child: OutlinedButton.icon(
                                    onPressed: _loading ||
                                            _roomController.text.trim().isEmpty
                                        ? null
                                        : () => _run(() => widget.api.joinRoom(
                                            widget.token,
                                            _roomController.text)),
                                    icon: const Icon(
                                        Icons.sports_esports_rounded,
                                        size: 32),
                                    label: const Text('Join Room'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DesktopOnlineActionRow(
                      icon: Icons.sync_rounded,
                      iconColor: const Color(0xFF3CA6FF),
                      title: 'Reconnect',
                      subtitle: 'Reconnect to your last game.',
                      onTap: _loading
                          ? null
                          : () =>
                              _run(() => widget.api.reconnect(widget.token)),
                    ),
                    const SizedBox(height: 18),
                    const _DesktopOnlineValidationRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopOnlineActionRow extends StatelessWidget {
  const _DesktopOnlineActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF071725),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF233B51)),
          ),
          child: Row(children: <Widget>[
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF233B51))),
              child: Icon(icon, color: iconColor, size: 39),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFFB8C3D1), fontSize: 17)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 34),
          ]),
        ),
      );
}

class _DesktopOnlineValidationRow extends StatelessWidget {
  const _DesktopOnlineValidationRow();
  @override
  Widget build(BuildContext context) => Container(
        height: 98,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF071725),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF233B51)),
        ),
        child: const Row(children: <Widget>[
          Icon(Icons.verified_user_outlined,
              color: Color(0xFF43D6C1), size: 48),
          SizedBox(width: 22),
          Text(
            'Moves are validated by ChessVerse AI servers.\nActive matches restore after an app restart.',
            style:
                TextStyle(color: Color(0xFFB8C3D1), fontSize: 17, height: 1.45),
          ),
        ]),
      );
}

class _MatchSearchingView extends StatefulWidget {
  const _MatchSearchingView({
    required this.randomSearch,
    required this.roomCode,
    required this.elapsedSeconds,
    required this.onCopyCode,
    required this.onCancel,
  });

  final bool randomSearch;
  final String roomCode;
  final int elapsedSeconds;
  final VoidCallback onCopyCode;
  final VoidCallback onCancel;

  @override
  State<_MatchSearchingView> createState() => _MatchSearchingViewState();
}

class _MatchSearchingViewState extends State<_MatchSearchingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String timer =
        '${(widget.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(widget.elapsedSeconds % 60).toString().padLeft(2, '0')}';
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
        decoration: BoxDecoration(
          color: const Color(0xFF071A2C),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD7A84E), width: 1.3),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF63D2B8).withValues(alpha: 0.22),
              blurRadius: 38,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'FINDING YOUR RIVAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE5B856),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 26),
            AnimatedBuilder(
              animation: _pulse,
              builder: (BuildContext context, Widget? child) {
                final double value = Curves.easeInOut.transform(_pulse.value);
                return SizedBox.square(
                  dimension: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: 92 + value * 48,
                        height: 92 + value * 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF63D2B8,
                            ).withValues(alpha: 0.12 + value * 0.28),
                            width: 2,
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: value * math.pi * 0.32,
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: <Color>[
                                Color(0x0063D2B8),
                                Color(0xFF63D2B8),
                                Color(0x0063D2B8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10283A),
                          border: Border.all(color: const Color(0xFF63D2B8)),
                        ),
                        child: const Icon(
                          Icons.public_rounded,
                          size: 42,
                          color: Color(0xFF63D2B8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Text(
              widget.randomSearch
                  ? 'Searching worldwide players...'
                  : 'Waiting for your friend...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              timer,
              style: const TextStyle(
                color: Color(0xFF63D2B8),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFeatures: <ui.FontFeature>[ui.FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 18),
            if (!widget.randomSearch) ...<Widget>[
              const Text(
                'SHARE ROOM CODE',
                style: TextStyle(
                  color: Color(0xFFAAA69E),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.roomCode,
                style: const TextStyle(
                  color: Color(0xFFE5B856),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              TextButton.icon(
                onPressed: widget.onCopyCode,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy code'),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'Keep this screen open. Your match starts automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAA69E), fontSize: 12),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpponentFoundView extends StatelessWidget {
  const _OpponentFoundView({required this.match});

  final OnlineMatchDto match;

  @override
  Widget build(BuildContext context) {
    final String you = match.yourColor == 'WHITE'
        ? (match.whitePlayerName ?? 'You')
        : (match.blackPlayerName ?? 'You');
    final String rival = match.yourColor == 'WHITE'
        ? (match.blackPlayerName ?? 'Online Rival')
        : (match.whitePlayerName ?? 'Online Rival');
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        builder: (BuildContext context, double value, Widget? child) {
          return Opacity(
            opacity: value.clamp(0, 1),
            child: Transform.scale(
              scale: 0.86 + value * 0.14,
              child: Container(
                margin: const EdgeInsets.all(18),
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFF123A42), Color(0xFF071A2C)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFE5B856),
                    width: 1.5,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(
                        0xFFE5B856,
                      ).withValues(alpha: 0.24),
                      blurRadius: 46,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF63D2B8),
                      size: 42,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'OPPONENT FOUND',
                      style: TextStyle(
                        color: Color(0xFF63D2B8),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _VersusPlayerCard(
                            name: you,
                            color: const Color(0xFF3D9FFF),
                            label: 'YOU',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Transform.scale(
                            scale: value,
                            child: const Text(
                              'VS',
                              style: TextStyle(
                                color: Color(0xFFE5B856),
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _VersusPlayerCard(
                            name: rival,
                            color: const Color(0xFFFF5577),
                            label: 'RIVAL',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const LinearProgressIndicator(
                      minHeight: 5,
                      color: Color(0xFF63D2B8),
                      backgroundColor: Color(0xFF163344),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Preparing the board...',
                      style: TextStyle(color: Color(0xFFD7D4CC)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VersusPlayerCard extends StatelessWidget {
  const _VersusPlayerCard({
    required this.name,
    required this.color,
    required this.label,
  });

  final String name;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.person_rounded, color: color, size: 48),
        ),
        const SizedBox(height: 9),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class MoveHistorySheet extends StatelessWidget {
  const MoveHistorySheet({required this.moves, super.key});

  final List<String> moves;

  @override
  Widget build(BuildContext context) {
    final List<String> chronological = moves.reversed.toList(growable: false);
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (BuildContext context, ScrollController controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF17231F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Move History',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: chronological.isEmpty
                      ? const EmptyMoveState()
                      : ListView.separated(
                          controller: controller,
                          itemCount: chronological.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final bool whiteMove = index.isEven;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: whiteMove
                                    ? const Color(0xFFE9D5B7)
                                    : const Color(0xFF242128),
                                foregroundColor:
                                    whiteMove ? Colors.black : Colors.white,
                                child: Text('${index + 1}'),
                              ),
                              title: Row(
                                children: <Widget>[
                                  Expanded(child: Text(chronological[index])),
                                  MoveQualityBadge(move: chronological[index]),
                                ],
                              ),
                              subtitle: Text(
                                moveCoachNoteForMove(
                                  chronological[index],
                                  whiteMove,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MoveQualityBadge extends StatelessWidget {
  const MoveQualityBadge({required this.move, super.key});

  final String move;

  @override
  Widget build(BuildContext context) {
    final String label = moveCoachLabelForMove(move);
    final Color color = moveCoachColorForLabel(label);
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String moveCoachLabelForMove(String move) {
  final String clean = move.replaceAll(' e.p.', '').trim().toLowerCase();
  if (clean.contains('o-o') || clean.contains('+') || clean.contains('check')) {
    return 'Superb';
  }
  if (clean.contains('x')) {
    return 'Good';
  }
  if (clean.length >= 4 &&
      <String>{
        'd4',
        'd5',
        'e4',
        'e5',
      }.contains(clean.substring(clean.length - 2))) {
    return 'Good';
  }
  return 'Average';
}

Color moveCoachColorForLabel(String label) {
  return switch (label) {
    'Superb' => const Color(0xFF63D2B8),
    'Good' => const Color(0xFFD6A84F),
    _ => const Color(0xFFAAA69E),
  };
}

String moveCoachNoteForMove(String move, bool whiteMove) {
  final String side = whiteMove ? 'White' : 'Black';
  final String clean = move.replaceAll(' e.p.', '').trim();
  if (clean.contains('O-O')) {
    return '$side superb step: king safety improved. Best follow-up is central pressure.';
  }
  if (clean.contains('+') || clean.toLowerCase().contains('check')) {
    return '$side superb step: check creates tempo. Calculate every king reply.';
  }
  if (clean.contains('x')) {
    return '$side good step: capture found. Before moving, compare checks and stronger captures.';
  }
  if (clean.length >= 4 &&
      <String>{
        'd4',
        'd5',
        'e4',
        'e5',
      }.contains(clean.substring(clean.length - 2))) {
    return '$side good step: central square controlled. Next develop with tempo.';
  }
  return '$side average step: playable. Best habit: check checks, captures, then threats.';
}

class BoardThemeChoice extends StatelessWidget {
  const BoardThemeChoice({
    required this.palette,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final BoardPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${palette.label} board',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 104,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? palette.accent.withValues(alpha: 0.16)
                : const Color(0xFF202329),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? palette.accent : const Color(0xFF45474C),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  width: 25,
                  height: 25,
                  child: Row(
                    children: <Widget>[
                      Expanded(child: ColoredBox(color: palette.light)),
                      Expanded(child: ColoredBox(color: palette.dark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  palette.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyMoveState extends StatelessWidget {
  const EmptyMoveState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF242128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3B352D)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Select a coin, then choose its target square.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class SessionLoadingOverlay extends StatelessWidget {
  const SessionLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF07120F),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ChessVerseMark(size: 76),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Color(0xFFD6A84F)),
            SizedBox(height: 14),
            Text('Restoring your secure session...'),
          ],
        ),
      ),
    );
  }
}

class AuthOverlay extends StatelessWidget {
  const AuthOverlay({
    required this.registerMode,
    required this.awaitingCode,
    required this.message,
    required this.hasError,
    required this.onModeChanged,
    required this.onUsernameChanged,
    required this.onDisplayNameChanged,
    required this.onIdentityChanged,
    required this.onPasswordChanged,
    required this.onCodeChanged,
    required this.onSubmit,
    required this.onContinueDefault,
    required this.onFacebookLogin,
    required this.onForgotPassword,
    required this.onResendCode,
    required this.onBackFromCode,
    required this.loading,
    super.key,
  });

  final bool registerMode;
  final bool awaitingCode;
  final String message;
  final bool hasError;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<String> onDisplayNameChanged;
  final ValueChanged<String> onIdentityChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onContinueDefault;
  final VoidCallback onFacebookLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onResendCode;
  final VoidCallback onBackFromCode;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF07120F).withValues(alpha: 0.97),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF15161B).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD6A84F)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFD6A84F).withValues(alpha: 0.18),
                      blurRadius: 38,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const ChessVerseMark(size: 34),
                          const SizedBox(width: 8),
                          Text(
                            'CHESSVERSEAI',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        registerMode
                            ? 'Create ChessVerseAI ID'
                            : 'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      if (!hasError && message.trim().isNotEmpty)
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 16),
                      if (!awaitingCode)
                        SegmentedButton<bool>(
                          segments: const <ButtonSegment<bool>>[
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Register'),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Login'),
                            ),
                          ],
                          selected: <bool>{registerMode},
                          onSelectionChanged: (Set<bool> selected) {
                            onModeChanged(selected.first);
                          },
                        ),
                      if (!awaitingCode) const SizedBox(height: 14),
                      if (!awaitingCode) ...<Widget>[
                        if (registerMode) ...<Widget>[
                          TextField(
                            onChanged: onUsernameChanged,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'User ID',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: onDisplayNameChanged,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Player name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          onChanged: onIdentityChanged,
                          textInputAction: TextInputAction.next,
                          keyboardType: registerMode
                              ? TextInputType.emailAddress
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText:
                                registerMode ? 'Email' : 'User ID or email',
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: onPasswordChanged,
                          obscureText: true,
                          onSubmitted: (_) => onSubmit(),
                          decoration: InputDecoration(
                            labelText:
                                registerMode ? 'Create password' : 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            helperText:
                                registerMode ? 'At least 8 characters' : null,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        if (!registerMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: loading ? null : onForgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                      ],
                      if (awaitingCode) ...<Widget>[
                        const SizedBox(height: 18),
                        Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD6A84F,
                              ).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Icon(
                                Icons.mark_email_read_outlined,
                                color: Color(0xFFD6A84F),
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          onChanged: onCodeChanged,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                          onSubmitted: (_) => onSubmit(),
                          decoration: const InputDecoration(
                            labelText: 'Six-digit verification code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (hasError) ...<Widget>[
                        const SizedBox(height: 14),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF5350,
                            ).withValues(alpha: 0.12),
                            border: Border.all(
                              color: const Color(
                                0xFFEF5350,
                              ).withValues(alpha: 0.65),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFFF7774),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      color: Color(0xFFFFB4B2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: loading ? null : onSubmit,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                awaitingCode
                                    ? Icons.verified_rounded
                                    : Icons.login_rounded,
                              ),
                        label: Text(
                          awaitingCode
                              ? 'Verify and Continue'
                              : registerMode
                                  ? 'Send Code'
                                  : 'Login',
                        ),
                      ),
                      if (!awaitingCode) ...<Widget>[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: loading ? null : onContinueDefault,
                          icon: const Icon(Icons.person_pin_circle_outlined),
                          label: const Text('Continue as Guest Player'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: loading ? null : onFacebookLogin,
                          icon: const Icon(Icons.facebook_rounded),
                          label: const Text(
                            'Facebook Login',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (awaitingCode)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: loading ? null : onResendCode,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Resend code'),
                            ),
                            TextButton.icon(
                              onPressed: loading ? null : onBackFromCode,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Change details'),
                            ),
                          ],
                        ),
                      if (!awaitingCode) ...<Widget>[
                        const SizedBox(height: 14),
                        const Text(
                          'Use a verified ChessVerseAI account to save games, ratings and coach history. Guest Player is local-only for quick testing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFAAA69E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.72),
        child: Semantics(
          liveRegion: true,
          label: 'Your turn',
          child: TweenAnimationBuilder<double>(
            key: const ValueKey<String>('prominent-turn-banner'),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: const Text(
              'YOUR TURN',
              style: TextStyle(
                color: Color(0xFF4DA8FF),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                shadows: <Shadow>[
                  Shadow(color: Colors.black, blurRadius: 12),
                  Shadow(color: Color(0xFF0756A6), blurRadius: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnlineReconnectCountdown extends StatelessWidget {
  const OnlineReconnectCountdown({required this.secondsRemaining, super.key});

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final String countdown =
        '00:${secondsRemaining.clamp(0, 60).toString().padLeft(2, '0')}';
    return IgnorePointer(
      child: Center(
        child: Semantics(
          liveRegion: true,
          label: 'Waiting for opponent. $secondsRemaining seconds remaining.',
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xF20A1D2C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7B84B), width: 1.4),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x77000000), blurRadius: 24),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Color(0xFF63D2B8),
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Text(
                    'WAITING FOR OPPONENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    countdown,
                    style: const TextStyle(
                      color: Color(0xFFE7B84B),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFeatures: <ui.FontFeature>[
                        ui.FontFeature.tabularFigures(),
                      ],
                    ),
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

class OnlineVictoryCelebration extends StatefulWidget {
  const OnlineVictoryCelebration({
    required this.winnerAtTop,
    required this.title,
    this.showTitle = true,
    super.key,
  });

  final bool winnerAtTop;
  final String title;
  final bool showTitle;

  @override
  State<OnlineVictoryCelebration> createState() =>
      _OnlineVictoryCelebrationState();
}

class _OnlineVictoryCelebrationState extends State<OnlineVictoryCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.showTitle
              ? TweenAnimationBuilder<double>(
                  key: ValueKey<String>('victory-title-${widget.title}'),
                  tween: Tween<double>(begin: .35, end: 1),
                  duration: const Duration(milliseconds: 950),
                  curve: Curves.elasticOut,
                  builder:
                      (BuildContext context, double scale, Widget? child) =>
                          Transform.scale(scale: scale, child: child),
                  child: Align(
                    alignment: const Alignment(0, -0.48),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFFE5A92F), Color(0xFFFFE18A)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Color(0xAAE5A92F), blurRadius: 30),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(Icons.emoji_events_rounded,
                                  color: Color(0xFF07131E)),
                              const SizedBox(width: 9),
                              Text(widget.title.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF07131E),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  )),
                            ]),
                      ),
                    ),
                  ),
                )
              : null,
          builder: (BuildContext context, Widget? child) => Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _VictoryFireworksPainter(
                    progress: _controller.value,
                    winnerAtTop: widget.winnerAtTop,
                  ),
                ),
              ),
              if (child != null) child,
            ],
          ),
        ),
      );
}

class _VictoryFireworksPainter extends CustomPainter {
  const _VictoryFireworksPainter({
    required this.progress,
    required this.winnerAtTop,
  });

  final double progress;
  final bool winnerAtTop;

  static const List<Color> _colors = <Color>[
    Color(0xFFFFC857),
    Color(0xFF63D2B8),
    Color(0xFFFF6B6B),
    Color(0xFF6EA8FF),
    Color(0xFFC77DFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double bandCenter =
        winnerAtTop ? size.height * .24 : size.height * .76;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    for (int burst = 0; burst < 5; burst++) {
      final double phase = (progress + burst * .19) % 1;
      final double opacity = (1 - phase).clamp(0.0, 1.0);
      final Offset center = Offset(
        size.width * (.14 + burst * .18),
        bandCenter + math.sin(burst * 1.7) * size.height * .08,
      );
      for (int ray = 0; ray < 12; ray++) {
        final double angle = (math.pi * 2 * ray / 12) + burst * .35;
        final double radius =
            (18 + 88 * phase) * math.min(1.25, size.shortestSide / 420);
        final Offset particle =
            center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        paint.color =
            _colors[(burst + ray) % _colors.length].withValues(alpha: opacity);
        canvas.drawCircle(particle, 2.2 + 2.8 * opacity, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VictoryFireworksPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.winnerAtTop != winnerAtTop;
}

class GameResultOverlay extends StatelessWidget {
  const GameResultOverlay({
    required this.title,
    required this.detail,
    required this.scoreLabel,
    required this.accuracy,
    required this.turningPoint,
    required this.onNewGame,
    this.newGameLabel,
    this.onRematch,
    required this.onDismiss,
    required this.onReview,
    super.key,
  });

  final String title;
  final String detail;
  final String scoreLabel;
  final int? accuracy;
  final String? turningPoint;
  final VoidCallback onNewGame;
  final String? newGameLabel;
  final VoidCallback? onRematch;
  final VoidCallback onDismiss;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final bool draw = title.toLowerCase().contains('draw');
    final bool missed = title.toLowerCase().contains('challenge missed');
    final bool dailyComplete =
        title.toLowerCase().contains('challenge complete');
    final Widget resultCard = ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewport) {
            final bool shortLandscape =
                viewport.maxWidth > viewport.maxHeight &&
                    viewport.maxHeight < 500;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: viewport.maxHeight - 12,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF17181D),
                    border: Border.all(color: const Color(0xFFD6A84F)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFFD6A84F).withValues(alpha: 0.25),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(shortLandscape ? 16 : 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          draw
                              ? Icons.handshake_rounded
                              : missed
                                  ? Icons.flag_outlined
                                  : Icons.emoji_events_rounded,
                          color: draw
                              ? const Color(0xFFAAA69E)
                              : missed
                                  ? const Color(0xFF68D2BE)
                                  : const Color(0xFFD6A84F),
                          size: shortLandscape ? 38 : 56,
                        ),
                        SizedBox(height: shortLandscape ? 6 : 16),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: shortLandscape ? 3 : 8),
                        Text(
                          scoreLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: missed
                                    ? const Color(0xFF68D2BE)
                                    : const Color(0xFFD6A84F),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        SizedBox(height: shortLandscape ? 3 : 8),
                        Text(detail, textAlign: TextAlign.center),
                        if (accuracy != null) ...<Widget>[
                          SizedBox(height: shortLandscape ? 5 : 10),
                          Text(
                            'AI accuracy: $accuracy%',
                            style: const TextStyle(
                              color: Color(0xFF57E0C3),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (turningPoint != null)
                            Text(
                              'Turning point: $turningPoint',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFFFFC857)),
                            ),
                        ],
                        SizedBox(height: shortLandscape ? 3 : 8),
                        Text(
                          missed
                              ? 'This attempt is not counted as a loss. Review the position and retry today.'
                              : 'Saved locally. Open Saved Games to review this match.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFAAA69E)),
                        ),
                        SizedBox(height: shortLandscape ? 10 : 24),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onReview,
                                icon: const Icon(Icons.analytics_outlined),
                                label: const Text('AI Review My Game'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: (onRematch == null)
                                  ? FilledButton.icon(
                                      onPressed:
                                          dailyComplete ? onDismiss : onNewGame,
                                      icon: Icon(
                                        dailyComplete
                                            ? Icons.schedule_rounded
                                            : Icons.refresh_rounded,
                                      ),
                                      label: Text(
                                        dailyComplete
                                            ? 'Done'
                                            : missed
                                                ? 'Try again'
                                                : newGameLabel ?? 'New game',
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: onRematch,
                                      icon: const Icon(Icons.sync_rounded),
                                      label: const Text('Rematch'),
                                    ),
                            ),
                          ],
                        ),
                        if (onRematch != null) ...<Widget>[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onNewGame,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('New opponent'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    if (draw || missed) return resultCard;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        resultCard,
        Positioned.fill(
          child: OnlineVictoryCelebration(
            winnerAtTop: true,
            title: title,
          ),
        ),
      ],
    );
  }
}

class CoachInsight extends StatelessWidget {
  const CoachInsight({required this.note, required this.enabled, super.key});

  final String note;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF242128) : const Color(0xFF17171B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? const Color(0xFF6C5530) : const Color(0xFF323238),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              enabled
                  ? Icons.psychology_alt_rounded
                  : Icons.visibility_off_rounded,
              color: const Color(0xFFD6A84F),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                enabled ? note : 'AI coach is paused.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CapturedMaterial extends StatelessWidget {
  const CapturedMaterial({
    required this.capturedWhite,
    required this.capturedBlack,
    super.key,
  });

  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Captured', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: CaptureRow(label: 'White', pieces: capturedWhite),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CaptureRow(label: 'Black', pieces: capturedBlack),
            ),
          ],
        ),
      ],
    );
  }
}

class CaptureRow extends StatelessWidget {
  const CaptureRow({required this.label, required this.pieces, super.key});

  final String label;
  final List<ChessPiece> pieces;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF202127),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B352D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: pieces.isEmpty
                  ? <Widget>[
                      const Text(
                        '-',
                        style: TextStyle(color: Color(0xFF9B948A)),
                      ),
                    ]
                  : pieces
                      .map(
                        (ChessPiece piece) => MiniCapturedPiece(piece: piece),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniCapturedPiece extends StatelessWidget {
  const MiniCapturedPiece({required this.piece, super.key});

  final ChessPiece piece;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: piece.white
              ? const <Color>[Color(0xFF30343C), Color(0xFF080A0F)]
              : const <Color>[Color(0xFFFFFFFF), Color(0xFFD8DCE3)],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color:
              piece.white ? const Color(0xFF8A909B) : const Color(0xFFFFFFFF),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: piece.white
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ValueListenableBuilder<ChessPieceAppearance>(
            valueListenable: ChessPieceAppearanceController.current,
            builder:
                (BuildContext context, ChessPieceAppearance appearance, _) {
              if (appearance.style == ChessPieceVisualStyle.classic2d) {
                return Text(
                  pieceGlyph(piece),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 28,
                    height: 1,
                    color: piece.white
                        ? const Color(0xFFFFF4D0)
                        : const Color(0xFF111722),
                    shadows: const <Shadow>[
                      Shadow(color: Colors.black87, blurRadius: 2),
                    ],
                  ),
                );
              }
              Widget image = Image.asset(
                pieceAsset(piece),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                semanticLabel:
                    'Captured ${piece.white ? 'white' : 'black'} ${pieceName(piece.code)}',
              );
              if (appearance.style == ChessPieceVisualStyle.highContrast) {
                image = ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    piece.white
                        ? const Color(0xFFFFF0B8)
                        : const Color(0xFF89BFFF),
                    BlendMode.modulate,
                  ),
                  child: image,
                );
              }
              return image;
            },
          ),
        ),
      ),
    );
  }
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final String initial =
        name.trim().isEmpty ? 'P' : name.trim().substring(0, 1).toUpperCase();
    return Tooltip(
      message: 'Signed in as $name',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF245A4A),
          border: Border.all(color: const Color(0xFF63D2B8), width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF63D2B8).withValues(alpha: 0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MatchClock extends StatelessWidget {
  const MatchClock({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1C20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3124)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF242128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B352D)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xFFD6A84F)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF6F1E8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
