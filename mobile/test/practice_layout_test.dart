import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/core/theme/app_theme.dart';
import 'package:chessverse_ai/features/tutorial/presentation/opening_trainer_screen.dart';
import 'package:chessverse_ai/features/online/presentation/game_link_import_screen.dart';
import 'package:chessverse_ai/features/analysis/presentation/daily_routine_card.dart';
import 'package:chessverse_ai/features/daily_challenge/widgets/daily_puzzle_streak.dart';

void main() {
  final languages = AppLanguageController.supported
      .where((l) => l.code != 'system')
      .toList();
  for (final language in languages) {
    testWidgets(
      'practice screens ${language.code} narrow enlarged with keyboard',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        await tester.runAsync(() => UiCopy.load(language.code));
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Widget app(Widget screen, {bool keyboard = false}) => MaterialApp(
          theme: AppTheme.darkTheme,
          locale: Locale(language.code),
          supportedLocales: languages.map((l) => Locale(l.code)),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
              viewInsets: EdgeInsets.only(bottom: keyboard ? 280 : 0),
            ),
            child: Directionality(
              textDirection: ['ar', 'he', 'fa', 'ur'].contains(language.code)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child!,
            ),
          ),
          home: screen,
        );
        await tester.pumpWidget(app(const OpeningTrainerScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('opening-square-e2')));
        await tester.tap(find.byKey(const ValueKey('opening-square-e3')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          app(const GameLinkImportScreen(), keyboard: true),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).first,
          'https://www.chess.com/game/live/123',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          app(
            Scaffold(
              body: SingleChildScrollView(
                child: DailyRoutineCard(onPuzzle: (_) async {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            UiCopy.text(
              'Starter plan. Review your games to personalise future practice.',
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          app(
            const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    DailyPuzzleStreak(streak: 0, completedToday: false),
                    DailyPuzzleStreak(streak: 3, completedToday: true),
                    DailyPuzzleStreak(streak: 7, completedToday: false),
                    DailyPuzzleStreak(streak: 8, completedToday: true),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
