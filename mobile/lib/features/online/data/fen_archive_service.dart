import '../../../core/local_game_archive.dart';

class FenArchiveService {
  const FenArchiveService();

  List<String> importPositions(String source) {
    final positions = source
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .map(normalize)
        .toList(growable: false);
    if (positions.isEmpty) {
      throw const FormatException('The FEN file is empty.');
    }
    return positions;
  }

  String exportPositions(Iterable<SavedGameRecord> games) {
    final positions = <String>{};
    for (final game in games) {
      if (game.initialFen?.trim().isNotEmpty == true) {
        positions.add(normalize(game.initialFen!));
      }
      for (final review in game.moveReviews) {
        if (review.fenBefore.trim().isNotEmpty) {
          positions.add(normalize(review.fenBefore));
        }
      }
    }
    if (positions.isEmpty) {
      throw const FormatException(
        'No saved FEN positions are available yet. Import a FEN or analyse a game first.',
      );
    }
    return positions.join('\n');
  }

  String normalize(String source) {
    final fields = source.trim().split(RegExp(r'\s+'));
    if (fields.length != 6) {
      throw const FormatException('A FEN must contain exactly 6 fields.');
    }
    final ranks = fields[0].split('/');
    if (ranks.length != 8) {
      throw const FormatException('A FEN board must contain 8 ranks.');
    }
    int whiteKings = 0;
    int blackKings = 0;
    for (final rank in ranks) {
      int width = 0;
      for (final rune in rank.runes) {
        final char = String.fromCharCode(rune);
        final empty = int.tryParse(char);
        if (empty != null) {
          if (empty < 1 || empty > 8) {
            throw const FormatException('Invalid empty-square count in FEN.');
          }
          width += empty;
        } else if ('prnbqkPRNBQK'.contains(char)) {
          width++;
          if (char == 'K') whiteKings++;
          if (char == 'k') blackKings++;
        } else {
          throw const FormatException('Invalid chess piece in FEN.');
        }
      }
      if (width != 8) {
        throw const FormatException('Every FEN rank must contain 8 squares.');
      }
    }
    if (whiteKings != 1 || blackKings != 1) {
      throw const FormatException('A FEN must contain one king for each side.');
    }
    if (fields[1] != 'w' && fields[1] != 'b') {
      throw const FormatException('Invalid side to move in FEN.');
    }
    if (!RegExp(r'^(?:-|K?Q?k?q?)$').hasMatch(fields[2])) {
      throw const FormatException('Invalid castling rights in FEN.');
    }
    if (!RegExp(r'^(?:-|[a-h][36])$').hasMatch(fields[3])) {
      throw const FormatException('Invalid en-passant square in FEN.');
    }
    final halfmove = int.tryParse(fields[4]);
    final fullmove = int.tryParse(fields[5]);
    if (halfmove == null || halfmove < 0 || fullmove == null || fullmove < 1) {
      throw const FormatException('Invalid FEN move counters.');
    }
    return fields.join(' ');
  }
}
