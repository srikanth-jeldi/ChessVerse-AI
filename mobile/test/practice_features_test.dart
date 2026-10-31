import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/domain/daily_routine.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_weaknesses.dart';
import 'package:chessverse_ai/features/tutorial/domain/opening_repertoire.dart';
import 'package:chessverse_ai/features/online/data/public_game_import.dart';
import 'package:chessverse_ai/features/puzzles/domain/puzzle_catalog.dart';

void main() {
  for (final line in openingRepertoire) {
    for (final white in [true, false]) {
      test('${line.name} legal line and practice as $white', () {
        expect(line.positions.length, line.moves.length + 1);
        final practice = OpeningPractice(line, playWhite: white);
        final before = practice.fen;
        expect(practice.tryMove('a1a8'), false);
        expect(practice.fen, before);
        var turns = 0;
        while (!practice.complete && turns < 20) {
          expect(practice.ply.isEven, white);
          expect(practice.tryMove(practice.expected!), true);
          turns++;
        }
        expect(practice.complete, true);
        expect(turns, 5);
        expect(practice.tryMove('e2e4'), false);
      });
    }
  }
  test('new users get honest starter plan and unsolved real puzzles', () {
    final solved = {PuzzleCatalog.all.first.id};
    final plan = DailyRoutine.create([], solved, DateTime.utc(2026, 10, 29));
    expect(plan.personalised, false);
    expect(plan.mistakes, isEmpty);
    expect(plan.puzzles.length, 3);
    expect(plan.puzzles.any(solved.contains), false);
    expect(DailyRoutine.fromJson(plan.toJson()).puzzles, plan.puzzles);
  });
  test(
    'own recent endgame evidence personalises plan, opponent data does not',
    () {
      final now = DateTime.utc(2026, 10, 29);
      SavedGameRecord game(String scope) => SavedGameRecord(
        mode: 'Computer',
        result: '0-1',
        detail: '',
        moves: ['e2e4'],
        playedAt: now,
        whitePlayer: 'You',
        blackPlayer: 'AI',
        reviewScope: scope,
        playerSide: 'white',
        moveReviews: [
          SavedMoveReview.fromJson({
            'ply': 1,
            'fenBefore': '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1',
            'playedMove': 'e3d3',
            'bestMove': 'e3d4',
            'classification': 'Blunder',
            'coachingTheme': 'endgame',
            'centipawnLoss': 400,
          }),
        ],
      );
      final plan = DailyRoutine.create([game('player')], {}, now);
      expect(plan.focus, MistakeCategory.endgame);
      expect(plan.mistakes.length, 1);
      expect(
        DailyRoutine.create([game('opponent')], {}, now).personalised,
        false,
      );
      expect(
        DailyRoutine.create(
          [game('player')],
          {},
          now.add(const Duration(days: 31)),
        ).personalised,
        false,
      );
    },
  );
  test('URL variants match without permitting arbitrary hosts', () {
    for (final path in [
      'game/live/123',
      'analysis/game/live/123',
      'live/game/123',
    ]) {
      expect(
        PublicGameImport.gameKey('https://www.chess.com/$path?tab=review'),
        'live/123',
      );
    }
    for (final link in [
      'http://chess.com/game/live/123',
      'https://chess.com.evil.com/game/live/123',
      'https://user@chess.com/game/live/123',
      'https://localhost/game/live/123',
      'https://chess.com/game/live/123/extra',
    ]) {
      expect(() => PublicGameImport.gameKey(link), throwsFormatException);
    }
  });
  test(
    'public archive picks exact finished game and checks player/month path',
    () async {
      final api = PublicGameImport(
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://api.chess.com/pub/player/player-one/games/2026/09',
          );
          return http.Response(
            jsonEncode({
              'games': [
                {
                  'url': 'https://www.chess.com/game/live/124',
                  'rules': 'chess',
                  'pgn': 'WRONG',
                },
                {
                  'url': 'https://www.chess.com/game/live/123',
                  'rules': 'chess',
                  'pgn': '[Event "Test"]\n1. e4 e5 1/2-1/2',
                },
              ],
            }),
            200,
          );
        }),
      );
      final result = await api.fetch(
        link: 'https://www.chess.com/analysis/game/live/123',
        username: 'Player-One',
        month: DateTime(2026, 9),
      );
      expect(result, contains('1. e4 e5'));
      api.close();
    },
  );
  for (final status in [404, 429, 500, 302]) {
    test('import handles HTTP $status without false success', () async {
      final api = PublicGameImport(
        client: MockClient((_) async => http.Response('', status)),
      );
      await expectLater(
        api.fetch(
          link: 'https://www.chess.com/game/live/1',
          username: 'player',
          month: DateTime(2026, 9),
        ),
        throwsFormatException,
      );
      api.close();
    });
  }
}
