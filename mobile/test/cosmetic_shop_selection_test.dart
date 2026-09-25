import 'package:chessverse_ai/features/shop/data/shop_api.dart';
import 'package:chessverse_ai/features/shop/presentation/cosmetic_shop_screen.dart';
import 'package:flutter_test/flutter_test.dart';

CosmeticItemDto item({
  required String id,
  required String category,
  required String currency,
  bool equipped = false,
}) => CosmeticItemDto(
  id: id,
  slug: id,
  category: category,
  name: id,
  description: '',
  priceCurrency: currency,
  priceAmount: 0,
  owned: true,
  equipped: equipped,
);

void main() {
  test(
    'equipped premium board and pieces can return to their free defaults',
    () {
      final CosmeticItemDto boardDefault = item(
        id: 'board-default',
        category: 'BOARD',
        currency: 'FREE',
      );
      final CosmeticItemDto premiumBoard = item(
        id: 'board-premium',
        category: 'BOARD',
        currency: 'COINS',
        equipped: true,
      );
      final CosmeticItemDto piecesDefault = item(
        id: 'pieces-default',
        category: 'PIECES',
        currency: 'FREE',
      );
      final CosmeticItemDto premiumPieces = item(
        id: 'pieces-premium',
        category: 'PIECES',
        currency: 'COINS',
        equipped: true,
      );
      final List<CosmeticItemDto> catalog = <CosmeticItemDto>[
        boardDefault,
        premiumBoard,
        piecesDefault,
        premiumPieces,
      ];

      expect(defaultCosmeticFor(catalog, 'BOARD'), same(boardDefault));
      expect(defaultCosmeticFor(catalog, 'PIECES'), same(piecesDefault));
      expect(canRestoreDefaultCosmetic(premiumBoard, catalog), isTrue);
      expect(canRestoreDefaultCosmetic(premiumPieces, catalog), isTrue);
      expect(canRestoreDefaultCosmetic(boardDefault, catalog), isFalse);
    },
  );

  test('badges and unequipped items keep their existing equip behaviour', () {
    final CosmeticItemDto defaultFrame = item(
      id: 'frame-default',
      category: 'FRAME',
      currency: 'FREE',
    );
    final CosmeticItemDto premiumFrame = item(
      id: 'frame-premium',
      category: 'FRAME',
      currency: 'COINS',
      equipped: true,
    );
    final CosmeticItemDto premiumBoard = item(
      id: 'board-premium',
      category: 'BOARD',
      currency: 'COINS',
    );
    final List<CosmeticItemDto> catalog = <CosmeticItemDto>[
      defaultFrame,
      premiumFrame,
      premiumBoard,
    ];

    expect(canRestoreDefaultCosmetic(premiumFrame, catalog), isFalse);
    expect(canRestoreDefaultCosmetic(premiumBoard, catalog), isFalse);
  });
}
