import 'package:chessverse_ai/features/analysis/data/ai_coach_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses session memory, candidate comparisons and board annotations',
      () {
    final AiCoachAnswer answer = AiCoachAnswer.fromJson(<String, dynamic>{
      'interactionId': 'interaction-1',
      'sessionId': 'session-1',
      'answer': 'Develop the knight and meet the central threat.',
      'remainingToday': 27,
      'cacheHit': true,
      'conversationTurns': 3,
      'comparisons': <Map<String, dynamic>>[
        <String, dynamic>{
          'move': 'g1f3',
          'classification': 'Best',
          'centipawnLoss': 0,
        },
        <String, dynamic>{
          'move': 'f2f3',
          'classification': 'Blunder',
          'centipawnLoss': 286,
        },
      ],
      'annotations': <Map<String, dynamic>>[
        <String, dynamic>{
          'from': 'g1',
          'to': 'f3',
          'kind': 'best',
          'label': 'Best move',
        },
        <String, dynamic>{
          'from': 'd8',
          'to': 'h4',
          'kind': 'threat',
          'label': 'Opponent threat',
        },
      ],
    });

    expect(answer.sessionId, 'session-1');
    expect(answer.conversationTurns, 3);
    expect(answer.cacheHit, isTrue);
    expect(answer.comparisons, hasLength(2));
    expect(answer.comparisons.last.centipawnLoss, 286);
    expect(answer.annotations, hasLength(2));
    expect(answer.annotations.last.kind, 'threat');
    expect(answer.annotations.last.from, 'd8');
    expect(answer.annotations.last.to, 'h4');
  });

  test('keeps backward-compatible defaults for older coach responses', () {
    final AiCoachAnswer answer = AiCoachAnswer.fromJson(<String, dynamic>{
      'interactionId': 'interaction-2',
      'sessionId': 'session-2',
      'answer': 'Keep calculating forcing moves.',
      'remainingToday': 10,
    });

    expect(answer.cacheHit, isFalse);
    expect(answer.conversationTurns, 1);
    expect(answer.comparisons, isEmpty);
    expect(answer.annotations, isEmpty);
  });
}
