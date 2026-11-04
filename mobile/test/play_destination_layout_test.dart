import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in AppLanguageController.supported.where(
    (l) => l.code != 'system',
  )) {
    for (final width in [320.0, 1000.0]) {
      testWidgets('Play modes ${language.code} $width enlarged', (
        tester,
      ) async {
        await tester.runAsync(() => UiCopy.load(language.code));
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var dailyOpened = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: ChessVerseTheme.dark(),
            home: Directionality(
              textDirection: {'ar', 'fa', 'he', 'ur'}.contains(language.code)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 740),
                  textScaler: const TextScaler.linear(1.6),
                ),
                child: PlayDestinationScreen(
                  onComputer: () {},
                  onMyGames: () {},
                  onPositionCreator: () {},
                  onSpectate: () {},
                  onOnline: () {},
                  onLocal: () {},
                  onTournaments: () {},
                  onDaily: () {
                    dailyOpened = true;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pump();
        await tester.tap(find.byType(InkWell).last);
        expect(dailyOpened, isTrue, reason: 'Final mode must remain reachable');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
