enum BlindfoldExerciseType { squareColour, knightPath, positionMemory }

class BlindfoldExercise {
  const BlindfoldExercise({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
    this.pieces = const <String, String>{},
  });

  final String id;
  final BlindfoldExerciseType type;
  final String prompt;
  final List<String> options;
  final String answer;
  final String explanation;
  final Map<String, String> pieces;

  bool isCorrect(String value) => value == answer;
}

abstract final class BlindfoldCatalog {
  static const List<BlindfoldExercise> exercises = <BlindfoldExercise>[
    BlindfoldExercise(
      id: 'colour-e4',
      type: BlindfoldExerciseType.squareColour,
      prompt: 'Without looking at pieces: what colour is e4?',
      options: <String>['Light', 'Dark'],
      answer: 'Light',
      explanation: 'a1 is dark and colours alternate. e4 has an odd file-plus-rank total, so it is light.',
    ),
    BlindfoldExercise(
      id: 'knight-f3',
      type: BlindfoldExerciseType.knightPath,
      prompt: 'Picture a knight on f3. Which square can it reach?',
      options: <String>['f5', 'e5', 'e4'],
      answer: 'e5',
      explanation: 'A knight changes one file and two ranks, or two files and one rank. f3 to e5 is a legal L-jump.',
    ),
    BlindfoldExercise(
      id: 'memory-f3',
      type: BlindfoldExerciseType.positionMemory,
      prompt: 'After the pieces disappear, where was the white knight?',
      options: <String>['c3', 'f3', 'g1'],
      answer: 'f3',
      explanation: 'The knight was developed on f3, in front of the king-side starting position.',
      pieces: <String, String>{
        'g1': '♔',
        'd1': '♕',
        'f3': '♘',
        'g8': '♚',
        'a8': '♜',
      },
    ),
  ];

  static bool isLightSquare(String square) {
    final int file = square.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1;
    final int rank = int.parse(square[1]);
    return (file + rank).isOdd;
  }

  static Set<String> knightTargets(String square) {
    final int file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final int rank = int.parse(square[1]) - 1;
    const List<(int, int)> jumps = <(int, int)>[
      (1, 2),
      (2, 1),
      (-1, 2),
      (-2, 1),
      (1, -2),
      (2, -1),
      (-1, -2),
      (-2, -1),
    ];
    return <String>{
      for (final (int, int) jump in jumps)
        if (file + jump.$1 >= 0 &&
            file + jump.$1 < 8 &&
            rank + jump.$2 >= 0 &&
            rank + jump.$2 < 8)
          '${String.fromCharCode('a'.codeUnitAt(0) + file + jump.$1)}${rank + jump.$2 + 1}',
    };
  }
}
