import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/club_localizations.dart';
import 'package:chessverse_ai/main.dart' show ChessBoard;

import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/data/social_api.dart';
import 'package:chessverse_ai/features/social/presentation/club_activity_screen.dart';

class FakeCommunity extends CommunityApi {
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
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(find.text(clubText('rules', code)), findsOneWidget);
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
}
