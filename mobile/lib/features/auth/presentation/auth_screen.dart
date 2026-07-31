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
    super.key,
  });

  final ValueChanged<ChessVerseAuthResult> onAuthenticated;

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
                          _verificationMode
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
                        if (!_verificationMode)
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
                        if (_verificationMode) ...<Widget>[
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
                        if (!_verificationMode) ...<Widget>[
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
                        if (_loginMode && !_verificationMode)
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
                        FilledButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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
                        const SizedBox(height: 10),
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
                                      label: const Text('Google'),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => _showSocialPlaceholder('Apple'),
                                icon: const Icon(Icons.apple_rounded),
                                label: const Text('Apple'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
      final Map<String, dynamic> data = await _authApi.post(
        'google',
        <String, String>{'idToken': idToken},
      );
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
      await _completeAuthentication(data, guestOverride: true);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Guest identity could not be created. Try again.');
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

class _AuthField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
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
