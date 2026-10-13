import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:chessverse_ai/core/audio/chess_sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runtime chess sounds remain in the asset bundle', () async {
    final paths = <String>{
      ...ChessSoundService.pieceAssetPaths.values,
      'audio/check-warning.wav',
      'audio/chess_capture.wav',
      'audio/chess_check.wav',
      'audio/chess_checkmate_dark.wav',
      'audio/chess_draw.wav',
      'audio/chess_error.wav',
      'audio/chess_move.wav',
      'audio/chess_tap.wav',
      'audio/chess_victory.wav',
    };
    for (final path in paths) {
      final bytes = await rootBundle.load('assets/$path');
      expect(bytes.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('every chess piece has a genuinely distinct sound asset', () {
    final Iterable<String> paths = ChessSoundService.pieceAssetPaths.values;

    expect(ChessSoundService.pieceAssetPaths.keys,
        containsAll(<String>['P', 'N', 'B', 'R', 'Q', 'K']));
    expect(paths.toSet(), hasLength(6));
    expect(ChessSoundService.assetForPiece('n'), 'audio/piece_knight.ogg');
    expect(ChessSoundService.assetForPiece('b'), 'audio/piece_bishop.ogg');
    expect(ChessSoundService.assetForPiece('q'), 'audio/piece_queen.wav');
    expect(ChessSoundService.assetForPiece('k'), 'audio/piece_king.wav');
  });

  test('unknown piece code safely falls back to the normal move sound', () {
    expect(
      ChessSoundService.assetForPiece('?'),
      'audio/chess_move.wav',
    );
  });
}
