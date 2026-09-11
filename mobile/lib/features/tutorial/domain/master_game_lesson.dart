enum MasterThinkingStyle { attack, calculation, endurance }

class MasterGameLesson {
  const MasterGameLesson({
    required this.id,
    required this.white,
    required this.black,
    required this.event,
    required this.year,
    required this.result,
    required this.moveNumber,
    required this.sideToMove,
    required this.question,
    required this.choices,
    required this.answer,
    required this.idea,
    required this.continuation,
    required this.style,
    required this.sourceLabel,
    required this.fen,
    required this.masterFrom,
    required this.masterTo,
  });

  final String id;
  final String white;
  final String black;
  final String event;
  final int year;
  final String result;
  final int moveNumber;
  final String sideToMove;
  final String question;
  final List<String> choices;
  final String answer;
  final String idea;
  final List<String> continuation;
  final MasterThinkingStyle style;
  final String sourceLabel;
  final String fen;
  final String masterFrom;
  final String masterTo;

  bool isCorrect(String move) => move == answer;
}

abstract final class MasterGameCatalog {
  static const List<MasterGameLesson> lessons = <MasterGameLesson>[
    MasterGameLesson(
      id: 'kasparov-topalov-1999',
      white: 'Garry Kasparov',
      black: 'Veselin Topalov',
      event: 'Hoogovens Wijk aan Zee',
      year: 1999,
      result: '1–0',
      moveNumber: 24,
      sideToMove: 'White',
      question: 'The black king looks protected. Which move begins the legendary king hunt?',
      choices: <String>['24. Rxd4!!', '24. h4', '24. Qd2'],
      answer: '24. Rxd4!!',
      idea: 'Kasparov gives up a rook to drag Black’s pieces away, open lines, and keep the king under forcing checks. Calculate the opponent’s replies—not the material count alone.',
      continuation: <String>['24.Rxd4!', 'cxd4', '25.Re7+', 'Kb6', '26.Qxd4+'],
      style: MasterThinkingStyle.attack,
      sourceLabel: 'Hoogovens 1999 · Round 4',
      fen: 'b2r3r/k4p1p/p2q1np1/NppP4/3p1Q2/P4PPB/1PP4P/1K1RR3 w - - 1 24',
      masterFrom: 'd1',
      masterTo: 'd4',
    ),
    MasterGameLesson(
      id: 'aronian-anand-2013',
      white: 'Levon Aronian',
      black: 'Viswanathan Anand',
      event: 'Tata Steel Wijk aan Zee',
      year: 2013,
      result: '0–1',
      moveNumber: 12,
      sideToMove: 'Black',
      question: 'White has aimed a knight at the king. How did Anand seize the initiative in the centre?',
      choices: <String>['12…c5!', '12…h6', '12…Be7'],
      answer: '12…c5!',
      idea: 'Anand answers a wing threat with a central break. The move activates every black piece and makes White calculate concrete consequences immediately.',
      continuation: <String>['12…c5!', '13.Nxh7', 'Ng4', '14.f4', 'cxd4'],
      style: MasterThinkingStyle.calculation,
      sourceLabel: 'Tata Steel 2013 · Round 4',
      fen:
          '2rq1rk1/pb1n1ppp/2pbpn2/1p4N1/3P4/P1NBP3/1PQ2PPP/R1B2RK1 b - - 2 12',
      masterFrom: 'c6',
      masterTo: 'c5',
    ),
    MasterGameLesson(
      id: 'carlsen-nepomniachtchi-2021',
      white: 'Magnus Carlsen',
      black: 'Ian Nepomniachtchi',
      event: 'FIDE World Championship · Game 6',
      year: 2021,
      result: '1–0',
      moveNumber: 80,
      sideToMove: 'White',
      question: 'After hours of play, which practical decision reshaped the material and kept the winning attempt alive?',
      choices: <String>['80. Rxf7+!', '80. Kg3', '80. Ra2'],
      answer: '80. Rxf7+!',
      idea: 'Carlsen exchanges a rook for bishop and pawns, choosing an unusual imbalance that is difficult to defend. Endurance chess means creating fresh problems without losing control.',
      continuation: <String>['80.Rxf7+!', 'Kxf7', '81.Rb7+', 'Kg6', '82.Rxa7'],
      style: MasterThinkingStyle.endurance,
      sourceLabel: 'Dubai 2021 · 136 moves',
      fen: '8/b4pk1/8/1R3R1p/5P2/3qP1P1/4NK2/8 w - - 1 80',
      masterFrom: 'f5',
      masterTo: 'f7',
    ),
    MasterGameLesson(
      id: 'morphy-opera-1858',
      white: 'Paul Morphy',
      black: 'Duke Karl & Count Isouard',
      event: 'Paris Opera House',
      year: 1858,
      result: '1–0',
      moveNumber: 1,
      sideToMove: 'White',
      question: 'Which first move begins Morphy’s famous lesson in rapid development?',
      choices: <String>['1. e4', '1. a3', '1. h4'],
      answer: '1. e4',
      idea: 'Morphy claims the centre first, then develops every piece with tempo. The Opera Game is memorable because speed of development—not an early pawn hunt—opens the decisive lines.',
      continuation: <String>['1.e4', 'e5', '2.Nf3', 'd6', '3.d4'],
      style: MasterThinkingStyle.attack,
      sourceLabel: 'Paris 1858 · The Opera Game · 17 moves',
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      masterFrom: 'e2',
      masterTo: 'e4',
    ),
    MasterGameLesson(
      id: 'byrne-fischer-1956',
      white: 'Donald Byrne',
      black: 'Bobby Fischer',
      event: 'Rosenwald Memorial',
      year: 1956,
      result: '0–1',
      moveNumber: 1,
      sideToMove: 'White',
      question: 'How did Byrne begin the game that became Fischer’s Game of the Century?',
      choices: <String>['1. Nf3', '1. e4', '1. b4'],
      answer: '1. Nf3',
      idea: 'The quiet Réti start became a tactical classic. Fischer’s later queen sacrifice worked because his minor pieces arrived with forcing tempo and coordinated around the exposed king.',
      continuation: <String>['1.Nf3', 'Nf6', '2.c4', 'g6', '3.Nc3'],
      style: MasterThinkingStyle.calculation,
      sourceLabel: 'New York 1956 · Game of the Century · 41 moves',
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      masterFrom: 'g1',
      masterTo: 'f3',
    ),
    MasterGameLesson(
      id: 'kasparov-anand-1995-game10',
      white: 'Garry Kasparov',
      black: 'Viswanathan Anand',
      event: 'PCA World Championship · Game 10',
      year: 1995,
      result: '1–0',
      moveNumber: 1,
      sideToMove: 'White',
      question: 'Which central move opened Kasparov’s immediate comeback in match game 10?',
      choices: <String>['1. e4', '1. c4', '1. g3'],
      answer: '1. e4',
      idea: 'Kasparov chose an open king-pawn battle after losing game nine. His preparation in the Open Ruy Lopez shows how opening knowledge must serve an active middlegame plan.',
      continuation: <String>['1.e4', 'e5', '2.Nf3', 'Nc6', '3.Bb5'],
      style: MasterThinkingStyle.calculation,
      sourceLabel: 'New York 1995 · Match Game 10 · 38 moves',
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      masterFrom: 'e2',
      masterTo: 'e4',
    ),
    MasterGameLesson(
      id: 'capablanca-marshall-1918',
      white: 'José Raúl Capablanca',
      black: 'Frank Marshall',
      event: 'Manhattan Chess Club',
      year: 1918,
      result: '1–0',
      moveNumber: 1,
      sideToMove: 'White',
      question: 'Which move began Capablanca’s historic defence against Marshall’s prepared attack?',
      choices: <String>['1. e4', '1. d4', '1. f4'],
      answer: '1. e4',
      idea: 'Capablanca accepted a dangerous prepared gambit and defended through calm development, accurate exchanges, and king safety. Great defence begins before the attack becomes visible.',
      continuation: <String>['1.e4', 'e5', '2.Nf3', 'Nc6', '3.Bb5'],
      style: MasterThinkingStyle.endurance,
      sourceLabel: 'New York 1918 · Birth of the Marshall Attack',
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      masterFrom: 'e2',
      masterTo: 'e4',
    ),
  ];

  static MasterGameLesson byId(String id) =>
      lessons.firstWhere((MasterGameLesson lesson) => lesson.id == id);

  static Map<String, String> piecesFromFen(String fen) {
    final List<String> ranks = fen.split(' ').first.split('/');
    if (ranks.length != 8) throw const FormatException('Invalid FEN ranks');
    final Map<String, String> result = <String, String>{};
    for (int row = 0; row < 8; row++) {
      int file = 0;
      for (final int rune in ranks[row].runes) {
        final String token = String.fromCharCode(rune);
        final int? empty = int.tryParse(token);
        if (empty != null) {
          file += empty;
        } else {
          if (file >= 8) throw const FormatException('Invalid FEN file');
          result['${String.fromCharCode(97 + file)}${8 - row}'] = token;
          file++;
        }
      }
      if (file != 8) throw const FormatException('Invalid FEN width');
    }
    return result;
  }
}
