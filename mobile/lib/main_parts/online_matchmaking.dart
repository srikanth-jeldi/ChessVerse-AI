part of '../main.dart';

enum OnlineLobbyMode { random, friends }

typedef _SearchPreferences = ({
  int timeControlMinutes,
  String region,
  int ratingRange,
  int entryCoins,
});

class OnlineMatchmakingSheet extends StatefulWidget {
  const OnlineMatchmakingSheet({
    required this.api,
    required this.token,
    required this.onProfile,
    this.onAiFallback,
    this.initialMode = OnlineLobbyMode.random,
    super.key,
  });

  final OnlineMatchApi api;
  final String token;
  final VoidCallback onProfile;
  final Future<void> Function(String rivalName)? onAiFallback;
  final OnlineLobbyMode initialMode;

  @override
  State<OnlineMatchmakingSheet> createState() => _OnlineMatchmakingSheetState();
}

class _OnlineMatchmakingSheetState extends State<OnlineMatchmakingSheet> {
  static const int _randomSearchLimitSeconds = 20;
  static const List<String> _aiRivalNames = <String>[
    'Arjun Knight',
    'Maya Bishop',
    'Ravi Rook',
    'Tara Queen',
    'Vikram Pawn',
    'Nisha Gambit',
    'Kabir Castle',
    'Anaya Tactics',
  ];
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
  int? _onlinePlayerCount;
  final Set<String> _closedWaitingMatchIds = <String>{};
  int _timeControlMinutes = 10;
  String _searchRegion = 'WORLDWIDE';
  int _ratingRange = 0;
  int _entryCoins = 100;
  int? _coinBalance;
  String _connectionQuality = 'STANDARD';
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshCoinBalance());
  }

  Future<void> _refreshCoinBalance() async {
    try {
      final EconomyRewardStatus status = await const EconomyRewardsApi().status(
        widget.token,
      );
      if (mounted) setState(() => _coinBalance = status.coins);
    } on Object {
      // The server still performs the authoritative balance check.
    }
  }

  bool get _needsPlayCoins =>
      _error?.toLowerCase().contains('insufficient coins') ?? false;

  Future<void> _openEarnCoins() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CosmeticShopScreen(token: widget.token),
      ),
    );
    if (mounted) setState(() => _error = null);
  }

  Widget _errorNotice() {
    if (_needsPlayCoins) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x332A213D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD6A84F)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.monetization_on_rounded, color: Color(0xFFD6A84F)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Not enough play coins. Claim the free daily reward or watch rewarded videos—no purchase needed.',
                style: TextStyle(color: Color(0xFFFFE2A3)),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _openEarnCoins,
              child: const Text('Earn free coins'),
            ),
          ],
        ),
      );
    }
    return Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B)));
  }

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
    if (randomSearch) unawaited(_refreshOnlinePlayerCount());
    try {
      final OnlineMatchDto match = await operation();
      if (!mounted) return;
      unawaited(_refreshCoinBalance());
      _accept(match);
    } on OnlineMatchException catch (error) {
      if (mounted) {
        final bool insufficientCoins =
            error.statusCode == 409 &&
            _coinBalance != null &&
            _coinBalance! < _entryCoins;
        setState(
          () => _error = insufficientCoins
              ? 'Insufficient coins to enter this match.'
              : error.message,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshOnlinePlayerCount() async {
    try {
      final Stopwatch latency = Stopwatch()..start();
      final int count = await widget.api.onlinePlayerCount(widget.token);
      latency.stop();
      if (mounted) {
        setState(() {
          _onlinePlayerCount = count;
          _connectionQuality = latency.elapsedMilliseconds <= 180
              ? 'EXCELLENT'
              : latency.elapsedMilliseconds <= 650
              ? 'STANDARD'
              : 'LIMITED';
        });
      }
    } on OnlineMatchException {
      // Presence is supporting context; matchmaking remains available when
      // the count endpoint is temporarily unavailable.
    }
  }

  Future<OnlineMatchDto> _requestRandomMatch() => widget.api.randomMatch(
    widget.token,
    timeControlMinutes: _timeControlMinutes,
    region: _searchRegion,
    ratingRange: _ratingRange,
    entryCoins: _entryCoins,
    connectionQuality: _connectionQuality,
  );

  Future<void> _applySearchPreferences(_SearchPreferences preferences) async {
    final OnlineMatchDto? waiting = _match;
    if (waiting != null) {
      _closedWaitingMatchIds.add(waiting.id);
      _pollTimer?.cancel();
      _elapsedTimer?.cancel();
      _socketReconnectTimer?.cancel();
      await _socketSubscription?.cancel();
      await _channel?.sink.close();
      try {
        await widget.api.cancelWaiting(widget.token, waiting.id);
      } on OnlineMatchException {
        // The server may have already expired the old queue entry.
      }
    }
    if (!mounted) return;
    setState(() {
      _match = null;
      _elapsedSeconds = 0;
      _timeControlMinutes = preferences.timeControlMinutes;
      _searchRegion = preferences.region;
      _ratingRange = preferences.ratingRange;
      _entryCoins = preferences.entryCoins;
    });
    await _run(_requestRandomMatch, randomSearch: true);
  }

  void _accept(OnlineMatchDto match) {
    // A poll or websocket event may complete after the 20-second expiry or a
    // manual cancellation. Never let that stale response revive the search.
    if (_closedWaitingMatchIds.contains(match.id)) return;
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
      // Give the premium rival-found reveal enough time to complete its
      // three-second countdown before opening the board.
      _foundTimer = Timer(const Duration(milliseconds: 3600), () {
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
    unawaited(_openSocket(match));
  }

  Future<void> _expireRandomSearch(OnlineMatchDto waiting) async {
    if (!_randomSearch || _match?.id != waiting.id || _foundMatch != null) {
      return;
    }
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    _socketReconnectTimer?.cancel();
    _closedWaitingMatchIds.add(waiting.id);
    await _socketSubscription?.cancel();
    await _channel?.sink.close();
    try {
      await widget.api.cancelWaiting(widget.token, waiting.id);
    } on OnlineMatchException {
      // The lobby may already have expired server-side.
    }
    if (!mounted || _match?.id != waiting.id || _foundMatch != null) return;
    final String rivalName =
        _aiRivalNames[DateTime.now().millisecondsSinceEpoch %
            _aiRivalNames.length];
    final Future<void> Function(String rivalName)? fallback =
        widget.onAiFallback;
    if (fallback == null) {
      setState(() {
        _match = null;
        _randomSearch = false;
        _loading = false;
        _elapsedSeconds = 0;
        _error = 'No active rival found. Try searching again.';
      });
      return;
    }
    final bool continueWithComputer = await _confirmComputerFallback();
    if (!mounted || _foundMatch != null) return;
    if (!continueWithComputer) {
      setState(() {
        _match = null;
        _randomSearch = false;
        _loading = false;
        _elapsedSeconds = 0;
        _error = 'No online player was available. Search again when ready.';
      });
      return;
    }
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(fallback(rivalName));
    });
  }

  Future<bool> _confirmComputerFallback() async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF071725),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF0B84B), width: 1.2),
        ),
        icon: const Icon(
          Icons.person_search_rounded,
          color: Color(0xFF58DFC9),
          size: 44,
        ),
        title: const Text(
          'No online player found',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'No suitable player is online right now. Would you like to continue '
          'this match against ChessVerseAI? Your selected coin entry will not '
          'be used for a computer match.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB8C4D0), height: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('SEARCH LATER'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.smart_toy_rounded),
            label: const Text('PLAY COMPUTER'),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _openSocket(OnlineMatchDto match) async {
    _socketReconnectTimer?.cancel();
    unawaited(_socketSubscription?.cancel());
    unawaited(_channel?.sink.close());
    try {
      final WebSocketChannel channel = await widget.api.openMatchChannel(
        widget.token,
        match.id,
      );
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
      () => unawaited(_openSocket(match)),
    );
  }

  Future<void> _poll() async {
    final OnlineMatchDto? current = _match;
    if (current == null) return;
    try {
      final OnlineMatchDto latest = await widget.api.getMatch(
        widget.token,
        current.id,
      );
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
      _closedWaitingMatchIds.add(waiting.id);
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
    final bool compactLobby = size.width < 600;
    final double maxWidth = wideLayout ? 1180 : math.min(560, size.width - 20);
    final double maxHeight = size.height * (wideLayout ? 0.94 : 0.96);
    final OnlineMatchDto? found = _foundMatch;

    if (wideLayout &&
        widget.initialMode == OnlineLobbyMode.random &&
        found == null &&
        _match == null) {
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
            constraints: BoxConstraints(
              maxWidth: math.min(maxWidth, wideLayout ? 980 : 460),
            ),
            child: _MatchSearchingView(
              match: waiting,
              randomSearch: _randomSearch,
              roomCode: waiting.roomCode,
              elapsedSeconds: _elapsedSeconds,
              onlinePlayerCount: _onlinePlayerCount,
              wideLayout: wideLayout,
              preferences: (
                timeControlMinutes: _timeControlMinutes,
                region: _searchRegion,
                ratingRange: _ratingRange,
                entryCoins: _entryCoins,
              ),
              onPreferencesChanged: _applySearchPreferences,
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
                          widget.initialMode == OnlineLobbyMode.random
                              ? 'Play Online'
                              : 'Play with Friends',
                          style:
                              (wideLayout
                                      ? Theme.of(
                                          context,
                                        ).textTheme.headlineMedium
                                      : Theme.of(
                                          context,
                                        ).textTheme.headlineSmall)
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
                  Text(
                    widget.initialMode == OnlineLobbyMode.random
                        ? 'Find a live opponent from around the world.'
                        : 'Create a private room or join your friend with a code.',
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    _errorNotice(),
                  ],
                  SizedBox(height: wideLayout ? 22 : 16),
                  if (widget.initialMode == OnlineLobbyMode.random)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        image: !compactLobby
                            ? const DecorationImage(
                                image: AssetImage(
                                  'assets/backgrounds/online-matchmaking-hero-v1.webp',
                                ),
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                opacity: .78,
                              )
                            : null,
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
                        padding: EdgeInsets.fromLTRB(
                          wideLayout ? 230 : 18,
                          wideLayout ? 30 : 20,
                          wideLayout ? 230 : 18,
                          wideLayout ? 30 : 18,
                        ),
                        child: Column(
                          crossAxisAlignment: wideLayout
                              ? CrossAxisAlignment.stretch
                              : CrossAxisAlignment.center,
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
                                    maxLines: 1,
                                    style:
                                        (wideLayout
                                                ? Theme.of(
                                                    context,
                                                  ).textTheme.headlineMedium
                                                : Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge)
                                            ?.copyWith(
                                              fontSize: wideLayout ? null : 20,
                                              fontWeight: FontWeight.w900,
                                            ),
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
                            if (compactLobby) ...<Widget>[
                              const SizedBox(height: 12),
                              Container(
                                key: const ValueKey<String>(
                                  'mobile-matchmaking-hero',
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF020D19),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xAA2F9CFF),
                                  ),
                                  boxShadow: const <BoxShadow>[
                                    BoxShadow(
                                      color: Color(0x332F9CFF),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: AspectRatio(
                                  // Keep the pawn and world map visible like
                                  // the desktop hero instead of cropping them
                                  // into a shallow banner on phones.
                                  aspectRatio: 1.62,
                                  child: Image.asset(
                                    'assets/backgrounds/online-matchmaking-hero-v1.webp',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _CoinStakeSelector(
                              balance: _coinBalance,
                              entryCoins: _entryCoins,
                              enabled: !_loading,
                              onSelected: (int coins) =>
                                  setState(() => _entryCoins = coins),
                            ),
                            SizedBox(height: wideLayout ? 18 : 12),
                            Align(
                              alignment: wideLayout
                                  ? Alignment.centerLeft
                                  : Alignment.center,
                              child: SizedBox(
                                width: wideLayout ? 280 : 176,
                                height: wideLayout ? 52 : 44,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: wideLayout ? 17 : 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  onPressed: _loading
                                      ? null
                                      : () => _run(
                                          _requestRandomMatch,
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
                  if (widget.initialMode == OnlineLobbyMode.random)
                    const SizedBox(height: 14),
                  if (widget.initialMode == OnlineLobbyMode.friends)
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
                  if (widget.initialMode == OnlineLobbyMode.friends)
                    const SizedBox(height: 14),
                  if (widget.initialMode == OnlineLobbyMode.friends)
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
                  if (widget.initialMode == OnlineLobbyMode.friends)
                    const SizedBox(height: 12),
                  if (widget.initialMode == OnlineLobbyMode.friends)
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
                        : () => _run(() => widget.api.reconnect(widget.token)),
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
                            'Moves are validated by ChessVerseAI servers.\n'
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
              onProfile: widget.onProfile,
              onAnalysis: () => Navigator.of(context).pop(),
              onRankings: () => Navigator.of(context).pop(),
              onFriends: () {},
              onEvents: () {},
              onStore: () {},
              onSettings: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compactDesktop ? 24 : 38,
                  compactDesktop ? 18 : 22,
                  compactDesktop ? 24 : 36,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF082431),
                            border: Border.all(color: teal),
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            color: teal,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Online 2 Players',
                                style: textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 32,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Play online with a random opponent or invite a friend to a private room.',
                                style: TextStyle(
                                  color: Color(0xFFB8C3D1),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0A1A2B),
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 26),
                        ),
                      ],
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _errorNotice(),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      height: 440,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/backgrounds/online-matchmaking-hero-v1.webp',
                          ),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFF2F9CFF),
                          width: 1.6,
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Color(0x442F9CFF), blurRadius: 18),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compactDesktop ? 210 : 365,
                          30,
                          compactDesktop ? 22 : 36,
                          24,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: compactDesktop ? 430 : 500,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Random Match',
                                  maxLines: 1,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'We’ll find a player for you\nfrom around the world.',
                                  style: TextStyle(
                                    color: Color(0xFFC8D1DD),
                                    fontSize: 17,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _CoinStakeSelector(
                                  balance: _coinBalance,
                                  entryCoins: _entryCoins,
                                  enabled: !_loading,
                                  onSelected: (int coins) =>
                                      setState(() => _entryCoins = coins),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: compactDesktop ? 230 : 260,
                                  height: 48,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: gold,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    onPressed: _loading
                                        ? null
                                        : () => _run(
                                            _requestRandomMatch,
                                            randomSearch: true,
                                          ),
                                    icon: const Icon(
                                      Icons.bolt_rounded,
                                      size: 21,
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
                      height: 242,
                      padding: const EdgeInsets.all(24),
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
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF267D72),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.group_rounded,
                                        color: teal,
                                        size: 31,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Play with Friend',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.only(left: 72),
                                  child: Text(
                                    'Create a private room or join\none using a room code.',
                                    style: TextStyle(
                                      color: Color(0xFFB8C3D1),
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                          const SizedBox(width: 26),
                          const VerticalDivider(color: Color(0xFF244257)),
                          const SizedBox(width: 26),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  width: double.infinity,
                                  height: 62,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Color(0xFF23D8C2),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    onPressed: _loading
                                        ? null
                                        : () => _run(
                                            () => widget.api.createRoom(
                                              widget.token,
                                            ),
                                          ),
                                    icon: const Icon(
                                      Icons.person_add_rounded,
                                      color: teal,
                                      size: 27,
                                    ),
                                    label: const Text('Create Room'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 62,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _loading ||
                                            _roomController.text.trim().isEmpty
                                        ? null
                                        : () => _run(
                                            () => widget.api.joinRoom(
                                              widget.token,
                                              _roomController.text,
                                            ),
                                          ),
                                    icon: const Icon(
                                      Icons.sports_esports_rounded,
                                      size: 27,
                                    ),
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
      child: Row(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF233B51)),
            ),
            child: Icon(icon, color: iconColor, size: 39),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB8C3D1),
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 34),
        ],
      ),
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
    child: const Row(
      children: <Widget>[
        Icon(Icons.verified_user_outlined, color: Color(0xFF43D6C1), size: 48),
        SizedBox(width: 22),
        Text(
          'Moves are validated by ChessVerseAI servers.\nActive matches restore after an app restart.',
          style: TextStyle(
            color: Color(0xFFB8C3D1),
            fontSize: 17,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _MatchSearchingView extends StatefulWidget {
  const _MatchSearchingView({
    required this.match,
    required this.randomSearch,
    required this.roomCode,
    required this.elapsedSeconds,
    required this.onlinePlayerCount,
    required this.wideLayout,
    required this.preferences,
    required this.onPreferencesChanged,
    required this.onCopyCode,
    required this.onCancel,
  });

  final OnlineMatchDto match;
  final bool randomSearch;
  final String roomCode;
  final int elapsedSeconds;
  final int? onlinePlayerCount;
  final bool wideLayout;
  final _SearchPreferences preferences;
  final ValueChanged<_SearchPreferences> onPreferencesChanged;
  final VoidCallback onCopyCode;
  final VoidCallback onCancel;

  @override
  State<_MatchSearchingView> createState() => _MatchSearchingViewState();
}

class _MatchSearchingViewState extends State<_MatchSearchingView>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  late final AnimationController _rivalShuffle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 9600),
  )..repeat();
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  )..forward();

  @override
  void dispose() {
    _pulse.dispose();
    _rivalShuffle.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String timer =
        '${(widget.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(widget.elapsedSeconds % 60).toString().padLeft(2, '0')}';
    if (widget.randomSearch) {
      if (widget.wideLayout) {
        return _buildWideReferenceSearch(context, timer);
      }
      return _buildMobileAdvancedSearch(context, timer);
    }
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

  Widget _buildWideReferenceSearch(BuildContext context, String timer) {
    const Color teal = Color(0xFF58DFC9);
    const Color gold = Color(0xFFF0B84B);
    final bool userIsWhite = widget.match.yourColor == 'WHITE';
    final String? resolvedName = userIsWhite
        ? widget.match.whitePlayerName
        : widget.match.blackPlayerName;
    final String playerName = resolvedName?.trim().isNotEmpty == true
        ? resolvedName!.trim()
        : 'You';
    final String rating = widget.match.ratingBefore?.toString() ?? 'Unrated';
    final int remaining = math.max(0, 20 - widget.elapsedSeconds);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.1,
      child: Material(
        color: const Color(0xFF020B14),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              'assets/backgrounds/grandmaster-table-v1.webp',
              fit: BoxFit.cover,
              color: const Color(0xFF02101C).withValues(alpha: .86),
              colorBlendMode: BlendMode.srcATop,
              filterQuality: FilterQuality.medium,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -.2),
                  radius: 1.05,
                  colors: <Color>[Color(0x3316B6AE), Color(0xF0020B14)],
                ),
              ),
            ),
            const Positioned(
              left: -48,
              bottom: -74,
              child: Icon(
                Icons.castle_rounded,
                size: 300,
                color: Color(0x1558DFC9),
              ),
            ),
            const Positioned(
              right: -38,
              bottom: -52,
              child: Icon(
                Icons.castle_outlined,
                size: 330,
                color: Color(0x14F0B84B),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compactHeight = constraints.maxHeight < 760;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      30,
                      compactHeight ? 16 : 24,
                      30,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1320),
                        child: Column(
                          children: <Widget>[
                            Text(
                              'RANKED RAPID • ${widget.preferences.timeControlMinutes} MIN',
                              style: const TextStyle(
                                color: gold,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.1,
                              ),
                            ),
                            SizedBox(height: compactHeight ? 8 : 12),
                            const Text(
                              'FINDING YOUR RIVAL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'serif',
                                color: Color(0xFFF1EDE4),
                                fontSize: 38,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Searching worldwide for the best available match',
                              style: TextStyle(
                                color: Color(0xFFB5BEC8),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _CoinPoolBanner(
                              entryCoins: widget.preferences.entryCoins,
                            ),
                            SizedBox(height: compactHeight ? 14 : 22),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(-.65, 0),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _entrance,
                                          curve: Curves.easeOutBack,
                                        ),
                                      ),
                                  child: FadeTransition(
                                    opacity: _entrance,
                                    child: SizedBox(
                                      key: const ValueKey<String>(
                                        'wide-player-card',
                                      ),
                                      width: 236,
                                      child: _WideSearchPlayerCard(
                                        accent: teal,
                                        icon: Icons.person_rounded,
                                        title: playerName,
                                        rating: rating,
                                        detail: rating == 'Unrated'
                                            ? 'Unrated'
                                            : 'Gold II',
                                        footer: 'Worldwide',
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _WideSearchCore(
                                    pulse: _pulse,
                                    timer: timer,
                                    compact: compactHeight,
                                  ),
                                ),
                                SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(.65, 0),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _entrance,
                                          curve: Curves.easeOutBack,
                                        ),
                                      ),
                                  child: FadeTransition(
                                    opacity: _entrance,
                                    child: SizedBox(
                                      key: const ValueKey<String>(
                                        'wide-rival-card',
                                      ),
                                      width: 236,
                                      child: _SearchingRivalCard(
                                        animation: _rivalShuffle,
                                        wide: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: compactHeight ? 12 : 18),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xD9071725),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color(0xFF655A3D),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _MobileSearchFact(
                                        icon: Icons.groups_rounded,
                                        value:
                                            widget.onlinePlayerCount
                                                ?.toString() ??
                                            '—',
                                        label: 'Players online',
                                      ),
                                    ),
                                    const _MobileFactDivider(),
                                    Expanded(
                                      child: _MobileSearchFact(
                                        icon: Icons.schedule_rounded,
                                        value: '< ${remaining}s',
                                        label: 'Estimated wait',
                                      ),
                                    ),
                                    const _MobileFactDivider(),
                                    Expanded(
                                      child: _MobileSearchFact(
                                        icon: Icons.gps_fixed_rounded,
                                        value:
                                            widget.preferences.ratingRange == 0
                                            ? 'Open'
                                            : '±${widget.preferences.ratingRange}',
                                        label: 'Rating range',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: widget.onCancel,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: gold,
                                    side: const BorderSide(
                                      color: gold,
                                      width: 1.4,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('CANCEL SEARCH'),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _showMobileSearchSettings(context),
                              icon: const Icon(Icons.settings_rounded),
                              label: const Text('SEARCH SETTINGS'),
                            ),
                            const Text(
                              'Keep this screen open. Your match starts automatically.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF98A4B0),
                                fontSize: 13,
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
          ],
        ),
      ),
    );
  }

  // Kept as a compact fallback while the shared composition is rolled out.
  // ignore: unused_element
  Widget _buildAdvancedSearch(BuildContext context, String timer) {
    const Color teal = Color(0xFF58DFC9);
    const Color gold = Color(0xFFE7B64F);
    final bool userIsWhite = widget.match.yourColor == 'WHITE';
    final String playerName =
        (userIsWhite
                    ? widget.match.whitePlayerName
                    : widget.match.blackPlayerName)
                ?.trim()
                .isNotEmpty ==
            true
        ? (userIsWhite
              ? widget.match.whitePlayerName!
              : widget.match.blackPlayerName!)
        : 'ChessVerseAI Player';
    final String rating = widget.match.ratingBefore?.toString() ?? 'Unrated';
    final int remaining = math.max(0, 20 - widget.elapsedSeconds);

    return Material(
      color: const Color(0xFF020C16),
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.fromLTRB(34, 26, 34, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF061B2B), Color(0xFF020B15)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF28475B)),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x332FD9C4), blurRadius: 34),
          ],
        ),
        child: Stack(
          children: <Widget>[
            const Positioned(
              left: 18,
              bottom: -46,
              child: Icon(
                Icons.castle_rounded,
                size: 210,
                color: Color(0x0D58DFC9),
              ),
            ),
            const Positioned(
              right: 12,
              top: -48,
              child: Icon(
                Icons.castle_outlined,
                size: 230,
                color: Color(0x0DE7B64F),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: .12),
                        shape: BoxShape.circle,
                        border: Border.all(color: teal.withValues(alpha: .65)),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: teal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'CHESSVERSEAI MATCHMAKING',
                            style: TextStyle(
                              color: gold,
                              fontSize: 13,
                              letterSpacing: 1.35,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Finding the strongest available rival',
                            style: TextStyle(
                              color: Color(0xFF9FB1C2),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SearchFact(
                      icon: Icons.public_rounded,
                      value: widget.onlinePlayerCount?.toString() ?? '—',
                      label: 'Online now',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: _MatchPlayerCard(
                        accent: teal,
                        icon: Icons.person_rounded,
                        eyebrow: 'YOU',
                        name: playerName,
                        rating: rating,
                        detail: 'Worldwide pool',
                        active: true,
                      ),
                    ),
                    SizedBox(
                      width: 210,
                      child: Column(
                        children: <Widget>[
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (BuildContext context, Widget? child) {
                              final double value = Curves.easeInOut.transform(
                                _pulse.value,
                              );
                              return Transform.scale(
                                scale: .94 + value * .08,
                                child: Container(
                                  width: 112,
                                  height: 112,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      transform: GradientRotation(
                                        value * math.pi * 2,
                                      ),
                                      colors: const <Color>[
                                        Color(0x0058DFC9),
                                        teal,
                                        Color(0x00E7B64F),
                                        gold,
                                        Color(0x0058DFC9),
                                      ],
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: teal.withValues(
                                          alpha: .18 + value * .16,
                                        ),
                                        blurRadius: 26,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    width: 94,
                                    height: 94,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF071A2A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text(
                                      'VS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'SEARCHING',
                            style: TextStyle(
                              color: teal,
                              fontSize: 12,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timer,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              fontFeatures: <ui.FontFeature>[
                                ui.FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      child: _MatchPlayerCard(
                        accent: gold,
                        icon: Icons.person_search_rounded,
                        eyebrow: 'RIVAL',
                        name: 'Searching…',
                        rating: 'Best match',
                        detail: 'Worldwide pool',
                        active: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xAA071725),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF233D50)),
                  ),
                  child: Row(
                    children: <Widget>[
                      _SearchFact(
                        icon: Icons.timer_outlined,
                        value: '${remaining}s',
                        label: 'Search window',
                      ),
                      const _SearchDivider(),
                      const _SearchFact(
                        icon: Icons.speed_rounded,
                        value: '10 min',
                        label: 'Rapid chess',
                      ),
                      const _SearchDivider(),
                      const _SearchFact(
                        icon: Icons.tune_rounded,
                        value: 'Open pool',
                        label: 'Rating range',
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF806B45)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 19),
                        label: const Text('Cancel search'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAdvancedSearch(BuildContext context, String timer) {
    const Color teal = Color(0xFF58DFC9);
    const Color gold = Color(0xFFF0B84B);
    final bool userIsWhite = widget.match.yourColor == 'WHITE';
    final String? resolvedName = userIsWhite
        ? widget.match.whitePlayerName
        : widget.match.blackPlayerName;
    final String playerName = resolvedName?.trim().isNotEmpty == true
        ? resolvedName!.trim()
        : 'You';
    final String rating = widget.match.ratingBefore?.toString() ?? 'Unrated';
    final int remaining = math.max(0, 20 - widget.elapsedSeconds);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.1,
      child: Material(
        color: const Color(0xFF020B14),
        child: Stack(
          children: <Widget>[
            const Positioned(
              left: -64,
              bottom: 80,
              child: Icon(
                Icons.castle_rounded,
                size: 220,
                color: Color(0x0C58DFC9),
              ),
            ),
            const Positioned(
              right: -66,
              bottom: 130,
              child: Icon(
                Icons.castle_outlined,
                size: 220,
                color: Color(0x0CF0B84B),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Cancel search',
                          onPressed: widget.onCancel,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: gold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'RANKED RAPID • ${widget.preferences.timeControlMinutes} MIN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.7,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Search settings',
                          onPressed: () => _showMobileSearchSettings(context),
                          icon: const Icon(Icons.tune_rounded, color: gold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'FINDING YOUR RIVAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Searching worldwide for the best available match',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFA8B4C1), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    _CoinPoolBanner(entryCoins: widget.preferences.entryCoins),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(-.7, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _entrance,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                            child: FadeTransition(
                              opacity: _entrance,
                              child: _MobileMatchPlayerCard(
                                key: const ValueKey<String>(
                                  'mobile-player-card',
                                ),
                                accent: teal,
                                icon: Icons.person_rounded,
                                title: playerName,
                                rating: rating,
                                subtitle: 'Worldwide',
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (BuildContext context, Widget? child) {
                              final double value = Curves.easeInOut.transform(
                                _pulse.value,
                              );
                              return Container(
                                width: 50 + value * 4,
                                height: 50 + value * 4,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF071725),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: gold),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: gold.withValues(
                                        alpha: .13 + value * .16,
                                      ),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'VS',
                                  style: TextStyle(
                                    color: gold,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(.7, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _entrance,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                            child: FadeTransition(
                              opacity: _entrance,
                              child: _SearchingRivalCard(
                                animation: _rivalShuffle,
                                wide: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (BuildContext context, Widget? child) {
                        final double value = Curves.easeInOut.transform(
                          _pulse.value,
                        );
                        return SizedBox.square(
                          dimension: 212,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              for (int index = 0; index < 4; index++)
                                Builder(
                                  builder: (BuildContext context) {
                                    final double wave =
                                        (value + index / 4) % 1.0;
                                    return Container(
                                      width: 106 + wave * 104,
                                      height: 106 + wave * 104,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: (index.isEven ? teal : gold)
                                              .withValues(
                                                alpha: (.52 * (1 - wave)) + .04,
                                              ),
                                          width: 1.2 + (1 - wave),
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: (index.isEven ? teal : gold)
                                                .withValues(
                                                  alpha: .13 * (1 - wave),
                                                ),
                                            blurRadius: 14,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              Container(
                                width: 158,
                                height: 158,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: <Color>[
                                      teal.withValues(alpha: .2),
                                      const Color(0xFF03111D),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: teal.withValues(alpha: .7),
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: teal.withValues(alpha: .2),
                                      blurRadius: 26,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/matchmaking/neon_rival_knights.webp',
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Text(
                      'SEARCH TIME',
                      style: TextStyle(
                        color: Color(0xFFAAB5C1),
                        fontSize: 12,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      timer,
                      style: const TextStyle(
                        color: teal,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        fontFeatures: <ui.FontFeature>[
                          ui.FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xD9071725),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: const Color(0xFF46503F)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _MobileSearchFact(
                              icon: Icons.groups_rounded,
                              value:
                                  widget.onlinePlayerCount?.toString() ?? '—',
                              label: 'Online',
                            ),
                          ),
                          const _MobileFactDivider(),
                          Expanded(
                            child: _MobileSearchFact(
                              icon: Icons.schedule_rounded,
                              value: '${remaining}s',
                              label: 'Window',
                            ),
                          ),
                          const _MobileFactDivider(),
                          Expanded(
                            child: _MobileSearchFact(
                              icon: Icons.gps_fixed_rounded,
                              value: widget.preferences.ratingRange == 0
                                  ? 'Open'
                                  : '±${widget.preferences.ratingRange}',
                              label: 'Range',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Keep this screen open. Your match starts automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A2AF), fontSize: 12),
                    ),
                    const SizedBox(height: 11),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gold,
                          side: const BorderSide(color: gold, width: 1.4),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('CANCEL SEARCH'),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showMobileSearchSettings(context),
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('SEARCH SETTINGS'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMobileSearchSettings(BuildContext context) async {
    int minutes = widget.preferences.timeControlMinutes;
    String region = widget.preferences.region;
    int range = widget.preferences.ratingRange;
    int entryCoins = widget.preferences.entryCoins;
    final _SearchPreferences?
    selected = await showModalBottomSheet<_SearchPreferences>(
      context: context,
      backgroundColor: const Color(0xFF071725),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) =>
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.1,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    28 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Search settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: minutes,
                        decoration: const InputDecoration(
                          labelText: 'Time control',
                          prefixIcon: Icon(Icons.speed_rounded),
                        ),
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem(
                            value: 3,
                            child: Text('Blitz • 3 min'),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text('Blitz • 5 min'),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child: Text('Rapid • 10 min'),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text('Rapid • 15 min'),
                          ),
                        ],
                        onChanged: (int? value) =>
                            setSheetState(() => minutes = value ?? 10),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: entryCoins,
                        decoration: const InputDecoration(
                          labelText: 'Play coin entry',
                          prefixIcon: Icon(Icons.monetization_on_rounded),
                        ),
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem(
                            value: 100,
                            child: Text('100 entry • 200 prize'),
                          ),
                          DropdownMenuItem(
                            value: 200,
                            child: Text('200 entry • 400 prize'),
                          ),
                          DropdownMenuItem(
                            value: 500,
                            child: Text('500 entry • 1,000 prize'),
                          ),
                        ],
                        onChanged: (int? value) =>
                            setSheetState(() => entryCoins = value ?? 100),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: region,
                        decoration: const InputDecoration(
                          labelText: 'Region',
                          prefixIcon: Icon(Icons.public_rounded),
                        ),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(
                            value: 'WORLDWIDE',
                            child: Text('Worldwide'),
                          ),
                          DropdownMenuItem(
                            value: 'COUNTRY',
                            child: Text('My country'),
                          ),
                        ],
                        onChanged: (String? value) =>
                            setSheetState(() => region = value ?? 'WORLDWIDE'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: range,
                        decoration: const InputDecoration(
                          labelText: 'Rating range',
                          prefixIcon: Icon(Icons.tune_rounded),
                        ),
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem(
                            value: 100,
                            child: Text('±100 rating'),
                          ),
                          DropdownMenuItem(
                            value: 250,
                            child: Text('±250 rating'),
                          ),
                          DropdownMenuItem(
                            value: 500,
                            child: Text('±500 rating'),
                          ),
                          DropdownMenuItem(value: 0, child: Text('Open pool')),
                        ],
                        onChanged: (int? value) =>
                            setSheetState(() => range = value ?? 0),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(sheetContext).pop((
                          timeControlMinutes: minutes,
                          region: region,
                          ratingRange: range,
                          entryCoins: entryCoins,
                        )),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('APPLY & RESTART SEARCH'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
    if (selected != null && selected != widget.preferences) {
      widget.onPreferencesChanged(selected);
    }
  }
}

class _WideSearchPlayerCard extends StatelessWidget {
  const _WideSearchPlayerCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.rating,
    required this.detail,
    required this.footer,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String rating;
  final String detail;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 318,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xE8071A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: .85), width: 1.25),
        boxShadow: <BoxShadow>[
          BoxShadow(color: accent.withValues(alpha: .09), blurRadius: 28),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  accent.withValues(alpha: .27),
                  const Color(0xFF061522),
                ],
              ),
              border: Border.all(color: accent, width: 1.5),
              boxShadow: <BoxShadow>[
                BoxShadow(color: accent.withValues(alpha: .2), blurRadius: 20),
              ],
            ),
            child: Icon(icon, color: accent, size: 58),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '🏆  $rating',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            detail,
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: const TextStyle(color: Color(0xFFA6B2BE), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _WideSearchCore extends StatelessWidget {
  const _WideSearchCore({
    required this.pulse,
    required this.timer,
    required this.compact,
  });

  final Animation<double> pulse;
  final String timer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const Color teal = Color(0xFF58DFC9);
    const Color gold = Color(0xFFF0B84B);
    final double dimension = compact ? 270 : 318;
    return Column(
      children: <Widget>[
        AnimatedBuilder(
          animation: pulse,
          builder: (BuildContext context, Widget? child) {
            final double phase = pulse.value;
            final double value = Curves.easeInOut.transform(pulse.value);
            return SizedBox.square(
              dimension: dimension,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  for (int index = 0; index < 5; index++)
                    Builder(
                      builder: (BuildContext context) {
                        final double wave = (value + index / 5) % 1;
                        return Container(
                          width: dimension * (.5 + wave * .48),
                          height: dimension * (.5 + wave * .48),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (index.isEven ? teal : gold).withValues(
                                alpha: .5 * (1 - wave) + .03,
                              ),
                              width: 1.2,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: (index.isEven ? teal : gold).withValues(
                                  alpha: .12 * (1 - wave),
                                ),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  for (int index = 0; index < 8; index++)
                    Transform.translate(
                      offset: Offset(
                        math.cos(phase * math.pi * 2 + index * math.pi / 4) *
                            dimension *
                            .43,
                        math.sin(phase * math.pi * 2 + index * math.pi / 4) *
                            dimension *
                            .43,
                      ),
                      child: Container(
                        width: index.isEven ? 8 : 5,
                        height: index.isEven ? 8 : 5,
                        decoration: BoxDecoration(
                          color: index.isEven ? teal : gold,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: (index.isEven ? teal : gold).withValues(
                                alpha: .75,
                              ),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(0, math.sin(phase * math.pi * 2) * 5),
                    child: Transform.scale(
                      scale: .98 + value * .035,
                      child: Container(
                        width: dimension * .72,
                        height: dimension * .72,
                        padding: EdgeInsets.all(dimension * .055),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              teal.withValues(alpha: .22 + value * .08),
                              const Color(0xFF03111D),
                            ],
                          ),
                          border: Border.all(
                            color: teal.withValues(alpha: .72),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: teal.withValues(alpha: .18 + value * .18),
                              blurRadius: 34 + value * 16,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/matchmaking/neon_rival_knights.webp',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 68,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xF2071725),
                      border: Border.all(color: gold, width: 1.4),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: gold.withValues(alpha: .25),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: gold,
                        fontFamily: 'serif',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Text(
          'SEARCH TIME',
          style: TextStyle(
            color: Color(0xFFAAB5C1),
            fontSize: 12,
            letterSpacing: 1.6,
          ),
        ),
        Text(
          timer,
          style: const TextStyle(
            color: teal,
            fontSize: 38,
            height: 1.1,
            fontWeight: FontWeight.w900,
            fontFeatures: <ui.FontFeature>[ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _MobileMatchPlayerCard extends StatelessWidget {
  const _MobileMatchPlayerCard({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.rating,
    required this.subtitle,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String rating;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 112,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xD9071928),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: .75)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: .13),
            border: Border.all(color: accent.withValues(alpha: .7)),
          ),
          child: Icon(icon, color: accent, size: 24),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          rating,
          maxLines: 1,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF91A3B4), fontSize: 10),
        ),
      ],
    ),
  );
}

class _SearchingRivalCard extends StatelessWidget {
  const _SearchingRivalCard({required this.animation, required this.wide});

  final Animation<double> animation;
  final bool wide;

  static const List<(IconData, Color)> _candidates = <(IconData, Color)>[
    (Icons.face_rounded, Color(0xFFF0B84B)),
    (Icons.face_2_rounded, Color(0xFF58DFC9)),
    (Icons.face_3_rounded, Color(0xFF76A9FF)),
    (Icons.face_4_rounded, Color(0xFFE98CC7)),
    (Icons.face_5_rounded, Color(0xFFA98BFF)),
    (Icons.face_6_rounded, Color(0xFFFF8E72)),
    (Icons.account_circle_rounded, Color(0xFF65D49A)),
    (Icons.person_rounded, Color(0xFFFFC857)),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double phase = animation.value;
        final int candidate =
            (phase * _candidates.length).floor() % _candidates.length;
        final (IconData avatar, Color accent) = _candidates[candidate];
        final Widget card = wide
            ? _WideSearchPlayerCard(
                accent: accent,
                icon: avatar,
                title: 'Searching…',
                rating: '????',
                detail: 'Best match',
                footer: 'Worldwide',
              )
            : _MobileMatchPlayerCard(
                key: const ValueKey<String>('mobile-rival-card'),
                accent: accent,
                icon: avatar,
                title: 'Searching…',
                rating: 'Best match',
                subtitle: 'Worldwide',
              );
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 620),
          reverseDuration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> transition) =>
              FadeTransition(
                opacity: transition,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.12, 0),
                    end: Offset.zero,
                  ).animate(transition),
                  child: child,
                ),
              ),
          child: KeyedSubtree(key: ValueKey<int>(candidate), child: card),
        );
      },
    );
  }
}

class _MobileSearchFact extends StatelessWidget {
  const _MobileSearchFact({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Icon(icon, color: const Color(0xFF58DFC9), size: 22),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF94A5B5), fontSize: 10),
      ),
    ],
  );
}

class _MobileFactDivider extends StatelessWidget {
  const _MobileFactDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: const Color(0xFF334A5B));
}

// ignore: unused_element
class _SearchSettingRow extends StatelessWidget {
  const _SearchSettingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF58DFC9)),
        const SizedBox(width: 14),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _MatchPlayerCard extends StatelessWidget {
  const _MatchPlayerCard({
    required this.accent,
    required this.icon,
    required this.eyebrow,
    required this.name,
    required this.rating,
    required this.detail,
    required this.active,
  });

  final Color accent;
  final IconData icon;
  final String eyebrow;
  final String name;
  final String rating;
  final String detail;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xD9071929),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: accent.withValues(alpha: active ? .75 : .4)),
    ),
    child: Column(
      children: <Widget>[
        Text(
          eyebrow,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: .11),
            border: Border.all(color: accent.withValues(alpha: .72)),
          ),
          child: Icon(icon, color: accent, size: 38),
        ),
        const SizedBox(height: 13),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          children: <Widget>[
            Icon(Icons.military_tech_rounded, color: accent, size: 17),
            Text(rating, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          style: const TextStyle(color: Color(0xFF95A8BA), fontSize: 12),
        ),
      ],
    ),
  );
}

class _SearchFact extends StatelessWidget {
  const _SearchFact({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 21, color: const Color(0xFF58DFC9)),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8FA3B6), fontSize: 11),
          ),
        ],
      ),
    ],
  );
}

class _CoinPoolBanner extends StatelessWidget {
  const _CoinPoolBanner({required this.entryCoins});

  final int entryCoins;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: .94, end: 1),
    duration: const Duration(milliseconds: 650),
    curve: Curves.easeOutBack,
    builder: (BuildContext context, double value, Widget? child) =>
        Transform.scale(scale: value, child: child),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF241D0D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF1B94C), width: 1.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x55F1B94C), blurRadius: 20),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFF1B94C),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              '$entryCoins + $entryCoins  =  ${entryCoins * 2} COIN POOL',
              style: const TextStyle(
                color: Color(0xFFFFE2A3),
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SearchDivider extends StatelessWidget {
  const _SearchDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: const Color(0xFF294255),
  );
}

class _CoinStakeSelector extends StatelessWidget {
  const _CoinStakeSelector({
    required this.balance,
    required this.entryCoins,
    required this.enabled,
    required this.onSelected,
  });

  final int? balance;
  final int entryCoins;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFF0B93F);
    const Color teal = Color(0xFF55DFC7);
    return Container(
      key: const ValueKey<String>('coin-stake-selector'),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xF20A2233), Color(0xF2051422)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF476076)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _StakeSummary(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'BALANCE',
                  value: balance == null
                      ? 'Checking…'
                      : formatCoinAmount(balance!),
                  color: gold,
                ),
              ),
              Container(width: 1, height: 38, color: const Color(0xFF294357)),
              Expanded(
                child: _StakeSummary(
                  icon: Icons.emoji_events_rounded,
                  label: 'WINNER GETS',
                  value: '${formatCoinAmount(entryCoins * 2)} COINS',
                  color: teal,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'SELECT MATCH ENTRY',
            style: TextStyle(
              color: Color(0xFFAFC1CF),
              fontSize: 10,
              letterSpacing: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const double gap = 7;
              final double tileWidth = (constraints.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <int>[100, 200, 500]
                    .map((int coins) {
                      final bool selected = entryCoins == coins;
                      final bool affordable =
                          balance == null || balance! >= coins;
                      return SizedBox(
                        width: tileWidth,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: enabled && affordable
                                ? () => onSelected(coins)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? const LinearGradient(
                                        colors: <Color>[
                                          Color(0xFFFFD568),
                                          Color(0xFFE5A72F),
                                        ],
                                      )
                                    : null,
                                color: selected
                                    ? null
                                    : const Color(0xFF0B2A3C),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFFE59B)
                                      : const Color(0xFF385C72),
                                ),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Icon(
                                    Icons.monetization_on_rounded,
                                    size: 17,
                                    color: selected
                                        ? const Color(0xFF07131D)
                                        : (affordable
                                              ? gold
                                              : const Color(0xFF647684)),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${formatCoinAmount(coins)} ENTRY',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF07131D)
                                          : (affordable
                                                ? Colors.white
                                                : const Color(0xFF718391)),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '${formatCoinAmount(coins * 2)} PRIZE',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF17303D)
                                          : (affordable
                                                ? teal
                                                : const Color(0xFF647684)),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StakeSummary extends StatelessWidget {
  const _StakeSummary({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: alignEnd
        ? MainAxisAlignment.end
        : MainAxisAlignment.start,
    children: <Widget>[
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 7),
      Flexible(
        child: Column(
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF91A6B6),
                fontSize: 9,
                letterSpacing: .8,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _OpponentFoundView extends StatefulWidget {
  const _OpponentFoundView({required this.match});

  final OnlineMatchDto match;

  @override
  State<_OpponentFoundView> createState() => _OpponentFoundViewState();
}

class _OpponentFoundViewState extends State<_OpponentFoundView>
    with SingleTickerProviderStateMixin {
  int _countdown = 3;
  Timer? _timer;
  late final AnimationController _versusEntrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..forward();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted || _countdown <= 1) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _versusEntrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OnlineMatchDto match = widget.match;
    final String you = match.yourColor == 'WHITE'
        ? (match.whitePlayerName ?? 'You')
        : (match.blackPlayerName ?? 'You');
    final String rival = match.yourColor == 'WHITE'
        ? (match.blackPlayerName ?? 'Online Rival')
        : (match.whitePlayerName ?? 'Online Rival');
    final String? yourPhotoUrl = match.yourColor == 'WHITE'
        ? match.whitePlayerPhotoUrl
        : match.blackPlayerPhotoUrl;
    final String? rivalPhotoUrl = match.yourColor == 'WHITE'
        ? match.blackPlayerPhotoUrl
        : match.whitePlayerPhotoUrl;
    const Color teal = Color(0xFF55E5D0);
    const Color gold = Color(0xFFF1B94C);
    final bool wide = MediaQuery.sizeOf(context).width >= 760;
    final String rating = match.ratingBefore?.toString() ?? 'Unrated';
    return Material(
      color: const Color(0xFF010A13),
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
                constraints: BoxConstraints(maxWidth: wide ? 1160 : 540),
                margin: EdgeInsets.all(wide ? 22 : 10),
                padding: EdgeInsets.fromLTRB(
                  wide ? 34 : 16,
                  wide ? 28 : 16,
                  wide ? 34 : 16,
                  wide ? 24 : 18,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFF061B2A), Color(0xFF010A13)],
                  ),
                  borderRadius: BorderRadius.circular(wide ? 32 : 24),
                  border: Border.all(color: gold.withValues(alpha: .7)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFE5B856).withValues(alpha: 0.24),
                      blurRadius: 46,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'RANKED RAPID • ${(match.whiteTimeMs ~/ 60000).clamp(1, 60)} MIN',
                        style: const TextStyle(
                          color: gold,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'RIVAL FOUND',
                        style: TextStyle(
                          color: Color(0xFFF4EFE5),
                          fontSize: wide ? 38 : 29,
                          fontFamily: 'serif',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const Text(
                        'Your match is ready',
                        style: TextStyle(
                          color: Color(0xFFB7C1CB),
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: wide ? 20 : 15),
                      if (match.rewardPoolCoins > 0) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: gold.withValues(alpha: .65),
                            ),
                          ),
                          child: Text(
                            '${match.entryCoins} + ${match.entryCoins}  •  ${match.rewardPoolCoins} COIN POOL',
                            style: const TextStyle(
                              color: gold,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        SizedBox(height: wide ? 18 : 13),
                      ],
                      AnimatedBuilder(
                        animation: _versusEntrance,
                        builder: (BuildContext context, Widget? child) {
                          final double collision = Curves.easeOutBack.transform(
                            CurvedAnimation(
                              parent: _versusEntrance,
                              curve: const Interval(0, .72),
                            ).value,
                          );
                          final double reveal = CurvedAnimation(
                            parent: _versusEntrance,
                            curve: const Interval(
                              .48,
                              1,
                              curve: Curves.elasticOut,
                            ),
                          ).value;
                          final double travel = wide ? 190 : 88;
                          return Row(
                            children: <Widget>[
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(-travel * (1 - collision), 0),
                                  child: Opacity(
                                    opacity: collision.clamp(0, 1),
                                    child: _VersusPlayerCard(
                                      name: you,
                                      color: teal,
                                      label: 'YOU • ${match.yourColor}',
                                      rating: rating,
                                      rival: false,
                                      photoUrl: yourPhotoUrl,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: wide ? 28 : 7,
                                ),
                                child: Transform.scale(
                                  scale: reveal,
                                  child: Container(
                                    width: wide ? 88 : 54,
                                    height: wide ? 88 : 54,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF061522),
                                      border: Border.all(
                                        color: gold,
                                        width: 1.4,
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: gold.withValues(
                                            alpha: .25 + reveal * .35,
                                          ),
                                          blurRadius: 28 + reveal * 24,
                                          spreadRadius: reveal * 3,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'VS',
                                      style: TextStyle(
                                        color: gold,
                                        fontFamily: 'serif',
                                        fontSize: wide ? 30 : 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(travel * (1 - collision), 0),
                                  child: Opacity(
                                    opacity: collision.clamp(0, 1),
                                    child: _VersusPlayerCard(
                                      name: rival,
                                      color: gold,
                                      label:
                                          'RIVAL • ${match.yourColor == 'WHITE' ? 'BLACK' : 'WHITE'}',
                                      rating: 'Ready',
                                      rival: true,
                                      photoUrl: rivalPhotoUrl,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: wide ? 18 : 15),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(seconds: 3),
                        builder:
                            (
                              BuildContext context,
                              double progress,
                              Widget? child,
                            ) => SizedBox.square(
                              dimension: wide ? 210 : 164,
                              child: CustomPaint(
                                painter: _CountdownRingPainter(
                                  progress: progress,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text(
                                      'MATCH STARTS IN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.2,
                                        color: Color(0xFFB4BEC8),
                                      ),
                                    ),
                                    Text(
                                      '$_countdown',
                                      style: TextStyle(
                                        color: teal,
                                        fontSize: wide ? 76 : 62,
                                        height: 1.05,
                                        fontWeight: FontWeight.w900,
                                        shadows: const <Shadow>[
                                          Shadow(color: teal, blurRadius: 22),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                      SizedBox(height: wide ? 16 : 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xD9071928),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF314A5C)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: _FoundFact(
                                icon: Icons.schedule_rounded,
                                label:
                                    'Rapid • ${(match.whiteTimeMs ~/ 60000).clamp(1, 60)} min',
                              ),
                            ),
                            const _MobileFactDivider(),
                            const Expanded(
                              child: _FoundFact(
                                icon: Icons.shield_outlined,
                                label: 'Rated Match',
                              ),
                            ),
                            const _MobileFactDivider(),
                            const Expanded(
                              child: _FoundFact(
                                icon: Icons.wifi_rounded,
                                label: 'Live server',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                      const Text(
                        'Preparing the board and synchronizing clocks...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB4BEC8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        minHeight: 4,
                        color: teal,
                        backgroundColor: Color(0xFF173344),
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

class _VersusPlayerCard extends StatelessWidget {
  const _VersusPlayerCard({
    required this.name,
    required this.color,
    required this.label,
    required this.rating,
    required this.rival,
    this.photoUrl,
  });

  final String name;
  final Color color;
  final String label;
  final String rating;
  final bool rival;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: MediaQuery.sizeOf(context).width >= 760 ? 16 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xC9071928),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .8)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: MediaQuery.sizeOf(context).width >= 760 ? 96 : 66,
            height: MediaQuery.sizeOf(context).width >= 760 ? 96 : 66,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: ClipOval(
              child: photoUrl == null
                  ? Icon(
                      Icons.person_rounded,
                      color: color,
                      size: MediaQuery.sizeOf(context).width >= 760 ? 58 : 40,
                    )
                  : Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person_rounded,
                        color: color,
                        size: MediaQuery.sizeOf(context).width >= 760 ? 58 : 40,
                      ),
                    ),
            ),
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
            rating,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
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
      ),
    );
  }
}

class _FoundFact extends StatelessWidget {
  const _FoundFact({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, color: const Color(0xFF55E5D0), size: 21),
      const SizedBox(height: 4),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFD9D5CC),
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 - 10;
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF193A45);
    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF55E5D0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: <Color>[
          Color(0xFF55E5D0),
          Color(0xFFF1B94C),
          Color(0xFF55E5D0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, track);
    final double sweep = math.pi * 2 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      glow,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
    canvas.drawCircle(
      center,
      radius - 15,
      track..color = const Color(0xFF27606A),
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
