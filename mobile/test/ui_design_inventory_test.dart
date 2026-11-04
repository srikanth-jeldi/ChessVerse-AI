import 'package:chessverse_ai/features/analysis/presentation/setup_analysis_screen.dart';
import 'package:chessverse_ai/features/analysis/data/engine_candidates_api.dart';
import 'package:chessverse_ai/features/missions/presentation/missions_screen.dart';
import 'package:chessverse_ai/features/academy/presentation/my_academy_screen.dart';
import 'package:chessverse_ai/features/leaderboard/presentation/coin_rankings_screen.dart';
import 'package:chessverse_ai/features/profile/presentation/linked_accounts_screen.dart';
import 'package:chessverse_ai/features/puzzles/presentation/puzzle_sprint_leaderboard_screen.dart';
import 'package:chessverse_ai/features/legal/presentation/legal_screen.dart';
import 'package:chessverse_ai/features/social/presentation/tournament_detail_screen.dart';
import 'package:chessverse_ai/features/social/presentation/daily_practice_cup_screen.dart';
import 'package:chessverse_ai/features/social/presentation/club_activity_screen.dart';
import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/data/social_api.dart';
import 'package:chessverse_ai/features/online/presentation/spectator_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/interactive_academy_lesson_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/academy_boss_challenge_screen.dart';
import 'package:chessverse_ai/features/tutorial/domain/academy_lesson.dart';
import 'package:chessverse_ai/features/splash/presentation/premium_splash_screen.dart';
import 'package:chessverse_ai/features/splash/presentation/reference_splash_screen.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'club_activity_screen_test.dart' show FakeCommunity;
import 'shop_localizations_test.dart' show Catalog;
import 'coin_credit_flow_test.dart' as coinFixtures;

import 'package:chessverse_ai/features/shop/presentation/cosmetic_shop_screen.dart';

import 'package:flutter/rendering.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
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

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:chessverse_ai/features/daily_challenge/widgets/daily_puzzle_streak.dart';
import 'package:chessverse_ai/features/coaches/coach_picker_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/opening_trainer_screen.dart';
import 'package:chessverse_ai/features/online/presentation/game_link_import_screen.dart';
import 'package:chessverse_ai/features/analysis/presentation/mistake_bank_screen.dart';

void main({bool deviceAudit = false}) {
  if (!deviceAudit && Platform.environment['CHESSVERSE_CAPTURE_UI'] != '1') {
    test(
      'UI design inventory is an opt-in visual capture tool',
      () {},
      skip: true,
    );
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final channel in [
      'xyz.luan/audioplayers/events/chessverse-cloud-narration',
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (_) async => null);
    }

    if (!deviceAudit) {
      await (FontLoader('Roboto')..addFont(
            Future.value(
              ByteData.sublistView(
                await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes(),
              ),
            ),
          ))
          .load();
    }
    await (FontLoader(
      'serif',
    )..addFont(rootBundle.load('assets/fonts/ChessVerseSerif.ttf'))).load();
    await (FontLoader(
      'ChessVerseSerif',
    )..addFont(rootBundle.load('assets/fonts/ChessVerseSerif.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final screens = <String, Widget Function()>{
    'collection': () => CosmeticShopScreen(
      token: 'test',
      shopApi: Catalog(),
      rewardsApi: coinFixtures.Rewards(),
      rewardedCoins: coinFixtures.Video(),
    ),
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
      onPuzzles: () {},
      onSavedGames: () {},
      onLearnChess: () {},
      onProfile: () {},
      onSettings: () {},
    ),
  };
  screens.addAll({
    'setup_analysis': () => SetupAnalysisScreen(
      fen: '4k3/p7/8/8/8/8/8/4K3 b - - 0 1',
      analyze: (_) async => const [
        EngineCandidateLine(
          move: 'a7a6',
          evaluationCp: 125,
          principalVariation: ['a7a6', 'e1d1'],
        ),
      ],
    ),
    'setup_analysis_error': () => SetupAnalysisScreen(
      fen: '4k3/p7/8/8/8/8/8/4K3 b - - 0 1',
      analyze: (_) async => throw Exception('Preview connection unavailable'),
    ),
    'missions': () => const MissionsScreen(token: 'preview'),
    'my_academy': () => MyAcademyScreen(
      token: 'preview',
      onPuzzle: (_) async {},
      onPosition: (_, _, _) async {},
    ),
    'coin_rankings': () => CoinRankingsScreen(onRating: () {}),
    'linked_accounts': () => const LinkedAccountsScreen(token: 'preview'),
    'puzzle_rankings': () => const PuzzleSprintLeaderboardScreen(),
    'privacy': () => const LegalScreen(type: LegalPageType.privacy),
    'terms': () => const LegalScreen(type: LegalPageType.terms),
    'spectator': () => const SpectatorScreen(token: 'preview'),
    'premium_splash': () => const PremiumSplashScreen(),
    'reference_splash': () => const ReferenceSplashScreen(),
    'academy_lesson': () => InteractiveAcademyLessonScreen(
      lesson: AcademyCatalog.forChapter('Pins'),
    ),
    'academy_boss': () => AcademyBossChallengeScreen(
      courseId: 'preview',
      courseTitle: 'Tactical Mastery',
      lessons: [AcademyCatalog.forChapter('Pins')],
      accent: Colors.teal,
    ),
    'club': () => ClubActivityScreen(
      club: const ClubDto(
        id: 'preview',
        name: 'Practice Club',
        description: 'Practice and learn together',
        members: 6,
        ratingRequirement: 0,
        joined: true,
      ),
      token: 'preview',
      api: FakeCommunity(),
    ),
    'daily_cup': () =>
        DailyPracticeCupScreen(api: _PracticeApi(), token: 'preview'),
    'tournament_detail': () => TournamentDetailScreen(
      id: 'preview',
      token: 'preview',
      api: const _PreviewTournamentApi(),
    ),
    'play': () => PlayDestinationScreen(
      onComputer: () {},
      onMyGames: () {},
      onPositionCreator: () {},
      onSpectate: () {},
      onOnline: () {},
      onLocal: () {},
      onTournaments: () {},
      onDaily: () {},
    ),
    'daily_streak': () => DailyStreakScreen(onPractice: () {}),
    'coaches': () => const CoachPickerScreen(),
    'opening_trainer': () => const OpeningTrainerScreen(),
    'url_import': () => const GameLinkImportScreen(),
    'mistake_bank': () => const MistakeBankScreen(),
    'game_ai': () => const GameScreen(
      initiallySignedIn: true,
      useRemoteEngine: false,
      initialPlayerName: 'Preview Player',
    ),
  });
  screens.addAll({
    'settings_language_sheet': () =>
        const SettingsScreen(openLanguagePickerOnStart: true),
    'profile_edit_sheet': screens['profile']!,
    'url_import_keyboard': screens['url_import']!,
    'daily_cup_board': screens['daily_cup']!,
  });
  const localeFilter = String.fromEnvironment('UI_AUDIT_LANGUAGES');
  const screenFilter = String.fromEnvironment('UI_AUDIT_SCREENS');
  final locales = deviceAudit
      ? AppLanguageController.supported
            .where(
              (l) =>
                  l.code != 'system' &&
                  (localeFilter.isEmpty ||
                      localeFilter.split(',').contains(l.code)),
            )
            .map((l) => l.code)
      : ['en'];
  for (final language in locales) {
    for (final entry in screens.entries.where(
      (e) => screenFilter.isEmpty || screenFilter.split(',').contains(e.key),
    )) {
      testWidgets('design inventory $language/${entry.key}', (tester) async {
        if (deviceAudit) debugPrint('AUDIT start $language/${entry.key}');
        ChessSoundService.instance.enabled = false;
        FlutterSecureStorage.setMockInitialValues({
          'settings.language': language,
          'settings.coachLanguage': language,
        });
        AppLanguageController.effectiveLanguageChanges.value = language;
        if (deviceAudit) {
          await UiCopy.load(language);
        } else {
          await tester.runAsync(() => UiCopy.load(language));
        }
        if (deviceAudit) debugPrint('AUDIT translations loaded');
        if (!deviceAudit) {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
        }
        final key = GlobalKey();
        if (deviceAudit) debugPrint('AUDIT mounting');
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: Locale(language),
            supportedLocales: AppLanguageController.supported
                .where((l) => l.code != 'system')
                .map((l) => Locale(l.code)),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ChessVerseTheme.dark().copyWith(
              appBarTheme: ChessVerseTheme.dark().appBarTheme.copyWith(
                titleTextStyle: ChessVerseTheme.dark()
                    .appBarTheme
                    .titleTextStyle
                    ?.copyWith(fontFamily: 'Roboto'),
              ),
            ),
            builder: (context, child) => RepaintBoundary(
              key: key,
              child: Directionality(
                textDirection: ['ar', 'fa', 'he', 'ur'].contains(language)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
            ),
            home: TickerMode(enabled: false, child: entry.value()),
          ),
        );
        if (deviceAudit) debugPrint('AUDIT mounted');
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        });
        await tester.pump();
        if (entry.key == 'profile_edit_sheet') {
          await tester.ensureVisible(find.text(UiCopy.text('Edit profile')));
          await tester.tap(find.text(UiCopy.text('Edit profile')));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(BottomSheet), findsOneWidget);
        }
        if (entry.key == 'url_import_keyboard') {
          await tester.tap(find.byType(TextField).first);
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pump();
        }
        if (entry.key == 'settings_language_sheet') {
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(BottomSheet), findsOneWidget);
        }
        if (entry.key == 'daily_cup_board') {
          await tester.tap(find.text(UiCopy.text('Enter / Resume game')).first);
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        }
        Future<void> capture(String phase) async {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: deviceAudit ? 1.5 : 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final root = deviceAudit
                ? '${Directory.systemTemp.path}/chessverse-ui-audit/$language'
                : '../.build-tmp/ui-design-inventory';
            final suffix = deviceAudit ? '-$phase' : '';
            final file = File('$root/${entry.key}$suffix.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await capture('top');
        if (deviceAudit) {
          final scrollables = find.byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                axisDirectionToAxis(w.axisDirection) == Axis.vertical,
          );
          final sheet = find.byType(BottomSheet);
          final targets = sheet.evaluate().isNotEmpty
              ? find.descendant(of: sheet.last, matching: scrollables)
              : scrollables;
          for (final element in targets.evaluate().toList()) {
            if (!element.mounted) continue;
            final target = find.byWidget(element.widget);
            final position = tester.state<ScrollableState>(target).position;
            // Decorative board-preview grids are intentionally non-scrollable;
            // their containing page is the user-scrollable surface.
            if (!position.physics.allowUserScrolling) continue;
            for (var step = 0; step < 50 && position.extentAfter > 1; step++) {
              final size =
                  tester.view.physicalSize / tester.view.devicePixelRatio;
              final bounds = tester
                  .getRect(target)
                  .intersect(
                    Rect.fromLTWH(0, 60, size.width, size.height - 100),
                  );
              if (bounds.isEmpty) break;
              await tester.dragFrom(
                bounds.center,
                Offset(0, -bounds.height * .7),
              );
              await tester.pump(const Duration(milliseconds: 100));
            }
            await tester.pump(const Duration(milliseconds: 350));
            debugPrint(
              'AUDIT scroll $language/${entry.key}: pixels=${position.pixels} max=${position.maxScrollExtent} remaining=${position.extentAfter}',
            );
            expect(
              position.extentAfter,
              lessThanOrEqualTo(1.0),
              reason:
                  '$language/${entry.key}: last control must be reachable by scrolling',
            );
          }
          await capture('bottom');
          final error = tester.takeException();
          await tester.runAsync(() async {
            final file = File(
              '${Directory.systemTemp.path}/chessverse-ui-audit/results.jsonl',
            );
            await file.writeAsString(
              '${jsonEncode({'language': language, 'screen': entry.key, 'error': error?.toString()})}\n',
              mode: FileMode.append,
            );
          });
          expect(
            error,
            isNull,
            reason: '$language/${entry.key} real-device rendering',
          );
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }
}

class _PracticeApi extends CommunityApi {
  Completer<void>? holdMove;
  SocialException? joinFailure;
  final state = {
    'id': 'cup',
    'mySeat': 0,
    'seats': List.generate(6, (i) => {'name': 'Player $i', 'bot': i != 0}),
    'games': [
      {'number': 1, 'round': 1, 'white': 0, 'black': 5, 'result': '*'},
    ],
  };
  String? played;
  int? expectedPly;
  @override
  Future<Map<String, dynamic>> joinDailyPractice(String token) async {
    if (joinFailure != null) throw joinFailure!;
    return state;
  }

  @override
  Future<Map<String, dynamic>> dailyPracticeStandings(
    String token,
    String cup,
  ) async => state;
  @override
  Future<Map<String, dynamic>> practiceBoard(
    String token,
    String cup,
    int board, {
    String? move,
    int? ply,
  }) async {
    played = move;
    expectedPly = ply;
    if (move != null && holdMove != null) await holdMove!.future;
    if (move != null) {
      ((state['games'] as List).first as Map)['moves'] = 'e2e4 e8e7';
    }
    return {
      'cup': state,
      'board': 1,
      'ply': move == null ? 0 : 2,
      'legal': ['e2e4'],
      'fen': move == null
          ? '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1'
          : '8/4k3/8/8/4P3/8/8/4K3 w - - 0 2',
    };
  }
}

class _PreviewTournamentApi extends CommunityApi {
  const _PreviewTournamentApi();
  @override
  Future<TournamentDetailDto> tournamentDetail(String token, String id) async =>
      const TournamentDetailDto(
        id: 'preview',
        name: 'Hyderabad Royal Cup',
        description: 'City chess tournament',
        minutes: 10,
        players: 8,
        capacity: 128,
        status: 'OPEN',
        joined: false,
        currentRound: 0,
        rounds: [],
      );
}
