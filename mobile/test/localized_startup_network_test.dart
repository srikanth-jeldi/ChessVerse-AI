import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/core/network/network_health_controller.dart';
import 'package:chessverse_ai/core/widgets/network_status_layer.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _Health extends NetworkHealthController {
  _Health(super.health) : super.forTesting();
  @override
  Future<void> initialize() async {}
  @override
  Future<void> checkNow() async {}
}

void main() {
  for (final language in AppLanguageController.supported.where(
    (language) => language.code != 'system',
  )) {
    for (final state in ['loading', 'offline', 'slow']) {
      testWidgets('$state translated ${language.code}', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.runAsync(() => UiCopy.load(language.code));
        final health = _Health(
          state == 'offline' ? NetworkHealth.offline : NetworkHealth.slow,
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language.code),
            supportedLocales: AppLanguageController.supported
                .where((language) => language.code != 'system')
                .map((language) => Locale(language.code)),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: state == 'loading'
                ? const ChessVerseLoadingScreen()
                : NetworkStatusLayer(
                    controller: health,
                    child: const Scaffold(body: Text('Game fixture')),
                  ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        if (state == 'loading') {
          for (final label in ['Compete', 'Progress', 'Puzzles']) {
            expect(find.text(UiCopy.text(label)), findsOneWidget);
          }
        } else {
          final label = state == 'offline'
              ? 'Offline · Local play is available'
              : 'Connection is slow. Some actions may take longer.';
          expect(find.text(UiCopy.text(label)), findsOneWidget);
          if (UiCopy.text(label) != label) {
            expect(find.text(label), findsNothing);
          }
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pump();
          expect(find.text('Game fixture'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        health.dispose();
        await UiCopy.load('en');
      });
    }
  }
}
