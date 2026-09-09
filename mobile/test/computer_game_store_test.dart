import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chessverse_ai/core/computer_game_store.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

ComputerGameDraft draft(String id) =>
    ComputerGameDraft(id: id, updatedAt: DateTime.utc(2026, 9, 9), state: {
      'version': 1,
      'pieces': {'e1': 'wK', 'e8': 'bK'},
      'moves': <String>[],
      'humanWhite': true,
      'level': 4,
      'whiteSeconds': 600,
      'blackSeconds': 600,
      'whiteName': 'Player',
      'blackName': 'Computer',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, Map<String, dynamic>> accounts;
  setUp(() {
    accounts = {};
    ComputerGameStore.client = MockClient((request) async {
      final owner = request.headers['Authorization']!;
      final slot =
          accounts.putIfAbsent(owner, () => {'revision': 0, 'draft': null});
      if (request.method != 'GET') {
        final body = jsonDecode(request.body) as Map;
        if (slot['revision'] != body['revision']) return http.Response('', 409);
        slot['revision'] = (slot['revision'] as int) + 1;
        slot['draft'] =
            request.url.path.endsWith('/finish') ? null : body['draft'];
      }
      return http.Response(jsonEncode(slot), 200);
    });
  });
  test('round trips position and turn data', () {
    final original = draft('one');
    final loaded =
        ComputerGameDraft.fromJson(jsonDecode(jsonEncode(original.toJson())));
    expect(loaded.state, original.state);
    expect(loaded.updatedAt, original.updatedAt);
  });
  test('single slot replacement keeps accounts isolated', () async {
    await ComputerGameStore.prepare('alice', null);
    await ComputerGameStore.save('alice', draft('one'));
    expect(await ComputerGameStore.load('bob'), isEmpty);
    await ComputerGameStore.prepare('alice', null, replacing: draft('one'));
    await ComputerGameStore.save('alice', draft('two'));
    expect((await ComputerGameStore.load('alice')).single.id, 'two');
  });
  test('stale confirmation does not delete newer game', () async {
    await ComputerGameStore.prepare('alice', null);
    await ComputerGameStore.save('alice', draft('one'));
    accounts['Bearer alice']!['draft'] = draft('other-device').toJson();
    await expectLater(
        ComputerGameStore.prepare('alice', null, replacing: draft('one')),
        throwsA(isA<ComputerGameConflict>()));
    expect((await ComputerGameStore.load('alice')).single.id, 'other-device');
  });
  test('stale device save cannot overwrite claimed slot', () async {
    await ComputerGameStore.prepare('alice', null);
    accounts['Bearer alice']!['revision'] = 999;
    await expectLater(ComputerGameStore.save('alice', draft('one')),
        throwsA(isA<ComputerGameConflict>()));
  });
  test('queued saves preserve order; finish clears only unfinished slot',
      () async {
    await ComputerGameStore.prepare('alice', null);
    await Future.wait([
      ComputerGameStore.save('alice', draft('one')),
      ComputerGameStore.save('alice', draft('two'))
    ]);
    expect((await ComputerGameStore.load('alice')).single.id, 'two');
    await ComputerGameStore.finish('alice', draft('two'));
    expect(await ComputerGameStore.load('alice'), isEmpty);
  });
  test('network errors are not reported as an empty saved game', () async {
    ComputerGameStore.client = MockClient((_) async => http.Response('', 503));
    await expectLater(ComputerGameStore.load('alice'), throwsStateError);
  });

  test('history never imports device games into the active account', () async {
    FlutterSecureStorage.setMockInitialValues({});
    LocalGameArchive.addGame(SavedGameRecord(
      mode: 'Play vs AI', result: 'White wins', detail: '', moves: const [],
      playedAt: DateTime.utc(2026), whitePlayer: 'Kamal', blackPlayer: 'Computer',
    ));
    final requests = <http.Request>[];
    ComputerGameStore.client = MockClient((request) async {
      requests.add(request);
      return http.Response(jsonEncode([
        draft('legacy-unverified').toJson(), draft('owned-by-guest').toJson(),
      ]), 200);
    });
    final games = await ComputerGameStore.history('guest-token');
    expect(games.map((g) => g.id), ['owned-by-guest']);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(requests.single.headers['Authorization'], 'Bearer guest-token');
    await LocalGameArchive.clearDeviceUserData();
  });
}
