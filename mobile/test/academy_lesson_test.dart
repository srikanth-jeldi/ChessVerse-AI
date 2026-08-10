import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/features/tutorial/domain/academy_lesson.dart';

void main() {
  group('AcademyCatalog', () {
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
      expect(AcademyCatalog.lessons.length, greaterThanOrEqualTo(16));
    });

    test('maps the public course chapter names to focused lessons', () {
      expect(AcademyCatalog.forChapter('How pawns move').id, 'pawn');
      expect(AcademyCatalog.forChapter('The knight jump').id, 'knight');
      expect(AcademyCatalog.forChapter('Back-rank mates').id, 'back-rank');
      expect(AcademyCatalog.forChapter('Promoting a pawn').id, 'promotion');
      expect(AcademyCatalog.forChapter('Queen checkmates').id, 'queen-mate');
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
