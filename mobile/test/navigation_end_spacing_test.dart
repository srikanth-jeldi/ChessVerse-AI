import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/features/profile/presentation/profile_screen.dart';
import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/presentation/tournament_circuit_view.dart';
import 'package:chessverse_ai/main.dart' show ChessVerseTheme;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in AppLanguageController.supported.where(
    (l) => l.code != 'system',
  )) {
    for (final profile in [true, false]) {
      testWidgets(
        '${language.code} ${profile ? 'profile' : 'tournaments'} end action clears navigation without a large gap',
        (tester) async {
          FlutterSecureStorage.setMockInitialValues({
            'settings.language': language.code,
          });
          AppLanguageController.effectiveLanguageChanges.value = language.code;
          await tester.runAsync(() => UiCopy.load(language.code));
          tester.view.physicalSize = const Size(360, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          var tapped = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: ChessVerseTheme.dark(),
              locale: Locale(language.code),
              supportedLocales: AppLanguageController.supported
                  .where((l) => l.code != 'system')
                  .map((l) => Locale(l.code)),
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: Scaffold(
                bottomNavigationBar: const SizedBox(
                  key: ValueKey('navigation'),
                  height: 70,
                ),
                body: profile
                    ? ProfileScreen(
                        isGuest: true,
                        onSecureProgress: () async {
                          tapped = true;
                        },
                      )
                    : TournamentCircuitView(
                        tournaments: const [
                          TournamentDto(
                            id: 'london',
                            name: 'London Classic',
                            description: 'Traditional tournament chess with a modern competitive edge.',
                            minutes: 5,
                            players: 0,
                            capacity: 128,
                            status: 'OPEN',
                            joined: false,
                          ),
                        ],
                        fairPlayScore: 100,
                        circuitPoints: 0,
                        onRefresh: () async {},
                        onOpen: (_) => tapped = true,
                      ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final scroll = find.byType(Scrollable).first;
          for (
            var n = 0;
            n < 30 &&
                tester.state<ScrollableState>(scroll).position.extentAfter > 1;
            n++
          ) {
            await tester.drag(scroll, const Offset(0, -450));
            await tester.pumpAndSettle();
          }
          final action = profile
              ? find.byKey(const ValueKey('secure-guest-progress'))
              : find.text(UiCopy.text('VIEW DETAILS & REGISTER'));
          final gap =
              tester.getTopLeft(find.byKey(const ValueKey('navigation'))).dy -
              tester.getBottomRight(action).dy;
          expect(
            gap,
            inInclusiveRange(8, 64),
            reason: 'Final action must stay above navigation without a spare navigation-sized gap',
          );
          await tester.tap(action);
          expect(tapped, isTrue);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
