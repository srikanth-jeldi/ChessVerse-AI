import 'package:chessverse_ai/features/missions/presentation/missions_screen.dart';
import 'package:chessverse_ai/features/online/presentation/spectator_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/academy_boss_challenge_screen.dart';

import 'dart:convert';

import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/core/analysis_dashboard_localizations.dart';
import 'package:chessverse_ai/features/analysis/presentation/analysis_screen.dart';
import 'package:chessverse_ai/features/analysis/presentation/mistake_bank_screen.dart';
import 'package:chessverse_ai/features/analysis/presentation/adaptive_ai_review.dart';
import 'package:chessverse_ai/features/analysis/domain/ai_review_report.dart';
import 'package:chessverse_ai/features/online/presentation/match_history_screen.dart';
import 'package:chessverse_ai/features/library/presentation/reference_screens.dart';
import 'package:chessverse_ai/features/settings/presentation/settings_screen.dart';
import 'package:chessverse_ai/features/settings/presentation/device_sessions_screen.dart';
import 'package:chessverse_ai/features/notifications/presentation/notification_center_screen.dart';
import 'package:chessverse_ai/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:chessverse_ai/features/puzzles/presentation/puzzle_sprint_leaderboard_screen.dart';

import 'mistake_bank_screen_test.dart' as mistakes;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/audio/chess_sound_service.dart';
import 'package:chessverse_ai/core/club_social_localizations.dart';
import 'package:chessverse_ai/core/widgets/ai_language_picker.dart';
import 'package:chessverse_ai/features/auth/presentation/auth_screen.dart';
import 'package:chessverse_ai/features/profile/presentation/profile_screen.dart';
import 'package:chessverse_ai/features/profile/presentation/linked_accounts_screen.dart';
import 'package:chessverse_ai/features/legal/presentation/legal_screen.dart';
import 'package:chessverse_ai/features/academy/presentation/my_academy_screen.dart';
import 'package:chessverse_ai/features/social/presentation/club_social_dialog.dart';
import 'package:chessverse_ai/features/social/presentation/club_activity_screen.dart';
import 'package:chessverse_ai/features/social/presentation/social_hub_screen.dart';
import 'package:chessverse_ai/features/social/presentation/tournament_detail_screen.dart';
import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/data/social_api.dart';
import 'package:chessverse_ai/features/tutorial/presentation/master_games_screen.dart';
import 'package:chessverse_ai/features/tutorial/presentation/interactive_academy_lesson_screen.dart';
import 'package:chessverse_ai/features/tutorial/domain/academy_lesson.dart';
import 'package:chessverse_ai/features/shop/presentation/cosmetic_shop_screen.dart';
import 'package:chessverse_ai/features/shop/data/shop_api.dart';
import 'package:chessverse_ai/main.dart' show ChessVerseTheme;

import 'club_activity_screen_test.dart' as clubs;
import 'coin_credit_flow_test.dart' as coins;

class _FailedInvites extends clubs.FakeCommunity {
  @override
  Future<void> inviteToClub(
    String token,
    String clubId,
    String identity,
  ) async {
    throw const SocialException('Connection unavailable');
  }
}

class _FailedShop extends ShopApi {
  @override
  Future<ShopDto> load(String token) async =>
      throw const ShopException('Connection unavailable');
}

const _club = ClubDto(
  id: 'one',
  name: 'International chess friends club',
  description: 'A populated club with a long name',
  members: 150,
  ratingRequirement: 0,
  joined: true,
);
const _social = SocialHubDto(
  friends: [
    SocialPlayerDto(
      connectionId: 'c',
      playerId: 'p',
      username: 'international_player',
      displayName: 'International chess player with a long name',
      country: 'India',
      rating: 1542,
      online: true,
      relationship: 'FRIEND',
    ),
  ],
  incoming: [],
  outgoing: [],
  challenges: [
    SocialChallengeDto(
      id: 'c',
      opponentName: 'International chess player with a long name',
      minutes: 10,
      roomCode: 'CV1234',
      matchId: 'm',
      status: 'PENDING',
      incoming: true,
      expiresAt: null,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers.global',
      'flutter_tts',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          messenger.setMockMethodCallHandler(
            MethodChannel(
              'xyz.luan/audioplayers/events/${(call.arguments as Map)['playerId']}',
            ),
            (_) async => null,
          );
        }
        return null;
      },
    );
    ChessSoundService.instance.enabled = false;
  });
  final states = [
    'auth_keyboard',
    'profile_editor_keyboard',
    'profile_menu',
    'language_popup',
    'club_loaded',
    'club_error',
    'club_invite_error_keyboard',
    'club_create_keyboard',
    'social_loaded',
    'tournament_loaded',
    'master_answer',
    'lesson_loaded',
    'shop_loaded',
    'shop_error',
    'linked_accounts_error',
    'academy_error_keyboard',
    'missions_loaded',
    'spectator_loaded',
    'spectator_error',
    'academy_loaded',
    'boss_loaded',
    'legal_privacy',
    'legal_terms',
    'analysis_saved',
    'library_saved',
    'mistakes_saved',
    'review_popup',
    'review_full',
    'history_import_popup',
    'history_export_popup',
    'settings_logout_popup',
    'settings_delete_popup',
    'settings_language_keyboard',
    'notifications_loaded',
    'sessions_loaded',
    'leaderboard_loaded',
    'sprint_loaded',
    'sprint_guest',
  ];
  for (final locale in AppLanguageController.supported.where(
    (l) => l.code != 'system',
  )) {
    for (final state in states) {
      testWidgets('$state ${locale.code} 320px scale1.3', (tester) async {
        FlutterSecureStorage.setMockInitialValues({
          'settings.language': locale.code,
          'settings.coachLanguage': locale.code,
        });
        AppLanguageController.effectiveLanguageChanges.value = locale.code;
        await tester.runAsync(() => UiCopy.load(locale.code));
        if ([
          'notifications_loaded',
          'sessions_loaded',
          'leaderboard_loaded',
          'sprint_loaded',
        ].contains(state)) {
          const storage = FlutterSecureStorage();
          await storage.write(key: 'auth.token', value: 'fixture-token');
          await storage.write(key: 'auth.displayName', value: 'Fixture player');
          await storage.write(
            key: 'auth.expiresAt',
            value: DateTime.now()
                .add(const Duration(days: 1))
                .toIso8601String(),
          );
        }
        await LocalGameArchive.init();
        if (state.endsWith('_saved') || state.startsWith('history_')) {
          LocalGameArchive.addGame(
            SavedGameRecord(
              mode: 'Computer',
              result: '1-0',
              detail: 'Checkmate',
              moves: const ['e2e3', 'e7e5', 'g1f3'],
              playedAt: DateTime(2026, 10, 19),
              whitePlayer: 'International chess player with a long name',
              blackPlayer: 'Another international player',
              moveReviews: [mistakes.review()],
            ),
          );
        }
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        if (state == 'profile_editor_keyboard') {
          tester.view.padding = const FakeViewPadding(top: 30);
          tester.view.viewPadding = const FakeViewPadding(top: 30);
        }
        addTearDown(tester.view.reset);
        final previous = FlutterError.onError;
        FlutterError.onError = (error) {
          debugPrint('$state/${locale.code}: $error');
          previous?.call(error);
        };
        addTearDown(() => FlutterError.onError = previous);
        Future<void> mount(Widget child) async {
          await http.runWithClient(
            () async {
              await tester.pumpWidget(
                MaterialApp(
                  locale: Locale(locale.code),
                  supportedLocales: AppLanguageController.supported
                      .where((l) => l.code != 'system')
                      .map((l) => Locale(l.code)),
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  theme: ChessVerseTheme.dark(),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.3)),
                    child: Directionality(
                      textDirection:
                          ['ar', 'fa', 'he', 'ur'].contains(locale.code)
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: child!,
                    ),
                  ),
                  home: child,
                ),
              );
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 600));
            },
            () => MockClient((request) async {
              final path = request.url.path;
              if (path.endsWith('/me/country')) return http.Response('{}', 200);
              if (path.contains('/progression/missions')) {
                return http.Response(
                  jsonEncode({
                    'daily': [
                      {
                        'code': 'DAILY_PLAY',
                        'cadence': 'DAILY',
                        'progress': 1,
                        'target': 1,
                        'rewardCoins': 25,
                        'completed': true,
                        'claimed': false,
                        'resetsAt': DateTime.now()
                            .add(const Duration(hours: 2))
                            .toIso8601String(),
                      },
                    ],
                    'weekly': [],
                  }),
                  200,
                );
              }
              if (path.endsWith('/matches/live') &&
                  state != 'spectator_error') {
                return http.Response(
                  jsonEncode([
                    {
                      'id': 'm',
                      'roomCode': 'CV1234',
                      'status': 'ACTIVE',
                      'yourColor': 'SPECTATOR',
                      'activeColor': 'WHITE',
                      'whitePlayerName':
                          'International player with a long name',
                      'blackPlayerName':
                          'Another international player with a long name',
                      'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                      'moves': [],
                    },
                  ]),
                  200,
                );
              }
              if (state == 'academy_loaded') {
                if (path.endsWith('/me')) {
                  return http.Response(
                    jsonEncode({
                      'organizations': [
                        {
                          'id': 'org',
                          'name':
                              'International chess academy with a long name',
                          'role': 'STUDENT',
                        },
                      ],
                    }),
                    200,
                  );
                }
                if (path.endsWith('/workspace')) {
                  return http.Response(
                    jsonEncode({
                      'students': [],
                      'members': [],
                      'batches': [],
                      'reports': [],
                      'assignments': [
                        {
                          'id': 'a',
                          'title': 'A detailed chess training assignment with a long title',
                          'kind': 'OPENINGS',
                          'due_date': '2026-10-25',
                          'instructions': 'Review the opening and compare your strongest candidate moves.',
                        },
                      ],
                    }),
                    200,
                  );
                }
                if (path.endsWith('/app-activity')) {
                  return http.Response('{"sharing":[]}', 200);
                }
                if (path.endsWith('/announcements')) {
                  return http.Response(
                    jsonEncode([
                      {
                        'title': 'Welcome to the international chess academy',
                        'message': 'Practise every day and review your games.',
                      },
                    ]),
                    200,
                  );
                }
              }
              if (path.contains('notifications')) {
                return http.Response(
                  jsonEncode({
                    'unreadCount': 1,
                    'notifications': [
                      {
                        'id': 'n',
                        'type': 'CLUB_INVITE',
                        'title': 'A long invitation title from an international chess club',
                        'body': 'A friend invited you to join their club and play a friendly match together.',
                        'read': false,
                        'createdAt': DateTime.now().toIso8601String(),
                      },
                    ],
                  }),
                  200,
                );
              }
              if (path.endsWith('/sessions')) {
                return http.Response(
                  jsonEncode([
                    {
                      'id': 's',
                      'deviceName': 'Samsung International Test Device Name',
                      'current': true,
                      'lastSeenAt': DateTime.now().toIso8601String(),
                    },
                  ]),
                  200,
                );
              }
              if (path.contains('sprint')) {
                return http.Response(
                  jsonEncode([
                    {
                      'id': 'r',
                      'playerName':
                          'International chess player with a long name',
                      'score': 25,
                      'attempted': 30,
                      'durationSeconds': 180,
                      'mode': 'RUSH',
                    },
                  ]),
                  200,
                );
              }
              if (path.endsWith('/leaderboard')) {
                return http.Response(
                  jsonEncode({
                    'you': {'displayName': 'Fixture player'},
                    'entries': [
                      for (var i = 0; i < 8; i++)
                        {
                          'rank': i + 1,
                          'playerId': 'p$i',
                          'displayName':
                              'International player number $i with a long name',
                          'country': 'India',
                          'rating': 1500,
                          'you': i == 2,
                        },
                    ],
                  }),
                  200,
                );
              }
              return http.Response(
                '{"message":"Connection unavailable. Please try again."}',
                503,
              );
            }),
          );
        }

        Future<void> keyboard(Finder field) async {
          await tester.ensureVisible(field);
          await tester.pump();
          await tester.tap(field);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.enterText(field, 'International player name');
          await tester.pump();
        }

        switch (state) {
          case 'auth_keyboard':
            await mount(AuthScreen(onAuthenticated: (_) {}));
            await tester.ensureVisible(
              find.byKey(const ValueKey('open-account-access')),
            );
            await tester.pump();
            await tester.tap(find.byKey(const ValueKey('open-account-access')));
            await tester.pump(const Duration(milliseconds: 400));
            await keyboard(find.byType(TextField).first);
          case 'profile_editor_keyboard':
          case 'profile_menu':
            await mount(
              ProfileScreen(
                playerName: 'International chess player with a long name',
                username: 'international_player',
                isGuest: false,
                onDisplayNameChanged: (_) async {},
              ),
            );
            await tester.tap(
              find.byKey(
                ValueKey(
                  state == 'profile_menu'
                      ? 'profile-actions-menu'
                      : 'edit-player-profile',
                ),
              ),
            );
            await tester.pumpAndSettle();
            if (state != 'profile_menu') {
              await keyboard(
                find.byKey(const ValueKey('profile-display-name-field')),
              );
              expect(
                tester.getTopLeft(find.byType(BottomSheet)).dy,
                greaterThanOrEqualTo(30),
                reason: 'Profile editor must stay below the status bar.',
              );
            }
          case 'language_popup':
            await mount(
              Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showAiLanguagePicker(context),
                    child: const Text('Open'),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('Open'));
            await tester.pumpAndSettle();
          case 'club_loaded':
          case 'club_error':
            await mount(
              ClubActivityScreen(
                club: _club,
                token: 'test',
                api: clubs.FakeCommunity()..fail = state == 'club_error',
                socialApi: clubs.FakeSocial(),
              ),
            );
          case 'club_invite_error_keyboard':
          case 'club_create_keyboard':
            await mount(
              Scaffold(
                body: ClubSocialDialog(
                  api: _FailedInvites(),
                  token: 'test',
                  language: locale.code,
                  clubId: state == 'club_create_keyboard' ? null : 'one',
                ),
              ),
            );
            await keyboard(find.byType(TextField).first);
            if (state == 'club_invite_error_keyboard') {
              final send = find.widgetWithText(
                FilledButton,
                clubSocialText('send', locale.code),
              );
              await tester.ensureVisible(send);
              await tester.tap(send);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 200));
            }
          case 'social_loaded':
            await mount(const SocialHubScreen(previewHub: _social));
          case 'tournament_loaded':
            await mount(
              Scaffold(
                body: TournamentDetailContent(
                  detail: TournamentDetailDto(
                    id: 'one',
                    name: 'Hyderabad Royal Cup',
                    description:
                        'International tournament with a detailed description',
                    minutes: 10,
                    players: 64,
                    capacity: 128,
                    status: 'ACTIVE',
                    joined: true,
                    currentRound: 2,
                    startsAt: DateTime(2026, 10, 20),
                    rounds: const [
                      TournamentRoundDto(2, 'ACTIVE', [
                        TournamentPairingDto(
                          1,
                          TournamentPlayerDto(
                            'p1',
                            'International player with a long name',
                            null,
                          ),
                          TournamentPlayerDto(
                            'p2',
                            'Another international player with a long name',
                            null,
                          ),
                          'm',
                          null,
                          'ACTIVE',
                          true,
                        ),
                      ]),
                    ],
                  ),
                  busy: false,
                  onToggle: () async {},
                  onRefresh: () async {},
                ),
              ),
            );
          case 'master_answer':
            await mount(const MasterGamesScreen());
            final game = find.byKey(
              const ValueKey('master-game-kasparov-topalov-1999'),
            );
            await tester.ensureVisible(game);
            await tester.pump();
            await tester.tapAt(
              tester
                  .getRect(game)
                  .intersect(const Rect.fromLTWH(0, 80, 320, 640))
                  .center,
            );
            await tester.pumpAndSettle();
            final answer = find.byKey(
              const ValueKey('master-choice-24. Rxd4!!'),
            );
            await tester.scrollUntilVisible(
              answer,
              250,
              scrollable: find.byType(Scrollable).last,
            );
            await tester.pump();
            await tester.tap(answer);
            await tester.pump(const Duration(milliseconds: 400));
          case 'lesson_loaded':
            await mount(
              InteractiveAcademyLessonScreen(
                lesson: AcademyCatalog.forChapter('How pawns move'),
              ),
            );
          case 'shop_loaded':
          case 'shop_error':
            await mount(
              CosmeticShopScreen(
                token: 'test',
                shopApi: state == 'shop_error' ? _FailedShop() : coins.Shop(),
                rewardsApi: coins.Rewards(),
                rewardedCoins: coins.Video(),
              ),
            );
          case 'linked_accounts_error':
            await mount(const LinkedAccountsScreen(token: 'test'));
          case 'academy_error_keyboard':
            await mount(
              MyAcademyScreen(
                token: 'test',
                onPuzzle: (_) async {},
                onPosition: (_, _, _) async {},
              ),
            );
            if (find.byType(TextField).evaluate().isNotEmpty) {
              await keyboard(find.byType(TextField).first);
            }
          case 'missions_loaded':
            await mount(const MissionsScreen(token: 'test'));
          case 'spectator_loaded':
          case 'spectator_error':
            await mount(const SpectatorScreen(token: 'test'));
          case 'academy_loaded':
            await mount(
              MyAcademyScreen(
                token: 'test',
                onPuzzle: (_) async {},
                onPosition: (_, _, _) async {},
              ),
            );
            expect(
              find.text(
                'A detailed chess training assignment with a long title',
              ),
              findsOneWidget,
            );
          case 'boss_loaded':
            await mount(
              AcademyBossChallengeScreen(
                courseId: 'basic',
                courseTitle: 'Foundation chess course',
                lessons: [AcademyCatalog.forChapter('How pawns move')],
                accent: Colors.teal,
              ),
            );
          case 'analysis_saved':
            await mount(const AnalysisScreen());
          case 'library_saved':
            await mount(const SavedGamesScreen());
          case 'mistakes_saved':
            await mount(const MistakeBankScreen());
          case 'review_popup':
          case 'review_full':
            await mount(
              Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showAdaptiveAiReview(
                      context,
                      report: AiReviewReport.fromMoves(
                        ['e2e4', 'e7e5', 'g1f3'],
                        newestFirst: false,
                        knownAccuracy: 82,
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('Open'));
            await tester.pumpAndSettle();
            if (state == 'review_full') {
              final action = find.text(
                analysisDashboardText('openReview', locale.code),
              );
              await tester.ensureVisible(action);
              await tester.pump();
              await tester.tap(action);
              await tester.pumpAndSettle();
            }
          case 'history_import_popup':
          case 'history_export_popup':
            await mount(const MatchHistoryScreen());
            final action = find.byTooltip(
              UiCopy.text(
                state == 'history_import_popup'
                    ? 'Import PGN or FEN'
                    : 'Export PGN or FEN',
              ),
            );
            await tester.ensureVisible(action);
            await tester.pump();
            await tester.tap(action);
            await tester.pumpAndSettle();
          case 'settings_language_keyboard':
            await mount(
              SettingsScreen(
                onLogout: () async {},
                onDeleteAccount: () async {},
              ),
            );
            await tester.tap(
              find.byKey(const ValueKey('settings-language-shortcut')),
            );
            await tester.pumpAndSettle();
            await keyboard(find.byType(TextField).last);
            await tester.enterText(find.byType(TextField).last, 'Telugu');
            await tester.pumpAndSettle();
            final result = find.widgetWithText(ListTile, 'Telugu');
            expect(result, findsOneWidget);
            expect(result.hitTestable(), findsOneWidget);
          case 'settings_logout_popup':
          case 'settings_delete_popup':
            await mount(
              SettingsScreen(
                onLogout: () async {},
                onDeleteAccount: () async {},
              ),
            );
            final action = state == 'settings_delete_popup'
                ? find.byKey(const ValueKey('delete-account'))
                : find.text(UiCopy.text('Logout'));
            await tester.scrollUntilVisible(
              action,
              350,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pump();
            await tester.tap(action);
            await tester.pumpAndSettle();
          case 'notifications_loaded':
            await mount(const NotificationCenterScreen());
            expect(
              find.textContaining('A long invitation title'),
              findsOneWidget,
            );
          case 'sessions_loaded':
            await mount(const DeviceSessionsScreen());
            expect(
              find.text('Samsung International Test Device Name'),
              findsOneWidget,
            );
          case 'leaderboard_loaded':
            await mount(const LeaderboardScreen());
            expect(
              find.textContaining('International player number'),
              findsWidgets,
            );
          case 'sprint_loaded':
          case 'sprint_guest':
            await mount(const PuzzleSprintLeaderboardScreen());
            expect(find.byType(CircularProgressIndicator), findsNothing);
          case 'legal_privacy':
          case 'legal_terms':
            await mount(
              LegalScreen(
                type: state == 'legal_privacy'
                    ? LegalPageType.privacy
                    : LegalPageType.terms,
              ),
            );
        }
        // Walk the full primary scroll region so lazy content also gets laid out.
        final scroll = find.byType(Scrollable);
        if (scroll.evaluate().isNotEmpty && !state.endsWith('keyboard')) {
          for (var i = 0; i < 5; i++) {
            final bounds = tester
                .getRect(scroll.first)
                .intersect(const Rect.fromLTWH(0, 80, 320, 600));
            if (!bounds.isEmpty) {
              await tester.dragFrom(bounds.center, const Offset(0, -450));
            }
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        expect(tester.takeException(), isNull, reason: '$state/${locale.code}');
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
