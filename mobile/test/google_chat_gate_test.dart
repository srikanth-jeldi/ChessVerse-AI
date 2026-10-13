import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/features/auth/presentation/auth_screen.dart';
import 'package:chessverse_ai/features/auth/presentation/chat_access_copy.dart';
import 'package:chessverse_ai/features/auth/presentation/google_chat_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  testWidgets('dismissing the Google requirement never opens chat', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({'settings.language': 'en'});
    bool opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                opened = await GoogleChatGate.ensure(context) != null;
              },
              child: const Text('Open chat'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();
    expect(find.text(googleChatMessage('en')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(opened, isFalse);
    expect(find.byType(AuthScreen), findsNothing);
  });
  test('only a verified linked Google provider grants access', () {
    expect(GoogleChatGate.hasGoogle({}), isFalse);
    expect(
      GoogleChatGate.hasGoogle({
        'providers': [
          {'provider': 'facebook', 'linked': true},
        ],
      }),
      isFalse,
    );
    expect(
      GoogleChatGate.hasGoogle({
        'providers': [
          {'provider': 'google', 'linked': false},
        ],
      }),
      isFalse,
    );
    expect(
      GoogleChatGate.hasGoogle({
        'providers': [
          {'provider': 'google', 'linked': true},
        ],
      }),
      isTrue,
    );
  });

  test('chat requirement is translated in every supported language', () {
    for (final language in AppLanguageController.supported) {
      if (language.code == AppLanguageController.systemCode) continue;
      expect(
        googleChatMessages[language.code],
        isNotEmpty,
        reason: language.code,
      );
    }
  });

  testWidgets('chat login shows Google only with no guest or email bypass', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          googleChatOnly: true,
          chatLanguage: 'te',
          onAuthenticated: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text(googleChatMessage('te')), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('play-as-guest-primary')),
      findsNothing,
    );
    expect(find.textContaining('Facebook'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
