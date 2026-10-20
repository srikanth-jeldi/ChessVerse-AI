import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/features/auth/presentation/google_chat_gate.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in AppLanguageController.supported.where(
    (language) => language.code != 'system',
  )) {
    for (final scenario in ['chat_gate', 'review_retry']) {
      testWidgets('$scenario ${language.code} narrow enlarged text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        FlutterSecureStorage.setMockInitialValues({
          'settings.language': language.code,
        });
        AppLanguageController.effectiveLanguageChanges.value = language.code;
        await tester.runAsync(() => UiCopy.load(language.code));
        bool chatOpened = false;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language.code),
            supportedLocales: AppLanguageController.supported
                .where((l) => l.code != 'system')
                .map((l) => Locale(l.code)),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ChessVerseTheme.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: Directionality(
                textDirection: ['ar', 'fa', 'he', 'ur'].contains(language.code)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  child: const Text('Open fixture'),
                  onPressed: () async {
                    if (scenario == 'chat_gate') {
                      chatOpened = await GoogleChatGate.ensure(context) != null;
                    } else {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => ReviewedPositionRetryDialog(
                          fen: '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
                          initialPieces: const {
                            'e1': ChessPiece('K', true),
                            'e8': ChessPiece('K', false),
                            'e2': ChessPiece('P', true),
                          },
                          whiteToMove: true,
                          bestMove: 'e2e4',
                          explanation: '',
                          progressLabel: 'POSITION BEFORE MOVE 13',
                          languageCode: language.code,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open fixture'));
        await tester.pumpAndSettle();
        expect(
          scenario == 'chat_gate'
              ? find.byType(AlertDialog)
              : find.byType(ReviewedPositionRetryDialog),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (scenario == 'chat_gate') {
          await tester.tap(
            find.text(
              MaterialLocalizations.of(tester.element(find.byType(AlertDialog)))
                  .cancelButtonLabel,
            ),
          );
          await tester.pumpAndSettle();
          expect(chatOpened, isFalse);
          expect(find.byType(AlertDialog), findsNothing);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }
}
