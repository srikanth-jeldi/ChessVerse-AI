import 'dart:async';
import 'dart:convert';

import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/data/personal_mistake_backup.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_bank.dart';
import 'package:chessverse_ai/features/auth/data/auth_session_store.dart';
import 'package:chessverse_ai/features/tutorial/data/academy_progress_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const sessions = AuthSessionStore();
  const progress = AcademyProgressStore();
  const identity = 'account:a@test.invalid';
  final playedAt = DateTime.utc(2026, 10, 10);
  final game = SavedGameRecord(
    mode: 'Computer',
    result: 'Draw',
    detail: 'Draw',
    moves: ['e2e3'],
    playedAt: playedAt,
    whitePlayer: 'Player',
    blackPlayer: 'AI',
    moveReviews: [
      SavedMoveReview(
        ply: 1,
        fenBefore: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        playedMove: 'e2e3',
        bestMove: 'e2e4',
        classification: 'Mistake',
        centipawnLoss: 80,
        opponentThreat: 'Centre',
        explanation: 'Control the centre.',
        principalVariation: ['e2e4', 'e7e5', 'g1f3'],
      ),
    ],
  );

  Future<void> login({String account = 'a', bool guest = false}) async {
    await sessions.write(
      StoredAuthSession(
        token: account,
        expiresAt: DateTime.utc(2099),
        displayName: account,
        email: '$account@test.invalid',
        isGuest: guest,
      ),
    );
    final session = (await sessions.read())!;
    await LocalGameArchive.activateIdentity(
      await sessions.progressIdentity(session),
    );
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await LocalGameArchive.init();
    await login();
  });

  test('fresh installation restores playable mistakes and assisted/independent progress', () async {
    Map<String, dynamic> cloud = {'items': []};
    final api = PersonalMistakeBackup(
      client: MockClient((request) async {
        final data = jsonDecode(request.body) as Map<String, dynamic>;
        if ((data['items'] as List).isNotEmpty) cloud = data;
        return http.Response(jsonEncode(cloud), 200);
      }),
    );
    await LocalGameArchive.restoreMistakeGames(identity, [game]);
    final id = MistakeBank.all(LocalGameArchive.games).single.id;
    await progress.recordMistakeReview(id, true, now: playedAt, assisted: true);
    await progress.recordMistakeReview(
      id,
      true,
      now: playedAt.add(const Duration(minutes: 1)),
    );
    expect(await api.sync(), true);
    // Emulate uninstall: erase only the mocked device storage, not the server.
    FlutterSecureStorage.setMockInitialValues({});
    await LocalGameArchive.init();
    await login();
    expect(LocalGameArchive.games, isEmpty);
    expect(await api.sync(), true);
    final restored = MistakeBank.all(LocalGameArchive.games).single;
    expect(restored.id, id);
    expect(restored.review.principalVariation, ['e2e4', 'e7e5', 'g1f3']);
    expect(restored.review.explanation, 'Control the centre.');
    final review = (await progress.readMistakeReviews())[id]!;
    expect(review.assistedCompletions, 1);
    expect(review.attempts, 2);
    expect(review.successes, 1);
    expect(review.stage, 1);
    expect(await api.sync(), true);
    expect(LocalGameArchive.games, hasLength(1));
  });

  test(
    'late response after switching accounts cannot restore old account data',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final api = PersonalMistakeBackup(
        client: MockClient((request) async {
          entered.complete();
          await release.future;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': '${playedAt.millisecondsSinceEpoch}-1',
                  'game': game.toJson(),
                  'practice': null,
                },
              ],
            }),
            200,
          );
        }),
      );
      final pending = api.sync();
      await entered.future;
      await login(account: 'b');
      release.complete();
      expect(await pending, false);
      expect(LocalGameArchive.games, isEmpty);
      expect(await progress.readMistakeReviews(), isEmpty);
    },
  );

  test('offline failure preserves local games and retry succeeds', () async {
    var offline = true;
    final api = PersonalMistakeBackup(
      client: MockClient((request) async {
        if (offline) throw Exception('offline');
        return http.Response(request.body, 200);
      }),
    );
    await LocalGameArchive.restoreMistakeGames(identity, [game]);
    expect(await api.sync(), false);
    expect(MistakeBank.all(LocalGameArchive.games), hasLength(1));
    offline = false;
    expect(await api.sync(), true);
  });

  test('saved archive still reloads after background decoding', () async {
    await LocalGameArchive.restoreMistakeGames(identity, [game]);
    await LocalGameArchive.init();
    expect(LocalGameArchive.games.single.toJson(), game.toJson());
    expect(MistakeBank.all(LocalGameArchive.games), hasLength(1));
  });

  test('concurrent restored progress and a new practice attempt retain both', () async {
    final old = await progress.recordMistakeReview('1-1', true, now: playedAt);
    await Future.wait([
      progress.mergeMistakeReviewsFor(identity, {'1-1': old}),
      progress.recordMistakeReview('2-1', true, now: playedAt),
    ]);
    expect((await progress.readMistakeReviews()).keys.toSet(), {'1-1', '2-1'});
  });

  test('guest practice is never uploaded as an account backup', () async {
    await login(guest: true);
    final api = PersonalMistakeBackup(
      client: MockClient((request) async {
        fail('Guest data must not be uploaded');
      }),
    );
    expect(await api.sync(), false);
  });

  test(
    'stale restored progress cannot replace a newer local attempt',
    () async {
      final old = await progress.recordMistakeReview(
        '1-1',
        true,
        now: playedAt,
      );
      final recent = await progress.recordMistakeReview(
        '1-1',
        false,
        now: playedAt.add(const Duration(days: 2)),
      );
      await progress.mergeMistakeReviewsFor(identity, {'1-1': old});
      expect(
        (await progress.readMistakeReviews())['1-1']!.toJson(),
        recent.toJson(),
      );
    },
  );
}
