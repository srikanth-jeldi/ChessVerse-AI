import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/facebook_sdk_ready.dart';
import '../../../core/config/app_config.dart';
import '../../auth/data/auth_api.dart';

class LinkedAccountsScreen extends StatefulWidget {
  const LinkedAccountsScreen({required this.token, super.key});
  final String token;

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  final AuthApi _api = const AuthApi();
  Map<String, bool> _linked = const <String, bool>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _apply(await _api.linkedAccounts(widget.token));
    } on AuthApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(Map<String, dynamic> data) {
    final Object? values = data['providers'];
    final Map<String, bool> linked = <String, bool>{};
    if (values is List) {
      for (final Object? value in values) {
        if (value is Map) {
          linked['${value['provider']}'] = value['linked'] == true;
        }
      }
    }
    if (mounted) setState(() { _linked = linked; _error = null; });
  }

  Future<void> _google() async {
    await _run(() async {
      final GoogleSignIn signIn = GoogleSignIn.instance;
      await signIn.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? AppConfig.googleIosClientId : null,
        serverClientId: AppConfig.googleWebClientId,
      );
      final GoogleSignInAccount account = await signIn.authenticate();
      final String? token = account.authentication.idToken;
      if (token == null) throw const AuthApiException('Google did not return a secure token.');
      try {
        _apply(await _api.linkGoogle(widget.token, token));
      } on AuthApiException catch (error) {
        if (error.statusCode != 428) rethrow;
        final String? password = await _requestPassword();
        if (password == null) return;
        _apply(await _api.linkGoogle(widget.token, token, password));
      }
    });
  }

  Future<void> _facebook() async {
    await _run(() async {
      if (kIsWeb) await ensureFacebookSdkReady();
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: const <String>['email', 'public_profile'],
        loginBehavior: LoginBehavior.webOnly,
      );
      if (result.status != LoginStatus.success || result.accessToken == null) return;
      final String accessToken = result.accessToken!.tokenString;
      try {
        _apply(await _api.linkFacebook(widget.token, accessToken));
      } on AuthApiException catch (error) {
        if (error.statusCode != 428) rethrow;
        final String? password = await _requestPassword();
        if (password == null) return;
        _apply(await _api.linkFacebook(widget.token, accessToken, password));
      }
    });
  }

  Future<void> _unlink(String provider) => _run(() async {
    _apply(await _api.unlinkProvider(widget.token, provider));
  });

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _loading = true; _error = null; });
    try { await action(); }
    on AuthApiException catch (e) { if (mounted) setState(() => _error = e.message); }
    catch (_) { if (mounted) setState(() => _error = 'Sign-in provider could not be updated.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<String?> _requestPassword() async {
    final TextEditingController controller = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirm ChessVerseAI password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            helperText: 'Required because the provider uses a different email.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
    controller.dispose();
    final String password = result?.trim() ?? '';
    return password.isEmpty ? null : password;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('LINKED ACCOUNTS')),
    body: ListView(padding: const EdgeInsets.all(20), children: <Widget>[
      const Text('Use Email, Google or Facebook to open the same ChessVerseAI profile. Coins, XP, games and subscriptions stay on one player account.'),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
      const SizedBox(height: 20),
      if (_loading) const Center(child: CircularProgressIndicator()),
      if (!_loading) ...<Widget>[
        _provider('Google', 'google', Icons.g_mobiledata_rounded, _google),
        const SizedBox(height: 12),
        _provider('Facebook', 'facebook', Icons.facebook_rounded, _facebook),
        const SizedBox(height: 16),
        const ListTile(leading: Icon(Icons.email_outlined), title: Text('ChessVerseAI Email'), subtitle: Text('Available through Login and Forgot password')),
      ],
    ]),
  );

  Widget _provider(String label, String key, IconData icon, Future<void> Function() link) {
    final bool connected = _linked[key] == true;
    return ListTile(
      leading: Icon(icon), title: Text(label),
      subtitle: Text(connected ? 'Linked' : 'Not linked'),
      trailing: connected
          ? OutlinedButton(onPressed: () => _unlink(key), child: const Text('UNLINK'))
          : FilledButton(onPressed: link, child: const Text('LINK')),
    );
  }
}
