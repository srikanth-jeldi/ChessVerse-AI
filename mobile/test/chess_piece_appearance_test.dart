import 'package:chessverse_ai/core/chess_piece_appearance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChessPieceAppearanceController', () {
    test('maps current and legacy style labels', () {
      expect(
        ChessPieceAppearanceController.styleFromLabel('Premium 3D'),
        ChessPieceVisualStyle.premium3d,
      );
      expect(
        ChessPieceAppearanceController.styleFromLabel('Classic'),
        ChessPieceVisualStyle.classic2d,
      );
      expect(
        ChessPieceAppearanceController.styleFromLabel('Modern'),
        ChessPieceVisualStyle.highContrast,
      );
    });

    test('maps visible size labels', () {
      expect(
        ChessPieceAppearanceController.sizeFromLabel('Extra Large'),
        ChessPieceVisualSize.extraLarge,
      );
      expect(
        ChessPieceAppearanceController.sizeFromLabel('Large'),
        ChessPieceVisualSize.large,
      );
    });
  });
}
