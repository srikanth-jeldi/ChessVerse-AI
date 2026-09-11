import 'package:flutter/material.dart';

enum AcademyStage { foundation, safety, tactics, endgame }

@immutable
class AcademyPiece {
  const AcademyPiece(this.symbol, {required this.white});

  final String symbol;
  final bool white;
}

@immutable
class AcademyDemoMove {
  const AcademyDemoMove(this.from, this.to);

  final String from;
  final String to;
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
    this.demoLine = const <AcademyDemoMove>[],
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
  final List<AcademyDemoMove> demoLine;

  List<AcademyDemoMove> get demonstrationLine => demoLine.isEmpty
      ? <AcademyDemoMove>[AcademyDemoMove(from, to)]
      : demoLine;

  /// ChessVerseAI's story layer. It turns a rule into a memorable scene while
  /// keeping the actual chess instruction precise and short enough for TTS.
  String get storyNarration =>
      _foundationStories[id] ??
      'Every position tells a story. Today, your mission is $title. '
          '$explanation Watch the idea, predict the move, and then prove it on the board.';

  String get storyChapter => _foundationChapterNames[id] ?? 'THE NEXT MOVE';

  bool get usesDecisionCheckpoint => stage != AcademyStage.foundation;

  String get decisionQuestion => switch (stage) {
    AcademyStage.safety =>
      'Before the coach moves: which square best protects the king?',
    AcademyStage.tactics => 'Before the coach moves: which candidate creates the strongest forcing idea?',
    AcademyStage.endgame => 'Before the coach moves: which candidate follows the key endgame principle?',
    AcademyStage.foundation => 'Which destination completes the mission?',
  };

  List<String> get decisionOptions {
    final List<String> distractors = highlighted
        .where((String square) => square != from && square != to)
        .toList();
    for (final String fallback in const <String>['e4', 'd4', 'f3', 'c3']) {
      if (fallback != from &&
          fallback != to &&
          !distractors.contains(fallback)) {
        distractors.add(fallback);
      }
    }
    final List<String> options = <String>[to, ...distractors.take(2)];
    final int rotation = id.codeUnits.fold<int>(0, (int a, int b) => a + b) % 3;
    return <String>[...options.skip(rotation), ...options.take(rotation)];
  }

  String get decisionInsight => switch (stage) {
    AcademyStage.safety =>
      '$to is the safest candidate because it answers the immediate danger before making a new threat.',
    AcademyStage.tactics =>
      '$to is strongest. First scan checks, captures, and threats; forcing moves reduce the opponent\'s choices.',
    AcademyStage.endgame =>
      '$to follows the position\'s essential endgame principle. Activity and precise king or pawn placement matter more than speed.',
    AcademyStage.foundation => '$to completes the move shown in this lesson.',
  };
}

const Map<String, String> _foundationChapterNames = <String, String>{
  'board': 'THE KINGDOM OF 64 SQUARES',
  'pawn': 'THE BRAVE FIRST STEP',
  'rook': 'THE CASTLE GUARDIAN',
  'bishop': 'THE DIAGONAL SCOUT',
  'knight': 'THE ROYAL JUMPER',
  'queen': 'THE KINGDOM\'S POWER',
  'king': 'THE CROWN TO PROTECT',
  'capture': 'THE FAIR EXCHANGE',
  'check': 'THE KING UNDER FIRE',
  'escape': 'THREE DOORS TO SAFETY',
  'castle': 'THE KING FINDS SHELTER',
  'knight-fork': 'ONE KNIGHT, TWO TARGETS',
  'back-rank': 'THE LOCKED CASTLE',
  'promotion': 'THE PAWN WHO BECAME A QUEEN',
  'queen-mate': 'THE QUEEN BUILDS A BOX',
  'ladder-mate': 'THE CLOSING WALLS',
  'en-passant': 'THE PASSING PAWN',
  'pin': 'THE PIECE THAT CANNOT MOVE',
  'skewer': 'THE VALUABLE TARGET STEPS ASIDE',
  'discovered-attack': 'THE HIDDEN LINE AWAKENS',
  'mate-one': 'THE FINAL MOVE',
  'opposition': 'THE BATTLE OF THE KINGS',
  'rook-king-mate': 'BUILDING THE ROOK CAGE',
  'stalemate': 'LEAVE ONE SAFE DOOR',
  'deflection': 'REMOVE THE GUARDIAN',
  'decoy': 'THE IRRESISTIBLE SQUARE',
  'mate-two': 'SEE THE END BEFORE IT BEGINS',
  'smothered-mate': 'THE KING TRAPPED BY ITS OWN ARMY',
  'bishop-knight-mate': 'THE TWO-PIECE CORNER NET',
  'king-shelter': 'BUILD THE PAWN SHIELD',
  'hanging-piece': 'THE UNGUARDED TARGET',
  'double-attack': 'ONE MOVE, TWO PROBLEMS',
  'remove-defender': 'CUT THE LAST SAFETY ROPE',
  'king-pawn-basics': 'ESCORT THE PASSED PAWN',
  'rook-ending': 'THE ACTIVE ROOK RULE',
  'opening-centre': 'CLAIM THE KINGDOM’S CROSSROADS',
  'opening-develop': 'AWAKEN THE SLEEPING ARMY',
  'opening-tempo': 'THE RACE FOR TIME',
  'opening-castle': 'THE KING ENTERS THE FORTRESS',
  'opening-rooks': 'THE GUARDIANS JOIN FORCES',
  'opening-checklist': 'READY FOR THE REAL BATTLE',
  'opening-italian': 'THE BISHOP EYES THE KING',
  'opening-ruy-lopez': 'THE SPANISH PIN',
  'opening-sicilian': 'THE ASYMMETRIC BATTLE',
  'opening-queens-gambit': 'OFFER A PAWN, WIN THE CENTRE',
  'opening-caro-kann': 'THE SOLID COUNTERSTRIKE',
  'opening-punish-queen': 'WIN TIME BY CHASING THE QUEEN',
  'plan-worst-piece': 'RESCUE THE FORGOTTEN KNIGHT',
  'plan-open-file': 'THE ROOK FINDS A HIGHWAY',
  'plan-weak-square': 'THE KNIGHT’S PERMANENT CAMP',
  'plan-pawn-break': 'BREAK THE WALL',
  'plan-prophylaxis': 'SEE THEIR PLAN FIRST',
  'plan-three-step': 'THE COMMANDER’S BLUEPRINT',
  'clock-budget': 'SPEND TIME WHERE IT MATTERS',
  'clock-forcing-scan': 'THE TEN-SECOND EMERGENCY SCAN',
  'clock-increment': 'BANK THE INCREMENT',
  'clock-safe-premove': 'PREMOVE WITHOUT GAMBLING',
};

const Map<String, String> _foundationStories = <String, String>{
  'board': 'Welcome to the Kingdom of 64 Squares. Every square has a secret address: a letter for its file and a number for its rank. Your rook is waiting at a1. Guide it through the a-file to a8 and begin your journey.',
  'pawn': 'At the front of the kingdom stands a brave pawn. It normally marches one square, but on its very first move it may charge two. Send the pawn from e2 to e4 to claim the centre.',
  'rook': 'The rook is the castle guardian. It patrols open ranks and files in perfectly straight lines, but no piece may block its road. Clear the route and guide it from a1 to a6.',
  'bishop': 'The bishop is a diagonal scout. It glides across one colour for its entire journey and never changes paths. Follow the light-square road from c1 to g5.',
  'knight': 'The knight is the kingdom\'s fearless jumper. While every other piece needs a clear road, the knight leaps over crowds in an L shape. Jump from g1 to f3 and aim toward the centre.',
  'queen': 'The queen carries the power of both rook and bishop. She can race straight or sweep diagonally, but even the strongest piece needs a clear path. Travel from d1 to h5.',
  'king': 'The king moves only one careful step, because the whole kingdom depends on his safety. Before moving, inspect every enemy attack. Find the safe square from e1 to f2.',
  'capture': 'A wise commander does not capture blindly. Pawns are worth one, bishops and knights three, rooks five, and queens nine. Let your bishop take the loose rook on f7 and win the exchange.',
  'check': 'The king is under fire, so every other plan must wait. Identify the checking line, then move with purpose: capture the attacker, block the attack, or escape to a safe square.',
  'escape': 'When check arrives, imagine three doors: capture, block, or move. Test each door against every enemy attack and choose the one that leaves the king completely safe.',
  'castle': 'The centre is opening and the king needs shelter. Castle before launching an attack, connecting the rook while moving the king away from dangerous central files.',
  'knight-fork': 'The knight slips between straight lines and attacks two valuable targets at once. Find the jumping square that checks the king while threatening the queen.',
  'back-rank': 'The king is trapped behind its own pawns. Open the rook’s highway, remove the last defender, and deliver the back-rank check that has no escape square.',
  'promotion': 'A lone pawn has crossed the entire battlefield. Support its final step, control the promotion square, and transform the smallest piece into a new queen.',
  'queen-mate': 'The queen cannot mate alone without the king’s help. Shrink the enemy king’s box one rank at a time, keep a knight’s distance, and avoid stalemate.',
  'ladder-mate': 'Two rooks become moving walls. One gives check while the other seals the next rank, forcing the king backward until the final wall closes.',
  'en-passant': 'An enemy pawn rushes two squares past your guard. For this move only, capture it as though it had advanced one square and remove it from the square it crossed.',
  'pin': 'A defender wants to move, but a more valuable piece stands behind it. Attack along the line and make movement impossible or painfully expensive.',
  'skewer': 'Attack the valuable piece first. When it steps away, the piece hiding behind it becomes yours; the order of the targets creates the tactic.',
  'discovered-attack': 'One friendly piece is blocking another’s power. Move the front piece with tempo and uncover the rook, bishop, or queen behind it.',
  'mate-one': 'There is no need for a long combination. Check every legal check, verify captures and escapes, then choose the single move that ends the game.',
  'opposition': 'The kings face each other with one square between them. Take the opposition and force the enemy king aside so your pawn can advance.',
  'rook-king-mate': 'The rook builds a cage while the king walks closer. Cut off a rank, protect the rook, and steadily squeeze the enemy king toward the edge.',
  'stalemate': 'A winning position can disappear if the enemy has no legal move. Before every final check or promotion, leave one safe door until checkmate is ready.',
  'deflection': 'A crucial defender is holding everything together. Force it away from its duty, then capture the piece or enter the square it was protecting.',
  'decoy': 'The target refuses to stand where your tactic works. Offer an irresistible capture that lures it onto the exact square your combination needs.',
  'mate-two': 'See the reply before making the first move. Begin with a forcing check or quiet threat, predict the only defence, and prepare the unavoidable mate.',
  'smothered-mate': 'The enemy king is sealed into the corner by its own rook and pawns. The knight needs no open line: jump from f7 to h6, attack h8, and let the crowded fortress become a prison with no escape.',
  'bishop-knight-mate': 'A bishop and knight can mate only in a corner matching the bishop’s colour. The king holds g8 and g7, the knight seals h7, and the bishop moves from f6 to g7 to close the final door on h8.',
  'king-shelter': 'A castled king still needs a strong roof. Keep the three shield pawns connected, close open files, and repair the square an enemy piece wants to enter.',
  'hanging-piece': 'Before attacking, count every defender. The enemy bishop has no protection; capture it cleanly and learn to scan for loose pieces before every move.',
  'double-attack': 'The strongest move gives the opponent two problems at once. Place the queen where it checks the king and attacks the loose rook on the same turn.',
  'remove-defender': 'One defender is holding the position together. Capture that guardian first, then the valuable piece behind it loses its final protection.',
  'king-pawn-basics': 'A passed pawn needs its king as an escort. Step in front of the pawn, win the key square, and create a safe road to promotion.',
  'rook-ending': 'Rooks belong behind passed pawns. Move behind the enemy pawn, attack it along the file, and keep your rook active instead of waiting passively.',
  'opening-centre': 'Four central squares are the crossroads of the kingdom. Send the e-pawn forward, claim space, and open roads for the queen and bishop.',
  'opening-develop': 'An army cannot win while sleeping on the back rank. Wake the knight, point it toward the centre, and prepare the king’s escape to safety.',
  'opening-tempo': 'The opening is a race where every move is a heartbeat. Bring a new bishop into battle instead of spending another heartbeat on an already active knight.',
  'opening-castle': 'The centre is about to open like a collapsing gate. Move the king into its fortress and bring the rook into action before the attack begins.',
  'opening-rooks': 'The two rook guardians are separated by their own army. Move the queen to a useful square, clear the final path, and let the guardians defend each other.',
  'opening-checklist': 'Before the real battle starts, inspect the kingdom: centre claimed, pieces awake, king safe, rooks connected. Develop the final bishop and complete the checklist.',
  'opening-italian': 'Both sides claim the centre and develop their knights. Now the Italian bishop enters on c4, watching the sensitive f7 square and preparing a fast castle. Remember the idea, not only the moves: centre, development, king safety.',
  'opening-ruy-lopez': 'After the kings pawns meet and both knights develop, the bishop travels to b5. This is the Ruy Lopez: the bishop questions the knight that protects e5 while White prepares to castle and build lasting central pressure.',
  'opening-sicilian': 'Black answers e4 from the flank with c5, creating an unbalanced Sicilian battle. White develops the knight, Black supports the centre, then d4 opens the position before Black can settle comfortably.',
  'opening-queens-gambit': 'White claims the centre with d4 and Black answers d5. The c-pawn now advances to c4, offering a temporary pawn to pull Black away from the centre. The real prize is space, development, and central control.',
  'opening-caro-kann': 'Black prepares a strong d5 counterstrike with c6. White builds the centre with e4 and d4, then Black challenges it directly. The Caro-Kann stays solid while keeping the light bishop free to develop.',
  'opening-punish-queen': 'Black brings the queen into the centre too early after the Scandinavian pawn exchange. Develop the b1 knight to c3 with an attack on the queen. You gain a useful piece and force the opponent to spend another move retreating.',
  'plan-worst-piece': 'One knight has been forgotten at the edge while every other piece has a job. Rescue it, give it a route toward the centre, and strengthen the whole army.',
  'plan-open-file': 'An open file is an empty highway into enemy territory. Put the rook on that road, seize the entrance, and prepare to invade the seventh rank.',
  'plan-weak-square': 'The enemy pawns can never chase a knight from e5. Establish a permanent camp there and turn one weak square into a base for the attack.',
  'plan-pawn-break': 'The pawn chains form a locked wall. Prepare the c-pawn, strike the base of the chain, and change the battlefield when your pieces are ready.',
  'plan-prophylaxis': 'A strong commander asks what the opponent wants before choosing a plan. Stop the bishop’s pin before it appears, then continue without carrying a hidden weakness.',
  'plan-three-step': 'Build the commander’s blueprint: choose the c7 pawn as the target, place the rook on the c-file, then prepare the pawn break that opens the road.',
  'clock-budget': 'Not every move deserves the same time. The position is calm, so develop the knight quickly and save your thinking budget for the first irreversible decision.',
  'clock-forcing-scan': 'With seconds left, do not calculate every legal move. Scan checks, captures, and threats in that order; the queen capture on h7 arrives with check and forces the reply.',
  'clock-increment': 'An increment is a tiny refill, not permission to panic. Make the safe king step, breathe while the clock adds time, and begin the next turn with a fresh scan.',
  'clock-safe-premove': 'A safe premove must remain legal and sensible against every likely reply. Choose the simple opening pawn move; never premove a capture when the target may disappear.',
};

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
  static const AcademyPiece blackBishop = AcademyPiece('B', white: false);
  static const AcademyPiece blackKnight = AcademyPiece('N', white: false);
  static const AcademyPiece blackPawn = AcademyPiece('P', white: false);

  static const List<AcademyLesson> lessons = <AcademyLesson>[
    AcademyLesson(
      id: 'board',
      title: 'Meet the chessboard',
      stage: AcademyStage.foundation,
      eyebrow: 'FILES, RANKS & SQUARES',
      explanation: 'Every square has an address. Files use letters a-h and ranks use numbers 1-8.',
      coachPrompt: 'Move the highlighted rook from a1 to a8.',
      successMessage:
          'Perfect. You travelled up the a-file from rank 1 to rank 8.',
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
      explanation: 'A pawn moves straight ahead, normally one square. From its starting rank it may move two squares.',
      coachPrompt: 'Advance the pawn from e2 to e4.',
      successMessage:
          'Great start. The two-square first move claims central space.',
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
      explanation: 'A rook moves any number of clear squares horizontally or vertically. It cannot jump over another piece.',
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
      explanation: 'A bishop glides diagonally and always stays on the same square colour.',
      coachPrompt: 'Develop the bishop from c1 to g5.',
      successMessage:
          'Correct. The bishop crossed one long light-square diagonal.',
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
      explanation: 'The knight moves two squares in one direction and one sideways. It is the only piece that jumps over pieces.',
      coachPrompt: 'Jump the knight from g1 to f3.',
      successMessage:
          'Nice jump. The knight now attacks the central e5 and d4 squares.',
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
      explanation: 'The queen combines rook and bishop movement: straight or diagonal across any clear distance.',
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
      explanation: 'The king moves one square in any direction, but may never move onto an attacked square.',
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
      explanation: 'Capture by moving onto an opponent piece. Compare value before every trade: queen 9, rook 5, bishop or knight 3, pawn 1.',
      coachPrompt: 'Use the bishop on c4 to capture the loose rook on f7.',
      successMessage:
          'Strong capture. A bishop traded for a rook wins material.',
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
      explanation: 'Check attacks the king. Checkmate is check with no legal escape, block, or capture.',
      coachPrompt: 'Give check by moving the rook from a1 to e1.',
      successMessage:
          'Check! The rook now attacks the black king along the e-file.',
      pieces: <String, AcademyPiece>{
        'a1': whiteRook,
        'g1': whiteKing,
        'e8': blackKing,
      },
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
      explanation: 'When checked, move the king, capture the attacker, or block the checking line.',
      coachPrompt: 'Escape the rook check by moving the king from e1 to f2.',
      successMessage: 'Safe escape. The king left the attacked e-file.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'e8': blackRook,
        'a8': blackKing,
      },
      from: 'e1',
      to: 'f2',
      highlighted: <String>['d2', 'f2'],
    ),
    AcademyLesson(
      id: 'castle',
      title: 'Castling safely',
      stage: AcademyStage.safety,
      eyebrow: 'KING SAFETY IN ONE MOVE',
      explanation: 'Castling moves the king two squares toward a rook, then places that rook beside the king.',
      coachPrompt: 'Castle kingside: move the king from e1 to g1.',
      successMessage: 'Castled. Your king is safer and the rook is activated.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'h1': whiteRook,
        'e8': blackKing,
      },
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
      explanation: 'A fork attacks multiple valuable targets at once. Knights are especially dangerous fork creators.',
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
      explanation: 'A king trapped behind its own pawns can be checkmated by a rook or queen on the back rank.',
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
      successMessage:
          'Promotion! Converting passed pawns is the heart of many endgames.',
      pieces: <String, AcademyPiece>{
        'e7': whitePawn,
        'a1': whiteKing,
        'h8': blackKing,
      },
      from: 'e7',
      to: 'e8',
      highlighted: <String>['e7', 'e8'],
    ),
    AcademyLesson(
      id: 'queen-mate',
      title: 'Queen checkmates',
      stage: AcademyStage.endgame,
      eyebrow: 'SHRINK THE BOX',
      explanation: 'The queen restricts the enemy king while your king approaches to support the final check.',
      coachPrompt: 'Move the queen from f6 to g7 for checkmate.',
      successMessage: 'Checkmate. Your king protects the queen and seals the escape squares.',
      pieces: <String, AcademyPiece>{
        'f6': whiteQueen,
        'f7': whiteKing,
        'h8': blackKing,
      },
      from: 'f6',
      to: 'g7',
      highlighted: <String>['g7', 'h8'],
    ),
    AcademyLesson(
      id: 'ladder-mate',
      title: 'Rook ladder mate',
      stage: AcademyStage.endgame,
      eyebrow: 'TWO ROOKS WORK TOGETHER',
      explanation: 'Two rooks can alternate checks, cutting off one rank at a time until the king reaches the edge.',
      coachPrompt: 'Move the rook from a6 to h6 for the final ladder check.',
      successMessage:
          'Checkmate. The other rook blocks the entire seventh rank.',
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
    AcademyLesson(
      id: 'en-passant',
      title: 'En passant capture',
      stage: AcademyStage.safety,
      eyebrow: 'THE SPECIAL PAWN CAPTURE',
      explanation: 'Immediately after an enemy pawn advances two squares beside yours, your pawn may capture it as if it moved only one square.',
      coachPrompt: 'Capture en passant by moving the pawn from e5 to d6.',
      successMessage:
          'Correct. En passant is available only on the very next move.',
      pieces: <String, AcademyPiece>{
        'e5': whitePawn,
        'd5': blackPawn,
        'e1': whiteKing,
        'e8': blackKing,
      },
      from: 'e5',
      to: 'd6',
      highlighted: <String>['d5', 'd6', 'e5'],
    ),
    AcademyLesson(
      id: 'pin',
      title: 'Pins',
      stage: AcademyStage.tactics,
      eyebrow: 'FREEZE THE DEFENDER',
      explanation: 'A pinned piece cannot move without exposing a more valuable piece behind it. A king pin is absolute.',
      coachPrompt:
          'Move the bishop from b5 to c6 and pin the knight to the king.',
      successMessage:
          'Strong pin. The knight cannot leave while its king is on e8.',
      pieces: <String, AcademyPiece>{
        'b5': whiteBishop,
        'd7': blackPawn,
        'e8': blackKing,
        'e1': whiteKing,
      },
      from: 'b5',
      to: 'c6',
      highlighted: <String>['c6', 'd7', 'e8'],
    ),
    AcademyLesson(
      id: 'skewer',
      title: 'Skewers',
      stage: AcademyStage.tactics,
      eyebrow: 'ATTACK THROUGH THE KING',
      explanation: 'A skewer attacks a valuable piece first; when it moves, the piece behind it is captured.',
      coachPrompt: 'Move the rook from a1 to e1 and skewer the king and queen.',
      successMessage:
          'Skewer found. The king must move, leaving the queen behind it.',
      pieces: <String, AcademyPiece>{
        'a1': whiteRook,
        'e8': blackKing,
        'e7': blackQueen,
        'g1': whiteKing,
      },
      from: 'a1',
      to: 'e1',
      path: <String>['b1', 'c1', 'd1'],
      highlighted: <String>['e1', 'e7', 'e8'],
    ),
    AcademyLesson(
      id: 'discovered-attack',
      title: 'Discovered attacks',
      stage: AcademyStage.tactics,
      eyebrow: 'UNMASK A HIDDEN ATTACK',
      explanation: 'Move one piece away to reveal an attack from the rook, bishop, or queen behind it.',
      coachPrompt:
          'Move the knight from d4 to f5 and uncover the bishop on c3.',
      successMessage: 'Excellent. One move created a knight threat and opened the bishop line.',
      pieces: <String, AcademyPiece>{
        'c3': whiteBishop,
        'd4': whiteKnight,
        'g7': blackQueen,
        'e1': whiteKing,
        'e8': blackKing,
      },
      from: 'd4',
      to: 'f5',
      highlighted: <String>['c3', 'f5', 'g7'],
    ),
    AcademyLesson(
      id: 'mate-one',
      title: 'Mate in one',
      stage: AcademyStage.tactics,
      eyebrow: 'CHECK EVERY FORCING MOVE',
      explanation: 'Search checks first, then confirm every king escape, capture, and block is covered.',
      coachPrompt: 'Move the queen from f6 to g7 for immediate checkmate.',
      successMessage:
          'Mate in one solved. The protected queen covers every escape square.',
      pieces: <String, AcademyPiece>{
        'f6': whiteQueen,
        'f7': whiteKing,
        'h8': blackKing,
      },
      from: 'f6',
      to: 'g7',
      highlighted: <String>['g7', 'h8'],
    ),
    AcademyLesson(
      id: 'opposition',
      title: 'King opposition',
      stage: AcademyStage.endgame,
      eyebrow: 'CONTROL THE KEY SQUARES',
      explanation: 'Kings facing each other with one square between them create opposition. The side not moving often controls the route.',
      coachPrompt: 'Take the opposition by moving the king from e4 to e5.',
      successMessage: 'Opposition secured. The enemy king must give way.',
      pieces: <String, AcademyPiece>{
        'e4': whiteKing,
        'e7': blackKing,
        'd5': whitePawn,
      },
      from: 'e4',
      to: 'e5',
      highlighted: <String>['e5', 'e6', 'e7'],
    ),
    AcademyLesson(
      id: 'rook-king-mate',
      title: 'Rook and king checkmate',
      stage: AcademyStage.endgame,
      eyebrow: 'BUILD A BOX',
      explanation: 'Use the rook to shrink the enemy king box, then bring your king close enough to support the final check.',
      coachPrompt: 'Move the rook from a7 to h7 to complete the edge mate.',
      successMessage: 'Checkmate. Your king protects the rook and blocks the escape squares.',
      pieces: <String, AcademyPiece>{
        'a7': whiteRook,
        'f6': whiteKing,
        'h8': blackKing,
      },
      from: 'a7',
      to: 'h7',
      path: <String>['b7', 'c7', 'd7', 'e7', 'f7', 'g7'],
      highlighted: <String>['h7', 'h8'],
    ),
    AcademyLesson(
      id: 'stalemate',
      title: 'Avoiding stalemate',
      stage: AcademyStage.endgame,
      eyebrow: 'LEAVE THE KING A MOVE',
      explanation: 'Stalemate is a draw when the player to move has no legal move but is not in check. Keep a safe waiting square.',
      coachPrompt: 'Move the queen from b6 to c6 without trapping the king.',
      successMessage: 'Patient move. The king still has a legal square, so you can finish safely.',
      pieces: <String, AcademyPiece>{
        'b6': whiteQueen,
        'f6': whiteKing,
        'h8': blackKing,
      },
      from: 'b6',
      to: 'c6',
      highlighted: <String>['c6', 'h7', 'h8'],
    ),
    AcademyLesson(
      id: 'deflection',
      title: 'Deflection tactics',
      stage: AcademyStage.tactics,
      eyebrow: 'REMOVE THE GUARD',
      explanation: 'Force a defending piece away from its duty, then capture the target it was protecting.',
      coachPrompt: 'Move the rook from d1 to d8 and deflect the queen from f8.',
      successMessage: 'Deflection found. The defender must respond and its protected piece falls next.',
      pieces: <String, AcademyPiece>{
        'd1': whiteRook,
        'f8': blackQueen,
        'd8': blackRook,
        'g1': whiteKing,
        'g8': blackKing,
      },
      from: 'd1',
      to: 'd8',
      path: <String>['d2', 'd3', 'd4', 'd5', 'd6', 'd7'],
      highlighted: <String>['d8', 'f8'],
    ),
    AcademyLesson(
      id: 'decoy',
      title: 'Decoy tactics',
      stage: AcademyStage.tactics,
      eyebrow: 'LURE THE PIECE',
      explanation: 'Offer a forcing target that pulls an enemy piece onto a square where your next tactic works.',
      coachPrompt: 'Move the queen from g5 to d8 and lure the rook away.',
      successMessage: 'Powerful decoy. The forced capture places the defender on your tactical square.',
      pieces: <String, AcademyPiece>{
        'g5': whiteQueen,
        'd8': blackRook,
        'g8': blackKing,
        'g1': whiteKing,
      },
      from: 'g5',
      to: 'd8',
      path: <String>['f6', 'e7'],
      highlighted: <String>['d8', 'g8'],
    ),
    AcademyLesson(
      id: 'mate-two',
      title: 'Mate in two',
      stage: AcademyStage.tactics,
      eyebrow: 'CALCULATE THE FORCED REPLY',
      explanation: 'Find a first move that forces one reply, then prepare the unavoidable mating move.',
      coachPrompt: 'Start the forced line by moving the queen from h5 to e8.',
      successMessage: 'Correct first move. After the forced reply, Qh8 completes the mating net.',
      pieces: <String, AcademyPiece>{
        'h5': whiteQueen,
        'f6': whiteKing,
        'g8': blackKing,
        'g7': blackPawn,
      },
      from: 'h5',
      to: 'e8',
      path: <String>['g6', 'f7'],
      highlighted: <String>['e8', 'g8', 'h8'],
    ),
    AcademyLesson(
      id: 'smothered-mate',
      title: 'Smothered mate',
      stage: AcademyStage.tactics,
      eyebrow: 'USE THE CROWDED KING',
      explanation: 'A knight can mate a king trapped by its own pieces because it needs no open line.',
      coachPrompt: 'Jump the knight from f7 to h6 and smother the king on h8.',
      successMessage: 'Smothered mate. Every escape square is occupied and the knight cannot be blocked.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'f7': whiteKnight,
        'h8': blackKing,
        'g8': blackRook,
        'g7': blackPawn,
        'h7': blackPawn,
      },
      from: 'f7',
      to: 'h6',
      highlighted: <String>['h6', 'h8', 'g8', 'g7', 'h7'],
    ),
    AcademyLesson(
      id: 'king-shelter',
      title: 'Building a king shelter',
      stage: AcademyStage.safety,
      eyebrow: 'REPAIR THE PAWN SHIELD',
      explanation: 'Connected pawns deny entry squares and protect a castled king from files and diagonals.',
      coachPrompt: 'Move the pawn from h2 to h3 and deny the g4 entry square.',
      successMessage: 'Shelter repaired. The king keeps a connected shield without opening a direct file.',
      pieces: <String, AcademyPiece>{
        'g1': whiteKing,
        'f2': whitePawn,
        'g2': whitePawn,
        'h2': whitePawn,
        'g4': blackBishop,
        'e8': blackKing,
      },
      from: 'h2',
      to: 'h3',
      highlighted: <String>['h2', 'h3', 'g4'],
    ),
    AcademyLesson(
      id: 'hanging-piece',
      title: 'Hanging pieces',
      stage: AcademyStage.tactics,
      eyebrow: 'LOOSE PIECES DROP OFF',
      explanation: 'A hanging piece is undefended and can often be captured without losing material.',
      coachPrompt:
          'Capture the undefended bishop by moving the rook from e1 to e6.',
      successMessage: 'Clean win. You checked attackers and defenders before taking the loose piece.',
      pieces: <String, AcademyPiece>{
        'e1': whiteRook,
        'e6': blackBishop,
        'g1': whiteKing,
        'g8': blackKing,
      },
      from: 'e1',
      to: 'e6',
      path: <String>['e2', 'e3', 'e4', 'e5'],
      highlighted: <String>['e6'],
    ),
    AcademyLesson(
      id: 'double-attack',
      title: 'Double attacks',
      stage: AcademyStage.tactics,
      eyebrow: 'CREATE TWO THREATS',
      explanation: 'A double attack makes two threats with one move, so one target usually cannot be saved.',
      coachPrompt: 'Move the queen from d1 to a4, checking the king and attacking the rook.',
      successMessage: 'Double attack created. The check demands a reply while the rook remains threatened.',
      pieces: <String, AcademyPiece>{
        'd1': whiteQueen,
        'e1': whiteKing,
        'e8': blackKing,
        'a8': blackRook,
      },
      from: 'd1',
      to: 'a4',
      path: <String>['c2', 'b3'],
      highlighted: <String>['a4', 'a8', 'e8'],
    ),
    AcademyLesson(
      id: 'remove-defender',
      title: 'Removing the defender',
      stage: AcademyStage.tactics,
      eyebrow: 'BREAK THE DEFENCE',
      explanation:
          'Capture or drive away the only piece protecting a valuable target.',
      coachPrompt: 'Move the bishop from c4 to f7 and remove the queen’s final defender.',
      successMessage: 'Defender removed. The protected target is now vulnerable to the next move.',
      pieces: <String, AcademyPiece>{
        'c4': whiteBishop,
        'f7': blackKnight,
        'h5': whiteQueen,
        'e8': blackKing,
        'e1': whiteKing,
      },
      from: 'c4',
      to: 'f7',
      path: <String>['d5', 'e6'],
      highlighted: <String>['f7', 'e8'],
    ),
    AcademyLesson(
      id: 'king-pawn-basics',
      title: 'King and pawn basics',
      stage: AcademyStage.endgame,
      eyebrow: 'WIN THE KEY SQUARE',
      explanation: 'The king belongs in front of its passed pawn and must control the promotion route.',
      coachPrompt: 'Move the king from e4 to e5 and escort the pawn forward.',
      successMessage: 'Key square won. Your king leads the pawn and restricts the enemy king.',
      pieces: <String, AcademyPiece>{
        'e4': whiteKing,
        'e3': whitePawn,
        'e7': blackKing,
      },
      from: 'e4',
      to: 'e5',
      highlighted: <String>['e5', 'e6', 'e7'],
    ),
    AcademyLesson(
      id: 'rook-ending',
      title: 'Basic rook endings',
      stage: AcademyStage.endgame,
      eyebrow: 'ROOK BEHIND THE PAWN',
      explanation: 'An active rook belongs behind a passed pawn, where every advance stays under attack.',
      coachPrompt:
          'Move the rook from a1 to d1 and get behind the passed pawn.',
      successMessage: 'Active rook. The passed pawn is controlled from behind while your king can approach.',
      pieces: <String, AcademyPiece>{
        'a1': whiteRook,
        'g2': whiteKing,
        'd6': blackPawn,
        'g7': blackKing,
      },
      from: 'a1',
      to: 'd1',
      path: <String>['b1', 'c1'],
      highlighted: <String>['d1', 'd6'],
    ),
    AcademyLesson(
      id: 'bishop-knight-mate',
      title: 'Bishop and knight checkmate',
      stage: AcademyStage.endgame,
      eyebrow: 'CLOSE THE MATCHING CORNER',
      explanation: 'Drive the king to the bishop-coloured corner, then coordinate king, bishop, and knight.',
      coachPrompt:
          'Move the bishop from f6 to g7 and close the final escape square.',
      successMessage: 'Precise mate. King, bishop, and knight cover all three corner exits together.',
      pieces: <String, AcademyPiece>{
        'f7': whiteKing,
        'f8': whiteKnight,
        'f6': whiteBishop,
        'h8': blackKing,
      },
      from: 'f6',
      to: 'g7',
      highlighted: <String>['g7', 'g8', 'h7', 'h8'],
    ),
    AcademyLesson(
      id: 'opening-centre',
      title: 'Control the centre',
      stage: AcademyStage.safety,
      eyebrow: 'CLAIM THE CROSSROADS',
      explanation:
          'Central pawns control space and give every piece better routes.',
      coachPrompt: 'Move the pawn from e2 to e4 and claim the centre.',
      successMessage:
          'Centre claimed. Your queen and bishop now have useful lines.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'e2': whitePawn,
        'e8': blackKing,
      },
      from: 'e2',
      to: 'e4',
      path: <String>['e3'],
      highlighted: <String>['d4', 'e4', 'd5', 'e5'],
    ),
    AcademyLesson(
      id: 'opening-develop',
      title: 'Develop minor pieces',
      stage: AcademyStage.safety,
      eyebrow: 'BRING THE TEAM OUT',
      explanation: 'Knights and bishops should enter active squares before the queen attacks.',
      coachPrompt: 'Develop the knight from g1 to f3.',
      successMessage: 'Purposeful development. The knight attacks the centre and prepares castling.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'g1': whiteKnight,
        'e8': blackKing,
      },
      from: 'g1',
      to: 'f3',
      highlighted: <String>['f3', 'e5', 'd4'],
    ),
    AcademyLesson(
      id: 'opening-tempo',
      title: 'Do not move twice',
      stage: AcademyStage.safety,
      eyebrow: 'EVERY TEMPO COUNTS',
      explanation: 'Develop a new piece instead of moving the same piece repeatedly without need.',
      coachPrompt: 'Develop the bishop from f1 to c4 instead of moving the knight again.',
      successMessage:
          'Tempo saved. A second piece joins the game and castling is closer.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'f1': whiteBishop,
        'f3': whiteKnight,
        'e8': blackKing,
      },
      from: 'f1',
      to: 'c4',
      path: <String>['e2', 'd3'],
      highlighted: <String>['c4'],
    ),
    AcademyLesson(
      id: 'opening-castle',
      title: 'Castle early',
      stage: AcademyStage.safety,
      eyebrow: 'SECURE THE KING',
      explanation: 'Castle after developing the path so the king is safe before the centre opens.',
      coachPrompt: 'Castle by moving the king from e1 to g1.',
      successMessage: 'King secured and rook activated in one efficient move.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'h1': whiteRook,
        'e8': blackKing,
      },
      from: 'e1',
      to: 'g1',
      path: <String>['f1'],
      highlighted: <String>['g1', 'f1'],
    ),
    AcademyLesson(
      id: 'opening-rooks',
      title: 'Connect the rooks',
      stage: AcademyStage.safety,
      eyebrow: 'COMPLETE DEVELOPMENT',
      explanation: 'Clear the back rank between the rooks so they can defend each other.',
      coachPrompt: 'Move the queen from d1 to e2 and connect the rooks.',
      successMessage: 'Development complete. The rooks can now coordinate across the back rank.',
      pieces: <String, AcademyPiece>{
        'a1': whiteRook,
        'd1': whiteQueen,
        'h1': whiteRook,
        'g1': whiteKing,
        'e8': blackKing,
      },
      from: 'd1',
      to: 'e2',
      highlighted: <String>['a1', 'h1', 'e2'],
    ),
    AcademyLesson(
      id: 'opening-checklist',
      title: 'Opening checklist',
      stage: AcademyStage.safety,
      eyebrow: 'CHECK BEFORE ATTACKING',
      explanation: 'Ask: centre controlled, pieces developed, king safe, and rooks connected?',
      coachPrompt: 'Finish development by moving the bishop from c1 to f4.',
      successMessage: 'Checklist complete. Your position is ready for a sound middlegame plan.',
      pieces: <String, AcademyPiece>{
        'c1': whiteBishop,
        'g1': whiteKing,
        'a1': whiteRook,
        'f1': whiteRook,
        'e8': blackKing,
      },
      from: 'c1',
      to: 'f4',
      path: <String>['d2', 'e3'],
      highlighted: <String>['f4'],
    ),
    AcademyLesson(
      id: 'opening-italian',
      title: 'Italian Game',
      stage: AcademyStage.safety,
      eyebrow: 'DEVELOP WITH A THREAT',
      explanation: 'Claim the centre, develop quickly, and aim the bishop at f7 before castling.',
      coachPrompt:
          'Complete the Italian setup by moving the bishop from f1 to c4.',
      successMessage: 'Italian setup complete. Your pieces influence the centre and the king can castle next.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'e2': whitePawn,
        'g1': whiteKnight,
        'f1': whiteBishop,
        'e8': blackKing,
        'e7': blackPawn,
        'b8': blackKnight,
        'f7': blackPawn,
      },
      from: 'f1',
      to: 'c4',
      path: <String>['e2', 'd3'],
      highlighted: <String>['c4', 'f7', 'g1'],
      demoLine: <AcademyDemoMove>[
        AcademyDemoMove('e2', 'e4'),
        AcademyDemoMove('e7', 'e5'),
        AcademyDemoMove('g1', 'f3'),
        AcademyDemoMove('b8', 'c6'),
        AcademyDemoMove('f1', 'c4'),
      ],
    ),
    AcademyLesson(
      id: 'opening-ruy-lopez',
      title: 'Ruy Lopez',
      stage: AcademyStage.safety,
      eyebrow: 'PRESSURE THE CENTRE',
      explanation: 'Develop the bishop to b5 and question the knight that protects the e5 pawn.',
      coachPrompt:
          'Complete the Spanish setup by moving the bishop from f1 to b5.',
      successMessage: 'Ruy Lopez setup complete. The c6 knight and e5 centre are under pressure.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'e2': whitePawn,
        'g1': whiteKnight,
        'f1': whiteBishop,
        'e8': blackKing,
        'e7': blackPawn,
        'b8': blackKnight,
      },
      from: 'f1',
      to: 'b5',
      path: <String>['e2', 'd3', 'c4'],
      highlighted: <String>['b5', 'c6', 'e5'],
      demoLine: <AcademyDemoMove>[
        AcademyDemoMove('e2', 'e4'),
        AcademyDemoMove('e7', 'e5'),
        AcademyDemoMove('g1', 'f3'),
        AcademyDemoMove('b8', 'c6'),
        AcademyDemoMove('f1', 'b5'),
      ],
    ),
    AcademyLesson(
      id: 'opening-sicilian',
      title: 'Sicilian Defense',
      stage: AcademyStage.safety,
      eyebrow: 'CREATE AN UNBALANCED FIGHT',
      explanation: 'Black challenges the centre from the c-file; White answers with development and d4.',
      coachPrompt: 'Open the centre by moving the pawn from d2 to d4.',
      successMessage: 'Open Sicilian reached. Both sides have active play and different strategic chances.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'e2': whitePawn,
        'd2': whitePawn,
        'g1': whiteKnight,
        'e8': blackKing,
        'c7': blackPawn,
        'd7': blackPawn,
      },
      from: 'd2',
      to: 'd4',
      path: <String>['d3'],
      highlighted: <String>['d4', 'c5', 'f3'],
      demoLine: <AcademyDemoMove>[
        AcademyDemoMove('e2', 'e4'),
        AcademyDemoMove('c7', 'c5'),
        AcademyDemoMove('g1', 'f3'),
        AcademyDemoMove('d7', 'd6'),
        AcademyDemoMove('d2', 'd4'),
      ],
    ),
    AcademyLesson(
      id: 'opening-queens-gambit',
      title: "Queen's Gambit",
      stage: AcademyStage.safety,
      eyebrow: 'OFFER THE FLANK PAWN',
      explanation: 'Offer the c-pawn to challenge Black’s d5 pawn and gain central space.',
      coachPrompt: 'Offer the Queen’s Gambit by moving the pawn from c2 to c4.',
      successMessage: 'Gambit offered. The c-pawn challenges Black’s centre and opens development routes.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'd2': whitePawn,
        'c2': whitePawn,
        'e8': blackKing,
        'd7': blackPawn,
      },
      from: 'c2',
      to: 'c4',
      path: <String>['c3'],
      highlighted: <String>['c4', 'd5', 'd4'],
      demoLine: <AcademyDemoMove>[
        AcademyDemoMove('d2', 'd4'),
        AcademyDemoMove('d7', 'd5'),
        AcademyDemoMove('c2', 'c4'),
      ],
    ),
    AcademyLesson(
      id: 'opening-caro-kann',
      title: 'Caro-Kann Defense',
      stage: AcademyStage.safety,
      eyebrow: 'BUILD A SOLID COUNTERSTRIKE',
      explanation: 'Prepare d5 with c6, then challenge White’s pawn centre without blocking the bishop.',
      coachPrompt: 'Challenge the centre by moving the pawn from d7 to d5.',
      successMessage: 'Caro-Kann structure complete. Black has a solid centre and a free light bishop.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'e2': whitePawn,
        'd2': whitePawn,
        'e8': blackKing,
        'c7': blackPawn,
        'd7': blackPawn,
        'c8': blackBishop,
      },
      from: 'd7',
      to: 'd5',
      path: <String>['d6'],
      highlighted: <String>['d5', 'e4', 'c8'],
      demoLine: <AcademyDemoMove>[
        AcademyDemoMove('e2', 'e4'),
        AcademyDemoMove('c7', 'c6'),
        AcademyDemoMove('d2', 'd4'),
        AcademyDemoMove('d7', 'd5'),
      ],
    ),
    AcademyLesson(
      id: 'opening-punish-queen',
      title: 'Punish early queen moves',
      stage: AcademyStage.safety,
      eyebrow: 'DEVELOP WITH TEMPO',
      explanation: 'When the queen comes out too early, attack it while developing a useful piece.',
      coachPrompt:
          'Develop the knight from b1 to c3 and attack the exposed queen.',
      successMessage: 'Free tempo won. Your knight developed while the queen must move again.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'e2': whitePawn,
        'b1': whiteKnight,
        'e8': blackKing,
        'd7': blackPawn,
        'd8': blackQueen,
      },
      from: 'b1',
      to: 'c3',
      highlighted: <String>['c3', 'd5'],
      demoLine: <AcademyDemoMove>[
        AcademyDemoMove('e2', 'e4'),
        AcademyDemoMove('d7', 'd5'),
        AcademyDemoMove('e4', 'd5'),
        AcademyDemoMove('d8', 'd5'),
        AcademyDemoMove('b1', 'c3'),
      ],
    ),
    AcademyLesson(
      id: 'plan-worst-piece',
      title: 'Improve the worst piece',
      stage: AcademyStage.tactics,
      eyebrow: 'UPGRADE THE TEAM',
      explanation:
          'Find the least active piece and give it a square with a real job.',
      coachPrompt:
          'Move the knight from b1 to d2 toward active central squares.',
      successMessage: 'The worst piece improved and your whole position gained coordination.',
      pieces: <String, AcademyPiece>{
        'b1': whiteKnight,
        'g1': whiteKing,
        'g8': blackKing,
      },
      from: 'b1',
      to: 'd2',
      highlighted: <String>['d2', 'e4', 'f3'],
    ),
    AcademyLesson(
      id: 'plan-open-file',
      title: 'Use open files',
      stage: AcademyStage.tactics,
      eyebrow: 'ROOKS NEED HIGHWAYS',
      explanation: 'Place a rook on a file without pawns and invade the opponent position.',
      coachPrompt: 'Move the rook from a1 to d1 and occupy the open file.',
      successMessage:
          'The rook owns the open file and can enter the seventh rank next.',
      pieces: <String, AcademyPiece>{
        'a1': whiteRook,
        'g1': whiteKing,
        'g8': blackKing,
      },
      from: 'a1',
      to: 'd1',
      path: <String>['b1', 'c1'],
      highlighted: <String>['d1', 'd7'],
    ),
    AcademyLesson(
      id: 'plan-weak-square',
      title: 'Exploit weak squares',
      stage: AcademyStage.tactics,
      eyebrow: 'CREATE AN OUTPOST',
      explanation: 'A weak square cannot be defended by an enemy pawn and is ideal for a knight.',
      coachPrompt: 'Plant the knight from f3 on e5.',
      successMessage:
          'Outpost secured. The knight cannot be chased away by a pawn.',
      pieces: <String, AcademyPiece>{
        'f3': whiteKnight,
        'g1': whiteKing,
        'g8': blackKing,
      },
      from: 'f3',
      to: 'e5',
      highlighted: <String>['e5', 'c6', 'f7'],
    ),
    AcademyLesson(
      id: 'plan-pawn-break',
      title: 'Prepare a pawn break',
      stage: AcademyStage.tactics,
      eyebrow: 'CHANGE THE STRUCTURE',
      explanation: 'Support a pawn advance that opens a file or attacks the enemy centre.',
      coachPrompt: 'Play the prepared pawn break from c4 to c5.',
      successMessage: 'The pawn break gains space and challenges the base of the enemy chain.',
      pieces: <String, AcademyPiece>{
        'c4': whitePawn,
        'd3': whitePawn,
        'g1': whiteKing,
        'g8': blackKing,
        'd5': blackPawn,
      },
      from: 'c4',
      to: 'c5',
      highlighted: <String>['c5', 'd5'],
    ),
    AcademyLesson(
      id: 'plan-prophylaxis',
      title: 'Stop the opponent plan',
      stage: AcademyStage.tactics,
      eyebrow: 'ASK WHAT THEY WANT',
      explanation: 'Before your move, identify the opponent threat and prevent its key idea.',
      coachPrompt: 'Move the pawn from h2 to h3 and stop the bishop pin on g4.',
      successMessage: 'Prophylaxis found. Their plan is stopped before it becomes a threat.',
      pieces: <String, AcademyPiece>{
        'g1': whiteKing,
        'h2': whitePawn,
        'c8': blackBishop,
        'g8': blackKing,
      },
      from: 'h2',
      to: 'h3',
      highlighted: <String>['h3', 'g4'],
    ),
    AcademyLesson(
      id: 'plan-three-step',
      title: 'Build a three-step plan',
      stage: AcademyStage.tactics,
      eyebrow: 'TARGET, PIECE, BREAK',
      explanation: 'Choose a target, improve the piece that can attack it, then prepare the breakthrough.',
      coachPrompt:
          'Begin the plan by moving the rook from f1 to c1 toward the c-file.',
      successMessage: 'Plan started. Your rook has a target and the pawn break now has support.',
      pieces: <String, AcademyPiece>{
        'f1': whiteRook,
        'g1': whiteKing,
        'c7': blackPawn,
        'g8': blackKing,
      },
      from: 'f1',
      to: 'c1',
      path: <String>['e1', 'd1'],
      highlighted: <String>['c1', 'c7'],
    ),
    AcademyLesson(
      id: 'clock-budget',
      title: 'Build a thinking budget',
      stage: AcademyStage.tactics,
      eyebrow: 'SAVE TIME FOR CRITICAL MOMENTS',
      explanation: 'Play familiar, reversible moves quickly and invest time when captures, checks, or pawn breaks change the position.',
      coachPrompt:
          'Develop the knight from g1 to f3 without overspending time.',
      successMessage: 'Efficient decision. You improved a piece and saved time for the first critical moment.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'g1': whiteKnight,
        'e2': whitePawn,
        'e8': blackKing,
        'e7': blackPawn,
      },
      from: 'g1',
      to: 'f3',
      highlighted: <String>['f3', 'h3', 'e2'],
    ),
    AcademyLesson(
      id: 'clock-forcing-scan',
      title: 'Run the emergency scan',
      stage: AcademyStage.tactics,
      eyebrow: 'CHECKS, CAPTURES, THREATS',
      explanation: 'When the clock is low, scan forcing moves first instead of calculating every legal option.',
      coachPrompt: 'Capture on h7 with check before considering quiet moves.',
      successMessage: 'Forcing move found. A short ordered scan replaced slow random calculation.',
      pieces: <String, AcademyPiece>{
        'g1': whiteKing,
        'h5': whiteQueen,
        'g8': blackKing,
        'h7': blackPawn,
        'f7': blackPawn,
      },
      from: 'h5',
      to: 'h7',
      highlighted: <String>['h7', 'f7', 'e5'],
    ),
    AcademyLesson(
      id: 'clock-increment',
      title: 'Use increment to reset',
      stage: AcademyStage.safety,
      eyebrow: 'MOVE, BREATHE, RESCAN',
      explanation: 'Choose a safe move, let the increment land, then use the opponent turn to prepare your next scan.',
      coachPrompt:
          'Step the king from g1 to h2 and secure it before the next decision.',
      successMessage: 'Calm reset. The safe move banked the increment and restored your thinking rhythm.',
      pieces: <String, AcademyPiece>{
        'g1': whiteKing,
        'f2': whitePawn,
        'g2': whitePawn,
        'h3': whitePawn,
        'g8': blackKing,
      },
      from: 'g1',
      to: 'h2',
      highlighted: <String>['h2', 'f1', 'g2'],
    ),
    AcademyLesson(
      id: 'clock-safe-premove',
      title: 'Choose a safe premove',
      stage: AcademyStage.safety,
      eyebrow: 'SPEED WITHOUT A BLUNDER',
      explanation: 'Only premove when the move stays legal and sensible across every likely opponent reply.',
      coachPrompt: 'Use the robust opening premove e2 to e4.',
      successMessage: 'Safe premove chosen. You gained time without depending on a target that could move.',
      pieces: <String, AcademyPiece>{
        'e1': whiteKing,
        'e2': whitePawn,
        'g1': whiteKnight,
        'e8': blackKing,
        'e7': blackPawn,
      },
      from: 'e2',
      to: 'e4',
      path: <String>['e3'],
      highlighted: <String>['e3', 'e4', 'f3'],
    ),
  ];

  static AcademyLesson forChapter(String chapter) {
    final String normalized = chapter.toLowerCase();
    for (final AcademyLesson lesson in lessons) {
      if (lesson.title.toLowerCase() == normalized) return lesson;
    }
    if (normalized.contains('en passant')) {
      return lessons.firstWhere((l) => l.id == 'en-passant');
    }
    if (normalized.contains('king shelter')) {
      return lessons.firstWhere((l) => l.id == 'king-shelter');
    }
    if (normalized.contains('hanging')) {
      return lessons.firstWhere((l) => l.id == 'hanging-piece');
    }
    if (normalized.contains('double attack')) {
      return lessons.firstWhere((l) => l.id == 'double-attack');
    }
    if (normalized.contains('removing the defender')) {
      return lessons.firstWhere((l) => l.id == 'remove-defender');
    }
    if (normalized.contains('king and pawn')) {
      return lessons.firstWhere((l) => l.id == 'king-pawn-basics');
    }
    if (normalized.contains('basic rook')) {
      return lessons.firstWhere((l) => l.id == 'rook-ending');
    }
    if (normalized.contains('hanging') ||
        normalized.contains('protect') ||
        normalized.contains('capture scan') ||
        normalized.contains('checks, captures')) {
      return lessons.firstWhere((l) => l.id == 'capture');
    }
    if (normalized.contains('candidate')) {
      return lessons.firstWhere((l) => l.id == 'knight-fork');
    }
    if (normalized.contains('pawn')) {
      return lessons.firstWhere((l) => l.id == 'pawn');
    }
    if (normalized.contains('rook') && normalized.contains('king')) {
      return lessons.firstWhere((l) => l.id == 'rook-king-mate');
    }
    if (normalized.contains('rook')) {
      return lessons.firstWhere((l) => l.id == 'rook');
    }
    if (normalized.contains('bishop') || normalized.contains('diagonal')) {
      return lessons.firstWhere((l) => l.id == 'bishop');
    }
    if (normalized.contains('knight') || normalized.contains('fork')) {
      return lessons.firstWhere((l) => l.id == 'knight-fork');
    }
    if (normalized.contains('pin')) {
      return lessons.firstWhere((l) => l.id == 'pin');
    }
    if (normalized.contains('skewer')) {
      return lessons.firstWhere((l) => l.id == 'skewer');
    }
    if (normalized.contains('discover')) {
      return lessons.firstWhere((l) => l.id == 'discovered-attack');
    }
    if (normalized.contains('deflect')) {
      return lessons.firstWhere((l) => l.id == 'deflection');
    }
    if (normalized.contains('decoy')) {
      return lessons.firstWhere((l) => l.id == 'decoy');
    }
    if (normalized.contains('mate in two') ||
        normalized.contains('mate-in-2')) {
      return lessons.firstWhere((l) => l.id == 'mate-two');
    }
    if (normalized.contains('opposition')) {
      return lessons.firstWhere((l) => l.id == 'opposition');
    }
    if (normalized.contains('stalemate') || normalized.contains('drawing')) {
      return lessons.firstWhere((l) => l.id == 'stalemate');
    }
    if (normalized.contains('queen')) {
      return lessons.firstWhere((l) => l.id == 'queen-mate');
    }
    if (normalized.contains('mate') || normalized.contains('check')) {
      return lessons.firstWhere((l) => l.id == 'back-rank');
    }
    return lessons.first;
  }
}
