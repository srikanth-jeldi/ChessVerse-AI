import 'package:flutter/material.dart';

enum AcademyStage { foundation, safety, tactics, endgame }

@immutable
class AcademyPiece {
  const AcademyPiece(this.symbol, {required this.white});

  final String symbol;
  final bool white;
}

@immutable
class AcademyLesson {
  const AcademyLesson({
    required this.id,
    required this.title,
    required this.stage,
    required this.eyebrow,
    required this.explanation,
    required this.coachPrompt,
    required this.successMessage,
    required this.pieces,
    required this.from,
    required this.to,
    this.path = const <String>[],
    this.highlighted = const <String>[],
  });

  final String id;
  final String title;
  final AcademyStage stage;
  final String eyebrow;
  final String explanation;
  final String coachPrompt;
  final String successMessage;
  final Map<String, AcademyPiece> pieces;
  final String from;
  final String to;
  final List<String> path;
  final List<String> highlighted;
}

abstract final class AcademyCatalog {
  static const AcademyPiece whiteKing = AcademyPiece('K', white: true);
  static const AcademyPiece whiteQueen = AcademyPiece('Q', white: true);
  static const AcademyPiece whiteRook = AcademyPiece('R', white: true);
  static const AcademyPiece whiteBishop = AcademyPiece('B', white: true);
  static const AcademyPiece whiteKnight = AcademyPiece('N', white: true);
  static const AcademyPiece whitePawn = AcademyPiece('P', white: true);
  static const AcademyPiece blackKing = AcademyPiece('K', white: false);
  static const AcademyPiece blackQueen = AcademyPiece('Q', white: false);
  static const AcademyPiece blackRook = AcademyPiece('R', white: false);
  static const AcademyPiece blackPawn = AcademyPiece('P', white: false);

  static const List<AcademyLesson> lessons = <AcademyLesson>[
    AcademyLesson(
      id: 'board',
      title: 'Meet the chessboard',
      stage: AcademyStage.foundation,
      eyebrow: 'FILES, RANKS & SQUARES',
      explanation:
          'Every square has an address. Files use letters a-h and ranks use numbers 1-8.',
      coachPrompt: 'Move the highlighted rook from a1 to a8.',
      successMessage: 'Perfect. You travelled up the a-file from rank 1 to rank 8.',
      pieces: <String, AcademyPiece>{'a1': whiteRook, 'e1': whiteKing},
      from: 'a1',
      to: 'a8',
      path: <String>['a2', 'a3', 'a4', 'a5', 'a6', 'a7'],
      highlighted: <String>['a1', 'a8'],
    ),
    AcademyLesson(
      id: 'pawn',
      title: 'How pawns move',
      stage: AcademyStage.foundation,
      eyebrow: 'PAWN POWER',
      explanation:
          'A pawn moves straight ahead, normally one square. From its starting rank it may move two squares.',
      coachPrompt: 'Advance the pawn from e2 to e4.',
      successMessage: 'Great start. The two-square first move claims central space.',
      pieces: <String, AcademyPiece>{'e2': whitePawn, 'e8': blackKing},
      from: 'e2',
      to: 'e4',
      path: <String>['e3'],
      highlighted: <String>['e3', 'e4'],
    ),
    AcademyLesson(
      id: 'rook',
      title: 'Rooks and files',
      stage: AcademyStage.foundation,
      eyebrow: 'STRAIGHT-LINE FORCE',
      explanation:
          'A rook moves any number of clear squares horizontally or vertically. It cannot jump over another piece.',
      coachPrompt: 'Move the rook from a1 to a6.',
      successMessage: 'Excellent. The rook controls the entire open file.',
      pieces: <String, AcademyPiece>{'a1': whiteRook, 'h8': blackKing},
      from: 'a1',
      to: 'a6',
      path: <String>['a2', 'a3', 'a4', 'a5'],
      highlighted: <String>['a3', 'a6', 'd1'],
    ),
    AcademyLesson(
      id: 'bishop',
      title: 'Bishops and diagonals',
      stage: AcademyStage.foundation,
      eyebrow: 'DIAGONAL VISION',
      explanation:
          'A bishop glides diagonally and always stays on the same square colour.',
      coachPrompt: 'Develop the bishop from c1 to g5.',
      successMessage: 'Correct. The bishop crossed one long light-square diagonal.',
      pieces: <String, AcademyPiece>{'c1': whiteBishop, 'e8': blackKing},
      from: 'c1',
      to: 'g5',
      path: <String>['d2', 'e3', 'f4'],
      highlighted: <String>['c1', 'g5'],
    ),
    AcademyLesson(
      id: 'knight',
      title: 'The knight jump',
      stage: AcademyStage.foundation,
      eyebrow: 'THE L-SHAPED JUMP',
      explanation:
          'The knight moves two squares in one direction and one sideways. It is the only piece that jumps over pieces.',
      coachPrompt: 'Jump the knight from g1 to f3.',
      successMessage: 'Nice jump. The knight now attacks the central e5 and d4 squares.',
      pieces: <String, AcademyPiece>{
        'g1': whiteKnight,
        'f2': whitePawn,
        'g2': whitePawn,
        'h2': whitePawn,
        'e8': blackKing,
      },
      from: 'g1',
      to: 'f3',
      highlighted: <String>['e2', 'e3', 'f3', 'h3'],
    ),
    AcademyLesson(
      id: 'queen',
      title: 'Queen movement',
      stage: AcademyStage.foundation,
      eyebrow: 'THE MOST POWERFUL PIECE',
      explanation:
          'The queen combines rook and bishop movement: straight or diagonal across any clear distance.',
      coachPrompt: 'Move the queen diagonally from d1 to h5.',
      successMessage: 'Correct. From h5 the queen sees both the diagonal and the fifth rank.',
      pieces: <String, AcademyPiece>{'d1': whiteQueen, 'e8': blackKing},
      from: 'd1',
      to: 'h5',
      path: <String>['e2', 'f3', 'g4'],
      highlighted: <String>['d1', 'h5'],
    ),
    AcademyLesson(
      id: 'king',
      title: 'The king and legal moves',
      stage: AcademyStage.foundation,
      eyebrow: 'PROTECT THE KING',
      explanation:
          'The king moves one square in any direction, but may never move onto an attacked square.',
      coachPrompt: 'Move the king safely from e1 to f2.',
      successMessage: 'Safe move. Always check the opponent attacks before moving your king.',
      pieces: <String, AcademyPiece>{'e1': whiteKing, 'a8': blackKing},
      from: 'e1',
      to: 'f2',
      highlighted: <String>['d1', 'e2', 'f2'],
    ),
    AcademyLesson(
      id: 'capture',
      title: 'Captures and piece value',
      stage: AcademyStage.foundation,
      eyebrow: 'WIN MATERIAL',
      explanation:
          'Capture by moving onto an opponent piece. Compare value before every trade: queen 9, rook 5, bishop or knight 3, pawn 1.',
      coachPrompt: 'Use the bishop on c4 to capture the loose rook on f7.',
      successMessage: 'Strong capture. A bishop traded for a rook wins material.',
      pieces: <String, AcademyPiece>{
        'c4': whiteBishop,
        'f7': blackRook,
        'e1': whiteKing,
        'h8': blackKing,
      },
      from: 'c4',
      to: 'f7',
      path: <String>['d5', 'e6'],
      highlighted: <String>['f7'],
    ),
    AcademyLesson(
      id: 'check',
      title: 'Check and checkmate',
      stage: AcademyStage.safety,
      eyebrow: 'FORCING MOVES',
      explanation:
          'Check attacks the king. Checkmate is check with no legal escape, block, or capture.',
      coachPrompt: 'Give check by moving the rook from a1 to e1.',
      successMessage: 'Check! The rook now attacks the black king along the e-file.',
      pieces: <String, AcademyPiece>{'a1': whiteRook, 'g1': whiteKing, 'e8': blackKing},
      from: 'a1',
      to: 'e1',
      path: <String>['b1', 'c1', 'd1'],
      highlighted: <String>['e1', 'e8'],
    ),
    AcademyLesson(
      id: 'escape',
      title: 'Escaping from check',
      stage: AcademyStage.safety,
      eyebrow: 'THREE DEFENCES',
      explanation:
          'When checked, move the king, capture the attacker, or block the checking line.',
      coachPrompt: 'Escape the rook check by moving the king from e1 to f2.',
      successMessage: 'Safe escape. The king left the attacked e-file.',
      pieces: <String, AcademyPiece>{'e1': whiteKing, 'e8': blackRook, 'a8': blackKing},
      from: 'e1',
      to: 'f2',
      highlighted: <String>['d2', 'f2'],
    ),
    AcademyLesson(
      id: 'castle',
      title: 'Castling safely',
      stage: AcademyStage.safety,
      eyebrow: 'KING SAFETY IN ONE MOVE',
      explanation:
          'Castling moves the king two squares toward a rook, then places that rook beside the king.',
      coachPrompt: 'Castle kingside: move the king from e1 to g1.',
      successMessage: 'Castled. Your king is safer and the rook is activated.',
      pieces: <String, AcademyPiece>{'e1': whiteKing, 'h1': whiteRook, 'e8': blackKing},
      from: 'e1',
      to: 'g1',
      path: <String>['f1'],
      highlighted: <String>['e1', 'g1', 'h1'],
    ),
    AcademyLesson(
      id: 'knight-fork',
      title: 'Knight forks',
      stage: AcademyStage.tactics,
      eyebrow: 'ATTACK TWO PIECES',
      explanation:
          'A fork attacks multiple valuable targets at once. Knights are especially dangerous fork creators.',
      coachPrompt: 'Jump the knight from e5 to f7 and fork the king and queen.',
      successMessage: 'Brilliant fork. The king must respond, so the queen can be won next.',
      pieces: <String, AcademyPiece>{
        'e5': whiteKnight,
        'e8': blackKing,
        'h8': blackQueen,
        'e1': whiteKing,
      },
      from: 'e5',
      to: 'f7',
      highlighted: <String>['e5', 'f7', 'e8', 'h8'],
    ),
    AcademyLesson(
      id: 'back-rank',
      title: 'Back-rank mates',
      stage: AcademyStage.tactics,
      eyebrow: 'A CLASSIC MATING NET',
      explanation:
          'A king trapped behind its own pawns can be checkmated by a rook or queen on the back rank.',
      coachPrompt: 'Move the rook from a1 to e1 to deliver checkmate.',
      successMessage: 'Checkmate. The pawns take away every escape square.',
      pieces: <String, AcademyPiece>{
        'a1': whiteRook,
        'g1': whiteKing,
        'e8': blackKing,
        'd7': blackPawn,
        'e7': blackPawn,
        'f7': blackPawn,
      },
      from: 'a1',
      to: 'e1',
      path: <String>['b1', 'c1', 'd1'],
      highlighted: <String>['e1', 'e8'],
    ),
    AcademyLesson(
      id: 'promotion',
      title: 'Promoting a pawn',
      stage: AcademyStage.endgame,
      eyebrow: 'CREATE A NEW QUEEN',
      explanation:
          'When a pawn reaches the last rank it promotes, usually to a queen.',
      coachPrompt: 'Advance the pawn from e7 to e8 and promote.',
      successMessage: 'Promotion! Converting passed pawns is the heart of many endgames.',
      pieces: <String, AcademyPiece>{'e7': whitePawn, 'a1': whiteKing, 'h8': blackKing},
      from: 'e7',
      to: 'e8',
      highlighted: <String>['e7', 'e8'],
    ),
    AcademyLesson(
      id: 'queen-mate',
      title: 'Queen checkmates',
      stage: AcademyStage.endgame,
      eyebrow: 'SHRINK THE BOX',
      explanation:
          'The queen restricts the enemy king while your king approaches to support the final check.',
      coachPrompt: 'Move the queen from f6 to g7 for checkmate.',
      successMessage: 'Checkmate. Your king protects the queen and seals the escape squares.',
      pieces: <String, AcademyPiece>{'f6': whiteQueen, 'f7': whiteKing, 'h8': blackKing},
      from: 'f6',
      to: 'g7',
      highlighted: <String>['g7', 'h8'],
    ),
    AcademyLesson(
      id: 'ladder-mate',
      title: 'Rook ladder mate',
      stage: AcademyStage.endgame,
      eyebrow: 'TWO ROOKS WORK TOGETHER',
      explanation:
          'Two rooks can alternate checks, cutting off one rank at a time until the king reaches the edge.',
      coachPrompt: 'Move the rook from a6 to h6 for the final ladder check.',
      successMessage: 'Checkmate. The other rook blocks the entire seventh rank.',
      pieces: <String, AcademyPiece>{
        'a6': whiteRook,
        'a7': whiteRook,
        'e1': whiteKing,
        'h8': blackKing,
      },
      from: 'a6',
      to: 'h6',
      path: <String>['b6', 'c6', 'd6', 'e6', 'f6', 'g6'],
      highlighted: <String>['h6', 'h8'],
    ),
  ];

  static AcademyLesson forChapter(String chapter) {
    final String normalized = chapter.toLowerCase();
    for (final AcademyLesson lesson in lessons) {
      if (lesson.title.toLowerCase() == normalized) return lesson;
    }
    if (normalized.contains('pawn')) return lessons.firstWhere((l) => l.id == 'pawn');
    if (normalized.contains('rook')) return lessons.firstWhere((l) => l.id == 'rook');
    if (normalized.contains('bishop') || normalized.contains('diagonal')) {
      return lessons.firstWhere((l) => l.id == 'bishop');
    }
    if (normalized.contains('knight') || normalized.contains('fork')) {
      return lessons.firstWhere((l) => l.id == 'knight-fork');
    }
    if (normalized.contains('queen')) return lessons.firstWhere((l) => l.id == 'queen-mate');
    if (normalized.contains('mate') || normalized.contains('check')) {
      return lessons.firstWhere((l) => l.id == 'back-rank');
    }
    return lessons.first;
  }
}
