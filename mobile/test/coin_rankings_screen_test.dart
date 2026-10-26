import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/features/leaderboard/presentation/coin_rankings_screen.dart';

void main() {
  for (final language in AppLanguageController.supported.where(
    (l) => l.code != 'system',
  )) {
    testWidgets('loaded coin rankings ${language.code} enlarged 320px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => UiCopy.load(language.code));
      final periods = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: AppLanguageController.supported
              .where((l) => l.code != 'system')
              .map((l) => Locale(l.code)),
          locale: Locale(language.code),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: CoinRankingsScreen(
            onRating: () {},
            loader: (period) async {
              periods.add(period);
              final entry = {
                'rank': 1,
                'displayName':
                    'A very long player name for layout verification',
                'coinsWon': 123456,
                'wins': 123,
              };
              return {
                'entries': [entry],
                'you': entry,
                'firstPrizeWeek': '2026-11-02',
                'previousWinners': [
                  {
                    'place': 1,
                    'displayName': 'Previous champion with a long name',
                    'prize': 500,
                    'weekStart': '2026-10-26',
                  },
                ],
              };
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      final overall = find.byKey(const ValueKey('coin-period-overall'));
      await tester.scrollUntilVisible(
        overall,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(overall), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(overall);
      await tester.pump();
      await tester.pump();
      expect(periods, ['weekly', 'overall']);
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
