import 'package:chessverse_ai/features/tutorial/domain/master_game_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('master catalog offers attack, calculation and endurance stories', () {
    expect(MasterGameCatalog.lessons, hasLength(greaterThanOrEqualTo(7)));
    expect(
      MasterGameCatalog.lessons.map((MasterGameLesson lesson) => lesson.style),
      containsAll(MasterThinkingStyle.values),
    );
  });

  test('every critical position has one answer and a forcing continuation', () {
    for (final MasterGameLesson lesson in MasterGameCatalog.lessons) {
      expect(lesson.choices.where(lesson.isCorrect), hasLength(1));
      expect(
        lesson.continuation.first.replaceAll(' ', ''),
        lesson.answer.replaceAll('!!', '!').replaceAll(' ', ''),
      );
      expect(lesson.continuation, hasLength(greaterThanOrEqualTo(3)));
    }
  });

  test('verified historic metadata remains stable', () {
    final MasterGameLesson carlsen = MasterGameCatalog.byId(
      'carlsen-nepomniachtchi-2021',
    );
    expect(carlsen.year, 2021);
    expect(carlsen.result, '1–0');
    expect(carlsen.sourceLabel, contains('136 moves'));
    expect(MasterGameCatalog.byId('morphy-opera-1858').year, 1858);
    expect(MasterGameCatalog.byId('byrne-fischer-1956').result, '0–1');
  });

  test('critical FENs contain the master piece on its source square', () {
    for (final MasterGameLesson lesson in MasterGameCatalog.lessons) {
      final Map<String, String> pieces = MasterGameCatalog.piecesFromFen(
        lesson.fen,
      );
      expect(pieces[lesson.masterFrom], isNotNull, reason: lesson.id);
      expect(lesson.masterTo, matches(RegExp(r'^[a-h][1-8]$')));
    }
  });
}
