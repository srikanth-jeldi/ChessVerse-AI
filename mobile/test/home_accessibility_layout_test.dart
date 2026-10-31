import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/core/theme/app_theme.dart';
import 'package:chessverse_ai/features/home/presentation/home_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final languages = AppLanguageController.supported.where(
    (l) => l.code != 'system',
  );
  for (final language in languages) {
    for (final width in [320.0, 900.0, 1600.0]) {
      testWidgets('full home layout ${language.code} $width enlarged', (
        tester,
      ) async {
        FlutterSecureStorage.setMockInitialValues({
          'settings.language': language.code,
        });
        AppLanguageController.effectiveLanguageChanges.value = language.code;
        await tester.runAsync(() => UiCopy.load(language.code));
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const name = 'Chessverseai Epitomehub';
        final originalError = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint(details.toString());
          originalError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalError);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language.code),
            supportedLocales: languages.map((l) => Locale(l.code)),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.darkTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: Directionality(
                textDirection: ['ar', 'he', 'fa', 'ur'].contains(language.code)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
            ),
            home: TickerMode(
              enabled: false,
              child: HomeDashboardScreen(
                playerName: name,
                coinBalance: 2130,
                onPlayVsAi: () {},
                onDailyChallenge: () {},
                onLocalGame: () {},
                onAnalysis: () {},
                onPuzzles: () {},
                onSavedGames: () {},
                onLearnChess: () {},
                onProfile: () {},
                onSettings: () {},
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final carousel = tester.widget<PageView>(
          find.byKey(const ValueKey('home-hero-carousel')),
        );
        for (
          var page = 1;
          page < (carousel.childrenDelegate.estimatedChildCount ?? 1);
          page++
        ) {
          carousel.controller!.jumpToPage(page);
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'carousel page $page');
        }
        final exception = tester.takeException();
        if (exception is FlutterError) debugPrint(exception.toStringDeep());
        expect(exception, isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
