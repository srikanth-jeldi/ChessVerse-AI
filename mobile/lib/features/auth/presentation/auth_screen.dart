import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_api.dart';

class ChessVerseAuthResult {
  const ChessVerseAuthResult({
    required this.playerName,
    required this.isGuest,
    this.token,
  });

  final String playerName;
  final bool isGuest;
  final String? token;
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

  bool _loginMode = true;
  bool _loading = false;
  String? _message;
  String? _error;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                                'CHESSVERSE',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _loginMode ? 'Welcome back' : 'Create ChessVerse ID',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 18),
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
                        if (_loginMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _forgotPassword,
                              child: const Text('Forgot password?'),
                            ),
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(_loginMode ? 'Login' : 'Send Code'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => widget.onAuthenticated(
                                    const ChessVerseAuthResult(
                                      playerName: 'Guest Player',
                                      isGuest: true,
                                    ),
                                  ),
                          icon: const Icon(Icons.person_pin_circle_outlined),
                          label: const Text('Continue as Guest Player'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => _showSocialPlaceholder('Google'),
                                icon: const Icon(Icons.g_mobiledata_rounded),
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
                          'Use a verified account to save games, ratings and coach history. Guest Player is local-only for quick testing.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      if (_loginMode) {
        final Map<String, dynamic> data = await _authApi.post(
          'login',
          <String, String>{
            'identity': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );
        final String token = data['token'] as String? ?? '';
        final String name = data['displayName'] as String? ??
            data['userId'] as String? ??
            'ChessVerse Player';
        widget.onAuthenticated(
          ChessVerseAuthResult(playerName: name, isGuest: false, token: token),
        );
      } else {
        final Map<String, dynamic> data = await _authApi.post(
          'register',
          <String, String>{
            'userId': _userIdController.text.trim(),
            'displayName': _displayNameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );
        setState(() {
          _message = data['message'] as String? ??
              'Verification code sent. Check your email.';
          _loginMode = true;
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

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email first, then tap Forgot password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await _authApi.post(
        'forgot-password',
        <String, String>{'email': _emailController.text.trim()},
      );
      setState(() => _message = 'If that account exists, a reset code has been sent.');
    } on AuthApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
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
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
