import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_api.dart';
import '../data/auth_session_store.dart';
import 'web_google_button.dart';

class ChessVerseAuthResult {
  const ChessVerseAuthResult({
    required this.playerName,
    required this.isGuest,
    this.token,
    this.username,
    this.email,
    this.photoUrl,
  });

  final String playerName;
  final bool isGuest;
  final String? token;
  final String? username;
  final String? email;
  final String? photoUrl;
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.onAuthenticated,
    this.guestUpgradeToken,
    super.key,
  });

  final ValueChanged<ChessVerseAuthResult> onAuthenticated;
  final String? guestUpgradeToken;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const AuthApi _authApi = AuthApi();
  static const AuthSessionStore _sessionStore = AuthSessionStore();

  bool _loginMode = true;
  bool _verificationMode = false;
  bool _loading = false;
  bool _rememberMe = true;
  bool _googleInitialized = false;
  String? _message;
  String? _error;
  DateTime? _verificationExpiresAt;
  DateTime? _resendAvailableAt;
  Timer? _verificationTimer;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  StreamSubscription<GoogleSignInAuthenticationEvent>?
      _googleAuthenticationSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreRememberMePreference());
    if (kIsWeb) {
      unawaited(_initializeGoogleForWeb());
    }
  }

  Future<void> _restoreRememberMePreference() async {
    final bool rememberMe = await _sessionStore.rememberMeEnabled();
    if (mounted) setState(() => _rememberMe = rememberMe);
  }

  Future<void> _setRememberMe(bool value) async {
    setState(() => _rememberMe = value);
    await _sessionStore.setRememberMe(value);
    if (!value) await _sessionStore.clearSession();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    unawaited(_googleAuthenticationSubscription?.cancel());
    _userIdController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size viewport = MediaQuery.sizeOf(context);
    final bool compactLandscape = viewport.width >= 600 &&
        viewport.width > viewport.height * 1.35 &&
        viewport.height < 760;
    return Scaffold(
      backgroundColor: const Color(0xFF020914),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF06172A), Color(0xFF020914)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: compactLandscape
              ? _premiumCompactLandscapeBody(context)
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    child: _premiumResponsiveBody(context),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _premiumCompactLandscapeBody(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return KeyedSubtree(
          key: const ValueKey<String>('auth-landscape-split'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  'assets/backgrounds/home-online-hero-v1.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        Color(0xFF020B18),
                        Color(0xF2061426),
                        Color(0xB3061426),
                        Color(0x00061426),
                      ],
                      stops: <double>[0, .44, .59, .78],
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: constraints.maxWidth * .55,
                      height: constraints.maxHeight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 900,
                            height: 790,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xEE061426),
                                borderRadius: BorderRadius.circular(34),
                                border: Border.all(
                                  color: const Color(0xFF2B405B),
                                  width: 1.5,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .48),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  54,
                                  28,
                                  54,
                                  30,
                                ),
                                child: _premiumFormContent(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _premiumResponsiveBody(BuildContext context) {
    final Size viewport = MediaQuery.sizeOf(context);
    final bool wide = viewport.width >= 900;
    final bool compact = viewport.width < 430;
    final Widget card = SizedBox(
      width: viewport.width < 546 ? viewport.width - 36 : 510,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: _premiumPanelBackground()),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 22 : 44,
                compact ? 20 : 34,
                compact ? 22 : 44,
                compact ? 22 : 36,
              ),
              child: _premiumFormContent(context),
            ),
          ],
        ),
      ),
    );
    if (!wide) return card;
    return SizedBox(
      width: (viewport.width - 36).clamp(510.0, 1600.0).toDouble(),
      height: (viewport.height - 40).clamp(620.0, 900.0).toDouble(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              'assets/backgrounds/home-online-hero-v1.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Color(0xFF041225),
                    Color(0xF2051428),
                    Color(0x40020A16),
                    Colors.transparent,
                  ],
                  stops: <double>[0, .42, .62, 1],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 720,
                margin: const EdgeInsets.all(18),
                padding: const EdgeInsets.fromLTRB(64, 34, 64, 36),
                decoration: BoxDecoration(
                  color: const Color(0xE8061426),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF263B55)),
                ),
                child: SingleChildScrollView(
                  child: _premiumFormContent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumFormContent(BuildContext context) {
    final bool dense = MediaQuery.sizeOf(context).height < 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _premiumBrandHeader(context, dense: dense),
        SizedBox(height: dense ? 12 : 24),
        Text(
          widget.guestUpgradeToken != null
              ? 'Secure your progress'
              : _verificationMode
                  ? 'Verify your email'
                  : _loginMode
                      ? 'Welcome back'
                      : 'Create your account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: dense ? 26 : 31,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
        ),
        SizedBox(height: dense ? 6 : 10),
        Text(
          _loginMode
              ? 'Login to continue your games,\nratings and progress'
              : 'Create your ChessVerse AI identity\nand keep your progress secure',
          style: TextStyle(
            color: Color(0xFF9EACC2),
            fontSize: dense ? 13 : 16,
            height: dense ? 1.3 : 1.5,
          ),
        ),
        SizedBox(height: dense ? 12 : 22),
        if (!_verificationMode && widget.guestUpgradeToken == null)
          _premiumModeSelector(),
        SizedBox(height: dense ? 10 : 16),
        ..._premiumFormFields(context),
        if (_message != null) ...<Widget>[
          SizedBox(height: dense ? 8 : 14),
          _Notice(message: _message!, isError: false),
        ],
        if (_error != null) ...<Widget>[
          SizedBox(height: dense ? 8 : 14),
          _Notice(message: _error!, isError: true),
        ],
        SizedBox(height: dense ? 10 : 18),
        if (widget.guestUpgradeToken == null) _premiumPrimaryButton(),
        if (widget.guestUpgradeToken == null) ...<Widget>[
          SizedBox(height: dense ? 9 : 17),
          const _DividerLabel('or'),
          SizedBox(height: dense ? 9 : 16),
          _premiumGuestButton(),
          SizedBox(height: dense ? 9 : 17),
          const _DividerLabel('or continue with'),
          SizedBox(height: dense ? 8 : 14),
        ],
        _premiumSocialButtons(),
        if (widget.guestUpgradeToken == null) ...<Widget>[
          SizedBox(height: dense ? 8 : 18),
          if (!dense) const _SecurityNote(),
        ],
      ],
    );
  }

  Widget _premiumPanelBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF061426),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF263B55), width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.32,
              child: Image.asset(
                'assets/backgrounds/home-online-hero-v1.png',
                fit: BoxFit.cover,
                alignment: const Alignment(.72, .18),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Color(0xFF061426),
                  Color(0xF0061426),
                  Color(0x8A061426),
                ],
                stops: <double>[0, 0.58, 1],
              ),
            ),
          ),
          Positioned(
            top: 72,
            right: -34,
            height: 430,
            width: 210,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.48,
                child: Image.asset(
                  'assets/pieces/staunton_black_king.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.topRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 125,
            child: CustomPaint(painter: _CheckerPainter()),
          ),
        ],
      ),
    );
  }

  Widget _premiumBrandHeader(BuildContext context, {required bool dense}) {
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/branding/app_icon.png',
            width: dense ? 58 : 82,
            height: dense ? 58 : 82,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: dense ? 6 : 12),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              const TextSpan(text: 'ChessVerse '),
              TextSpan(
                text: 'AI',
                style: TextStyle(color: AppColors.accentGold),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontSize: dense ? 21 : 26,
                fontWeight: FontWeight.w900,
              ),
        ),
        SizedBox(height: dense ? 7 : 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(width: 54, height: 1, color: const Color(0xFF29405B)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.diamond_rounded,
                size: 11,
                color: AppColors.accentGold,
              ),
            ),
            Container(width: 54, height: 1, color: const Color(0xFF29405B)),
          ],
        ),
      ],
    );
  }

  Widget _premiumModeSelector() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xAA071528),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF344B65)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ModeButton(
              selected: _loginMode,
              icon: Icons.login_rounded,
              label: 'Login',
              onTap: _loading ? null : () => _setPremiumLoginMode(true),
            ),
          ),
          Expanded(
            child: _ModeButton(
              selected: !_loginMode,
              icon: Icons.person_add_alt_rounded,
              label: 'Register',
              onTap: _loading ? null : () => _setPremiumLoginMode(false),
            ),
          ),
        ],
      ),
    );
  }

  void _setPremiumLoginMode(bool value) {
    setState(() {
      _loginMode = value;
      _error = null;
      _message = null;
    });
  }

  List<Widget> _premiumFormFields(BuildContext context) {
    if (widget.guestUpgradeToken != null) {
      return const <Widget>[
        Text(
          'Link Google to keep this guest profile, rating and match history across devices. Your existing progress will not be deleted.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      ];
    }
    if (_verificationMode) {
      return <Widget>[
        Text(
          'Enter the 6-digit code sent to ${_emailController.text.trim()}.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _AuthField(
          controller: _verificationCodeController,
          label: 'Verification code',
          icon: Icons.verified_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onSubmitted: (_) => _submit(),
        ),
        Row(
          children: <Widget>[
            Expanded(child: Text(_verificationStatusText)),
            TextButton(
              onPressed: _loading || !_canResendVerification
                  ? null
                  : _resendVerificationCode,
              child: const Text('Resend code'),
            ),
          ],
        ),
      ];
    }
    return <Widget>[
      if (!_loginMode) ...<Widget>[
        _AuthField(
          controller: _userIdController,
          label: 'User ID',
          icon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 12),
        _AuthField(
          controller: _displayNameController,
          label: 'Player name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
      ],
      _AuthField(
        controller: _emailController,
        label: _loginMode ? 'Email or Username' : 'Email',
        icon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      _AuthField(
        controller: _passwordController,
        label: _loginMode ? 'Password' : 'Create password',
        icon: Icons.lock_outline_rounded,
        obscureText: true,
        onSubmitted: (_) => _submit(),
      ),
      if (_loginMode) ...<Widget>[
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Checkbox(
              value: _rememberMe,
              activeColor: AppColors.accentGold,
              checkColor: const Color(0xFF08111D),
              visualDensity: VisualDensity.compact,
              onChanged: _loading
                  ? null
                  : (bool? value) => unawaited(_setRememberMe(value ?? true)),
            ),
            const Expanded(
              child: Text(
                'Remember me',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _loading ? null : _forgotPassword,
              child: const Text(
                'Forgot password?',
                maxLines: 1,
                style: TextStyle(color: AppColors.accentGold, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    ];
  }

  Widget _premiumPrimaryButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(13),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.35),
            blurRadius: 18,
          ),
        ],
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF101010),
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        onPressed: _loading ? null : _submit,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login_rounded),
        label: Text(
          _verificationMode
              ? 'Verify & Continue'
              : _loginMode
                  ? 'Login'
                  : 'Send Code',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _premiumGuestButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF5EEAD4),
        side: const BorderSide(color: Color(0xFF5EEAD4)),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _loading ? null : _continueAsGuest,
      child: const Column(
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.person_outline_rounded),
                SizedBox(width: 10),
                Text(
                  'Continue as Guest',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Start playing instantly. Upgrade anytime.',
            style: TextStyle(color: Color(0xFF9EACC2), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _premiumSocialButtons() {
    final bool filePreview = kIsWeb &&
        (Uri.base.scheme == 'file' ||
            Uri.base.host == '127.0.0.1' ||
            Uri.base.host == 'localhost');
    final bool compactWeb = kIsWeb && MediaQuery.sizeOf(context).width < 600;
    if (compactWeb && !filePreview && widget.guestUpgradeToken == null) {
      return Column(
        children: <Widget>[
          SizedBox(
            height: 42,
            child: Center(child: buildWebGoogleSignInButton()),
          ),
          const SizedBox(height: 10),
          _SocialButton(
            label: 'Facebook',
            onPressed:
                _loading ? null : () => _showSocialPlaceholder('Facebook'),
            child: const Icon(
              Icons.facebook_rounded,
              color: Color(0xFF4285F4),
            ),
          ),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: kIsWeb && !filePreview
              ? Center(child: buildWebGoogleSignInButton())
              : _SocialButton(
                  label: widget.guestUpgradeToken == null
                      ? 'Google'
                      : 'SECURE WITH GOOGLE',
                  onPressed: _loading ? null : _signInWithGoogle,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
        ),
        if (widget.guestUpgradeToken == null) ...<Widget>[
          const SizedBox(width: 10),
          Expanded(
            child: _SocialButton(
              label: 'Facebook',
              onPressed:
                  _loading ? null : () => _showSocialPlaceholder('Facebook'),
              child: const Icon(
                Icons.facebook_rounded,
                color: Color(0xFF4285F4),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ignore: unused_element
  Widget _buildLegacy(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.border),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.36),
                        blurRadius: 38,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/branding/app_icon.png',
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'CHESSVERSEAI',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          widget.guestUpgradeToken != null
                              ? 'Secure your progress'
                              : _verificationMode
                                  ? 'Verify your email'
                                  : _loginMode
                                      ? 'Welcome back'
                                      : 'Create ChessVerseAI ID',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 18),
                        if (!_verificationMode &&
                            widget.guestUpgradeToken == null)
                          SegmentedButton<bool>(
                            segments: const <ButtonSegment<bool>>[
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Register'),
                                icon: Icon(Icons.person_add_alt_rounded),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('Login'),
                                icon: Icon(Icons.check_rounded),
                              ),
                            ],
                            selected: <bool>{_loginMode},
                            onSelectionChanged: _loading
                                ? null
                                : (Set<bool> value) {
                                    setState(() {
                                      _loginMode = value.first;
                                      _error = null;
                                      _message = null;
                                    });
                                  },
                          ),
                        const SizedBox(height: 18),
                        if (widget.guestUpgradeToken != null) ...<Widget>[
                          const Text(
                            'Link Google to keep this guest profile, rating and match history across devices. Your existing progress will not be deleted.',
                            style: TextStyle(
                                color: AppColors.textSecondary, height: 1.45),
                          ),
                        ] else if (_verificationMode) ...<Widget>[
                          Text(
                            'Enter the 6-digit code sent to ${_emailController.text.trim()}.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          _AuthField(
                            controller: _verificationCodeController,
                            label: 'Verification code',
                            icon: Icons.verified_outlined,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  _verificationStatusText,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              TextButton(
                                onPressed: _loading || !_canResendVerification
                                    ? null
                                    : _resendVerificationCode,
                                child: const Text('Resend code'),
                              ),
                            ],
                          ),
                        ] else if (!_loginMode) ...<Widget>[
                          _AuthField(
                            controller: _userIdController,
                            label: 'User ID',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 12),
                          _AuthField(
                            controller: _displayNameController,
                            label: 'Player name',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (!_verificationMode &&
                            widget.guestUpgradeToken == null) ...<Widget>[
                          _AuthField(
                            controller: _emailController,
                            label: _loginMode ? 'User ID or email' : 'Email',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _AuthField(
                            controller: _passwordController,
                            label: _loginMode ? 'Password' : 'Create password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            onSubmitted: (_) => _submit(),
                          ),
                        ],
                        if (_loginMode &&
                            !_verificationMode &&
                            widget.guestUpgradeToken == null)
                          Row(
                            children: <Widget>[
                              Checkbox(
                                value: _rememberMe,
                                onChanged: _loading
                                    ? null
                                    : (bool? value) => unawaited(
                                          _setRememberMe(value ?? true),
                                        ),
                              ),
                              const Expanded(child: Text('Remember me')),
                              TextButton(
                                onPressed: _loading ? null : _forgotPassword,
                                child: const Text('Forgot password?'),
                              ),
                            ],
                          ),
                        if (_message != null) ...<Widget>[
                          const SizedBox(height: 12),
                          _Notice(message: _message!, isError: false),
                        ],
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 12),
                          _Notice(message: _error!, isError: true),
                        ],
                        const SizedBox(height: 18),
                        if (widget.guestUpgradeToken == null)
                          FilledButton.icon(
                            onPressed: _loading ? null : _submit,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(
                              _verificationMode
                                  ? 'Verify & Continue'
                                  : _loginMode
                                      ? 'Login'
                                      : 'Send Code',
                            ),
                          ),
                        if (widget.guestUpgradeToken == null)
                          const SizedBox(height: 10),
                        if (widget.guestUpgradeToken == null)
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _continueAsGuest,
                            icon: const Icon(Icons.person_pin_circle_outlined),
                            label: const Text('Continue as Guest Player'),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: kIsWeb
                                  ? Center(
                                      child: buildWebGoogleSignInButton(),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed:
                                          _loading ? null : _signInWithGoogle,
                                      icon: const Icon(
                                        Icons.g_mobiledata_rounded,
                                      ),
                                      label: Text(
                                          widget.guestUpgradeToken == null
                                              ? 'Google'
                                              : 'SECURE WITH GOOGLE'),
                                    ),
                            ),
                          ],
                        ),
                        if (widget.guestUpgradeToken == null)
                          const SizedBox(height: 10),
                        if (widget.guestUpgradeToken == null)
                          OutlinedButton.icon(
                            onPressed: _loading
                                ? null
                                : () => _showSocialPlaceholder('Facebook'),
                            icon: const Icon(Icons.facebook_rounded),
                            label: const Text('Facebook Login'),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Guest players receive a secure numbered identity for online games, ratings and history. Add Google or email later for account recovery.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSocialPlaceholder(String provider) {
    setState(() {
      _message = AppConfig.usesDummySocialConfig
          ? '$provider login UI is ready with dummy placeholders. Replace IDs/tokens and enable backend OAuth callbacks before release.'
          : '$provider credentials are configured. Enable the live backend OAuth callback before release.';
      _error = null;
    });
  }

  Future<void> _initializeGoogleForWeb() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(clientId: AppConfig.googleWebClientId);
      _googleInitialized = true;
      _googleAuthenticationSubscription =
          googleSignIn.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            unawaited(_authenticateGoogleAccount(event.user));
          }
        },
        onError: (Object _) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = 'Google sign-in failed. Please try again.';
              _message = null;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Google sign-in could not start. Please refresh and retry.';
          _message = null;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await googleSignIn.initialize(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? AppConfig.googleIosClientId
              : null,
          serverClientId: AppConfig.googleWebClientId,
        );
        _googleInitialized = true;
      }
      final GoogleSignInAccount account = await googleSignIn.authenticate();
      await _authenticateGoogleAccount(account, manageLoading: false);
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled && mounted) {
        setState(() => _error = 'Google sign-in failed. Please try again.');
      }
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Google sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _authenticateGoogleAccount(
    GoogleSignInAccount account, {
    bool manageLoading = true,
  }) async {
    if (manageLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _message = null;
      });
    }
    try {
      final String? idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthApiException(
          'Google did not return a secure ID token. Please try again.',
        );
      }
      final String? upgradeToken = widget.guestUpgradeToken;
      final Map<String, dynamic> data = upgradeToken == null
          ? await _authApi.post('google', <String, String>{'idToken': idToken})
          : await _authApi.upgradeGuestWithGoogle(upgradeToken, idToken);
      await _completeAuthentication(data, photoUrl: account.photoUrl);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Google sign-in failed. Please try again.');
      }
    } finally {
      if (manageLoading && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeAuthentication(
    Map<String, dynamic> data, {
    String? photoUrl,
    bool? guestOverride,
  }) async {
    final String token = data['token'] as String? ?? '';
    final DateTime? expiresAt =
        DateTime.tryParse(data['expiresAt'] as String? ?? '');
    if (token.isEmpty || expiresAt == null) {
      throw const AuthApiException('The server returned an invalid session.');
    }

    Map<String, dynamic> player = _stringKeyedMap(data['player']);
    try {
      // Treat /me as the source of truth. Native Google Sign-In responses can
      // arrive before all player fields have been materialised in the client.
      final Map<String, dynamic> currentPlayer =
          await _authApi.currentPlayer(token);
      if (currentPlayer.isNotEmpty) {
        player = currentPlayer;
      }
    } on AuthApiException {
      // The authentication response is still a valid fallback when /me is
      // temporarily unavailable.
    }

    final String? username = _nonBlankString(player['username']);
    final String? email = _nonBlankString(player['email']);
    final bool isGuest = guestOverride ?? player['guest'] == true;
    final String name = _nonBlankString(player['displayName']) ??
        username ??
        email?.split('@').first ??
        'ChessVerseAI Player';
    if (_rememberMe || isGuest) {
      await _sessionStore.write(
        StoredAuthSession(
          token: token,
          expiresAt: expiresAt,
          displayName: name,
          username: username,
          email: email,
          photoUrl: photoUrl,
          isGuest: isGuest,
        ),
      );
    } else {
      await _sessionStore.setRememberMe(false);
      await _sessionStore.clearSession();
    }
    if (!mounted) return;
    widget.onAuthenticated(
      ChessVerseAuthResult(
        playerName: name,
        isGuest: isGuest,
        token: token,
        username: username,
        email: email,
        photoUrl: photoUrl,
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final String installationId = await _sessionStore.installationId();
      final Map<String, dynamic> data = await _authApi.post(
        'guest',
        <String, String>{'installationId': installationId},
      );
      await _completeAuthentication(data);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Guest identity could not be created. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _stringKeyedMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map(
      (Object? key, Object? entry) =>
          MapEntry<String, dynamic>(key.toString(), entry),
    );
  }

  String? _nonBlankString(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _submit() async {
    if (!_validateCurrentForm()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      if (_verificationMode) {
        final Map<String, dynamic> data = await _authApi.post(
          'verify-email',
          <String, String>{
            'email': _emailController.text.trim(),
            'code': _verificationCodeController.text.trim(),
          },
        );
        await _completeAuthentication(data);
      } else if (_loginMode) {
        final Map<String, dynamic> data = await _authApi.post(
          'login',
          <String, String>{
            'identity': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );
        await _completeAuthentication(data);
      } else {
        final Map<String, dynamic> data = await _authApi.post(
          'register',
          <String, String>{
            'username': _userIdController.text.trim(),
            'displayName': _displayNameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );
        setState(() {
          _message = data['message'] as String? ??
              'Verification code sent. Check your email.';
          _verificationMode = true;
          _applyVerificationTiming(data);
        });
      }
    } on AuthApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _validateCurrentForm() {
    if (_verificationMode) {
      if (!RegExp(r'^\d{6}$')
          .hasMatch(_verificationCodeController.text.trim())) {
        setState(() => _error = 'Enter the complete 6-digit code.');
        return false;
      }
      return true;
    }
    if (_loginMode) {
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty) {
        setState(() => _error = 'Enter your user ID/email and password.');
        return false;
      }
      return true;
    }

    final String username = _userIdController.text.trim();
    final String displayName = _displayNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (!RegExp(r'^[A-Za-z0-9_.-]{3,40}$').hasMatch(username)) {
      setState(() => _error =
          'User ID must be 3–40 characters using letters, numbers, dot, dash or underscore.');
      return false;
    }
    if (displayName.length < 2) {
      setState(
          () => _error = 'Player name must contain at least 2 characters.');
      return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return false;
    }
    if (password.length < 8 || password.length > 72) {
      setState(() => _error = 'Password must contain 8–72 characters.');
      return false;
    }
    return true;
  }

  void _applyVerificationTiming(Map<String, dynamic> data) {
    _verificationExpiresAt =
        DateTime.tryParse(data['expiresAt'] as String? ?? '')?.toLocal();
    _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  bool get _canResendVerification {
    final DateTime? availableAt = _resendAvailableAt;
    return availableAt == null || !DateTime.now().isBefore(availableAt);
  }

  String get _verificationStatusText {
    final DateTime now = DateTime.now();
    final DateTime? resendAt = _resendAvailableAt;
    if (resendAt != null && now.isBefore(resendAt)) {
      return 'Resend available in ${resendAt.difference(now).inSeconds + 1}s';
    }
    final DateTime? expiresAt = _verificationExpiresAt;
    if (expiresAt == null) return 'Code expires in 10 minutes.';
    final Duration remaining = expiresAt.difference(now);
    if (remaining.isNegative) return 'Code expired. Request a new code.';
    final int minutes = remaining.inMinutes;
    final int seconds = remaining.inSeconds.remainder(60);
    return 'Code expires in $minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendVerificationCode() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final Map<String, dynamic> data = await _authApi.post(
        'resend-verification',
        <String, String>{'email': _emailController.text.trim()},
      );
      if (!mounted) return;
      setState(() {
        _verificationCodeController.clear();
        _message = data['message'] as String? ?? 'A new code was sent.';
        _applyVerificationTiming(data);
      });
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _error =
            'Enter your registered email first, then tap Forgot password.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await _authApi.post(
        'password/forgot',
        <String, String>{'email': email},
      );
      if (!mounted) return;
      setState(
        () => _message = 'If that account exists, a reset code has been sent.',
      );
      await _showPasswordResetDialog(email);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showPasswordResetDialog(String email) async {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    String? dialogError;
    bool submitting = false;

    final bool? passwordUpdated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) =>
            AlertDialog(
          title: const Text('Reset password'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Enter the 6-digit reset code sent to $email.'),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Reset code',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    helperText: 'Use at least 8 characters.',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                ),
                if (dialogError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    dialogError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final String code = codeController.text.trim();
                      final String newPassword = newPasswordController.text;
                      if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                        setDialogState(
                          () =>
                              dialogError = 'Enter the complete 6-digit code.',
                        );
                        return;
                      }
                      if (newPassword.length < 8) {
                        setDialogState(
                          () => dialogError =
                              'New password must contain at least 8 characters.',
                        );
                        return;
                      }
                      setDialogState(() {
                        submitting = true;
                        dialogError = null;
                      });
                      try {
                        await _authApi.post(
                          'password/reset',
                          <String, String>{
                            'email': email,
                            'code': code,
                            'newPassword': newPassword,
                          },
                        );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(true);
                        }
                      } on AuthApiException catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            submitting = false;
                            dialogError = error.message;
                          });
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update password'),
            ),
          ],
        ),
      ),
    );

    codeController.dispose();
    newPasswordController.dispose();
    if (passwordUpdated == true && mounted) {
      _passwordController.clear();
      setState(() {
        _message = 'Password updated. Sign in with your new password.';
        _error = null;
      });
    }
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0A393E).withValues(alpha: 0.82)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: selected ? Border.all(color: const Color(0xFF5EEAD4)) : null,
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF5EEAD4).withValues(alpha: 0.2),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon,
                color: selected ? const Color(0xFF5EEAD4) : Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: selected ? const Color(0xFF5EEAD4) : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: Color(0xFF34445C))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label, style: const TextStyle(color: Color(0xFF9EACC2))),
        ),
        const Expanded(child: Divider(color: Color(0xFF34445C))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.child,
    required this.onPressed,
  });

  final String label;
  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 430;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF34445C)),
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: compact ? 4 : 8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          child,
          SizedBox(width: compact ? 4 : 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11.5 : 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xA80A1A30),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF132A44)),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.shield_outlined, color: Color(0xFF5EEAD4), size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Guest players receive a secure temporary identity.\nLink Google or email later for account recovery.',
              style: TextStyle(color: Color(0xFFB1BED1), height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const int columns = 8;
    const int rows = 2;
    final double cellWidth = size.width / columns;
    final double cellHeight = size.height / rows;
    for (int row = 0; row < rows; row++) {
      for (int column = 0; column < columns; column++) {
        final bool dark = (row + column).isEven;
        canvas.drawRect(
          Rect.fromLTWH(
            column * cellWidth,
            row * cellHeight,
            cellWidth,
            cellHeight,
          ),
          Paint()
            ..color = dark ? const Color(0x19182D45) : const Color(0x10091728),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.onSubmitted,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscured,
      onSubmitted: widget.onSubmitted,
      maxLength: widget.maxLength,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.label,
        hintStyle: const TextStyle(color: Color(0xFF8493AA)),
        prefixIcon: Icon(widget.icon, color: const Color(0xFFB7C3D4)),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFFB7C3D4),
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xA8071528),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF34445C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF5EEAD4)),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final Color color = isError ? AppColors.danger : AppColors.success;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
