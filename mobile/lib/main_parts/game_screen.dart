part of '../main.dart';

class _PlayDestination extends StatelessWidget {
  const _PlayDestination({
    required this.onComputer,
    required this.onMyGames,
    required this.onPositionCreator,
    required this.onSpectate,
    required this.onOnline,
    required this.onLocal,
    required this.onTournaments,
    required this.onDaily,
  });
  final VoidCallback onComputer;
  final VoidCallback onMyGames;
  final VoidCallback onPositionCreator;
  final VoidCallback onSpectate;
  final VoidCallback onOnline;
  final VoidCallback onLocal;
  final VoidCallback onTournaments;
  final VoidCallback onDaily;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: wide ? 96 : null,
        title: SizedBox(
          width: wide ? null : MediaQuery.sizeOf(context).width - 150,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PLAY',
                style: TextStyle(
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Choose your battle mode',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFAEC0D1),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
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
                        asset: 'assets/backgrounds/home-online-hero-v1.webp',
                        onTap: onOnline,
                      ),
                      _PlayModeCard(
                        icon: Icons.computer_rounded,
                        title: 'Play Computer',
                        subtitle: 'Challenge ChessVerseAI',
                        color: const Color(0xFF174A69),
                        asset: 'assets/backgrounds/play-computer-card-v2.webp',
                        onTap: onComputer,
                      ),
                      _PlayModeCard(
                        icon: Icons.history_rounded,
                        title: 'My Games',
                        subtitle: 'Continue or replay your saved games',
                        color: const Color(0xFF5A3F78),
                        asset: 'assets/backgrounds/home-analysis-hero-v1.webp',
                        onTap: onMyGames,
                      ),
                      _PlayModeCard(
                        icon: Icons.dashboard_customize_rounded,
                        title: 'Position Creator',
                        subtitle: 'Build any legal setup and challenge the AI',
                        color: const Color(0xFF7B5DA8),
                        asset: 'assets/backgrounds/home-analysis-hero-v1.webp',
                        onTap: onPositionCreator,
                      ),
                      _PlayModeCard(
                        icon: Icons.visibility_rounded,
                        title: 'Watch & Learn',
                        subtitle: 'Spectate live games with AI insights',
                        color: const Color(0xFF2B8C83),
                        asset: 'assets/backgrounds/home-online-hero-v1.webp',
                        onTap: onSpectate,
                      ),
                      _PlayModeCard(
                        icon: Icons.groups_rounded,
                        title: 'Local Match',
                        subtitle: 'Two players on one board',
                        color: const Color(0xFF25664F),
                        asset: 'assets/backgrounds/local-match-card-v2.webp',
                        onTap: onLocal,
                      ),
                      _PlayModeCard(
                        icon: Icons.emoji_events_rounded,
                        title: 'Tournaments',
                        subtitle: 'Enter the World Chess Circuit',
                        color: const Color(0xFFD5A63B),
                        asset:
                            'assets/backgrounds/tournament-new-york-grand-final-v1.webp',
                        onTap: onTournaments,
                      ),
                      _PlayModeCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Daily Challenge',
                        subtitle: 'Solve today’s featured position',
                        color: const Color(0xFF8A5A21),
                        asset:
                            'assets/backgrounds/daily-challenge-card-v2.webp',
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
    final Alignment imageAlignment = title == 'Play Online'
        ? const Alignment(0.5, 0)
        : title == 'Tournaments'
        ? const Alignment(0.72, 0)
        : Alignment.center;
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
                                    : title == 'Tournaments'
                                    ? 'View Tournaments'
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
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                              ),
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
                child: Row(
                  children: <Widget>[
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
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFFFF8ED),
                              fontSize: compact ? 22 : 26,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFC5D5E0),
                              fontSize: compact ? 13 : 14,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: color, size: 34),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String engineMoveReviewText({
  required bool isBestMove,
  required bool isWeakMove,
  required String recommendation,
}) {
  if (isBestMove) {
    return 'Best move • Confirmed by AI analysis.';
  }
  if (isWeakMove) {
    return 'Weak move alert • $recommendation was safer. Tap Analyze to see why.';
  }
  return 'Playable move • AI preferred $recommendation.';
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
    this.initialAiStyle = AiBotStyle.balanced,
    this.initialDailyDifficulty,
    this.initialPuzzleId,
    this.initialOnlineMatch,
    this.initialAuthToken,
    this.aiOpponentName,
    this.resumeDraft,
    this.onlineApi,
    this.spectatorMode = false,
    this.onLogout,
    this.onDisplayNameChanged,
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
  final AiBotStyle initialAiStyle;
  final DailyChallengeDifficulty? initialDailyDifficulty;
  final String? initialPuzzleId;
  final OnlineMatchDto? initialOnlineMatch;
  final String? initialAuthToken;
  final String? aiOpponentName;
  final ComputerGameDraft? resumeDraft;
  final OnlineMatchApi? onlineApi;
  final bool spectatorMode;
  final Future<void> Function()? onLogout;
  final Future<void> Function(String displayName)? onDisplayNameChanged;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  String _draftId = DateTime.now().microsecondsSinceEpoch.toString();
  String? _draftOwner;
  String? _lastDraftFingerprint;
  bool _computerPaused = false;
  bool _draftConflict = false;
  bool _draftSaveWarningShown = false;
  Future<void>? _draftWrite;
  bool _lastSaveOkay = true;
  bool _allowComputerExit = false;
  bool _leavingComputerGame = false;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_draftOwner != null) scheduleMicrotask(() => _persistComputerDraft());
  }

  Map<String, dynamic> _encodePosition(GameSnapshot snapshot) => {
    'pieces': snapshot.pieces.map(
      (square, piece) =>
          MapEntry(square, '${piece.white ? 'w' : 'b'}${piece.code}'),
    ),
    'moves': List<String>.from(snapshot.moves),
    'capturedWhite': snapshot.capturedWhite.map((p) => p.code).toList(),
    'capturedBlack': snapshot.capturedBlack.map((p) => p.code).toList(),
    'coachNote': snapshot.coachNote,
    'lastFrom': snapshot.lastFromSquare,
    'lastTo': snapshot.lastToSquare,
    'lastCapture': snapshot.lastCaptureSquare,
    'whiteSeconds': snapshot.whiteSeconds,
    'blackSeconds': snapshot.blackSeconds,
  };

  GameSnapshot _decodePosition(Map<String, dynamic> data) => GameSnapshot(
    pieces: (data['pieces'] as Map).map(
      (square, value) => MapEntry(
        square as String,
        ChessPiece((value as String).substring(1), value.startsWith('w')),
      ),
    ),
    moves: List<String>.from(data['moves'] as List),
    capturedWhite: (data['capturedWhite'] as List? ?? [])
        .map((p) => ChessPiece(p as String, true))
        .toList(),
    capturedBlack: (data['capturedBlack'] as List? ?? [])
        .map((p) => ChessPiece(p as String, false))
        .toList(),
    coachNote: data['coachNote'] as String? ?? 'Select a piece to begin',
    lastFromSquare: data['lastFrom'] as String?,
    lastToSquare: data['lastTo'] as String?,
    lastCaptureSquare: data['lastCapture'] as String?,
    whiteSeconds: (data['whiteSeconds'] as num).toInt(),
    blackSeconds: (data['blackSeconds'] as num).toInt(),
  );

  GameSnapshot get _currentPosition => GameSnapshot(
    pieces: _pieces,
    moves: _moves,
    capturedWhite: _capturedWhite,
    capturedBlack: _capturedBlack,
    coachNote: _coachNote,
    lastFromSquare: _lastFromSquare,
    lastToSquare: _lastToSquare,
    lastCaptureSquare: _lastCaptureSquare,
    whiteSeconds: _whiteSeconds,
    blackSeconds: _blackSeconds,
  );

  Future<void> _persistComputerDraft({bool force = false}) async {
    if (_draftWrite != null) {
      if (!force) return;
      await _draftWrite;
    }
    final write = _writeComputerDraft(force: force);
    _draftWrite = write;
    try {
      await write;
    } finally {
      if (identical(_draftWrite, write)) _draftWrite = null;
    }
  }

  Future<void> _writeComputerDraft({bool force = false}) async {
    final owner = _draftOwner;
    if (owner == null ||
        owner.isEmpty ||
        _gameMode != GameMode.computer ||
        !_signedIn ||
        _draftConflict) {
      return;
    }
    final id = _draftId;
    try {
      if (_gameResultTitle != null) {
        if (_lastDraftFingerprint == 'finished') return;
        await ComputerGameStore.finish(
          owner,
          ComputerGameDraft(
            id: id,
            updatedAt: DateTime.now(),
            state: {
              ..._encodePosition(_currentPosition),
              'version': 1,
              'humanWhite': _humanPlaysWhite,
              'level': _aiLevel,
              'aiStyle': _aiStyle.name,
              'whiteName': _whitePlayerName,
              'blackName': _blackPlayerName,
              'result': _gameResultTitle,
              'detail': _gameResultDetail,
              'outcome': playerOutcomeForResult(
                _gameResultTitle!,
                humanPlaysWhite: _humanPlaysWhite,
                tracksPlayer: true,
              ),
              'reviews': _moveReviews.map((r) => r.toJson()).toList(),
            },
          ),
        );
        _lastDraftFingerprint = 'finished';
        _lastSaveOkay = true;
        return;
      }
      // Never store an incomplete promotion decision; the prior legal position remains resumable.
      if (_pieces.entries.any(
        (e) =>
            e.value.code == 'P' && (e.key.endsWith('1') || e.key.endsWith('8')),
      )) {
        return;
      }
      final fingerprint =
          '${_moves.join(',')}|${_pieces.entries.map((e) => '${e.key}${e.value.code}').join(',')}|${_whiteSeconds ~/ 5}|${_blackSeconds ~/ 5}|${_moveReviews.length}';
      if (!force && fingerprint == _lastDraftFingerprint) return;
      final state = <String, dynamic>{
        ..._encodePosition(_currentPosition),
        'version': 1,
        'humanWhite': _humanPlaysWhite,
        'level': _aiLevel,
        'aiStyle': _aiStyle.name,
        'whiteName': _whitePlayerName,
        'blackName': _blackPlayerName,
        'history': _history.map(_encodePosition).toList(),
        'reviews': _moveReviews.map((r) => r.toJson()).toList(),
        'scores': List<int>.from(_playerMoveScores),
        'mistakes': List<String>.from(_importantMistakes),
        'turningPoint': _turningPoint,
        'lastPlayerMove': _lastPlayerMove,
        'lastPlayerCoachNote': _lastPlayerCoachNote,
      };
      await ComputerGameStore.save(
        owner,
        ComputerGameDraft(id: id, updatedAt: DateTime.now(), state: state),
      );
      _lastDraftFingerprint = fingerprint;
      _lastSaveOkay = true;
    } on ComputerGameConflict {
      _draftConflict = true;
      _computerPaused = true;
      _aiMoveEpoch++;
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Game changed on another device'),
            content: const Text(
              'This board can no longer save changes. Open My Games to continue the latest position.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.of(context).maybePop();
                },
                child: const Text('Back to My Games'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      _lastSaveOkay = false;
      _lastDraftFingerprint = null;
      if (mounted && !_draftSaveWarningShown) {
        _draftSaveWarningShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Game is not synced. Reconnect before leaving to continue on another device.',
            ),
          ),
        );
      }
    }
  }

  void _restoreComputerDraft(ComputerGameDraft draft) {
    final data = draft.state;
    final position = _decodePosition(data);
    _draftId = draft.id;
    _pieces = position.pieces;
    _moves
      ..clear()
      ..addAll(position.moves);
    _capturedWhite
      ..clear()
      ..addAll(position.capturedWhite);
    _capturedBlack
      ..clear()
      ..addAll(position.capturedBlack);
    _whiteSeconds = position.whiteSeconds;
    _blackSeconds = position.blackSeconds;
    _coachNote = position.coachNote;
    _lastFromSquare = position.lastFromSquare;
    _lastToSquare = position.lastToSquare;
    _lastCaptureSquare = position.lastCaptureSquare;
    _humanPlaysWhite = draft.humanWhite;
    _aiLevel = draft.level;
    _aiStyle = AiBotStyle.values.firstWhere(
      (AiBotStyle style) => style.name == data['aiStyle'],
      orElse: () => AiBotStyle.balanced,
    );
    _whitePlayerName = draft.whiteName;
    _blackPlayerName = draft.blackName;
    _history
      ..clear()
      ..addAll(
        (data['history'] as List? ?? []).map(
          (row) => _decodePosition(Map<String, dynamic>.from(row as Map)),
        ),
      );
    _moveReviews
      ..clear()
      ..addAll(
        (data['reviews'] as List? ?? []).map(
          (row) =>
              SavedMoveReview.fromJson(Map<String, dynamic>.from(row as Map)),
        ),
      );
    _playerMoveScores
      ..clear()
      ..addAll(List<int>.from(data['scores'] as List? ?? []));
    _importantMistakes
      ..clear()
      ..addAll(List<String>.from(data['mistakes'] as List? ?? []));
    _turningPoint = data['turningPoint'] as String?;
    _lastPlayerMove = data['lastPlayerMove'] as String?;
    _lastPlayerCoachNote = data['lastPlayerCoachNote'] as String?;
  }

  static const AuthApi _authApi = AuthApi();
  static const AuthSessionStore _sessionStore = AuthSessionStore();
  static const EngineApi _engineApi = EngineApi();
  static const GameAnalysisApi _gameAnalysisApi = GameAnalysisApi();
  OnlineMatchApi get _onlineApi => widget.onlineApi ?? const OnlineMatchApi();
  static const AppPreferences _preferences = AppPreferences();
  static const StoreReviewService _storeReview = StoreReviewService();
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
  Timer? _idleMoveHintTimer;
  Timer? _onlinePollTimer;
  WebSocketChannel? _onlineChannel;
  StreamSubscription<dynamic>? _onlineSocketSubscription;
  Timer? _onlineSocketReconnectTimer;
  int _onlineSocketReconnectAttempts = 0;
  Timer? _onlineHeartbeatTimer;
  Timer? _onlineResultPresentationTimer;
  Timer? _quickChatTimer;
  OnlineMatchDto? _onlineMatch;
  String? _handledDrawOfferKey;
  String? _archivedOnlineMatchId;
  String? _joiningRematchId;
  int _onlineConnectedPlayers = 0;
  bool _onlineSocketConnected = false;
  bool _onlineSubmitting = false;
  String? _onlineCelebrationMatchId;
  String? _quickChatMessage;
  bool _quickChatMine = false;
  String? _selectedSquare;
  String? _premoveFrom;
  String? _premoveTo;
  String? _lastFromSquare;
  String? _lastToSquare;
  String? _lastCaptureSquare;
  ChessPiece? _lastMovedPiece;
  ChessPiece? _lastCapturedPiece;
  String? _lastPlayerMove;
  String? _lastPlayerCoachNote;
  String? _moveQualityText;
  bool _moveQualityIsWeak = false;
  int _hintStage = 0;
  String? _coachArrowFrom;
  String? _coachArrowTo;
  String? _idleHintFrom;
  String? _idleHintTo;
  int _coachRequestEpoch = 0;
  int _moveReviewEpoch = 0;
  double _engineEvaluationPawns = 0;
  final List<int> _playerMoveScores = <int>[];
  final List<String> _importantMistakes = <String>[];
  final List<SavedMoveReview> _moveReviews = <SavedMoveReview>[];
  String? _turningPoint;
  String _coachNote = 'Select a coin to see legal moves.';
  String _coachLanguageCode = AppLanguageController.systemCode;
  bool _coachLanguageLoaded = false;
  BoardSkin _skin = BoardSkin.royalWalnut;
  GameMode _gameMode = GameMode.computer;
  double _aiLevel = 4;
  AiBotStyle _aiStyle = AiBotStyle.balanced;
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
    unawaited(_loadCoachLanguage());
    AppLanguageController.effectiveLanguageChanges.addListener(
      _onCoachLanguageChanged,
    );
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
    _aiStyle = widget.initialAiStyle;
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
    final String playerName =
        widget.initialPlayerName != null &&
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
    if (_gameMode == GameMode.computer && widget.resumeDraft != null) {
      _restoreComputerDraft(widget.resumeDraft!);
    }
    unawaited(
      ComputerGameStore.activeOwner().then((owner) {
        if (!mounted) return;
        _draftOwner = owner;
        unawaited(_persistComputerDraft(force: true));
      }),
    );
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
    if (_gameMode == GameMode.computer &&
        (_moves.length.isEven != _humanPlaysWhite)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAiMove());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _restartTurnReminder());
    if (_gameMode == GameMode.online &&
        widget.initialOnlineMatch != null &&
        widget.initialAuthToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _beginOnlineMatch(
            widget.initialOnlineMatch!,
            widget.initialAuthToken!,
          );
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
      if (_gameMode == GameMode.computer && _computerPaused) return;
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

  Future<void> _loadCoachLanguage() async {
    final String language = await AppLanguageController.selectedCode();
    if (mounted) {
      setState(() {
        _coachLanguageCode =
            AppLanguageController.effectiveLanguageChanges.value ?? language;
        _coachLanguageLoaded = true;
      });
    }
  }

  Future<void> _chooseGameCoachLanguage() async {
    final String? language = await selectAndSaveAiLanguage(context);
    if (language != null && mounted) {
      setState(() => _coachLanguageCode = language);
    }
  }

  void _onCoachLanguageChanged() {
    final language = AppLanguageController.effectiveLanguageChanges.value;
    if (!mounted || language == null) return;
    setState(() {
      _coachLanguageCode = language;
      _coachLanguageLoaded = true;
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
      _preferences.readString('pieceSize', fallback: 'Extra Large'),
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
      _skin = _onlineMatch?.isTournamentMatch == true
          ? tournamentBoardSkin(_onlineMatch?.tournamentName)
          : switch (boardTheme) {
              'Jade Glass' ||
              'Ocean Teal' ||
              'Royal Emerald' => BoardSkin.jadeGlass,
              'Tournament' => BoardSkin.tournament,
              'Marble' => BoardSkin.marble,
              'Sapphire' ||
              'Midnight Sapphire' ||
              'Neon Arena' => BoardSkin.sapphire,
              _ => BoardSkin.royalWalnut,
            };
    });
    ChessSoundService.instance.enabled = _soundEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_persistComputerDraft(force: true));
    AppLanguageController.effectiveLanguageChanges.removeListener(
      _onCoachLanguageChanged,
    );
    _clockTimer?.cancel();
    _moveQualityTimer?.cancel();
    _aiWatchdogTimer?.cancel();
    _turnReminderTimer?.cancel();
    _idleMoveHintTimer?.cancel();
    _onlinePollTimer?.cancel();
    unawaited(_onlineSocketSubscription?.cancel());
    unawaited(_onlineChannel?.sink.close());
    _onlineSocketReconnectTimer?.cancel();
    _onlineHeartbeatTimer?.cancel();
    _onlineResultPresentationTimer?.cancel();
    _quickChatTimer?.cancel();
    final AudioPlayer? warningPlayer = _warningPlayer;
    if (warningPlayer != null) {
      unawaited(warningPlayer.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _computerPaused = state != AppLifecycleState.resumed;
    if (_computerPaused && _gameMode == GameMode.computer) {
      _aiMoveEpoch++;
      _aiThinking = false;
      unawaited(_persistComputerDraft(force: true));
    }
    if (state == AppLifecycleState.resumed) {
      if (_gameMode == GameMode.online &&
          _onlineMatch != null &&
          _authToken != null) {
        _resumeOnlineSession();
      } else if (_gameMode == GameMode.computer && _gameResultTitle == null) {
        // Android can suspend delayed callbacks while the app is backgrounded.
        // Re-evaluate the position on resume so an interrupted AI turn never
        // leaves the board waiting until the player starts a new game.
        _recoverComputerTurnIfNeeded();
      }
    } else if (state != AppLifecycleState.resumed) {
      _onlineHeartbeatTimer?.cancel();
      unawaited(_onlineChannel?.sink.close());
    }
  }

  void _recoverComputerTurnIfNeeded() {
    if (!mounted ||
        _gameMode != GameMode.computer ||
        _gameResultTitle != null) {
      return;
    }
    final bool aiPlaysWhite = !_humanPlaysWhite;
    final bool aiTurn = _moves.length.isEven == aiPlaysWhite;
    if (!aiTurn) return;

    _aiWatchdogTimer?.cancel();
    _aiMoveEpoch++;
    if (_aiThinking) {
      setState(() => _aiThinking = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleAiMove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _gameMode != GameMode.computer ||
          _allowComputerExit ||
          _draftConflict,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_pauseComputerAndLeave());
      },
      child: _buildGameScreen(context),
    );
  }

  Future<void> _pauseComputerAndLeave() async {
    if (_leavingComputerGame) return;
    _leavingComputerGame = true;
    _computerPaused = true;
    _aiMoveEpoch++;
    _aiThinking = false;
    _draftOwner ??= await ComputerGameStore.activeOwner();
    await _persistComputerDraft(force: true);
    if (!mounted) return;
    if (!_lastSaveOkay && !_draftConflict) {
      _leavingComputerGame = false;
      _computerPaused = false;
      _recoverComputerTurnIfNeeded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not pause safely. Reconnect, then go back to save your game.',
          ),
        ),
      );
      return;
    }
    setState(() => _allowComputerExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _leaveGame() {
    if (_gameMode == GameMode.computer) {
      unawaited(_pauseComputerAndLeave());
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildGameScreen(BuildContext context) {
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
    final String? checkedKingSquare = sideInCheck
        ? _kingSquare(sideToMoveWhite)
        : null;
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
                  : boardWidth;
              // Portrait is a vertically scrolling composition. Limiting its
              // board by the viewport height left only ~145px for the online
              // AI Coach after the two player rails, so the action row was
              // clipped. Keep the board at the full usable width and let the
              // page scroll to a properly sized coach panel below it.
              final double boardDimension = math.max(
                0,
                wide || compactLandscape
                    ? math.min(boardWidth, boardHeight)
                    : boardWidth,
              );
              final bool terminalCheckmate = _gameMode == GameMode.online
                  ? _onlineMatch?.resultReason == 'CHECKMATE'
                  : _gameResultDetail == 'Checkmate';
              final bool losingKingWhite =
                  _gameMode == GameMode.online &&
                      _onlineMatch?.resultReason == 'CHECKMATE'
                  ? _onlineMatch!.result == '0-1'
                  : sideToMoveWhite;

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
                decisiveSquare: terminalCheckmate ? _lastToSquare : null,
                fallenKingSquare: terminalCheckmate
                    ? (_kingSquare(losingKingWhite) ??
                          (_lastCapturedPiece?.code == 'K'
                              ? _lastCaptureSquare
                              : null))
                    : null,
                fallenKingWhite: losingKingWhite,
                coachArrowFrom: _coachArrowFrom,
                coachArrowTo: _coachArrowTo,
                idleHintFrom: _idleHintFrom,
                idleHintTo: _idleHintTo,
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
                      tournamentName: _onlineMatch?.tournamentName,
                      tournamentRound: _onlineMatch?.tournamentRound,
                      compactOverlay: compactLandscape,
                      bottomAction:
                          !wide &&
                              !compactLandscape &&
                              !widget.spectatorMode &&
                              _signedIn &&
                              _onlineMatch?.isActive == true
                          ? _buildQuickChatButton()
                          : null,
                    )
                  : BoardStage(palette: palette, child: board);

              final Widget studioCoach = !_coachLanguageLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : _StudioCoachPanel(
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
                      coachNote: _localizedLiveCoachText(
                        _lastPlayerCoachNote ?? _coachNote,
                        _coachLanguageCode,
                      ),
                      languageCode: _coachLanguageCode,
                      onLanguage: _chooseGameCoachLanguage,
                      evaluationPawns: _engineEvaluationPawns,
                      lastMove: _lastPlayerMove,
                      lastMoveOwner: _lastPlayerMove == null
                          ? null
                          : 'Your move',
                      dailyProgress: _dailyPlayerMovesCompleted,
                      dailyGoal: _dailyChallenge.playerMoveGoal,
                      canUndo:
                          _gameMode != GameMode.online &&
                          _gameResultTitle == null &&
                          _history.isNotEmpty,
                      hintLabel: switch (_hintStage) {
                        1 => 'Direction',
                        2 => 'Exact move',
                        _ => 'Piece hint',
                      },
                      canHint: _gameResultTitle == null,
                      analyzeLabel: _moveQualityText == null
                          ? 'Analyze'
                          : _moveQualityIsWeak
                          ? 'Why weak?'
                          : 'Analyze move',
                      onHint: _showHint,
                      onAnalyze: _showAnalysis,
                      onTryAgain: _gameMode == GameMode.online
                          ? () => unawaited(
                              _refreshOnlineMatch(forceBoardReplay: true),
                            )
                          : _isTacticsMode
                          ? (_gameResultTitle?.toLowerCase().contains(
                                      'challenge missed',
                                    ) ==
                                    true
                                ? _reset
                                : null)
                          : _confirmNewGame,
                      onUndo: _undo,
                      puzzleComplete:
                          _gameMode == GameMode.puzzle &&
                          _gameResultTitle == 'Puzzle complete',
                      onNextPuzzle: _startNextPuzzle,
                      onBackToAcademy: () => Navigator.of(context).pop(),
                    );
              final bool yourTurn = switch (_gameMode) {
                GameMode.computer =>
                  sideToMoveWhite == _humanPlaysWhite && !_aiThinking,
                GameMode.online =>
                  _onlineMatch != null &&
                      _onlineMatch!.activeColor.toLowerCase() ==
                          _onlineMatch!.yourColor.toLowerCase(),
                _ => true,
              };
              return Padding(
                padding: pagePadding,
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    wide || compactLandscape
                        ? 'landscape-game-layout'
                        : 'portrait-game-layout',
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
                                  onHome: _leaveGame,
                                  onPause: _gameMode == GameMode.computer
                                      ? _leaveGame
                                      : null,
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
                                            height:
                                                boardDimension +
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
                                    onHome: _leaveGame,
                                    onPause: _gameMode == GameMode.computer
                                        ? _leaveGame
                                        : null,
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
                        SingleChildScrollView(
                          key: const ValueKey<String>(
                            'portrait-game-scroll-view',
                          ),
                          padding: EdgeInsets.only(
                            bottom: math.max(
                              12,
                              MediaQuery.viewPaddingOf(context).bottom + 12,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              CompactHeader(
                                onHome: _leaveGame,
                                onPause: _gameMode == GameMode.computer
                                    ? _leaveGame
                                    : null,
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
                              SizedBox(
                                key: const ValueKey<String>('mobile-ai-coach'),
                                height: (constraints.maxHeight * 0.46).clamp(
                                  360.0,
                                  440.0,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    6,
                                    0,
                                    6,
                                    0,
                                  ),
                                  child: studioCoach,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_signedIn &&
                          _gameResultTitle == null &&
                          yourTurn &&
                          _turnBannerVisible)
                        Positioned(
                          top: wide ? wideHeaderHeight + 12 : 66,
                          left: wide ? 24 : 12,
                          right: wide ? widePanelWidth + 42 : 12,
                          child: _TurnBanner(
                            label: _gameMode == GameMode.local
                                ? (_moves.length.isEven
                                      ? 'PLAYER 1 • WHITE'
                                      : 'PLAYER 2 • BLACK')
                                : 'YOUR TURN',
                          ),
                        ),
                      if (_signedIn &&
                          _gameMode == GameMode.online &&
                          _onlineMatch?.isActive == true &&
                          (wide ||
                              compactLandscape ||
                              _quickChatMessage != null))
                        Positioned(
                          top: wide
                              ? wideHeaderHeight + 18
                              : compactLandscape
                              ? mobileHeaderHeight + 8
                              : mobileHeaderHeight + 100,
                          right: wide ? widePanelWidth + 34 : 10,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (_quickChatMessage != null)
                                Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 190,
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _quickChatMine
                                        ? const Color(0xEE0D746A)
                                        : const Color(0xEE132C3A),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFF52DCCB),
                                    ),
                                  ),
                                  child: Text(
                                    _quickChatMessage!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              if (wide || compactLandscape)
                                _buildQuickChatButton(),
                            ],
                          ),
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
                          !widget.spectatorMode &&
                          _gameResultTitle != null &&
                          _resultVisible)
                        Positioned.fill(
                          child: GameResultOverlay(
                            title: _resultDisplayTitle(),
                            detail: _gameResultDetail ?? 'Game complete',
                            scoreLabel: _resultScoreLabel(),
                            accuracy: _playerAccuracy,
                            turningPoint: _turningPoint,
                            entryCoins: _gameMode == GameMode.online
                                ? _onlineMatch?.entryCoins
                                : null,
                            rewardPoolCoins: _gameMode == GameMode.online
                                ? _onlineMatch?.rewardPoolCoins
                                : null,
                            coinsEarned: _gameMode == GameMode.online
                                ? _onlineMatch?.coinsEarned
                                : null,
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
                            onDismiss: () {
                              setState(() => _resultVisible = false);
                              unawaited(_maybeRequestStoreReview());
                            },
                            onReview: () {
                              setState(() => _resultVisible = false);
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _showAiReview(),
                              );
                            },
                            onShare: () async {
                              final String result = <String>[
                                'ChessVerseAI • ${_resultDisplayTitle()}',
                                _resultScoreLabel(),
                                _gameResultDetail ?? 'Game complete',
                                if (_playerAccuracy != null)
                                  'AI accuracy: $_playerAccuracy%',
                                if (_turningPoint != null)
                                  'Turning point: $_turningPoint',
                                'Play and improve at chessverseai.com',
                              ].join('\n');
                              await Clipboard.setData(
                                ClipboardData(text: result),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Shareable result copied.'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      if (_signedIn &&
                          _gameResultTitle != null &&
                          !_resultVisible &&
                          !_gameResultTitle!.toLowerCase().contains('draw') &&
                          !_gameResultTitle!.toLowerCase().contains(
                            'challenge missed',
                          ))
                        Positioned(
                          // On desktop the board and coach share the body. The
                          // completion badge belongs over the board, so centre
                          // it in that region instead of the full viewport
                          // (which places it between the board and coach).
                          top: wide ? wideHeaderHeight : 0,
                          bottom: wide && showWideDock ? wideDockHeight : 0,
                          left: 0,
                          right: wide ? widePanelWidth + 50 : 0,
                          child: OnlineVictoryCelebration(
                            winnerAtTop: true,
                            title: _resultDisplayTitle(),
                            showTitle: true,
                          ),
                        ),
                      if (_signedIn &&
                          _gameResultTitle != null &&
                          !_resultVisible &&
                          _gameResultTitle!.toLowerCase().contains('draw'))
                        Positioned.fill(
                          child: _DrawResultBadge(
                            detail: _gameResultDetail ?? 'Game drawn',
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
                                    color:
                                        (_moveQualityIsWeak
                                                ? const Color(0xFFD6A84F)
                                                : const Color(0xFF55D6B9))
                                            .withValues(alpha: 0.78),
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.32,
                                      ),
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
                                      Icon(
                                        _moveQualityIsWeak
                                            ? Icons.warning_amber_rounded
                                            : Icons.check_circle_rounded,
                                        color: _moveQualityIsWeak
                                            ? const Color(0xFFD6A84F)
                                            : const Color(0xFF55D6B9),
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
          onDisplayNameChanged: widget.onDisplayNameChanged,
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
        <String, String>{'accessToken': result.accessToken!.tokenString},
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
                  final String baseMessage =
                      response['message'] as String? ??
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
                  onPressed: loading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
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
        final Map<String, dynamic> response = await _authApi
            .post('register', <String, String>{
              'username': _authUsername,
              'displayName': _authDisplayName,
              'email': _authIdentity,
              'password': _authPassword,
            });
        if (!mounted) return;
        setState(() {
          _awaitingCode = true;
          _authHasError = false;
          final String baseMessage =
              response['message'] as String? ??
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
        refreshToken: response['refreshToken'] as String?,
        refreshExpiresAt: DateTime.tryParse(
          response['refreshExpiresAt'] as String? ?? '',
        ),
        sessionId: response['sessionId'] as String?,
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
    await _persistComputerDraft(force: true);
    if (!mounted || !_lastSaveOkay) return;
    if (onLogout != null) {
      await onLogout();
      return;
    }

    final String? token = _authToken;
    if (token != null) {
      await FirebasePushService.instance.unregister(token);
      await _authApi.logout(token);
    }
    await const AcademyProgressStore().clearCurrentIdentity();
    await LocalGameArchive.clearDeviceUserData();
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

  void _changeGameMode(GameMode mode) async {
    if (mode == _gameMode) {
      _confirmNewGame();
      return;
    }
    await _persistComputerDraft(force: true);
    if (!mounted || !_lastSaveOkay || _draftConflict) return;
    if (mode == GameMode.computer && _gameMode != GameMode.computer) {
      try {
        final owner = await ComputerGameStore.activeOwner();
        final saved = await ComputerGameStore.load(owner);
        if (!mounted) return;
        if (saved.isNotEmpty) {
          final replace = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Replace paused computer game?'),
              content: const Text(
                'Your account can keep one paused computer game. Completed history stays saved.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('New Game'),
                ),
              ],
            ),
          );
          if (replace != true) return;
        }
        await ComputerGameStore.prepare(
          owner,
          null,
          replacing: saved.isEmpty ? null : saved.first,
        );
        if (!mounted) return;
        _draftOwner = owner;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not sync My Games. Please retry.'),
            ),
          );
        }
        return;
      }
    }
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
    _reset(confirmed: true);
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
        final String rivalName =
            widget.aiOpponentName?.trim().isNotEmpty == true
            ? '${widget.aiOpponentName!.trim()} • AI Rival'
            : 'ChessVerseAI';
        _whitePlayerName = _humanPlaysWhite ? playerName : rivalName;
        _blackPlayerName = _humanPlaysWhite ? rivalName : playerName;
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
    final bool central =
        target.file >= 2 &&
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
    final String queenFile = dailyChallengeQueenFileForPattern(
      challenge.pattern,
    );
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
        pieces['${files[fileIndex]}${8 - rankIndex}'] = ChessPiece(
          token.toUpperCase(),
          white,
        );
        fileIndex++;
      }
      if (fileIndex != 8) {
        throw StateError('Invalid curated puzzle FEN: $fen');
      }
    }
    if (!ChessRules.hasOneKingPerSide(pieces)) {
      throw StateError('Invalid chess FEN (expected one king per side): $fen');
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
    final bool firstCompletion = !LocalGameArchive.isPuzzleComplete(
      _activePuzzle.id,
    );
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
    if (_draftConflict || (_computerPaused && _gameMode == GameMode.computer)) {
      return;
    }
    // A playable game must always contain exactly one king per side. Never
    // let a malformed/restored state continue accepting moves as seen in the
    // reported king-less board recording.
    if (!ChessRules.hasOneKingPerSide(_pieces)) {
      _reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _coachNote =
              'Invalid board detected and safely reset. Kings cannot be captured.';
        });
      });
      return;
    }
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
      if (widget.spectatorMode) {
        setState(
          () => _coachNote =
              'Spectator mode • Watch the live position and AI insights.',
        );
        return;
      }
      if (_onlineSubmitting) {
        return;
      }
      if (!onlineMatch.isYourTurn) {
        _handlePremoveTap(square);
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
    int? engineReviewPly;

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
        final String expected = _dailyChallenge.solution[_dailyPlyIndex]
            .toLowerCase();
        if (!expected.startsWith('$from$square')) {
          // Every chess-legal move is playable. Leaving the curated line
          // starts exploration mode, where the defense continues replying.
          puzzleWrongMove = true;
          _puzzleExplorationMode = true;
        }
      }
      if ((_gameMode == GameMode.computer || _gameMode == GameMode.online) &&
          widget.useRemoteEngine) {
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
        engineReviewPly = _moves.length;
        if (_gameMode == GameMode.online) {
          final bool promotes =
              piece.code == 'P' &&
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
          final bool locallyWeak = _scoreForMoveFeedback(moveFeedback) < 60;
          _moveQualityIsWeak = locallyWeak;
          _moveQualityText = widget.useRemoteEngine
              ? 'AI review in progress…'
              : locallyWeak
              ? '$moveFeedback Tap “Why is this weak?” to understand the safer plan.'
              : 'Move review • $moveFeedback';
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
            // A tactics puzzle is an exact forcing line, not a free-play game.
            // End this attempt instead of allowing a long branch that can
            // eventually surface normal-game draw/stalemate results.
            _gameResultTitle = 'Challenge missed';
            _gameResultDetail =
                'That move leaves the puzzle solution. Find the forcing line and try again.';
            _resultVisible = true;
            _coachNote =
                'That is a legal chess move, but not the tactic. Tap Try again and look for checks, captures, and threats.';
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
          _reviewPlayerMoveWithEngine(
            engineReviewFen!,
            engineReviewMove!,
            engineReviewPly!,
          ),
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

  void _handlePremoveTap(String square) {
    final ChessPiece? tapped = _pieces[square];
    if (_selectedSquare == null) {
      if (tapped?.white != _humanPlaysWhite) {
        setState(() {
          _premoveFrom = null;
          _premoveTo = null;
          _coachNote = 'Premove cancelled. Select one of your pieces.';
        });
        return;
      }
      setState(() {
        _selectedSquare = square;
        _premoveFrom = null;
        _premoveTo = null;
        _coachNote = 'Premove: choose where $square should move.';
      });
      return;
    }
    final String from = _selectedSquare!;
    final List<String> targets = _legalTargetsFor(from);
    setState(() {
      _selectedSquare = null;
      if (!targets.contains(square)) {
        _premoveFrom = null;
        _premoveTo = null;
        _coachNote = 'That premove is not legal on the current board.';
        return;
      }
      _premoveFrom = from;
      _premoveTo = square;
      _coachArrowFrom = from;
      _coachArrowTo = square;
      _coachNote =
          'Premove queued: $from → $square. Tap another piece to replace it.';
    });
    unawaited(ChessSoundService.instance.tap());
  }

  void _executePremoveIfReady(OnlineMatchDto match) {
    final String? from = _premoveFrom;
    final String? to = _premoveTo;
    if (!match.isActive ||
        !match.isYourTurn ||
        from == null ||
        to == null ||
        _onlineSubmitting) {
      return;
    }
    final ChessPiece? piece = _pieces[from];
    final bool legal =
        piece?.white == _humanPlaysWhite && _legalTargetsFor(from).contains(to);
    setState(() {
      _premoveFrom = null;
      _premoveTo = null;
      _coachArrowFrom = null;
      _coachArrowTo = null;
      _coachNote = legal
          ? 'Playing premove $from → $to…'
          : 'Premove cancelled because the position changed.';
    });
    if (!legal) return;
    final bool promotes =
        piece!.code == 'P' &&
        ((piece.white && to.endsWith('8')) ||
            (!piece.white && to.endsWith('1')));
    unawaited(
      _submitOnlineMove('$from$to${promotes ? 'q' : ''}', match.plyCount),
    );
  }

  void _dismissTurnReminder() {
    _boardTouchedThisTurn = true;
    _turnReminderTimer?.cancel();
    _scheduleIdleMoveHint(clearVisibleHint: true);
    if (_turnBannerVisible && mounted) {
      setState(() => _turnBannerVisible = false);
    }
  }

  void _restartTurnReminder() {
    _scheduleIdleMoveHint(clearVisibleHint: true);
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
    int ply,
  ) async {
    // Multiple half-moves can finish analysis out of order. They all belong
    // to the same game epoch and must be retained; only a board reset makes
    // an outstanding result stale.
    final int reviewEpoch = _moveReviewEpoch;
    final int reviewedBoardPly = _moves.length;
    try {
      final Map<String, dynamic> engine = await _engineApi.reviewMove(
        fen: fen,
        playedMove: playedMove,
        level: math.max(5, _aiLevel.round()),
      );
      if (!mounted || reviewEpoch != _moveReviewEpoch) return;
      final String bestMove = engine['bestMove'] as String? ?? '';
      if (bestMove.length < 4) return;
      final String classification =
          engine['classification'] as String? ?? 'Playable';
      final bool best = classification == 'Best';
      final bool isWeak =
          classification == 'Mistake' || classification == 'Blunder';
      final String recommendation =
          '${bestMove.substring(0, 2)} to ${bestMove.substring(2, 4)}';
      final String explanation =
          engine['explanation'] as String? ??
          (best
              ? 'You found the strongest continuation.'
              : '$recommendation was more accurate.');
      final String reviewText = '$classification • $explanation';
      final int cp = (engine['evaluationAfterCp'] as num?)?.toInt() ?? 0;
      final int evaluationBeforeCp =
          (engine['evaluationBeforeCp'] as num?)?.toInt() ?? 0;
      final int centipawnLoss = (engine['centipawnLoss'] as num?)?.toInt() ?? 0;
      final String opponentThreat = engine['opponentThreat'] as String? ?? '';
      final List<String> principalVariation =
          (engine['principalVariation'] as List<dynamic>? ?? <dynamic>[])
              .whereType<String>()
              .toList(growable: false);
      setState(() {
        _engineEvaluationPawns = cp / 100;
        // Post-move review is textual. Board arrows are reserved for an
        // explicit Hint/Analyze request so a completed move never leaves two
        // competing motion trails on the board.
        _coachArrowFrom = null;
        _coachArrowTo = null;
        if (_playerMoveScores.isNotEmpty) {
          _playerMoveScores[_playerMoveScores.length - 1] =
              (100 - (centipawnLoss / 3).round()).clamp(0, 100);
        }
        // The coach card and the compact review label must have one verdict.
        // Previously the immediate heuristic could remain "Superb" while the
        // engine label changed to "Good", showing two grades for one move.
        _moveQualityText = reviewText;
        _moveQualityIsWeak = isWeak;
        _lastPlayerCoachNote = reviewText;
        // A remote review may finish after the opponent has replied. Keep it
        // in the player's review summary, but never replace the current-board
        // status with commentary about an earlier position.
        if (_moves.length == reviewedBoardPly) {
          _coachNote = reviewText;
        }
        _moveReviews.removeWhere((SavedMoveReview item) => item.ply == ply);
        _moveReviews.add(
          SavedMoveReview(
            ply: ply,
            fenBefore: fen,
            playedMove: playedMove,
            bestMove: bestMove,
            classification: classification,
            coachingTheme: engine['coachingTheme'] as String? ?? 'calculation',
            centipawnLoss: centipawnLoss,
            evaluationBeforeCp: evaluationBeforeCp,
            evaluationAfterCp: cp,
            opponentThreat: opponentThreat,
            explanation: explanation,
            principalVariation: principalVariation,
          ),
        );
        if (isWeak) {
          _turningPoint ??= '$playedMove — $recommendation was stronger.';
          _recordImportantMistake(
            '$playedMove • Prefer $recommendation. $explanation',
          );
        }
      });
      if (_resultSaved) {
        LocalGameArchive.updateLatestGameReviews(_moveReviews);
      }
      _scheduleMoveQualityDismiss();
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
    if (_draftConflict || _computerPaused) return;
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
            reply = AiCandidate(
              candidate.from,
              candidate.to,
              candidate.score,
              promotion: plannedMove.length >= 5
                  ? plannedMove.substring(4, 5).toUpperCase()
                  : null,
            );
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
      final bool castleMove = _isCastleMove(from, to);
      final String? enPassantCaptureSquare = _enPassantCaptureSquare(from, to);
      final ChessPiece piece = _pieces.remove(from)!;
      final ChessPiece? captured = enPassantCaptureSquare == null
          ? _pieces[to]
          : _pieces.remove(enPassantCaptureSquare);
      _lastMovedPiece = piece;
      _lastCapturedPiece = captured;
      if (captured != null) {
        captured.white
            ? _capturedWhite.add(captured)
            : _capturedBlack.add(captured);
        _lastCaptureSquare = to;
      }
      _pieces[to] = piece;
      if (castleMove) {
        _moveCastlingRook(to, piece.white);
      }
      final bool promotes =
          piece.code == 'P' &&
          ((piece.white && to.endsWith('8')) ||
              (!piece.white && to.endsWith('1')));
      if (promotes) {
        _pieces[to] = ChessPiece(reply.promotion ?? 'Q', piece.white);
      }
      final String notation = castleMove
          ? (to.startsWith('g') ? 'O-O' : 'O-O-O')
          : captured == null
          ? '$from$to${promotes ? '=${reply.promotion ?? 'Q'}' : ''}'
          : '$from x $to${promotes ? '=${reply.promotion ?? 'Q'}' : ''}';
      _moves.insert(0, notation);
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
            engineMove = AiCandidate(
              from,
              to,
              1000,
              promotion: uci.length >= 5 ? uci[4].toUpperCase() : null,
            );
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

    if (!ChessRules.hasOneKingPerSide(_pieces)) {
      _aiWatchdogTimer?.cancel();
      setState(() {
        _aiThinking = false;
        _pieces = Map<String, ChessPiece>.from(_initialPieces);
        _moves.clear();
        _history.clear();
        _capturedWhite.clear();
        _capturedBlack.clear();
        _coachNote =
            'An invalid board was detected and safely reset. No king can be captured.';
      });
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
        final double centerBonus =
            3.5 -
            (targetPosition.file - 3.5).abs() +
            3.5 -
            (targetPosition.rank - 4.5).abs();
        double captureScore = 0.0;
        if (captured != null) {
          captureScore = _aiPieceValue(captured.code);
        }
        final AiCandidate candidate = AiCandidate(
          entry.key,
          target,
          captureScore * 10 + centerBonus + _random.nextDouble(),
        );
        final double safeScore = scoreOfflineAiCandidate(
          candidate,
          _pieces,
          aiPlaysWhite: aiPlaysWhite,
        );
        final Map<String, ChessPiece> after = ChessRules.applyMove(
          entry.key,
          target,
          _pieces,
        );
        final bool givesCheck = ChessRules.isKingInCheck(!aiPlaysWhite, after);
        final double styleBonus = aiStyleMoveBonus(
          _aiStyle,
          capturedValue: captured == null ? 0 : _aiPieceValue(captured.code),
          givesCheck: givesCheck,
          castles: _isCastleMove(entry.key, target),
          queenMove: entry.value.code == 'Q',
          movesPlayed: _moves.length,
        );
        candidates.add(
          AiCandidate(
            entry.key,
            target,
            safeScore + styleBonus,
            promotion: candidate.promotion,
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
    final int selectionLevel =
        widget.useRemoteEngine && level >= 4 && engineMove == null ? 10 : level;
    final AiCandidate move = chooseAiCandidateForLevel(
      candidates,
      selectionLevel,
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
        _pieces[move.to] = ChessPiece(move.promotion ?? 'Q', piece.white);
      }
      final String notation = castleMove
          ? (move.to.startsWith('g') ? 'O-O' : 'O-O-O')
          : captured == null
          ? '${move.from}${move.to}${move.promotion == null ? '' : '=${move.promotion}'}'
          : '${move.from} x ${move.to}${move.promotion == null ? '' : '=${move.promotion}'}';
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
    for (int index = 0; index < _moves.length; index++) {
      final String move = _moves[index];
      if (move.startsWith('O-O')) {
        final int chronologicalPly = _moves.length - 1 - index;
        final bool whiteCastled = chronologicalPly.isEven;
        final String homeRank = whiteCastled ? '1' : '8';
        final String rookSquare = move.startsWith('O-O-O')
            ? 'a$homeRank'
            : 'h$homeRank';
        if (square == 'e$homeRank' || square == rookSquare) {
          return true;
        }
        continue;
      }
      final ParsedMove? parsed = _parseMove(move);
      if (parsed?.from == square ||
          ((square == 'a1' ||
                  square == 'h1' ||
                  square == 'a8' ||
                  square == 'h8') &&
              parsed?.to == square)) {
        return true;
      }
    }
    return false;
  }

  ParsedMove? _parseMove(String move) {
    if (move.startsWith('O-O')) {
      return null;
    }

    final String cleaned = move
        .replaceAll(' x ', '')
        .replaceAll(' e.p.', '')
        .split('=')
        .first;
    if (cleaned.length < 4) {
      return null;
    }
    return ParsedMove(cleaned.substring(0, 2), cleaned.substring(2, 4));
  }

  void _reset({bool confirmed = false}) async {
    if (_draftConflict) return;
    if (!confirmed &&
        _gameMode == GameMode.computer &&
        _moves.isNotEmpty &&
        _gameResultTitle == null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Replace this game?'),
          content: const Text(
            'Your unfinished computer game will be replaced. Completed history is kept.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('New Game'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    if (!confirmed) await _persistComputerDraft(force: true);
    if (!mounted || _draftConflict || !_lastSaveOkay) return;
    _draftId = DateTime.now().microsecondsSinceEpoch.toString();
    _lastDraftFingerprint = null;
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
    _moveReviewEpoch++;
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
      _idleHintFrom = null;
      _idleHintTo = null;
      _engineEvaluationPawns = 0;
      _playerMoveScores.clear();
      _importantMistakes.clear();
      _moveReviews.clear();
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
    if (_gameMode == GameMode.computer) {
      _reset();
      return;
    }
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
    final DateTime archivedAt = DateTime.now();
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
        playedAt: archivedAt,
        whitePlayer: _whitePlayerName,
        blackPlayer: _blackPlayerName,
        playerOutcome: playerOutcomeForResult(
          _gameResultTitle!,
          humanPlaysWhite: _humanPlaysWhite,
          tracksPlayer: _gameMode != GameMode.local,
        ),
        moveReviews: List<SavedMoveReview>.from(_moveReviews)
          ..sort((SavedMoveReview a, SavedMoveReview b) => a.ply - b.ply),
      ),
    );
    unawaited(_submitFinishedGameForCloudAnalysis(archivedAt));
  }

  Future<void> _maybeRequestStoreReview() {
    final String outcome = playerOutcomeForResult(
      _gameResultTitle ?? '',
      humanPlaysWhite: _humanPlaysWhite,
      tracksPlayer: _gameMode != GameMode.local,
    );
    return _storeReview.maybeRequestReview(
      completedGames: LocalGameArchive.games.length,
      positiveOutcome: outcome == 'win',
    );
  }

  bool get _isHumanTurnForIdleHint {
    // Challenges must not reveal a move simply because the player takes time.
    // Explicitly requested hints remain available through their own controls.
    if (_isTacticsMode ||
        !_showMoveHints ||
        _gameResultTitle != null ||
        _aiThinking) {
      return false;
    }
    return switch (_gameMode) {
      GameMode.computer => _moves.length.isEven == _humanPlaysWhite,
      GameMode.online =>
        _onlineMatch?.isActive == true &&
            _onlineMatch?.isYourTurn == true &&
            !_onlineSubmitting,
      _ => true,
    };
  }

  void _scheduleIdleMoveHint({bool clearVisibleHint = false}) {
    _idleMoveHintTimer?.cancel();
    if (clearVisibleHint && (_idleHintFrom != null || _idleHintTo != null)) {
      if (mounted) {
        setState(() {
          _idleHintFrom = null;
          _idleHintTo = null;
        });
      } else {
        _idleHintFrom = null;
        _idleHintTo = null;
      }
    }
    if (!mounted || !_isHumanTurnForIdleHint) return;
    final int scheduledPly = _gameMode == GameMode.online
        ? (_onlineMatch?.plyCount ?? -1)
        : _moves.length;
    _idleMoveHintTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || !_isHumanTurnForIdleHint) return;
      final int currentPly = _gameMode == GameMode.online
          ? (_onlineMatch?.plyCount ?? -1)
          : _moves.length;
      if (currentPly != scheduledPly) return;
      final ({String from, String to})? hint = _bestLocalHintMove(
        _gameMode == GameMode.online
            ? (_onlineMatch?.whiteToMove ?? _moves.length.isEven)
            : (_isTacticsMode ? true : _moves.length.isEven),
      );
      if (hint == null) return;
      setState(() {
        _idleHintFrom = hint.from;
        _idleHintTo = hint.to;
        _coachNote =
            'Need a nudge? Blue lights suggest ${hint.from} → ${hint.to}. You can still choose any legal move.';
      });
    });
  }

  ({String from, String to})? _bestLocalHintMove(bool whiteToMove) {
    String? bestFrom;
    String? bestTo;
    double bestScore = -double.infinity;
    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white != whiteToMove) continue;
      for (final String target in _legalTargetsFor(entry.key)) {
        final double score = _analysisMoveScore(entry.key, target, entry.value);
        if (score > bestScore) {
          bestScore = score;
          bestFrom = entry.key;
          bestTo = target;
        }
      }
    }
    if (bestFrom == null || bestTo == null) return null;
    return (from: bestFrom, to: bestTo);
  }

  Future<void> _submitFinishedGameForCloudAnalysis(DateTime archivedAt) async {
    final String? token = _authToken;
    if (token == null || token.isEmpty || _gameMode != GameMode.computer) {
      return;
    }
    final List<String>? uciMoves = _chronologicalUciMoves();
    if (uciMoves == null || uciMoves.isEmpty) return;
    try {
      CloudAnalysisJob job = await _gameAnalysisApi.create(
        token,
        clientRequestId: archivedAt.toUtc().toIso8601String(),
        initialFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        moves: uciMoves,
        depth: 16,
        playerColor: _humanPlaysWhite ? 'WHITE' : 'BLACK',
        timeControl: '10+0',
      );
      LocalGameArchive.updateCloudAnalysisForGame(
        playedAt: archivedAt,
        jobId: job.id,
        status: job.status,
        openingEco: job.openingEco,
        openingName: job.openingName,
        bookPlies: job.bookPlies,
        firstDeviationPly: job.firstDeviationPly,
      );
      for (
        int attempt = 0;
        attempt < 600 && (job.status == 'QUEUED' || job.status == 'ANALYZING');
        attempt++
      ) {
        await Future<void>.delayed(const Duration(seconds: 2));
        job = await _gameAnalysisApi.results(token, job.id);
        LocalGameArchive.updateCloudAnalysisForGame(
          playedAt: archivedAt,
          jobId: job.id,
          status: job.status,
          openingEco: job.openingEco,
          openingName: job.openingName,
          bookPlies: job.bookPlies,
          firstDeviationPly: job.firstDeviationPly,
        );
      }
      if (job.status == 'COMPLETED' && job.plies.length == job.totalPlies) {
        LocalGameArchive.updateCloudAnalysisForGame(
          playedAt: archivedAt,
          jobId: job.id,
          status: job.status,
          openingEco: job.openingEco,
          openingName: job.openingName,
          bookPlies: job.bookPlies,
          firstDeviationPly: job.firstDeviationPly,
          reviews: _savedReviewsFromCloud(job),
        );
      }
    } on GameAnalysisApiException catch (error, stackTrace) {
      unawaited(
        AppDiagnostics.recordError(
          error,
          stackTrace,
          reason: 'cloud game analysis submission',
        ),
      );
    }
  }

  List<String>? _chronologicalUciMoves() {
    final List<String> chronological = _moves.reversed.toList(growable: false);
    final List<String> result = <String>[];
    for (int index = 0; index < chronological.length; index++) {
      final String notation = chronological[index];
      if (notation.startsWith('O-O-O')) {
        result.add(index.isEven ? 'e1c1' : 'e8c8');
        continue;
      }
      if (notation.startsWith('O-O')) {
        result.add(index.isEven ? 'e1g1' : 'e8g8');
        continue;
      }
      final ParsedMove? parsed = _parseMove(notation);
      if (parsed == null) return null;
      final RegExpMatch? promotion = RegExp(
        r'=([QRBN])',
        caseSensitive: false,
      ).firstMatch(notation);
      result.add(
        '${parsed.from}${parsed.to}${promotion?.group(1)?.toLowerCase() ?? ''}',
      );
    }
    return result;
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
      knownReviews: _moveReviews,
    );
    showAdaptiveAiReview(
      context,
      report: report,
      timeControl: _gameMode == GameMode.computer ? '10+0' : null,
      onRetryPosition: _openReviewedPositionRetry,
      onGeneratePuzzles: _generateMistakePuzzles,
    );
  }

  Future<void> _openReviewedPositionRetry(AiMoveInsight insight) async {
    final String? fen = insight.fenBefore;
    final String? bestMove = insight.bestMove;
    if (fen == null || fen.isEmpty || bestMove == null || bestMove.length < 4) {
      return;
    }
    final language = await AppLanguageController.effectiveCode();
    if (!mounted) return;
    final List<String> fenParts = fen.split(RegExp(r'\s+'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => ReviewedPositionRetryDialog(
          fen: fen,
          initialPieces: _piecesFromFen(fen),
          whiteToMove: fenParts.length < 2 || fenParts[1] != 'b',
          bestMove: bestMove,
          explanation: _reviewPracticeExplanation(insight, language),
          progressLabel: 'POSITION BEFORE MOVE ${insight.number}',
          languageCode: language,
        ),
      );
    });
  }

  void _generateMistakePuzzles() {
    final List<SavedMoveReview> puzzles = _moveReviews
        .where(
          (SavedMoveReview review) =>
              review.fenBefore.isNotEmpty &&
              review.bestMove.length >= 4 &&
              const <String>{
                'Inaccuracy',
                'Mistake',
                'Blunder',
              }.contains(review.classification),
        )
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    if (puzzles.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openMistakePuzzle(puzzles, 0);
    });
  }

  String _reviewPracticeExplanation(AiMoveInsight insight, String language) {
    final copy = CoachLocalizations(language);
    final String variation = insight.principalVariation.isEmpty
        ? ''
        : '\n${copy.text('continuation')}: ${insight.principalVariation.take(5).join(' → ')}.';
    return '${localizeLiveCoach(localizeReviewNarrative(insight.explanation, language), language)}\n'
        '${copy.text('immediateReply')}: ${insight.opponentThreat ?? '—'}.$variation';
  }

  Future<void> _openMistakePuzzle(
    List<SavedMoveReview> puzzles,
    int index,
  ) async {
    if (!mounted || index >= puzzles.length) return;
    final language = await AppLanguageController.effectiveCode();
    if (!mounted) return;
    final SavedMoveReview puzzle = puzzles[index];
    final List<String> fenParts = puzzle.fenBefore.split(RegExp(r'\s+'));
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => ReviewedPositionRetryDialog(
        fen: puzzle.fenBefore,
        initialPieces: _piecesFromFen(puzzle.fenBefore),
        whiteToMove: fenParts.length < 2 || fenParts[1] != 'b',
        bestMove: puzzle.bestMove,
        languageCode: language,
        explanation: puzzle.explanation,
        progressLabel: coachExtraText('mistakePuzzle', language, {
          'index': '${index + 1}',
          'total': '${puzzles.length}',
        }),
        nextLabel: coachExtraText(
          index + 1 < puzzles.length ? 'nextPuzzle' : 'finishSet',
          language,
        ),
        onNext: () {
          Navigator.of(context).pop();
          if (index + 1 < puzzles.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openMistakePuzzle(puzzles, index + 1);
            });
          } else {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text(
                  coachExtraText('trainingComplete', language, {
                    'count': '${puzzles.length}',
                  }),
                ),
              ),
            );
          }
        },
      ),
    );
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
        ? computerUndoSnapshotIndex(_history, humanPlaysWhite: _humanPlaysWhite)
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
    if (_gameResultTitle != null) return;
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
    final String direction = target.file >= 4
        ? 'toward the king side'
        : 'toward the queen side';
    final bool simpleLanguage = _aiLevel <= 3;
    return switch (stage) {
      1 =>
        simpleLanguage
            ? 'Hint 1/3 • Start with the $name on $from.'
            : 'Piece hint 1/3 • Candidate: $name on $from. Check its forcing options.',
      2 =>
        simpleLanguage
            ? 'Hint 2/3 • Move that $name $direction.'
            : 'Direction hint 2/3 • Improve the $name $direction and challenge the centre.',
      _ =>
        simpleLanguage
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
          coachLine:
              '${_engineEvaluationExplanation(engine, whiteToMove)} '
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
      builder: (BuildContext context) => PositionAnalysisSheet(
        analysis: analysis,
        languageCode: _effectiveLiveCoachLanguage(_coachLanguageCode),
      ),
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
    final OnlineMatchDto? match = await Navigator.of(context)
        .push<OnlineMatchDto>(
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
                  onProfile: _openProfile,
                  onAiFallback: (String rivalName) async {
                    if (!mounted) return;
                    _onlinePollTimer?.cancel();
                    _onlineMatch = null;
                    setState(() {
                      _gameMode = GameMode.computer;
                      _humanPlaysWhite = true;
                      _whitePlayerName = _playerDisplayName;
                      _blackPlayerName = '$rivalName • AI Rival';
                    });
                    _reset();
                    if (mounted) {
                      setState(
                        () => _blackPlayerName = '$rivalName • AI Rival',
                      );
                    }
                  },
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
      if (match.isTournamentMatch) {
        _skin = tournamentBoardSkin(match.tournamentName);
        ChessPieceAppearanceController.current.value =
            const ChessPieceAppearance(
              style: ChessPieceVisualStyle.premium3d,
              size: ChessPieceVisualSize.extraLarge,
            );
      }
      _gameMode = GameMode.online;
      _humanPlaysWhite = match.yourColor.toLowerCase() == 'white';
      _whitePlayerName = match.whitePlayerName ?? 'White player';
      _blackPlayerName = match.blackPlayerName ?? 'Black player';
      _whitePlayerPhotoUrl =
          match.whitePlayerPhotoUrl ??
          (_humanPlaysWhite ? widget.initialProfilePhotoUrl : null);
      _blackPlayerPhotoUrl =
          match.blackPlayerPhotoUrl ??
          (!_humanPlaysWhite ? widget.initialProfilePhotoUrl : null);
      _coachNote = widget.spectatorMode
          ? 'Live spectator • ${match.activeColor} to move. Tap Analyze for AI insight.'
          : _onlineStatusText(match);
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
        _onlineSocketReconnectAttempts = 0;
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
    if (!widget.spectatorMode) {
      unawaited(_connectOnlineSocket(token, match.id));
    }
  }

  Future<void> _connectOnlineSocket(String token, String matchId) async {
    _onlineSocketReconnectTimer?.cancel();
    _onlineHeartbeatTimer?.cancel();
    try {
      final WebSocketChannel channel = await _onlineApi.openMatchChannel(
        token,
        matchId,
      );
      _onlineChannel = channel;
      _onlineHeartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        try {
          channel.sink.add('{"type":"heartbeat"}');
        } on Object {
          // Stream callbacks schedule the reconnect path.
        }
      });
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
    if (_onlineSocketReconnectTimer?.isActive == true) return;
    setState(() => _onlineSocketConnected = false);
    _onlineHeartbeatTimer?.cancel();
    _onlineSocketReconnectTimer?.cancel();
    _onlineSocketReconnectAttempts++;
    final int delaySeconds = (2 * _onlineSocketReconnectAttempts).clamp(2, 12);
    _onlineSocketReconnectTimer = Timer(
      Duration(seconds: delaySeconds),
      () => unawaited(_connectOnlineSocket(token, matchId)),
    );
  }

  String _onlineStatusText(OnlineMatchDto match) {
    if (widget.spectatorMode) {
      return match.status == 'FINISHED'
          ? 'Spectator • Game finished ${match.scoreLabel}'
          : 'Spectator • ${match.activeColor} to move. Analyze the live position.';
    }
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
      final bool yours =
          match.drawOfferedByColor!.toLowerCase() ==
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

  Future<void> _refreshOnlineMatch({bool forceBoardReplay = false}) async {
    final OnlineMatchDto? current = _onlineMatch;
    final String? token = _authToken;
    if (current == null || token == null || _onlineSubmitting) return;
    try {
      final OnlineMatchDto latest = widget.spectatorMode
          ? await _onlineApi.spectate(token, current.id)
          : await _onlineApi.getMatch(token, current.id);
      if (!mounted) return;
      _rebuildFromOnline(latest, forceBoardReplay: forceBoardReplay);
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
    final bool shouldRestartIdleHint =
        forceBoardReplay ||
        previous == null ||
        previous.id != match.id ||
        previous.plyCount != match.plyCount ||
        previous.isYourTurn != match.isYourTurn;
    final bool sameBoard =
        !forceBoardReplay &&
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
      if (shouldRestartIdleHint) {
        _scheduleIdleMoveHint(clearVisibleHint: true);
      }
      return;
    }
    final Map<String, ChessPiece> board = Map<String, ChessPiece>.from(
      _initialPieces,
    );
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
      history.insert(0, captured == null ? '$from$to' : '$from x $to');
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
      _whitePlayerPhotoUrl =
          match.whitePlayerPhotoUrl ??
          (_humanPlaysWhite ? widget.initialProfilePhotoUrl : null);
      _blackPlayerPhotoUrl =
          match.blackPlayerPhotoUrl ??
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
    _executePremoveIfReady(match);
    if (shouldRestartIdleHint) {
      _scheduleIdleMoveHint(clearVisibleHint: true);
    }
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
    if (!widget.spectatorMode) {
      unawaited(_connectOnlineSocket(token, match.id));
    }
  }

  Future<void> _startFreshOnlineGame() async {
    final OnlineMatchDto? completed = _onlineMatch;
    if (completed?.status == 'FINISHED') {
      await PostMatchAdService.instance.showAfterMatch(completed!.id);
    }
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
        setState(() {
          _onlineSocketConnected = true;
          _onlineSocketReconnectAttempts = 0;
        });
      }
      if (decoded['type'] == 'quick_chat') {
        final String value = decoded['value'] as String? ?? '';
        if (value.isEmpty || !mounted) return;
        _quickChatTimer?.cancel();
        setState(() {
          _quickChatMessage = value;
          _quickChatMine = decoded['mine'] as bool? ?? false;
        });
        _quickChatTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _quickChatMessage = null);
        });
        return;
      }
      if (decoded['type'] != 'presence.updated') return;
      final int connected = (decoded['connectedPlayers'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() {
        _onlineConnectedPlayers = connected;
        _onlineSocketConnected = true;
        _onlineSocketReconnectAttempts = 0;
        if (_onlineMatch?.isActive == true && connected < 2) {
          _coachNote = 'Opponent connection lost. Waiting for reconnect...';
        }
      });
    } on FormatException {
      // Ignore non-JSON socket frames; polling remains the source of truth.
    }
  }

  void _sendQuickChat(String value) {
    final WebSocketChannel? channel = _onlineChannel;
    if (channel == null || !_onlineSocketConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconnect to send a game message.')),
      );
      return;
    }
    channel.sink.add(
      jsonEncode(<String, String>{'type': 'quick_chat', 'value': value}),
    );
  }

  Widget _buildQuickChatButton() => IconButton.filled(
    key: const ValueKey<String>('online-quick-chat-button'),
    tooltip: 'Quick game chat',
    onPressed: _showQuickChatPicker,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xEE08283A),
      foregroundColor: const Color(0xFF59E5D2),
      side: const BorderSide(color: Color(0xFF59E5D2)),
    ),
    icon: const Icon(Icons.emoji_emotions_outlined),
  );

  Future<void> _showQuickChatPicker() async {
    const List<String> phrases = <String>[
      '👍 Good move',
      '🍀 Good luck',
      '🤝 Good game',
      '👏 Well played',
      '🔥 Nice tactic',
      '⚡ Your turn',
    ];
    const List<String> emojis = <String>[
      '😄',
      '😂',
      '😉',
      '😮',
      '😢',
      '😡',
      '👍',
      '👏',
      '♟️',
    ];
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0A1C2B),
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'QUICK GAME CHAT',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: phrases
                    .map(
                      (String message) => ActionChip(
                        label: Text(message),
                        onPressed: () => Navigator.pop(context, message),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 14),
              const Text(
                'REACTIONS',
                style: TextStyle(
                  color: Color(0xFF59E5D2),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emojis
                    .map(
                      (String emoji) => ActionChip(
                        label: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        onPressed: () => Navigator.pop(context, emoji),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) _sendQuickChat(selected);
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
    await PostMatchAdService.instance.showAfterMatch(match.id);
    setState(() {
      _resultVisible = false;
      _coachNote = 'Rematch requested. Waiting for your opponent...';
    });
    try {
      final OnlineMatchDto next = await _onlineApi.requestRematch(
        token,
        match.id,
      );
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
    if (widget.spectatorMode) {
      if (match.status == 'FINISHED' && mounted) {
        setState(
          () => _coachNote =
              'Game finished ${match.scoreLabel}. Open Watch & Learn for another live game.',
        );
      }
      return;
    }
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
          draw ? const Duration(milliseconds: 900) : const Duration(seconds: 3),
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
      final OnlineMatchDto rematch = await _onlineApi.getMatch(
        token,
        rematchId,
      );
      if (!mounted || _joiningRematchId != rematchId) return;
      _joiningRematchId = null;
      _beginOnlineMatch(rematch, token);
    } on OnlineMatchException catch (error) {
      if (!mounted) return;
      _joiningRematchId = null;
      setState(
        () => _coachNote = 'Rematch reconnect pending: ${error.message}',
      );
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
    final bool draw = match.result == '1/2-1/2';
    final bool userIsWhite = match.yourColor.toUpperCase() == 'WHITE';
    final bool userWon =
        (match.result == '1-0' && userIsWhite) ||
        (match.result == '0-1' && !userIsWhite);
    final String coinText = match.entryCoins <= 0
        ? ''
        : draw
        ? ' • ${match.entryCoins} coins refunded'
        : userWon
        ? ' • Prize +${match.coinsEarned} coins'
        : ' • Entry -${match.entryCoins} coins';
    return '${match.result ?? ''} • $reason$ratingText$coinText';
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
      if (_isTacticsMode) {
        _gameResultTitle = 'Challenge missed';
        _gameResultDetail =
            'Stalemate is not the checkmate objective. Try the forcing line again.';
        _resultVisible = true;
        unawaited(ChessSoundService.instance.error());
        return 'Stalemate avoids checkmate. Try again.';
      }
      _gameResultTitle = 'Draw';
      _gameResultDetail = 'Stalemate';
      _delayLocalResultOverlay(delay: const Duration(milliseconds: 900));
      _archiveFinishedGame();
      unawaited(ChessSoundService.instance.draw());
      return 'Stalemate. No legal move for $side.';
    }
    if (inCheck) {
      return '$side is in check.';
    }
    return fallback;
  }

  void _delayLocalResultOverlay({
    Duration delay = const Duration(seconds: 10),
  }) {
    _onlineResultPresentationTimer?.cancel();
    _resultVisible = false;
    _onlineResultPresentationTimer = Timer(delay, () {
      if (!mounted || _gameMode == GameMode.online) return;
      setState(() => _resultVisible = true);
    });
  }

  String _coachMoveExplanation({
    required ChessPiece piece,
    required String from,
    required String to,
    required ChessPiece? captured,
  }) {
    final String movedPieceName = switch (piece.code) {
      'P' => 'Pawn',
      'N' => 'Knight',
      'B' => 'Bishop',
      'R' => 'Rook',
      'Q' => 'Queen',
      'K' => 'King',
      _ => 'Piece',
    };
    final bool givesCheck = ChessRules.isKingInCheck(!piece.white, _pieces);
    final String? enemyKingSquare = ChessRules.kingSquare(
      !piece.white,
      _pieces,
    );
    final bool movedPieceGivesCheck =
        enemyKingSquare != null &&
        ChessRules.attacksSquare(to, enemyKingSquare, _pieces);
    final SquarePosition target = ChessRules.positionOf(to);
    final bool controlsCenter =
        target.file >= 2 &&
        target.file <= 5 &&
        target.rank >= 3 &&
        target.rank <= 6;
    final String sourceSquare = from.toLowerCase();
    final String targetSquare = to.toLowerCase();
    final String action = captured == null
        ? '$movedPieceName moved from $sourceSquare to $targetSquare.'
        : '$movedPieceName captured ${_pieceName(captured.code)} on $targetSquare.';
    final String piecePurpose = switch (piece.code) {
      'P' =>
        controlsCenter
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
      if (!movedPieceGivesCheck && enemyKingSquare != null) {
        final List<String> attackers = ChessRules.checkingAttackers(
          !piece.white,
          _pieces,
        );
        if (attackers.isNotEmpty) {
          final String attackerSquare = attackers.first;
          final ChessPiece attacker = _pieces[attackerSquare]!;
          final String attackerName = pieceName(attacker.code);
          return '$action Discovered check: moving the ${pieceName(piece.code)} opened the $attackerName attack from $attackerSquare onto the king at $enemyKingSquare. The opponent must answer that revealed check. $piecePurpose';
        }
      }
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

  String _engineEvaluationExplanation(Map<String, dynamic> engine, bool _) {
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
