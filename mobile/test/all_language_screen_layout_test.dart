import 'package:flutter/rendering.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chessverse_ai/features/puzzles/presentation/puzzle_academy_screen.dart';
import 'package:chessverse_ai/features/settings/presentation/device_sessions_screen.dart';
import 'package:chessverse_ai/features/settings/presentation/help_support_screen.dart';
import 'package:chessverse_ai/features/social/presentation/social_hub_screen.dart';
import 'package:chessverse_ai/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:chessverse_ai/features/notifications/presentation/notification_center_screen.dart';
import 'package:chessverse_ai/features/online/presentation/match_history_screen.dart';
import 'package:chessverse_ai/features/play/presentation/position_creator_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/blindfold_training_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/master_games_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/learn_chess_screen.dart';
import 'package:chessverse_ai/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:chessverse_ai/core/audio/chess_sound_service.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/presentation/analysis_screen.dart';
import 'package:chessverse_ai/features/auth/presentation/auth_screen.dart';
import 'package:chessverse_ai/features/home/presentation/home_dashboard_screen.dart';
import 'package:chessverse_ai/features/library/presentation/reference_screens.dart';
import 'package:chessverse_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:chessverse_ai/features/profile/presentation/profile_screen.dart';
import 'package:chessverse_ai/features/settings/presentation/settings_screen.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chessverse_ai/core/app_language.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  var trainingTaps = 0;
  final screens = <String, Widget Function()>{
    'daily_challenge': () => const DailyChallengeScreen(),
    'learn': () => const LearnChessScreen(),
    'master_games': () => const MasterGamesScreen(),
    'blindfold': () => const BlindfoldTrainingScreen(),
    'position_creator': () => const PositionCreatorScreen(),
    'match_history': () => const MatchHistoryScreen(),
    'notifications': () => const NotificationCenterScreen(),
    'leaderboard': () => const LeaderboardScreen(),
    'social': () => const SocialHubScreen(),
    'help': () => const HelpSupportScreen(),
    'device_sessions': () => const DeviceSessionsScreen(),
    'puzzle_academy': () => const PuzzleAcademyScreen(),
    'onboarding': () => OnboardingScreen(onComplete: () {}),
    'auth': () => AuthScreen(onAuthenticated: (_) {}),
    'analysis': () => AnalysisScreen(onSetUpBoard: () {}),
    'profile': () => const ProfileScreen(),
    'settings': () => const SettingsScreen(),
    'options': () => const GameOptionsScreen(),
    'moves': () => const MoveHistoryScreen(),
    'result': () => const GameResultScreen(),
    'puzzles': () => const PuzzlesScreen(),
    'saved-games': () => const SavedGamesScreen(),
    'home': () => HomeDashboardScreen(
      playerName: 'Guest Player',
      activityGames: const <SavedGameRecord>[],
      onPlayVsAi: () {},
      onDailyChallenge: () {},
      onLocalGame: () {},
      onOnlineGame: () {},
      onAnalysis: () {},
      onPuzzles: () {
        trainingTaps++;
      },
      onSavedGames: () {},
      onLearnChess: () {},
      onProfile: () {},
      onSettings: () {},
    ),
  };
  for (final language in AppLanguageController.supported.where(
    (l) => l.code != 'system',
  )) {
    for (final screen in screens.entries) {
      testWidgets('${screen.key} ${language.code} 320px enlarged text', (
        tester,
      ) async {
        ChessSoundService.instance.enabled = false;
        FlutterSecureStorage.setMockInitialValues({
          'settings.language': language.code,
          'settings.coachLanguage': language.code,
        });
        AppLanguageController.effectiveLanguageChanges.value = language.code;
        await tester.runAsync(() => UiCopy.load(language.code));
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final originalErrorHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint(details.toString());
          originalErrorHandler?.call(details);
        };
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
            home: TickerMode(enabled: false, child: screen.value()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        FlutterError.onError = originalErrorHandler;
        for (final element
            in find
                .byWidgetPredicate((w) => w is ButtonStyleButton)
                .evaluate()) {
          final button = find.byWidget(element.widget);
          for (final rich
              in find
                  .descendant(of: button, matching: find.byType(RichText))
                  .evaluate()) {
            final render = rich.renderObject;
            if (render is! RenderParagraph) continue;
            final painter = TextPainter(
              text: render.text,
              textDirection: render.textDirection,
              textScaler: render.textScaler,
            )..layout(maxWidth: render.size.width + 1);
            expect(
              render.didExceedMaxLines,
              isFalse,
              reason:
                  '${screen.key}/${language.code}: clipped ${render.text.toPlainText()}',
            );
            expect(
              painter.computeLineMetrics().length,
              lessThanOrEqualTo(1),
              reason:
                  '${screen.key}/${language.code}: wrapped ${render.text.toPlainText()}',
            );
            painter.dispose();
          }
        }
        final error = tester.takeException();
        expect(error, isNull, reason: '${screen.key}/${language.code}');
        if (screen.key == 'home') {
          for (final source in <String>[
            'Mira the Mentor', 'Nova the Tactician',
            'Sage the Strategist', 'Onyx the Guardian',
            'Friendly beginner practice', 'Sharp attacks',
            'Calm positional play', 'Solid defence',
          ]) {
            expect(find.text(UiCopy.text(source)), findsWidgets);
            for (final element in find.text(UiCopy.text(source)).evaluate()) {
              final paragraphs = find.descendant(
                of: find.byWidget(element.widget), matching: find.byType(RichText));
              for (final paragraph in paragraphs.evaluate()) {
                final render = paragraph.renderObject;
                if (render is RenderParagraph) {
                  expect(render.didExceedMaxLines, isFalse,
                    reason: '${language.code}: truncated opponent text $source');
                }
              }
            }
            if (language.code != 'en') {
              expect(UiCopy.text(source), isNot(source));
              expect(find.text(source), findsNothing);
            }
          }
          expect(
            find.byWidgetPredicate(
              (w) => w is Text && w.textSpan?.toPlainText() == 'ChessVerseAI',
            ),
            findsOneWidget,
          );
          final train = find.byKey(
            const ValueKey<String>('personal-training-action'),
          );
          expect(train, findsOneWidget);
          expect(tester.getSize(train).width, greaterThan(200));
          expect(tester.getSize(train).height, greaterThanOrEqualTo(48));
          await tester.ensureVisible(train);
          await tester.pump();
          final before = trainingTaps;
          await tester.tap(train);
          expect(trainingTaps, before + 1);
          expect(find.text(UiCopy.text('Play Now')), findsWidgets);
          if (UiCopy.text('Play Now') != 'Play Now') {
            expect(find.text('Play Now'), findsNothing);
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
