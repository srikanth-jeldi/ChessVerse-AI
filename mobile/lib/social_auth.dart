import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'google_provider_button.dart';

const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
const String googleServerClientId =
    String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const String appleServiceId = String.fromEnvironment('APPLE_SERVICE_ID');
const String appleRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');

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

  Future<void> _startApple() async {
    final bool usesWebAuthentication =
        kIsWeb || defaultTargetPlatform == TargetPlatform.android;
    if (usesWebAuthentication &&
        (appleServiceId.isEmpty || appleRedirectUri.isEmpty)) {
      widget.onError(
        'Apple login needs APPLE_SERVICE_ID and APPLE_REDIRECT_URI.',
      );
      return;
    }
    try {
      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
        scopes: const <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: usesWebAuthentication
            ? WebAuthenticationOptions(
                clientId: appleServiceId,
                redirectUri: Uri.parse(appleRedirectUri),
              )
            : null,
      );
      final String? idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        widget.onError('Apple did not return an identity token.');
        return;
      }
      final String displayName = <String?>[
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((String part) => part.isNotEmpty).join(' ');
      widget.onCredential(SocialCredential(
        provider: 'apple',
        idToken: idToken,
        displayName: displayName.isEmpty ? null : displayName,
      ));
    } catch (error) {
      widget.onError(_socialError('Apple', error));
    }
  }

  String _socialError(String provider, Object error) {
    if (error is SignInWithAppleAuthorizationException &&
        error.code == AuthorizationErrorCode.canceled) {
      return '$provider sign-in was cancelled.';
    }
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
        const SizedBox(height: 10),
        SignInWithAppleButton(
          onPressed: _startApple,
          text: 'Continue with Apple',
          height: 44,
          style: SignInWithAppleButtonStyle.black,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          iconAlignment: SignInWithAppleIconAlignment.left,
        ),
      ],
    );
  }
}
