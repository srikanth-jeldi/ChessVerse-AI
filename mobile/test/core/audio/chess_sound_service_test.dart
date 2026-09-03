import 'package:flutter_test/flutter_test.dart';

import 'package:chessverse_ai/core/audio/chess_sound_service.dart';

void main() {
  test('every chess piece has a genuinely distinct sound asset', () {
    final Iterable<String> paths = ChessSoundService.pieceAssetPaths.values;

    expect(ChessSoundService.pieceAssetPaths.keys,
        containsAll(<String>['P', 'N', 'B', 'R', 'Q', 'K']));
    expect(paths.toSet(), hasLength(6));
    expect(ChessSoundService.assetForPiece('n'), 'audio/piece_knight.ogg');
    expect(ChessSoundService.assetForPiece('b'), 'audio/piece_bishop.ogg');
    expect(ChessSoundService.assetForPiece('q'), 'audio/piece_queen.ogg');
    expect(ChessSoundService.assetForPiece('k'), 'audio/piece_king.wav');
  });

  test('unknown piece code safely falls back to the normal move sound', () {
    expect(
      ChessSoundService.assetForPiece('?'),
      'audio/chess_move.wav',
    );
  });
}
