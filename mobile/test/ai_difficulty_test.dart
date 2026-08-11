import 'dart:math' as math;

import 'package:chessverse_ai/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('beginner thinks more slowly than grandmaster', () {
    expect(aiThinkDelayFor(1), greaterThan(aiThinkDelayFor(10)));
  });

  test('beginner explores weak moves while grandmaster stays best', () {
    final List<AiCandidate> candidates = List<AiCandidate>.generate(
      20,
      (int index) => AiCandidate('a1', 'a${index + 1}', 100 - index.toDouble()),
    );
    final math.Random beginnerRandom = math.Random(7);
    final Set<AiCandidate> beginnerChoices = <AiCandidate>{
      for (int index = 0; index < 80; index++)
        chooseAiCandidateForLevel(candidates, 1, beginnerRandom),
    };

    expect(beginnerChoices.length, greaterThan(10));
    expect(beginnerChoices.any((AiCandidate move) => move.score < 90), isTrue);
    expect(
      chooseAiCandidateForLevel(candidates, 10, math.Random(1)),
      same(candidates.first),
    );
  });

  test('remote engine strength is progressively applied by level', () {
    final List<AiCandidate> candidates = <AiCandidate>[
      const AiCandidate('a1', 'a2', 10),
      const AiCandidate('b1', 'b2', 1),
    ];
    const AiCandidate engineMove = AiCandidate('h8', 'h1', 1000);

    expect(
      chooseAiCandidateForLevel(
        candidates,
        1,
        math.Random(3),
        engineMove: engineMove,
      ),
      isNot(same(engineMove)),
    );
    final int intermediateEngineMoves = List<AiCandidate>.generate(
      200,
      (int index) => chooseAiCandidateForLevel(
        candidates,
        4,
        math.Random(index),
        engineMove: engineMove,
      ),
    ).where((AiCandidate move) => identical(move, engineMove)).length;
    expect(intermediateEngineMoves, inInclusiveRange(45, 95));
    expect(
      chooseAiCandidateForLevel(
        candidates,
        10,
        math.Random(3),
        engineMove: engineMove,
      ),
      same(engineMove),
    );
  });

  test('difficulty profiles expose a monotonic strength curve', () {
    for (int level = 1; level < 10; level++) {
      expect(
        aiProfileFor(level).engineMoveProbability,
        lessThan(aiProfileFor(level + 1).engineMoveProbability),
      );
      expect(
        aiProfileFor(level).mistakeProbability,
        greaterThan(aiProfileFor(level + 1).mistakeProbability),
      );
    }
  });
}
