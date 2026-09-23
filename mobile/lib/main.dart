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

import 'core/analytics/app_analytics.dart';
import 'core/ai_bot_preset_store.dart';
import 'core/app_language.dart';
import 'core/coach_localizations.dart';
import 'core/coach_extra_localizations.dart';
import 'core/live_coach_localizations.dart';
import 'core/analysis_dashboard_localizations.dart';
import 'core/computer_game_store.dart';
import 'core/review_narrative_localizations.dart';
import 'core/ads/rewarded_coin_service.dart';
import 'core/ads/post_match_ad_service.dart';
import 'core/audio/chess_sound_service.dart';
import 'core/auth/facebook_sdk_ready.dart';
import 'core/app_preferences.dart';
import 'core/web_launch_policy.dart';
import 'core/chess_piece_appearance.dart';
import 'core/config/app_config.dart';
import 'core/diagnostics/app_diagnostics.dart';
import 'core/local_game_archive.dart';
import 'core/notifications/daily_reminder_service.dart';
import 'core/notifications/notification_preview.dart';
import 'core/notifications/firebase_push_service.dart';
import 'core/store_review_service.dart';
import 'core/widgets/chessverse_app_backdrop.dart';
import 'core/widgets/ai_language_picker.dart';
import 'core/widgets/desktop_app_sidebar.dart';
import 'core/widgets/network_status_layer.dart';
import 'core/widgets/coin_balance_badge.dart';
import 'core/desktop_navigation_bridge.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_session_store.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/engine/data/engine_api.dart';
import 'features/analysis/domain/ai_review_report.dart';
import 'features/analysis/data/game_analysis_api.dart';
import 'features/analysis/presentation/analysis_screen.dart';
import 'features/analysis/presentation/adaptive_ai_review.dart';
import 'features/home/presentation/home_dashboard_screen.dart';
import 'features/library/presentation/reference_screens.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/online/data/online_match_api.dart';
import 'features/online/data/pgn_archive_service.dart';
import 'features/online/presentation/match_history_screen.dart';
import 'features/online/presentation/spectator_screen.dart';
import 'features/notifications/data/notification_api.dart';
import 'features/notifications/presentation/notification_center_screen.dart';
import 'features/leaderboard/presentation/leaderboard_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/missions/presentation/missions_screen.dart';
import 'features/shop/presentation/cosmetic_shop_screen.dart';
import 'features/shop/data/economy_rewards_api.dart';
import 'features/puzzles/domain/puzzle_catalog.dart';
import 'features/play/presentation/position_creator_screen.dart';
import 'features/progress/data/cloud_progress_api.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/social/presentation/social_hub_screen.dart';
import 'features/social/data/community_api.dart';
import 'features/tutorial/presentation/learn_chess_screen.dart';
import 'features/tutorial/data/academy_progress_store.dart';

part 'main_parts/app_loading_and_theme.dart';
part 'main_parts/game_domain.dart';
part 'main_parts/game_screen.dart';
part 'main_parts/game_board_widgets.dart';
part 'main_parts/game_panels.dart';
part 'main_parts/online_matchmaking.dart';
part 'main_parts/game_support_widgets.dart';

List<SavedMoveReview> _savedReviewsFromCloud(CloudAnalysisJob job) => job.plies
    .map(
      (CloudAnalysisPly ply) => SavedMoveReview(
        ply: ply.ply,
        fenBefore: ply.fenBefore,
        playedMove: ply.playedMove,
        bestMove: ply.bestMove,
        classification: ply.classification,
        coachingTheme: ply.coachingTheme,
        centipawnLoss: ply.centipawnLoss,
        evaluationBeforeCp: ply.evaluationBeforeCp,
        evaluationAfterCp: ply.evaluationAfterCp,
        mateBefore: ply.mateBefore,
        mateAfter: ply.mateAfter,
        opponentThreat: ply.principalVariation.length > 1
            ? ply.principalVariation[1]
            : '',
        explanation: ply.classification == 'Best'
            ? 'This matched Stockfish’s strongest continuation.'
            : '${ply.bestMove} was stronger by ${ply.centipawnLoss} centipawns.',
        principalVariation: ply.principalVariation,
      ),
    )
    .toList(growable: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebasePushService.instance.initialize();
  await RewardedCoinService.instance.initialize();
  unawaited(PostMatchAdService.instance.load());
  await AppAnalytics.initialize();
  await AppDiagnostics.initialize();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
  }
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
        return NetworkStatusLayer(
          child: ChessVerseAppBackdrop(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const SplashGate(),
    );
  }
}

const List<NavigationDestination>
_primaryNavigationDestinations = <NavigationDestination>[
  NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
  NavigationDestination(
    icon: Icon(Icons.sports_esports_rounded),
    label: 'Play',
  ),
  NavigationDestination(icon: Icon(Icons.extension_rounded), label: 'Puzzles'),
  NavigationDestination(icon: Icon(Icons.school_rounded), label: 'Learn'),
  NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
  NavigationDestination(icon: Icon(Icons.groups_2_rounded), label: 'Community'),
];

class _GlassBottomNavigation extends StatelessWidget {
  const _GlassBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xC90A2233),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x4262E1D0)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x52000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x241E9BFF),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: SizedBox(
              height: 64,
              child: Row(
                children: List<Widget>.generate(
                  _primaryNavigationDestinations.length,
                  (int index) {
                    final NavigationDestination destination =
                        _primaryNavigationDestinations[index];
                    final bool selected = index == selectedIndex;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 5,
                        ),
                        child: Semantics(
                          selected: selected,
                          button: true,
                          label: destination.label,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onDestinationSelected(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0x522C9DCF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: selected
                                    ? const <BoxShadow>[
                                        BoxShadow(
                                          color: Color(0x3828A9DF),
                                          blurRadius: 12,
                                          spreadRadius: -3,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  IconTheme(
                                    data: IconThemeData(
                                      color: selected
                                          ? const Color(0xFFF7F1E5)
                                          : const Color(0xFFC3D1DC),
                                      size: selected ? 23 : 22,
                                    ),
                                    child: destination.icon,
                                  ),
                                  const SizedBox(height: 1),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      destination.label,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFFF7F1E5)
                                            : const Color(0xFFC3D1DC),
                                        fontSize: 10.5,
                                        fontWeight: selected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const AuthApi _authApi = AuthApi();
  static const AuthSessionStore _sessionStore = AuthSessionStore();
  static const CloudProgressApi _cloudProgressApi = CloudProgressApi();
  static const GameAnalysisApi _gameAnalysisApi = GameAnalysisApi();
  Timer? _timer;
  late final bool _forceFreshWebLogin;
  Timer? _presenceTimer;
  Timer? _notificationTimer;
  String? _notificationPollingToken;
  Timer? _sessionValidationTimer;
  bool _sessionValidationInFlight = false;
  final Set<String> _seenNotificationIds = <String>{};
  final Set<String> _openedNotificationMatchIds = <String>{};
  bool _openingNotificationMatch = false;
  bool _splashArtworkLoadingStarted = false;
  // The browser owns the first splash while Flutter downloads. Starting the
  // web app on another Flutter splash caused: loader -> splash -> loader.
  // Native platforms do not have that HTML hand-off, so they keep the normal
  // branded splash first.
  _RootStage _stage = kIsWeb ? _RootStage.loading : _RootStage.splash;
  String _playerName = 'Guest Player';
  String? _username;
  String? _email;
  String? _photoUrl;
  bool _isGuest = true;
  bool _cloudSyncInFlight = false;
  bool _cloudSyncQueued = false;
  int? _onlinePlayerCount;
  int? _coinBalance;
  TournamentDto? _nextTournament;
  int _primaryDestination = 0;
  int _communitySection = 0;

  @override
  void initState() {
    super.initState();
    DesktopNavigationBridge.request.addListener(_handleDesktopNavigation);
    _forceFreshWebLogin = consumeFreshWebLaunch();
    DailyReminderService.instance.playOpenRequests.addListener(
      _openPlayFromReminder,
    );
    DailyReminderService.instance.tournamentOpenRequests.addListener(
      _openTournamentsFromReminder,
    );
    DailyReminderService.instance.weeklyReportOpenRequests.addListener(
      _openWeeklyReportFromReminder,
    );
    unawaited(DailyReminderService.instance.initialize());
    if (kIsWeb) {
      unawaited(_restoreSession(forceFreshLogin: _forceFreshWebLogin));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb) return;
    if (_splashArtworkLoadingStarted) return;
    _splashArtworkLoadingStarted = true;
    final Size viewport = MediaQuery.sizeOf(context);
    // Match BrandedSplash exactly: every landscape surface preloads the wide
    // artwork, including phones rotated before or during app startup.
    final bool useWideArtwork =
        viewport.width > viewport.height ||
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
        unawaited(_restoreSession(forceFreshLogin: _forceFreshWebLogin));
      }
    });
  }

  Future<void> _restoreSession({required bool forceFreshLogin}) async {
    if (forceFreshLogin) {
      try {
        await _sessionStore.clear();
      } on Object {
        // Continue to authentication even if browser storage cannot be cleared.
      }
      if (mounted) {
        setState(() => _stage = _RootStage.onboarding);
      }
      return;
    }

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
      if (mounted) setState(() => _stage = _RootStage.onboarding);
      return;
    }
    if (session == null) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _stage = _RootStage.onboarding);
      return;
    }

    StoredAuthSession restoredSession = session;
    if (restoredSession.refreshToken != null &&
        restoredSession.refreshToken!.isNotEmpty) {
      try {
        final Map<String, dynamic> rotated = await _authApi.refresh(
          restoredSession.refreshToken!,
        );
        final DateTime? rotatedExpiry = DateTime.tryParse(
          rotated['expiresAt'] as String? ?? '',
        );
        final String rotatedToken = rotated['token'] as String? ?? '';
        if (rotatedToken.isNotEmpty && rotatedExpiry != null) {
          restoredSession = StoredAuthSession(
            token: rotatedToken,
            expiresAt: rotatedExpiry,
            displayName: restoredSession.displayName,
            username: restoredSession.username,
            email: restoredSession.email,
            photoUrl: restoredSession.photoUrl,
            isGuest: restoredSession.isGuest,
            refreshToken: rotated['refreshToken'] as String?,
            refreshExpiresAt: DateTime.tryParse(
              rotated['refreshExpiresAt'] as String? ?? '',
            ),
            sessionId: rotated['sessionId'] as String?,
          );
          await _sessionStore.write(restoredSession);
        }
      } on AuthApiException catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          await _sessionStore.clear();
          if (mounted) setState(() => _stage = _RootStage.onboarding);
          return;
        }
      }
    }
    String playerName = restoredSession.displayName;
    String? username = restoredSession.username;
    String? email = restoredSession.email;
    String? photoUrl = restoredSession.photoUrl;
    bool isGuest = restoredSession.isGuest;
    try {
      final Map<String, dynamic> player = await _authApi.currentPlayer(
        restoredSession.token,
      );
      playerName =
          _profileValue(player['displayName']) ??
          _profileValue(player['username']) ??
          playerName;
      username = _profileValue(player['username']) ?? username;
      email = _profileValue(player['email']) ?? email;
      photoUrl = _profileValue(player['photoUrl']) ?? photoUrl;
      isGuest = player['guest'] as bool? ?? isGuest;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _sessionStore.clear();
        if (mounted) setState(() => _stage = _RootStage.onboarding);
        return;
      }
      // A valid unexpired local session keeps the user signed in while the
      // network is temporarily unavailable.
    }
    if (!mounted) return;
    await LocalGameArchive.activateIdentity(
      await _sessionStore.progressIdentity(restoredSession),
    );
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
    _openPlayFromReminder();
    _openTournamentsFromReminder();
    _openWeeklyReportFromReminder();
    // Do not make active-match recovery wait for profile/progress sync. A
    // killed mobile process has a short server grace window and must reopen
    // its authoritative match as soon as the authenticated home route exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreActiveOnlineMatch(restoredSession.token));
    });
    unawaited(_syncCloudProgress(restoredSession.token));
    unawaited(_resumeCloudAnalysisJobs(restoredSession.token));
    _startOnlinePresence(restoredSession.token);
    unawaited(_refreshCoinBalance(restoredSession.token));
    _startNotificationPolling(restoredSession.token);
    _startSessionValidation(restoredSession.token);
    unawaited(
      FirebasePushService.instance.configureForSession(restoredSession.token),
    );
  }

  Future<void> _resumeCloudAnalysisJobs(String token) async {
    final List<SavedGameRecord> pending = LocalGameArchive.games
        .where(
          (SavedGameRecord game) =>
              game.cloudAnalysisJobId != null &&
              game.cloudAnalysisStatus != 'COMPLETED',
        )
        .toList(growable: false);
    for (final SavedGameRecord game in pending) {
      final String jobId = game.cloudAnalysisJobId!;
      try {
        CloudAnalysisJob job = await _gameAnalysisApi.results(token, jobId);
        for (
          int attempt = 0;
          attempt < 600 &&
              (job.status == 'QUEUED' || job.status == 'ANALYZING');
          attempt++
        ) {
          await Future<void>.delayed(const Duration(seconds: 2));
          job = await _gameAnalysisApi.results(token, jobId);
        }
        LocalGameArchive.updateCloudAnalysisForGame(
          playedAt: game.playedAt,
          jobId: job.id,
          status: job.status,
          openingEco: job.openingEco,
          openingName: job.openingName,
          bookPlies: job.bookPlies,
          firstDeviationPly: job.firstDeviationPly,
          reviews: job.status == 'COMPLETED'
              ? _savedReviewsFromCloud(job)
              : null,
        );
      } on GameAnalysisApiException catch (error, stackTrace) {
        unawaited(
          AppDiagnostics.recordError(
            error,
            stackTrace,
            reason: 'resume cloud game analysis',
          ),
        );
      }
    }
  }

  void _startSessionValidation(String token) {
    _sessionValidationTimer?.cancel();
    _sessionValidationTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => unawaited(_validateActiveSession(token)),
    );
  }

  Future<void> _validateActiveSession(String token) async {
    if (_sessionValidationInFlight || _stage != _RootStage.home) return;
    _sessionValidationInFlight = true;
    try {
      await _authApi.currentPlayer(token);
    } on AuthApiException catch (error) {
      if (error.statusCode != 401 && error.statusCode != 403) return;
      _sessionValidationTimer?.cancel();
      _presenceTimer?.cancel();
      _stopNotificationPolling();
      await _sessionStore.clearSession();
      if (!mounted) return;
      setState(() => _stage = _RootStage.onboarding);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'This account was signed in on another device. Please sign in again.',
            ),
          ),
        );
      });
    } finally {
      _sessionValidationInFlight = false;
    }
  }

  void _startOnlinePresence(String token) {
    _presenceTimer?.cancel();
    unawaited(_refreshOnlinePresence(token));
    unawaited(_refreshNextTournament(token));
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_refreshOnlinePresence(token)),
    );
  }

  Future<void> _refreshNextTournament(String token) async {
    try {
      final CommunityDto community = await const CommunityApi().load(token);
      final List<TournamentDto> current =
          community.tournaments
              .where(
                (event) => event.status == 'OPEN' || event.status == 'ACTIVE',
              )
              .toList()
            ..sort((a, b) {
              if (a.status == 'ACTIVE' && b.status != 'ACTIVE') return -1;
              if (b.status == 'ACTIVE' && a.status != 'ACTIVE') return 1;
              final DateTime aStart = a.startsAt ?? DateTime(2999);
              final DateTime bStart = b.startsAt ?? DateTime(2999);
              return aStart.compareTo(bStart);
            });
      if (mounted) {
        setState(
          () => _nextTournament = current.isEmpty ? null : current.first,
        );
      }
    } on Object {
      // The home remains usable offline; Community refresh retries on entry.
    }
  }

  Future<void> _refreshOnlinePresence(String token) async {
    try {
      final int count = await const OnlineMatchApi().onlinePlayerCount(token);
      if (mounted) setState(() => _onlinePlayerCount = count);
    } on OnlineMatchException {
      if (mounted) setState(() => _onlinePlayerCount = null);
    }
  }

  Future<void> _refreshCoinBalance(String token) async {
    try {
      final EconomyRewardStatus status = await const EconomyRewardsApi().status(
        token,
      );
      if (mounted) setState(() => _coinBalance = status.coins);
    } on Object {
      // Balance stays hidden while offline; the backend remains authoritative.
    }
  }

  Future<void> _openRewardsCenter(BuildContext context) async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (!context.mounted || session == null) return;
    await _push(
      context,
      CosmeticShopScreen(
        token: session.token,
        onDestinationSelected: (int index) =>
            _closeSettingsAndSelect(context, index),
        onMyGames: () {
          Navigator.of(context).pop();
          if (!mounted) return;
          unawaited(
            _push(
              context,
              MatchHistoryScreen(
                onDestinationSelected: (index) =>
                    _closeSettingsAndSelect(context, index),
                onResume: (draft) =>
                    _openGame(context, GameMode.computer, resumeDraft: draft),
                onPlayAgain: () =>
                    _chooseSideAndOpen(context, GameMode.computer),
              ),
            ),
          );
        },
      ),
    );
    await _refreshCoinBalance(session.token);
  }

  void _startNotificationPolling(String token) {
    _stopNotificationPolling();
    _notificationPollingToken = token;
    unawaited(_pollNotifications(token, initial: true));
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(_pollNotifications(token)),
    );
  }

  Future<void> _pollNotifications(String token, {bool initial = false}) async {
    if (!mounted ||
        _stage != _RootStage.home ||
        token != _notificationPollingToken) {
      return;
    }
    try {
      final NotificationInboxDto inbox = await const NotificationApi().load(
        token,
      );
      final List<PlayerNotificationDto> fresh = inbox.notifications
          .where(
            (value) => !value.read && !_seenNotificationIds.contains(value.id),
          )
          .toList();
      _seenNotificationIds.addAll(inbox.notifications.map((value) => value.id));
      if (initial) return;
      for (final PlayerNotificationDto value in fresh.take(3)) {
        await DailyReminderService.instance.showRealtime(
          value.id.hashCode & 0x7fffffff,
          value.title,
          notificationMessagePreview(value.body),
        );
        if (value.actionType == 'MATCH' && value.actionId != null) {
          unawaited(_openAcceptedChallenge(token, value.actionId!));
        }
      }
    } on NotificationException {
      // The persistent inbox will catch up after connectivity is restored.
    }
  }

  void _stopNotificationPolling() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _notificationPollingToken = null;
    NotificationBadgeState.unread.value = 0;
  }

  Future<void> _openAcceptedChallenge(String token, String matchId) async {
    if (_openingNotificationMatch ||
        _openedNotificationMatchIds.contains(matchId) ||
        !mounted ||
        _stage != _RootStage.home) {
      return;
    }
    _openingNotificationMatch = true;
    _openedNotificationMatchIds.add(matchId);
    try {
      final OnlineMatchDto match = await const OnlineMatchApi().getMatch(
        token,
        matchId,
      );
      if (!mounted || !match.isActive) return;
      await _openGame(
        context,
        GameMode.online,
        initialOnlineMatch: match,
        initialAuthToken: token,
      );
    } on OnlineMatchException {
      _openedNotificationMatchIds.remove(matchId);
    } finally {
      _openingNotificationMatch = false;
    }
  }

  Future<void> _restoreActiveOnlineMatch(String token) async {
    try {
      final OnlineMatchDto match = await const OnlineMatchApi().reconnect(
        token,
      );
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
    DesktopNavigationBridge.request.removeListener(_handleDesktopNavigation);
    DailyReminderService.instance.playOpenRequests.removeListener(
      _openPlayFromReminder,
    );
    DailyReminderService.instance.tournamentOpenRequests.removeListener(
      _openTournamentsFromReminder,
    );
    DailyReminderService.instance.weeklyReportOpenRequests.removeListener(
      _openWeeklyReportFromReminder,
    );
    _timer?.cancel();
    _presenceTimer?.cancel();
    _stopNotificationPolling();
    _sessionValidationTimer?.cancel();
    super.dispose();
  }

  void _handleDesktopNavigation() {
    final int? destination = DesktopNavigationBridge.request.value;
    if (destination == null || !mounted || _stage != _RootStage.home) return;
    DesktopNavigationBridge.request.value = null;
    if (destination >= 0 && destination <= 5) {
      setState(() => _primaryDestination = destination);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (destination == 6) {
        unawaited(
          _push(
            context,
            MatchHistoryScreen(
              onDestinationSelected: (index) =>
                  _closeSettingsAndSelect(context, index),
              onResume: (draft) =>
                  _openGame(context, GameMode.computer, resumeDraft: draft),
              onPlayAgain: () => _chooseSideAndOpen(context, GameMode.computer),
            ),
          ),
        );
      } else if (destination == 7) {
        unawaited(_openRewardsCenter(context));
      }
    });
  }

  void _openPlayFromReminder() {
    if (!mounted ||
        _stage != _RootStage.home ||
        !DailyReminderService.instance.hasPendingPlayOpen) {
      return;
    }
    DailyReminderService.instance.takePendingPlayOpen();
    setState(() => _primaryDestination = 1);
    unawaited(DailyReminderService.instance.recordPlayOpened());
  }

  void _openTournamentsFromReminder() {
    if (!mounted ||
        _stage != _RootStage.home ||
        !DailyReminderService.instance.hasPendingTournamentOpen) {
      return;
    }
    DailyReminderService.instance.takePendingTournamentOpen();
    setState(() {
      _communitySection = 2;
      _primaryDestination = 5;
    });
  }

  void _openWeeklyReportFromReminder() {
    if (!mounted ||
        _stage != _RootStage.home ||
        !DailyReminderService.instance.hasPendingWeeklyReportOpen) {
      return;
    }
    DailyReminderService.instance.takePendingWeeklyReportOpen();
    _push(context, const AnalysisScreen());
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
          onAuthenticated: (ChessVerseAuthResult result) async {
            final StoredAuthSession session = result.session;
            if (!mounted) return;
            await LocalGameArchive.activateIdentity(
              await _sessionStore.progressIdentity(session),
            );
            if (!mounted) return;
            setState(() {
              _playerName = result.playerName;
              _username = result.username;
              _email = result.email;
              _photoUrl = result.photoUrl;
              _isGuest = result.isGuest;
              _stage = _RootStage.home;
            });
            _openPlayFromReminder();
            _openTournamentsFromReminder();
            _openWeeklyReportFromReminder();
            unawaited(AppAnalytics.logAuthentication(guest: result.isGuest));
            if (result.token != null) {
              _enableCloudSync(result.token!);
              unawaited(_syncCloudProgress(result.token!));
              _startOnlinePresence(result.token!);
              unawaited(_refreshCoinBalance(result.token!));
              _startNotificationPolling(result.token!);
            }
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
        coinBalance: _coinBalance,
        nextTournament: _nextTournament,
        onPlayVsAi: () => _chooseSideAndOpen(context, GameMode.computer),
        onDailyChallenge: () => _openGame(context, GameMode.daily),
        onLocalGame: () => _chooseSideAndOpen(context, GameMode.local),
        onOnlineGame: () => _openOnlineGame(context),
        onFriendsGame: () => _openFriendPlayChooser(context),
        onAnalysis: () => _push(context, const AnalysisScreen()),
        onPuzzles: () => setState(() => _primaryDestination = 2),
        onSavedGames: () => _push(
          context,
          MatchHistoryScreen(
            onDestinationSelected: (index) =>
                _closeSettingsAndSelect(context, index),
            onResume: (draft) =>
                _openGame(context, GameMode.computer, resumeDraft: draft),
            onPlayAgain: () => _chooseSideAndOpen(context, GameMode.computer),
          ),
        ),
        onRankings: () => _push(
          context,
          LeaderboardScreen(
            profilePhotoUrl: _photoUrl,
            onOpenMatch: (OnlineMatchDto match) async {
              final StoredAuthSession? session = await const AuthSessionStore()
                  .read();
              if (!context.mounted || session == null) return;
              await _openGame(
                context,
                GameMode.online,
                initialOnlineMatch: match,
                initialAuthToken: session.token,
              );
            },
            onHome: () => _closeSettingsAndSelect(context, 0),
            onPlay: () => _closeSettingsAndSelect(context, 1),
            onPuzzles: () => _closeSettingsAndSelect(context, 2),
            onLearn: () => _closeSettingsAndSelect(context, 3),
            onProfile: () => _closeSettingsAndSelect(context, 4),
          ),
        ),
        onCommunity: () => setState(() => _primaryDestination = 5),
        onTournaments: () => setState(() {
          _communitySection = 2;
          _primaryDestination = 5;
        }),
        onNotifications: () => _openNotificationCenter(context),
        onCoins: () => _openRewardsCenter(context),
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
        onPositionCreator: () => _openPositionCreator(context),
        onSpectate: () => _openSpectator(context),
        onMyGames: () => _push(
          context,
          MatchHistoryScreen(
            onDestinationSelected: (index) =>
                _closeSettingsAndSelect(context, index),
            onResume: (draft) =>
                _openGame(context, GameMode.computer, resumeDraft: draft),
            onPlayAgain: () => _chooseSideAndOpen(context, GameMode.computer),
          ),
        ),
        onOnline: () => _openOnlineGame(context),
        onLocal: () => _chooseSideAndOpen(context, GameMode.local),
        onTournaments: () => setState(() {
          _communitySection = 2;
          _primaryDestination = 5;
        }),
        onDaily: () => _openGame(context, GameMode.daily),
      ),
      PuzzlesScreen(
        showPrimaryNavigation: false,
        onStartPuzzle: (String puzzleId) =>
            _openGame(context, GameMode.puzzle, puzzleId: puzzleId),
      ),
      const LearnChessScreen(),
      ProfileScreen(
        playerName: _playerName,
        username: _username,
        email: _email,
        profilePhotoUrl: _photoUrl,
        isGuest: _isGuest,
        onSecureProgress: _isGuest ? () => _secureGuestProgress(context) : null,
        onDisplayNameChanged: _updateDisplayName,
        onProfilePhotoChanged: _updateProfilePhoto,
        onLanguage: () => _openLanguageCentre(context),
        onMissions: () async {
          final StoredAuthSession? session = await _sessionStore.read();
          if (!context.mounted || session == null) return;
          await _push(
            context,
            MissionsScreen(
              token: session.token,
              onRewardClaimed: () =>
                  unawaited(_refreshCoinBalance(session.token)),
            ),
          );
          await _refreshCoinBalance(session.token);
        },
        onShop: () async {
          await _openRewardsCenter(context);
        },
      ),
      SocialHubScreen(
        initialSection: _communitySection,
        onOpenMatch: (OnlineMatchDto match) async {
          final StoredAuthSession? session = await const AuthSessionStore()
              .read();
          if (!context.mounted || session == null) return;
          await _openGame(
            context,
            GameMode.online,
            initialOnlineMatch: match,
            initialAuthToken: session.token,
          );
        },
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints size) {
        if (DesktopNavigationBridge.coinBalance.value != _coinBalance) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (DesktopNavigationBridge.coinBalance.value != _coinBalance) {
              DesktopNavigationBridge.coinBalance.value = _coinBalance;
            }
          });
        }
        // Desktop navigation is a width concern. Keeping a height requirement
        // here made the permanent sidebar disappear in short browser windows
        // (for example when DevTools was docked or the window was resized).
        final bool genuineWideLayout = size.maxWidth >= 700;
        final bool useDesktopSidebar = genuineWideLayout;
        final Widget destinationStack = IndexedStack(
          index: _primaryDestination,
          children: destinations,
        );
        final double coinTop = switch (_primaryDestination) {
          1 => useDesktopSidebar ? 25 : 8,
          2 => useDesktopSidebar ? 18 : 10,
          3 => useDesktopSidebar ? 18 : 10,
          4 || 5 => useDesktopSidebar ? 9 : 8,
          _ => 10,
        };
        final double coinRight = switch (_primaryDestination) {
          // The Learn app bar owns a language picker on the trailing edge.
          // Reserve its maximum width so the floating wallet never covers it.
          3 => 128,
          4 => useDesktopSidebar ? 92 : 66,
          5 => useDesktopSidebar ? 112 : 102,
          _ => useDesktopSidebar ? 22 : 12,
        };
        final Widget content = Stack(
          children: <Widget>[
            Positioned.fill(child: destinationStack),
            // Learning is intentionally distraction-free; the wallet remains
            // available from the play, profile and rewards surfaces.
            if (_primaryDestination != 0 && _primaryDestination != 3)
              Positioned(
                top: coinTop,
                right: coinRight,
                child: SafeArea(
                  bottom: false,
                  child: CoinBalanceBadge(
                    balance: _coinBalance,
                    expandedLabel: useDesktopSidebar,
                    compact: !useDesktopSidebar,
                    onTap: () => _openRewardsCenter(context),
                  ),
                ),
              ),
          ],
        );
        if (useDesktopSidebar) {
          const List<String> desktopSections = <String>[
            'Home',
            'Play',
            'Puzzles',
            'Learn',
            'Profile',
            'Community',
          ];
          void selectDestination(int value) {
            _selectPrimaryDestination(value);
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: <Widget>[
                DesktopAppSidebar(
                  selected: desktopSections[_primaryDestination],
                  onHome: () => selectDestination(0),
                  onPlay: () => selectDestination(1),
                  onMyGames: () => _push(
                    context,
                    MatchHistoryScreen(
                      onDestinationSelected: (index) =>
                          _closeSettingsAndSelect(context, index),
                      onResume: (draft) => _openGame(
                        context,
                        GameMode.computer,
                        resumeDraft: draft,
                      ),
                      onPlayAgain: () =>
                          _chooseSideAndOpen(context, GameMode.computer),
                    ),
                  ),
                  onPuzzles: () => selectDestination(2),
                  onLearn: () => selectDestination(3),
                  onProfile: () => selectDestination(4),
                  onFriends: () => selectDestination(5),
                  onCollection: () => _openRewardsCenter(context),
                ),
                Expanded(child: content),
              ],
            ),
          );
        }
        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: content,
          bottomNavigationBar: _GlassBottomNavigation(
            selectedIndex: _primaryDestination,
            onDestinationSelected: _selectPrimaryDestination,
          ),
        );
      },
    );
  }

  void _selectPrimaryDestination(int destination) {
    if (destination == 1) {
      unawaited(DailyReminderService.instance.recordPlayOpened());
    }
    setState(() => _primaryDestination = destination);
  }

  void _closeSettingsAndSelect(BuildContext context, int destination) {
    Navigator.of(context).pop();
    if (!mounted) return;
    setState(() => _primaryDestination = destination);
  }

  Future<void> _openLanguageCentre(BuildContext context) => _push(
    context,
    SettingsScreen(
      openLanguagePickerOnStart: true,
      onLogout: () => _logout(context),
      onDeleteAccount: () => _deleteAccount(context),
      onHome: () => _closeSettingsAndSelect(context, 0),
      onPlay: () => _closeSettingsAndSelect(context, 1),
      onPuzzles: () => _closeSettingsAndSelect(context, 2),
      onLearn: () => _closeSettingsAndSelect(context, 3),
      onProfile: () => _closeSettingsAndSelect(context, 4),
    ),
  );

  Future<void> _openNotificationCenter(BuildContext context) async {
    await _push(
      context,
      NotificationCenterScreen(onAction: _handleNotificationAction),
    );
  }

  Future<void> _handleNotificationAction(PlayerNotificationDto item) async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (!mounted || session == null) return;
    final String action = (item.actionType ?? '').toUpperCase();
    if (action == 'MATCH' && item.actionId != null) {
      await _openAcceptedChallenge(session.token, item.actionId!);
      return;
    }
    final int? communitySection = switch (action) {
      'CLUB' => 1,
      'TOURNAMENT' => 2,
      'CHAT' => 3,
      'CHALLENGE' || 'COMMUNITY' || 'FRIEND' => 0,
      _ => null,
    };
    if (communitySection != null) {
      setState(() => _primaryDestination = 5);
    }
  }

  Future<void> _openFriendPlayChooser(BuildContext context) async {
    final _FriendPlayChoice?
    choice = await showModalBottomSheet<_FriendPlayChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFA071827),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF29475C)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Colors.black54, blurRadius: 32),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Choose How to Play',
                              style: TextStyle(
                                color: Color(0xFFFFF8ED),
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Play online with a friend or share this device.',
                              style: TextStyle(color: Color(0xFFAFBCCB)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _FriendPlayChoiceCard(
                    icon: Icons.language_rounded,
                    title: 'Online with Friend',
                    subtitle: 'Create a private room or join with a room code.',
                    accent: const Color(0xFF4FD9C5),
                    onTap: () =>
                        Navigator.of(sheetContext)
                            .pop(_FriendPlayChoice.online),
                  ),
                  const SizedBox(height: 12),
                  _FriendPlayChoiceCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Two Players — Same Device',
                    subtitle: 'Player 1 • White   /   Player 2 • Black. Board stays fixed.',
                    accent: const Color(0xFFE2AE49),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_FriendPlayChoice.local),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || !context.mounted || choice == null) return;
    if (choice == _FriendPlayChoice.online) {
      await _openOnlineGame(context, lobbyMode: OnlineLobbyMode.friends);
    } else {
      await _chooseSideAndOpen(context, GameMode.local);
    }
  }

  Future<void> _chooseSideAndOpen(BuildContext context, GameMode mode) async {
    bool replacePausedComputerGame = false;
    if (mode == GameMode.computer) {
      try {
        final String owner = await ComputerGameStore.activeOwner();
        final List<ComputerGameDraft> saved = await ComputerGameStore.load(
          owner,
        );
        if (!context.mounted) return;
        if (saved.isNotEmpty) {
          final bool? startNew = await _askHowToOpenComputerGame(context);
          if (!context.mounted || startNew == null) return;
          if (!startNew) {
            await _openGame(context, mode, resumeDraft: saved.first);
            return;
          }
          replacePausedComputerGame = true;
        }
      } catch (_) {
        // Cloud resume is optional. Never cover navigation or block an offline
        // computer game because the account-save service is unavailable.
      }
    }
    List<AiBotPreset> botPresets = <AiBotPreset>[];
    if (mode == GameMode.computer) {
      try {
        botPresets = await AiBotPresetStore().list();
      } on Object {
        // Playing remains available while optional preset sync is offline.
      }
      if (!context.mounted) return;
    }
    final _GameLaunchChoice?
    choice = await showModalBottomSheet<_GameLaunchChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        PlayerSideChoice selected = PlayerSideChoice.white;
        double selectedRating = 1400;
        AiBotStyle selectedStyle = AiBotStyle.balanced;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) => SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool shortLandscape =
                    constraints.maxWidth > constraints.maxHeight &&
                    constraints.maxHeight < 500;
                final bool wide =
                    constraints.maxWidth >= 700 &&
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
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: Color(0xFFE2AE49),
                            size: 52,
                          ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        setSheetState(() => selected = side),
                                    borderRadius: BorderRadius.circular(20),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
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
                                          Text(
                                            side.label,
                                            style: TextStyle(
                                              fontSize: wide ? 24 : 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
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
                                'CUSTOM AI  •  ${selectedRating.round()} ELO',
                                style: const TextStyle(
                                  color: Color(0xFFE2AE49),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Slider(
                              key: const ValueKey<String>('computer-ai-level'),
                              value: selectedRating,
                              min: 400,
                              max: 3000,
                              divisions: 26,
                              label: '${selectedRating.round()} Elo',
                              onChanged: (double value) =>
                                  setSheetState(() => selectedRating = value),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const <Widget>[
                                Text('400', style: TextStyle(fontSize: 12)),
                                Text('3000', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<AiBotStyle>(
                              segments: AiBotStyle.values
                                  .map(
                                    (AiBotStyle style) =>
                                        ButtonSegment<AiBotStyle>(
                                          value: style,
                                          label: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              style.label,
                                              maxLines: 1,
                                              softWrap: false,
                                            ),
                                          ),
                                        ),
                                  )
                                  .toList(),
                              selected: <AiBotStyle>{selectedStyle},
                              showSelectedIcon: false,
                              onSelectionChanged: (Set<AiBotStyle> value) =>
                                  setSheetState(
                                    () => selectedStyle = value.first,
                                  ),
                            ),
                            if (botPresets.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: botPresets
                                    .map(
                                      (AiBotPreset preset) => InputChip(
                                        label: Text(
                                          '${preset.name} · ${preset.rating}',
                                        ),
                                        onPressed: () => setSheetState(() {
                                          selectedRating = preset.rating
                                              .toDouble();
                                          selectedStyle = preset.style;
                                        }),
                                        onDeleted: () async {
                                          try {
                                            await AiBotPresetStore().delete(
                                              preset.id,
                                            );
                                            setSheetState(
                                              () => botPresets = botPresets
                                                  .where(
                                                    (AiBotPreset item) =>
                                                        item.id != preset.id,
                                                  )
                                                  .toList(),
                                            );
                                          } on Object {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Could not delete preset. Check your connection.',
                                                      ),
                                                    ),
                                                  );
                                            }
                                          }
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              key: const ValueKey<String>('save-ai-preset'),
                              onPressed: () async {
                                final TextEditingController nameController =
                                    TextEditingController();
                                final String? name = await showDialog<String>(
                                  context: context,
                                  builder: (BuildContext dialogContext) =>
                                      AlertDialog(
                                        title: const Text('Save AI preset'),
                                        content: TextField(
                                          controller: nameController,
                                          autofocus: true,
                                          maxLength: 30,
                                          decoration: const InputDecoration(
                                            hintText: 'Example: Tactical Tiger',
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogContext),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              nameController.text.trim(),
                                            ),
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                );
                                nameController.dispose();
                                if (name == null || name.isEmpty) return;
                                try {
                                  final AiBotPreset saved =
                                      await AiBotPresetStore().save(
                                        name: name,
                                        rating: selectedRating.round(),
                                        style: selectedStyle,
                                      );
                                  setSheetState(
                                    () => botPresets = <AiBotPreset>[
                                      saved,
                                      ...botPresets,
                                    ],
                                  );
                                } on Object {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not save preset. Sign in, check connection, or remove an old preset.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.bookmark_add_rounded),
                              label: const Text('SAVE ACCOUNT PRESET'),
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
                                border: Border.all(
                                  color: const Color(0xFF5A4B2A),
                                ),
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
                                _GameLaunchChoice(
                                  selected,
                                  ratingToEngineLevel(selectedRating.round())
                                      .toDouble(),
                                  selectedStyle,
                                ),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                'START AS ${selected.label.toUpperCase()}',
                              ),
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
        aiStyle: choice.aiStyle,
        replacePausedComputerGame: replacePausedComputerGame,
      );
    }
  }

  Future<void> _openPositionCreator(BuildContext context) async {
    final PositionSetup? setup = await Navigator.of(context)
        .push<PositionSetup>(
          MaterialPageRoute<PositionSetup>(
            builder: (_) => const PositionCreatorScreen(),
          ),
        );
    if (!context.mounted || setup == null) return;
    final String player = _playerName.trim().isNotEmpty
        ? _playerName.trim()
        : 'Player';
    final ComputerGameDraft draft = ComputerGameDraft(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      updatedAt: DateTime.now(),
      state: <String, dynamic>{
        'version': 1,
        'pieces': setup.pieces,
        'moves': <String>[],
        'capturedWhite': <String>[],
        'capturedBlack': <String>[],
        'coachNote': 'Custom position ready. White moves first.',
        'lastFrom': null,
        'lastTo': null,
        'lastCapture': null,
        'whiteSeconds': 600,
        'blackSeconds': 600,
        'humanWhite': setup.humanWhite,
        'level': 4.0,
        'aiStyle': AiBotStyle.balanced.name,
        'whiteName': setup.humanWhite ? player : 'ChessVerseAI',
        'blackName': setup.humanWhite ? 'ChessVerseAI' : player,
        'history': <Object>[],
        'reviews': <Object>[],
        'scores': <int>[],
        'mistakes': <String>[],
      },
    );
    await _openGame(
      context,
      GameMode.computer,
      resumeDraft: draft,
      replacePausedComputerGame: true,
      customPosition: true,
    );
  }

  Future<void> _openSpectator(BuildContext context) async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (!context.mounted || session == null) return;
    final OnlineMatchDto? match = await Navigator.of(context)
        .push<OnlineMatchDto>(
          MaterialPageRoute<OnlineMatchDto>(
            builder: (_) => SpectatorScreen(token: session.token),
          ),
        );
    if (!context.mounted || match == null) return;
    await _push(
      context,
      GameScreen(
        initiallySignedIn: true,
        initialGameMode: GameMode.online,
        initialOnlineMatch: match,
        initialAuthToken: session.token,
        initialPlayerName: _playerName,
        initialUsername: _username,
        initialEmail: _email,
        initialProfilePhotoUrl: _photoUrl,
        initiallyGuest: _isGuest,
        spectatorMode: true,
      ),
    );
  }

  Future<bool?> _askHowToOpenComputerGame(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Continue your computer game?'),
        content: const Text(
          'Continue your paused game now, or create a new one. Starting a new game removes the paused game from this account; completed games stay in My Games.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGame(
    BuildContext context,
    GameMode mode, {
    PlayerSideChoice sideChoice = PlayerSideChoice.white,
    double aiLevel = 4,
    AiBotStyle aiStyle = AiBotStyle.balanced,
    DailyChallengeDifficulty? dailyDifficulty,
    String? puzzleId,
    OnlineMatchDto? initialOnlineMatch,
    String? initialAuthToken,
    String? aiOpponentName,
    ComputerGameDraft? resumeDraft,
    bool replacePausedComputerGame = false,
    bool customPosition = false,
  }) async {
    if (mode == GameMode.computer) {
      try {
        final owner = await ComputerGameStore.activeOwner();
        final saved = await ComputerGameStore.load(owner);
        if (!context.mounted) return;
        if (resumeDraft == null &&
            saved.isNotEmpty &&
            !replacePausedComputerGame) {
          final bool? replace = await _askHowToOpenComputerGame(context);
          if (replace == null) return;
          if (!replace) resumeDraft = saved.first;
        }
        await ComputerGameStore.prepare(
          owner,
          customPosition ? null : resumeDraft,
          replacing: saved.isEmpty ? null : saved.first,
        );
        if (!context.mounted) return;
      } catch (_) {
        // The board is local-first; cloud draft sync must not block launch.
      }
    }
    unawaited(DailyReminderService.instance.recordPlayOpened());
    unawaited(AppAnalytics.logGameStarted(mode: mode.name, guest: _isGuest));
    return _push(
      context,
      GameScreen(
        initiallySignedIn: true,
        // Computer games use the production Stockfish service. The game
        // already falls back to its offline move generator if the API is
        // unavailable, so genuine AI strength never sacrifices playability.
        useRemoteEngine: mode == GameMode.computer || mode == GameMode.online,
        initialGameMode: mode,
        initialPlayerName: _playerName,
        initialUsername: _username,
        initialEmail: _email,
        initialProfilePhotoUrl: _photoUrl,
        initiallyGuest: _isGuest,
        initialSideChoice: sideChoice,
        initialAiLevel: aiLevel,
        initialAiStyle: aiStyle,
        initialDailyDifficulty: dailyDifficulty,
        initialPuzzleId: puzzleId,
        initialOnlineMatch: initialOnlineMatch,
        initialAuthToken: initialAuthToken,
        aiOpponentName: aiOpponentName,
        resumeDraft: resumeDraft,
        onLogout: () => _logout(context),
        onDisplayNameChanged: _updateDisplayName,
      ),
    );
  }

  Future<void> _openOnlineGame(
    BuildContext context, {
    OnlineLobbyMode lobbyMode = OnlineLobbyMode.random,
  }) async {
    unawaited(DailyReminderService.instance.recordPlayOpened());
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (!context.mounted) return;
    if (session == null || session.token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to play online.')));
      return;
    }
    final OnlineMatchDto? match = await Navigator.of(context)
        .push<OnlineMatchDto>(
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
                  initialMode: lobbyMode,
                  onProfile: () {
                    Navigator.of(context).pop();
                    if (mounted) setState(() => _primaryDestination = 4);
                  },
                  onAiFallback: (String rivalName) async {
                    if (!context.mounted) return;
                    await _openGame(
                      context,
                      GameMode.computer,
                      aiLevel: 5,
                      aiOpponentName: rivalName,
                    );
                  },
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
    await _refreshCoinBalance(session.token);
  }

  Future<void> _logout(BuildContext currentRouteContext) async {
    _sessionValidationTimer?.cancel();
    _sessionValidationTimer = null;
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _stopNotificationPolling();
    const AuthSessionStore sessionStore = AuthSessionStore();
    const AuthApi authApi = AuthApi();
    final StoredAuthSession? session = await sessionStore.read();
    if (session != null) {
      await FirebasePushService.instance.unregister(session.token);
      try {
        await authApi.logout(session.token);
      } on AuthApiException {
        // A local logout must still succeed if the remote session expired.
      }
    }
    await const AcademyProgressStore().clearCurrentIdentity();
    await LocalGameArchive.clearDeviceUserData();
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
      _photoUrl = null;
      _isGuest = true;
      _onlinePlayerCount = null;
      _coinBalance = null;
      _stage = _RootStage.onboarding;
    });
  }

  Future<void> _deleteAccount(BuildContext currentRouteContext) async {
    _sessionValidationTimer?.cancel();
    _sessionValidationTimer = null;
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _stopNotificationPolling();
    final StoredAuthSession? session = await _sessionStore.read();
    if (session == null) {
      throw const AuthApiException('No signed-in account was found.');
    }
    await _authApi.deleteAccount(session.token);
    await FirebasePushService.instance.unregister(session.token);
    await const AcademyProgressStore().clearCurrentIdentity();
    await LocalGameArchive.clearDeviceUserData();
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
      _onlinePlayerCount = null;
      _coinBalance = null;
      _primaryDestination = 0;
      _stage = _RootStage.onboarding;
    });
  }

  Future<void> _updateDisplayName(String displayName) async {
    final StoredAuthSession? session = await _sessionStore.read();
    if (session == null) {
      throw const AuthApiException('Sign in to update your display name.');
    }
    final Map<String, dynamic> player = await _authApi.updateProfile(
      session.token,
      displayName,
    );
    final String savedName =
        _profileValue(player['displayName']) ?? displayName;
    await _sessionStore.write(
      StoredAuthSession(
        token: session.token,
        expiresAt: session.expiresAt,
        displayName: savedName,
        username: session.username,
        email: session.email,
        photoUrl: session.photoUrl,
        isGuest: session.isGuest,
      ),
    );
    if (!mounted) return;
    setState(() => _playerName = savedName);
  }

  Future<String?> _updateProfilePhoto(Uint8List bytes, String filename) async {
    final StoredAuthSession? session = await _sessionStore.read();
    if (session == null) {
      throw const AuthApiException('Sign in to update your profile photo.');
    }
    final player = await _authApi.uploadProfilePhoto(
      session.token,
      bytes,
      filename,
    );
    final photoUrl = _profileValue(player['photoUrl']);
    await _sessionStore.write(
      StoredAuthSession(
        token: session.token,
        expiresAt: session.expiresAt,
        displayName: session.displayName,
        username: session.username,
        email: session.email,
        photoUrl: photoUrl,
        isGuest: session.isGuest,
        refreshToken: session.refreshToken,
        refreshExpiresAt: session.refreshExpiresAt,
        sessionId: session.sessionId,
      ),
    );
    if (mounted) setState(() => _photoUrl = photoUrl);
    return photoUrl;
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
    return Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
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
      const AcademyProgressStore academyStore = AcademyProgressStore();
      final Set<String> localAcademy = await academyStore.readCompleted();
      LocalGameArchive.replaceAcademyLessonProgress(localAcademy);
      final Map<String, dynamic> merged = await _cloudProgressApi.merge(
        token,
        LocalGameArchive.cloudSnapshot(),
      );
      await LocalGameArchive.mergeCloudSnapshot(merged);
      await academyStore.writeCompleted(
        LocalGameArchive.completedAcademyLessonIds,
      );
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
