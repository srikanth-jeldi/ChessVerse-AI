import 'package:chessverse_ai/core/chess_piece_appearance.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChessPieceAppearanceController', () {
    test('uses Extra Large pieces by default', () {
      expect(
        const ChessPieceAppearance().size,
        ChessPieceVisualSize.extraLarge,
      );
    });

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
      expect(
        ChessPieceAppearanceController.sizeFromLabel('Double Extra Large'),
        ChessPieceVisualSize.doubleExtraLarge,
      );
      expect(
        ChessPieceAppearanceController.sizeLabel(
          ChessPieceVisualSize.doubleExtraLarge,
        ),
        'Double Extra Large',
      );
    });
  });

  testWidgets('Classic 2D uses distinct white and black Unicode pieces', (
    WidgetTester tester,
  ) async {
    ChessPieceAppearanceController.current.value = const ChessPieceAppearance(
      style: ChessPieceVisualStyle.classic2d,
    );
    addTearDown(() {
      ChessPieceAppearanceController.current.value =
          const ChessPieceAppearance();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: <Widget>[
            SizedBox.square(
              dimension: 80,
              child: ChessCoin(
                piece: ChessPiece('P', true),
                selected: false,
                accent: Colors.teal,
              ),
            ),
            SizedBox.square(
              dimension: 80,
              child: ChessCoin(
                piece: ChessPiece('P', false),
                selected: false,
                accent: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('♙'), findsNWidgets(2));
    expect(find.text('♟'), findsNWidgets(2));
  });
}
