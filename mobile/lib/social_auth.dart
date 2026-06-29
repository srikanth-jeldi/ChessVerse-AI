import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_provider_button.dart';

const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
const String googleServerClientId =
    String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.idToken,
    required this.displayName,
  });

  final String provider;
  final String idToken;
  final String? displayName;
}

class SocialLoginButtons extends StatefulWidget {
  const SocialLoginButtons({
    required this.onCredential,
    required this.onError,
    super.key,
  });

  final ValueChanged<SocialCredential> onCredential;
  final ValueChanged<String> onError;

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;
  bool _googleReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeGoogle());
  }

  Future<void> _initializeGoogle() async {
    final String? clientId =
        kIsWeb && googleWebClientId.isNotEmpty ? googleWebClientId : null;
    final String? serverClientId = !kIsWeb && googleServerClientId.isNotEmpty
        ? googleServerClientId
        : null;
    if (clientId == null && serverClientId == null) {
      return;
    }
    try {
      final GoogleSignIn google = GoogleSignIn.instance;
      await google.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      _googleSubscription = google.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _submitGoogleAccount(event.user);
          }
        },
        onError: (Object error) =>
            widget.onError(_socialError('Google', error)),
      );
      if (mounted) {
        setState(() => _googleReady = true);
      }
    } catch (error) {
      widget.onError(_socialError('Google', error));
    }
  }

  Future<void> _submitGoogleAccount(GoogleSignInAccount account) async {
    final String? idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      widget.onError('Google did not return an identity token.');
      return;
    }
    widget.onCredential(SocialCredential(
      provider: 'google',
      idToken: idToken,
      displayName: account.displayName,
    ));
  }

  Future<void> _startGoogle() async {
    if (!_googleReady) {
      widget.onError(
        'Google login needs GOOGLE_WEB_CLIENT_ID and GOOGLE_SERVER_CLIENT_ID.',
      );
      return;
    }
    if (kIsWeb) {
      return;
    }
    try {
      await GoogleSignIn.instance.authenticate();
    } catch (error) {
      widget.onError(_socialError('Google', error));
    }
  }

  String _socialError(String provider, Object error) {
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      return '$provider sign-in was cancelled.';
    }
    return '$provider sign-in failed. Check the OAuth client configuration.';
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (!_googleReady && googleWebClientId.isEmpty)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startGoogle,
              icon: const Icon(Icons.g_mobiledata_rounded),
              label: const Text('Continue with Google'),
            ),
          )
        else
          buildGoogleProviderButton(_startGoogle),
      ],
    );
  }
}
