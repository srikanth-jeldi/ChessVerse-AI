import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/core/theme/app_theme.dart';
import 'package:chessverse_ai/features/home/presentation/home_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final languages = AppLanguageController.supported.where(
    (l) => l.code != 'system',
  );
  for (final language in languages) {
    for (final width in [320.0, 900.0]) {
      testWidgets('full home name ${language.code} $width enlarged', (
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
            home: Scaffold(
              body: SingleChildScrollView(
                child: TickerMode(
                  enabled: false,
                  child: HomePlayerHeader(
                    playerName: name,
                    coinBalance: 2130,
                    wide: width >= 700,
                    onNotifications: () {},
                    onCoins: () {},
                    onProfile: () {},
                    onSettings: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final text = find.byKey(const ValueKey('home-player-name'));
        final rich = find.descendant(of: text, matching: find.byType(RichText));
        final paragraph = tester.renderObject<RenderParagraph>(rich);
        expect(paragraph.text.toPlainText(), name);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.maxLines, isNull);
        expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
        final rect = tester.getRect(text);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
        for (final key in [
          'home-settings-top',
          'home-notifications',
          'home-profile',
          'home-free-coins',
        ]) {
          expect(
            rect.overlaps(tester.getRect(find.byKey(ValueKey(key)))),
            isFalse,
            reason: key,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
