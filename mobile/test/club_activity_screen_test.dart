import 'package:chessverse_ai/core/club_social_localizations.dart';
import 'package:chessverse_ai/features/social/presentation/club_social_dialog.dart';
import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/club_localizations.dart';
import 'package:chessverse_ai/core/club_learning_strings.dart';
import 'package:chessverse_ai/main.dart' show ChessBoard;

import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/data/social_api.dart';
import 'package:chessverse_ai/features/social/presentation/club_activity_screen.dart';

class FakeCommunity extends CommunityApi {
  String? createdName, invitedIdentity, invitedClub;
  @override
  Future<ClubDto> createClub(
    String token,
    String name,
    String description,
  ) async {
    createdName = name;
    return ClubDto(
      id: 'created',
      name: name,
      description: description,
      members: 1,
      ratingRequirement: 0,
      joined: true,
    );
  }

  @override
  Future<void> inviteToClub(
    String token,
    String clubId,
    String identity,
  ) async {
    invitedClub = clubId;
    invitedIdentity = identity;
  }

  List<SocialChallengeDto> queue = [];
  @override
  Future<List<SocialChallengeDto>> clubChallenges(
    String token,
    String clubId,
  ) async => queue;

  @override
  Future<Map<String, dynamic>> clubPuzzleHelp(
    String token,
    String clubId,
    String day,
    List<String> moves, {
    bool reveal = false,
  }) async => {
    'nextMove': 'e2e3',
    'legalMoves': ['e2e3'],
    'solution': reveal
        ? [
            {
              'move': 'e2e3',
              'fenBefore': '8/8/8/8/8/8/4K3/7k w - - 0 1',
              'fenAfter': '8/8/8/8/8/4K3/8/7k b - - 1 1',
              'piece': 'K',
              'effect': 'improve',
              'playerMove': true,
            },
          ]
        : [],
  };
  bool fail = false;
  int attempts = 0;
  Completer<Map<String, dynamic>>? answer;
  @override
  Future<Map<String, dynamic>> clubPuzzle(
    String token,
    String clubId,
    String day,
    List<String> moves,
  ) {
    attempts++;
    return answer!.future;
  }

  @override
  Future<Map<String, dynamic>> clubActivities(
    String token,
    String clubId,
  ) async {
    if (fail) throw const SocialException('Connection unavailable');
    return {
      'day': '2026-10-17',
      'weekStart': '2026-10-12',
      'fen': '8/8/8/8/8/8/4K3/7k w - - 0 1',
      'completed': false,
      'totalMoves': 2,
      'reward': {
        'streak': 2,
        'earnedToday': false,
        'nextCoins': 15,
        'awardedCoins': 0,
      },
      'completedMembers': 0,
      'members': <Map<String, dynamic>>[
        {
          'id': 'a',
          'name': 'Arjun',
          'rating': 1240,
          'self': true,
          'online': true,
        },
        {
          'id': 'b',
          'name': 'Meera',
          'rating': 1320,
          'self': false,
          'online': true,
        },
      ],
      'leaderboard': <Map<String, dynamic>>[
        {'id': 'b', 'name': 'Meera', 'points': 23},
        {'id': 'a', 'name': 'Arjun', 'points': 10},
      ],
    };
  }
}

class FakeSocial extends SocialApi {
  @override
  Future<SocialHubDto> load(String token) async => const SocialHubDto(
    friends: [],
    incoming: [],
    outgoing: [],
    challenges: [],
  );
}

void main() {
  setUpAll(() async {
    if (Platform.environment['CLUB_VISUAL_FONTS'] != '1') return;
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            await File('C:/Windows/Fonts/Nirmala.ttc').readAsBytes(),
          ),
        ),
      );
    await font.load();
    final arabic = FontLoader('ArabicPreview')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes(),
          ),
        ),
      );
    await arabic.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'settings.language': 'en'});
    AppLanguageController.effectiveLanguageChanges.value = 'en';
  });
  test(
    'All 34 languages cover every club label without empty fallback rows',
    () {
      final codes = AppLanguageController.supported
          .where((l) => l.code != 'system')
          .map((l) => l.code)
          .toSet();
      expect(clubTranslations.keys.toSet(), codes);
      expect(codes.length, 34);
      expect(clubSocialRows.keys.toSet(), codes);
      for (final row in clubSocialRows.values) {
        expect(row.split('|').length, clubSocialKeys.length);
        expect(
          row.split('|').every((value) => value.trim().isNotEmpty),
          isTrue,
        );
      }
      expect(clubLearningTranslations.keys.toSet(), codes);
      for (final code in codes) {
        expect(
          clubLearningTranslations[code]!.length,
          clubLearningKeys.length,
          reason: code,
        );
        for (final key in clubLearningKeys) {
          expect(clubLearningText(key, code).trim(), isNotEmpty);
        }
      }
      for (final code in codes) {
        expect(clubTranslations[code]!.length, clubKeys.length, reason: code);
        for (final key in clubKeys) {
          expect(clubText(key, code).trim(), isNotEmpty);
        }
        if (code != 'en') {
          expect(clubTranslations[code], isNot(clubTranslations['en']));
        }
      }
    },
  );
  testWidgets(
    'Puzzle blocks duplicate submissions and displays saved completion',
    (tester) async {
      final api = FakeCommunity()..answer = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        MaterialApp(
          home: ClubPuzzleScreen(
            api: api,
            token: 'test',
            clubId: 'one',
            day: '2026-10-17',
            initialFen: '8/8/8/8/8/8/4K3/7k w - - 0 1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      var board = tester.widget<ChessBoard>(find.byType(ChessBoard));
      board.onSquareTap('e2');
      await tester.pump();
      board = tester.widget<ChessBoard>(find.byType(ChessBoard));
      board.onSquareTap('e3');
      board.onSquareTap('e3');
      await tester.pump();
      expect(api.attempts, 1);
      api.answer!.complete({
        'correct': true,
        'completed': true,
        'fen': '8/8/8/8/8/4K3/8/7k b - - 1 1',
      });
      await tester.pumpAndSettle();
      expect(find.text(clubText('complete', 'en')), findsOneWidget);
      tester.widget<ChessBoard>(find.byType(ChessBoard)).onSquareTap('e4');
      expect(api.attempts, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Hints and solution review guide moves without awarding completion',
    (tester) async {
      final api = FakeCommunity();
      await tester.pumpWidget(
        MaterialApp(
          home: ClubPuzzleScreen(
            api: api,
            token: 'test',
            clubId: 'one',
            day: '2026-10-18',
            initialFen: '8/8/8/8/8/8/4K3/7k w - - 0 1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final hint = find.byKey(const ValueKey('club-hint'));
      await tester.ensureVisible(hint);
      await tester.pumpAndSettle();
      await tester.tap(hint);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ChessBoard>(find.byType(ChessBoard)).selectedSquare,
        'e2',
      );
      await tester.ensureVisible(hint);
      await tester.pumpAndSettle();
      await tester.tap(hint);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ChessBoard>(find.byType(ChessBoard)).coachArrowTo,
        'e3',
      );
      final solution = find.byKey(const ValueKey('club-solution'));
      await tester.ensureVisible(solution);
      await tester.pumpAndSettle();
      await tester.tap(solution);
      await tester.pumpAndSettle();
      expect(api.attempts, 0);
      final next = find.byKey(const ValueKey('club-solution-next'));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChessBoard>(find.byType(ChessBoard))
            .pieces
            .containsKey('e3'),
        true,
      );
      expect(api.attempts, 0);
      final back = find.byKey(const ValueKey('club-back-practice'));
      await tester.ensureVisible(back);
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChessBoard>(find.byType(ChessBoard))
            .pieces
            .containsKey('e2'),
        true,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  const club = ClubDto(
    id: 'one',
    name: 'Test club',
    description: '',
    members: 1,
    ratingRequirement: 0,
    joined: true,
  );
  testWidgets('Member sees daily puzzle and can recover from request failure', (
    tester,
  ) async {
    final api = FakeCommunity()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ClubActivityScreen(
          club: club,
          token: 'test',
          api: api,
          socialApi: FakeSocial(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(clubText('error', 'en')), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('club-daily-puzzle')), findsOneWidget);
    expect(find.text(clubText('error', 'en')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Challenge queue is separate from members and shows received invitations',
    (tester) async {
      final api = FakeCommunity()
        ..queue = [
          SocialChallengeDto(
            id: 'challenge',
            opponentName: 'Inviting player',
            minutes: 5,
            roomCode: 'room',
            matchId: 'match',
            status: 'PENDING',
            incoming: true,
            expiresAt: DateTime.now().add(const Duration(minutes: 10)),
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          home: ClubActivityScreen(
            club: club,
            token: 'test',
            api: api,
            socialApi: FakeSocial(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inviting player'), findsNothing);
      final tab = find.byKey(const ValueKey('club-challenges-tab'));
      await tester.scrollUntilVisible(
        tab,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tab);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Inviting player'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Inviting player'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final code
      in AppLanguageController.supported
          .where((l) => l.code != 'system')
          .map((l) => l.code)) {
    testWidgets('Club layout fits 360px in $code and switches tabs', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({'settings.language': code});
      AppLanguageController.effectiveLanguageChanges.value = code;
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: code == 'ar' ? 'ArabicPreview' : null),
          home: ClubActivityScreen(
            club: club,
            token: 'test',
            api: FakeCommunity(),
            socialApi: FakeSocial(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(clubText('daily', code)), findsOneWidget);
      final tab = find.byKey(const ValueKey('club-week-tab'));
      await tester.scrollUntilVisible(
        tab,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(find.text(clubText('rules', code)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('club-challenges-tab')));
      await tester.pumpAndSettle();
      expect(find.text(clubSocialText('empty', code)), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['CLUB_VISUAL_FONTS'] == '1' &&
          ['te', 'ar', 'en'].contains(code)) {
        await tester.tap(find.byKey(const ValueKey('club-members-tab')));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/club_$code.png'),
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final code in ['en', 'te', 'ar']) {
    testWidgets('Puzzle screen preview $code', (tester) async {
      FlutterSecureStorage.setMockInitialValues({'settings.language': code});
      AppLanguageController.effectiveLanguageChanges.value = code;
      tester.view.physicalSize = const Size(390, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final rows = File('../backend/src/main/resources/club_daily_puzzles.txt')
          .readAsLinesSync()
          .where((s) => s.isNotEmpty && !s.startsWith('#'));
      final fen = rows.first.split('|')[1];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: code == 'ar' ? 'ArabicPreview' : null),
          home: ClubPuzzleScreen(
            api: FakeCommunity(),
            token: 'test',
            clubId: 'one',
            day: '2026-10-18',
            initialFen: fen,
            totalMoves: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (Platform.environment['CLUB_VISUAL_FONTS'] == '1') {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/club_puzzle_$code.png'),
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final code in clubSocialRows.keys) {
    for (final invite in [false, true]) {
      testWidgets('Club form $code invite=$invite at 320px', (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 740),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Scaffold(
                body: ClubSocialDialog(
                  api: FakeCommunity(),
                  token: 'test',
                  language: code,
                  clubId: invite ? 'one' : null,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  for (final invite in [false, true]) {
    testWidgets('Club form submits trimmed input invite=$invite', (
      tester,
    ) async {
      final api = FakeCommunity();
      Object? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<Object>(
                    context: context,
                    builder: (_) => ClubSocialDialog(
                      api: api,
                      token: 'test',
                      language: 'en',
                      clubId: invite ? 'one' : null,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        invite ? ' friend@example.com ' : ' My chess friends ',
      );
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          clubSocialText(invite ? 'send' : 'create', 'en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ClubSocialDialog), findsNothing);
      if (invite) {
        expect(api.invitedIdentity, 'friend@example.com');
        expect(api.invitedClub, 'one');
        expect(result, true);
      } else {
        expect(api.createdName, 'My chess friends');
        expect((result as ClubDto).joined, true);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
