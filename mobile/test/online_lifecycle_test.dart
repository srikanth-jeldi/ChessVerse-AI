import 'package:chessverse_ai/features/online/data/online_match_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('online match parses authoritative lifecycle state', () {
    final OnlineMatchDto match = OnlineMatchDto.fromJson(
      <String, dynamic>{
        'id': 'match-1',
        'roomCode': 'CV1234',
        'status': 'finished',
        'yourColor': 'black',
        'activeColor': 'white',
        'whiteTimeMs': 1200,
        'blackTimeMs': 3400,
        'serverNow': '2026-07-30T10:00:00Z',
        'turnStartedAt': '2026-07-30T09:59:58Z',
        'result': '0-1',
        'resultReason': 'RESIGNATION',
        'drawOfferedByColor': null,
        'rematchRequestedByYou': true,
        'rematchMatchId': 'match-2',
        'createdAt': '2026-07-30T09:40:00Z',
        'startedAt': '2026-07-30T09:42:00Z',
        'finishedAt': '2026-07-30T10:00:00Z',
        'durationSeconds': 1080,
        'updatedAt': '2026-07-30T10:00:01Z',
        'moves': <Map<String, dynamic>>[
          <String, dynamic>{'ply': 1, 'uci': 'E2E4'},
        ],
      },
    );

    expect(match.status, 'FINISHED');
    expect(match.yourColor, 'BLACK');
    expect(match.whiteTimeMs, 1200);
    expect(match.blackTimeMs, 3400);
    expect(match.result, '0-1');
    expect(match.resultReason, 'RESIGNATION');
    expect(match.scoreLabel, '0 - 1');
    expect(match.rematchRequestedByYou, isTrue);
    expect(match.rematchMatchId, 'match-2');
    expect(match.startedAt, DateTime.utc(2026, 7, 30, 9, 42));
    expect(match.finishedAt, DateTime.utc(2026, 7, 30, 10));
    expect(match.durationSeconds, 1080);
    expect(match.moves.single.uci, 'e2e4');
    expect(match.whiteToMove, isTrue);
    expect(match.isYourTurn, isFalse);
  });

  test('older server responses keep safe lifecycle defaults', () {
    const OnlineMatchDto match = OnlineMatchDto(
      id: 'match-legacy',
      roomCode: 'OLD123',
      status: 'WAITING',
      yourColor: 'WHITE',
      activeColor: 'WHITE',
      whitePlayerName: 'You',
      blackPlayerName: null,
      fen: '',
      moves: <OnlineMoveDto>[],
    );

    expect(match.whiteTimeMs, 600000);
    expect(match.blackTimeMs, 600000);
    expect(match.rematchRequestedByYou, isFalse);
    expect(match.result, isNull);
    expect(match.scoreLabel, isEmpty);
  });

  test('black turn is derived from authoritative activeColor, not ply parity',
      () {
    final OnlineMatchDto match = OnlineMatchDto.fromJson(
      <String, dynamic>{
        'id': 'match-black-turn',
        'roomCode': 'CVBLK1',
        'status': 'ACTIVE',
        'yourColor': 'black',
        'activeColor': 'black',
        'whitePlayerName': 'White',
        'blackPlayerName': 'Black',
        'fen': 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
        'moves': <Map<String, dynamic>>[
          <String, dynamic>{'ply': 0, 'uci': 'e2e4'},
        ],
      },
    );

    expect(match.whiteToMove, isFalse);
    expect(match.isYourTurn, isTrue);
    expect(match.blackTimeMs, 600000);
  });
}
