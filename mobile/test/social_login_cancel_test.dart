import 'package:chessverse_ai/features/auth/presentation/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

class _CanceledGoogle extends GoogleSignInPlatform {
  int attempts = 0;
  @override
  Future<void> init(InitParameters params) async {}
  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) async {
    attempts++;
    throw const GoogleSignInException(code: GoogleSignInExceptionCode.canceled);
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('canceled Google login explains failure and permits retry', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'settings.language': 'en'});
    final previous = GoogleSignInPlatform.instance;
    final platform = _CanceledGoogle();
    GoogleSignInPlatform.instance = platform;
    addTearDown(() => GoogleSignInPlatform.instance = previous);
    var authenticated = false;
    await tester.pumpWidget(MaterialApp(home: AuthScreen(
      googleChatOnly: true,
      chatLanguage: 'en',
      onAuthenticated: (_) => authenticated = true,
    )));
    await tester.pumpAndSettle();
    for (var attempt = 1; attempt <= 2; attempt++) {
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('Sign-in was not completed. Please try again.'), findsOneWidget);
      expect(authenticated, isFalse);
      expect(platform.attempts, attempt);
      expect(tester.takeException(), isNull);
    }
  });
}
