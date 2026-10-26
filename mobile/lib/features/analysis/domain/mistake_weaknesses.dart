import 'mistake_bank.dart';

enum MistakeCategory {
  tactics('Tactics'),
  kingSafety('King safety'),
  opening('Opening'),
  endgame('Endgame'),
  timePressure('Time pressure'),
  other('Other mistakes');

  const MistakeCategory(this.label);
  final String label;
}

abstract final class MistakeWeaknesses {
  static Set<MistakeCategory> tags(MistakeBankItem item) {
    final tags = <MistakeCategory>{};
    switch (item.review.coachingTheme) {
      case 'tactics':
      case 'hangingPieces':
      case 'missedCaptures':
        tags.add(MistakeCategory.tactics);
      case 'kingSafety':
        tags.add(MistakeCategory.kingSafety);
      case 'opening':
        tags.add(MistakeCategory.opening);
      case 'endgame':
        tags.add(MistakeCategory.endgame);
    }
    final board = item.review.fenBefore.split(' ').first;
    // A conservative board-phase tag, not a claim about the cause of a mistake.
    if (board.split('/').length == 8 &&
        RegExp('[K]').hasMatch(board) &&
        RegExp('[k]').hasMatch(board) &&
        RegExp('[qrbnQRBN]').allMatches(board).length <= 4) {
      tags.add(MistakeCategory.endgame);
    }
    final seconds = item.review.clockSecondsBefore;
    if (seconds != null && seconds >= 0 && seconds <= 30) {
      tags.add(MistakeCategory.timePressure);
    }
    if (tags.isEmpty) tags.add(MistakeCategory.other);
    return tags;
  }

  static List<MistakeBankItem> recent(
    Iterable<MistakeBankItem> items, {
    required int days,
    required DateTime now,
  }) {
    final end = now.toUtc();
    final start = end.subtract(Duration(days: days));
    return items
        .where((item) {
          final date = item.game.playedAt.toUtc();
          if (date.isBefore(start) || date.isAfter(end)) return false;
          if (item.game.reviewScope == 'opponent') return false;
          if (item.game.reviewScope == 'both') {
            final side = item.game.playerSide;
            if (side != 'white' && side != 'black') return false;
            final fen = item.review.fenBefore.split(' ');
            if (fen.length < 2 || fen[1] != (side == 'white' ? 'w' : 'b')) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }
}
