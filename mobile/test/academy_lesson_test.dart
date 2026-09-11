import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/features/tutorial/domain/academy_lesson.dart';

void main() {
  group('AcademyCatalog', () {
    test('single-move lessons expose a sequence-compatible demo line', () {
      final AcademyLesson lesson = AcademyCatalog.forChapter('How pawns move');
      expect(lesson.demonstrationLine, hasLength(1));
      expect(lesson.demonstrationLine.single.from, lesson.from);
      expect(lesson.demonstrationLine.single.to, lesson.to);
    });
    test('contains unique, playable core lessons', () {
      final Set<String> ids = <String>{};
      for (final AcademyLesson lesson in AcademyCatalog.lessons) {
        expect(ids.add(lesson.id), isTrue, reason: 'duplicate ${lesson.id}');
        expect(lesson.pieces[lesson.from], isNotNull);
        expect(_validSquare(lesson.from), isTrue);
        expect(_validSquare(lesson.to), isTrue);
        expect(lesson.from, isNot(lesson.to));
        for (final String square in lesson.path) {
          expect(_validSquare(square), isTrue);
        }
      }
      expect(AcademyCatalog.lessons.length, greaterThanOrEqualTo(27));
    });

    test('every animated demonstration is internally consistent', () {
      for (final AcademyLesson lesson in AcademyCatalog.lessons) {
        final Map<String, AcademyPiece> position =
            Map<String, AcademyPiece>.from(lesson.pieces);
        final List<AcademyDemoMove> line = lesson.demonstrationLine;
        expect(line.last.from, lesson.from, reason: lesson.id);
        expect(line.last.to, lesson.to, reason: lesson.id);
        for (final AcademyDemoMove move in line) {
          expect(
            position[move.from],
            isNotNull,
            reason: '${lesson.id}: ${move.from} must contain a piece',
          );
          final AcademyPiece piece = position.remove(move.from)!;
          position[move.to] = piece;
        }
      }
    });

    test('maps the public course chapter names to focused lessons', () {
      expect(AcademyCatalog.forChapter('How pawns move').id, 'pawn');
      expect(AcademyCatalog.forChapter('The knight jump').id, 'knight');
      expect(AcademyCatalog.forChapter('Back-rank mates').id, 'back-rank');
      expect(AcademyCatalog.forChapter('Promoting a pawn').id, 'promotion');
      expect(AcademyCatalog.forChapter('Queen checkmates').id, 'queen-mate');
      expect(AcademyCatalog.forChapter('En passant capture').id, 'en-passant');
      expect(AcademyCatalog.forChapter('Pins').id, 'pin');
      expect(AcademyCatalog.forChapter('Skewers').id, 'skewer');
      expect(
        AcademyCatalog.forChapter('Discovered attacks').id,
        'discovered-attack',
      );
      expect(AcademyCatalog.forChapter('King opposition').id, 'opposition');
      expect(
        AcademyCatalog.forChapter('Rook and king checkmate').id,
        'rook-king-mate',
      );
      expect(AcademyCatalog.forChapter('Avoiding stalemate').id, 'stalemate');
      expect(AcademyCatalog.forChapter('Deflection tactics').id, 'deflection');
      expect(AcademyCatalog.forChapter('Decoy tactics').id, 'decoy');
      expect(AcademyCatalog.forChapter('Mate in two').id, 'mate-two');
      expect(AcademyCatalog.forChapter('Smothered mate').id, 'smothered-mate');
      expect(
        AcademyCatalog.forChapter('Bishop and knight checkmate').id,
        'bishop-knight-mate',
      );
      expect(
        AcademyCatalog.forChapter('Building a king shelter').id,
        'king-shelter',
      );
      expect(AcademyCatalog.forChapter('Hanging pieces').id, 'hanging-piece');
      expect(AcademyCatalog.forChapter('Double attacks').id, 'double-attack');
      expect(
        AcademyCatalog.forChapter('Removing the defender').id,
        'remove-defender',
      );
      expect(
        AcademyCatalog.forChapter('King and pawn basics').id,
        'king-pawn-basics',
      );
      expect(AcademyCatalog.forChapter('Basic rook endings').id, 'rook-ending');
      expect(
        AcademyCatalog.forChapter('Control the centre').id,
        'opening-centre',
      );
      expect(
        AcademyCatalog.forChapter('Develop minor pieces').id,
        'opening-develop',
      );
      expect(
        AcademyCatalog.forChapter('Do not move twice').id,
        'opening-tempo',
      );
      expect(AcademyCatalog.forChapter('Castle early').id, 'opening-castle');
      expect(
        AcademyCatalog.forChapter('Connect the rooks').id,
        'opening-rooks',
      );
      expect(
        AcademyCatalog.forChapter('Opening checklist').id,
        'opening-checklist',
      );
      expect(AcademyCatalog.forChapter('Italian Game').id, 'opening-italian');
      expect(AcademyCatalog.forChapter('Ruy Lopez').id, 'opening-ruy-lopez');
      expect(
        AcademyCatalog.forChapter('Sicilian Defense').id,
        'opening-sicilian',
      );
      expect(
        AcademyCatalog.forChapter("Queen's Gambit").id,
        'opening-queens-gambit',
      );
      expect(
        AcademyCatalog.forChapter('Caro-Kann Defense').id,
        'opening-caro-kann',
      );
      expect(
        AcademyCatalog.forChapter('Punish early queen moves').id,
        'opening-punish-queen',
      );
      expect(
        AcademyCatalog.forChapter('Improve the worst piece').id,
        'plan-worst-piece',
      );
      expect(AcademyCatalog.forChapter('Use open files').id, 'plan-open-file');
      expect(
        AcademyCatalog.forChapter('Exploit weak squares').id,
        'plan-weak-square',
      );
      expect(
        AcademyCatalog.forChapter('Prepare a pawn break').id,
        'plan-pawn-break',
      );
      expect(
        AcademyCatalog.forChapter('Stop the opponent plan').id,
        'plan-prophylaxis',
      );
      expect(
        AcademyCatalog.forChapter('Build a three-step plan').id,
        'plan-three-step',
      );
      expect(
        AcademyCatalog.forChapter('Build a thinking budget').id,
        'clock-budget',
      );
      expect(
        AcademyCatalog.forChapter('Run the emergency scan').id,
        'clock-forcing-scan',
      );
      expect(
        AcademyCatalog.forChapter('Use increment to reset').id,
        'clock-increment',
      );
      expect(
        AcademyCatalog.forChapter('Choose a safe premove').id,
        'clock-safe-premove',
      );
    });

    test('foundation course has memorable narrated story chapters', () {
      final Iterable<AcademyLesson> foundation = AcademyCatalog.lessons.where(
        (AcademyLesson lesson) => lesson.stage == AcademyStage.foundation,
      );
      expect(foundation, isNotEmpty);
      for (final AcademyLesson lesson in foundation) {
        expect(lesson.storyChapter, isNot('THE NEXT MOVE'));
        expect(
          lesson.storyNarration.length,
          greaterThan(120),
          reason: '${lesson.id} needs a complete narrated scene',
        );
        expect(
          lesson.storyNarration,
          contains(lesson.to),
          reason: '${lesson.id} story must teach the target square',
        );
      }
    });

    test('intermediate lessons require three-candidate thinking', () {
      final Iterable<AcademyLesson> intermediate = AcademyCatalog.lessons.where(
        (AcademyLesson lesson) => lesson.stage != AcademyStage.foundation,
      );
      for (final AcademyLesson lesson in intermediate) {
        expect(lesson.usesDecisionCheckpoint, isTrue);
        expect(lesson.decisionOptions, hasLength(3));
        expect(lesson.decisionOptions.toSet(), hasLength(3));
        expect(lesson.decisionOptions, contains(lesson.to));
        expect(lesson.decisionInsight, contains(lesson.to));
      }
    });
  });
}

bool _validSquare(String value) {
  if (value.length != 2) return false;
  final int file = value.codeUnitAt(0);
  final int rank = value.codeUnitAt(1);
  return file >= 'a'.codeUnitAt(0) &&
      file <= 'h'.codeUnitAt(0) &&
      rank >= '1'.codeUnitAt(0) &&
      rank <= '8'.codeUnitAt(0);
}
