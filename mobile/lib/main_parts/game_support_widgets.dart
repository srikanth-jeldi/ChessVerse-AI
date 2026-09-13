part of '../main.dart';

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
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final bool whiteMove = index.isEven;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: whiteMove
                                    ? const Color(0xFFE9D5B7)
                                    : const Color(0xFF242128),
                                foregroundColor: whiteMove
                                    ? Colors.black
                                    : Colors.white,
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
                            labelText: registerMode
                                ? 'Email'
                                : 'User ID or email',
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
                            labelText: registerMode
                                ? 'Create password'
                                : 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            helperText: registerMode
                                ? 'At least 8 characters'
                                : null,
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
  const _TurnBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.72),
        child: Semantics(
          liveRegion: true,
          label: label,
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
            child: Text(
              label,
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

class _DrawResultBadge extends StatelessWidget {
  const _DrawResultBadge({required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: .72, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutBack,
        builder: (BuildContext context, double scale, Widget? child) =>
            Transform.scale(scale: scale, child: child),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xF2071827),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF65C9F4), width: 1.5),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x663CA6FF), blurRadius: 28),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'DRAW',
                  style: TextStyle(
                    color: Color(0xFF65C9F4),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
              builder: (BuildContext context, double scale, Widget? child) =>
                  Transform.scale(scale: scale, child: child),
              child: Align(
                alignment: Alignment.center,
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
                      horizontal: 28,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFF07131E),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          widget.title.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF07131E),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
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
          ?child,
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
    final double bandCenter = winnerAtTop
        ? size.height * .24
        : size.height * .76;
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
        paint.color = _colors[(burst + ray) % _colors.length].withValues(
          alpha: opacity,
        );
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
    this.entryCoins,
    this.rewardPoolCoins,
    this.coinsEarned,
    required this.onNewGame,
    this.newGameLabel,
    this.onRematch,
    required this.onDismiss,
    required this.onReview,
    required this.onShare,
    super.key,
  });

  final String title;
  final String detail;
  final String scoreLabel;
  final int? accuracy;
  final String? turningPoint;
  final int? entryCoins;
  final int? rewardPoolCoins;
  final int? coinsEarned;
  final VoidCallback onNewGame;
  final String? newGameLabel;
  final VoidCallback? onRematch;
  final VoidCallback onDismiss;
  final VoidCallback onReview;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    final bool draw = title.toLowerCase().contains('draw');
    final bool missed = title.toLowerCase().contains('challenge missed');
    final bool dailyComplete = title.toLowerCase().contains(
      'challenge complete',
    );
    final bool showCoinOutcome =
        (rewardPoolCoins ?? 0) > 0 && (draw || (coinsEarned ?? 0) > 0);
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
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: missed
                                    ? const Color(0xFF68D2BE)
                                    : const Color(0xFFD6A84F),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        SizedBox(height: shortLandscape ? 3 : 8),
                        Text(detail, textAlign: TextAlign.center),
                        if (showCoinOutcome) ...<Widget>[
                          SizedBox(height: shortLandscape ? 7 : 14),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: .75, end: 1),
                            duration: const Duration(milliseconds: 850),
                            curve: Curves.elasticOut,
                            builder:
                                (
                                  BuildContext context,
                                  double value,
                                  Widget? child,
                                ) =>
                                    Transform.scale(scale: value, child: child),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: draw
                                    ? const Color(0xFF13262A)
                                    : (coinsEarned ?? 0) > 0
                                    ? const Color(0xFF2A210D)
                                    : const Color(0xFF25171A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: draw
                                      ? const Color(0xFF63D2B8)
                                      : (coinsEarned ?? 0) > 0
                                      ? const Color(0xFFD6A84F)
                                      : const Color(0xFFB65B67),
                                ),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Icon(
                                    Icons.monetization_on_rounded,
                                    color: draw
                                        ? const Color(0xFF63D2B8)
                                        : const Color(0xFFD6A84F),
                                    size: 34,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    draw
                                        ? '${entryCoins ?? 0} COINS REFUNDED'
                                        : '+${coinsEarned ?? 0} COINS WON',
                                    style: const TextStyle(
                                      color: Color(0xFFFFE2A3),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    draw
                                        ? 'Draw refund completed'
                                        : '${entryCoins ?? 0} + ${entryCoins ?? 0} = ${rewardPoolCoins ?? 0} coin pool',
                                    style: const TextStyle(
                                      color: Color(0xFFBFC8CF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                                      onPressed: dailyComplete
                                          ? onDismiss
                                          : onNewGame,
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
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey<String>('share-game-result'),
                            onPressed: onShare,
                            icon: const Icon(Icons.ios_share_rounded),
                            label: const Text('COPY SHAREABLE RESULT'),
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
      ),
    );
    // The board already presents the cinematic king-fall/title/fireworks
    // sequence before this result sheet is revealed. Keep the sheet calm and
    // fully readable instead of starting a second celebration over its CTAs.
    return resultCard;
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
          color: piece.white
              ? const Color(0xFF8A909B)
              : const Color(0xFFFFFFFF),
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
            builder: (BuildContext context, ChessPieceAppearance appearance, _) {
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
    final String initial = name.trim().isEmpty
        ? 'P'
        : name.trim().substring(0, 1).toUpperCase();
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
