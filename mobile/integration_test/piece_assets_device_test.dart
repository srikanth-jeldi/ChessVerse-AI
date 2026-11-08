import 'package:chessverse_ai/core/chess_piece_appearance.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('all refreshed pieces render on phone in LTR and RTL', (
    tester,
  ) async {
    for (final finish in [
      'classic-staunton',
      'crimson-crown-3d',
      'inferno-gold',
      'ruby-emperor',
      'obsidian-regal',
      'sapphire-elite',
      'emerald-sovereign',
    ]) {
      ChessPieceAppearanceController.current.value = ChessPieceAppearance(
        finish: finish,
      );
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                backgroundColor: const Color(0xFF102739),
                body: SafeArea(
                  child: Column(
                    children: [
                      Text(finish, style: const TextStyle(color: Colors.white)),
                      for (final white in [true, false])
                        Wrap(
                          children: [
                            for (final code in ['K', 'Q', 'B', 'N', 'R', 'P'])
                              SizedBox.square(
                                dimension: 52,
                                child: ChessCoin(
                                  piece: ChessPiece(code, white),
                                  selected: false,
                                  accent: Colors.teal,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ChessCoin), findsNWidgets(12));
        expect(tester.takeException(), isNull, reason: '$finish / $direction');
      }
    }
    ChessPieceAppearanceController.current.value = const ChessPieceAppearance();
  });
}
