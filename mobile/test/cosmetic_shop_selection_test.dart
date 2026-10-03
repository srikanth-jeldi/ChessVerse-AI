import 'package:chessverse_ai/features/shop/data/shop_api.dart';
import 'package:chessverse_ai/features/shop/presentation/cosmetic_shop_screen.dart';
import 'package:chessverse_ai/core/chess_piece_appearance.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    ChessPieceAppearanceController.current.value = const ChessPieceAppearance();
  });

  test(
    'every equipped collection board or piece set can use the app default',
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
      expect(canRestoreDefaultCosmetic(boardDefault), false);
      expect(canRestoreDefaultCosmetic(piecesDefault), false);
      expect(canRestoreDefaultCosmetic(premiumBoard), true);
      expect(canRestoreDefaultCosmetic(premiumPieces), true);
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
    expect(canRestoreDefaultCosmetic(defaultFrame), false);
    expect(canRestoreDefaultCosmetic(premiumFrame), false);
    expect(canRestoreDefaultCosmetic(premiumBoard), false);
  });

  test('an equipped free collection item also offers the app default', () {
    final CosmeticItemDto boardDefault = item(
      id: 'board-default',
      category: 'BOARD',
      currency: 'FREE',
      equipped: true,
    );

    expect(canRestoreDefaultCosmetic(boardDefault), true);
  });

  test('equipping a premium set activates its finish for the game board', () {
    const ChessPieceAppearance classic = ChessPieceAppearance(
      style: ChessPieceVisualStyle.classic2d,
      size: ChessPieceVisualSize.extraLarge,
    );

    final ChessPieceAppearance equipped = appearanceForEquippedPieceSet(
      classic,
      'ruby-emperor',
    );

    expect(equipped.style, ChessPieceVisualStyle.premium3d);
    expect(equipped.finish, 'ruby-emperor');
    expect(equipped.size, ChessPieceVisualSize.extraLarge);
  });

  test('server loadout uses premium pieces only while explicitly equipped', () async {
    ShopDto loadout({required bool equipped}) => ShopDto(
      playerId: 'player',
      wallet: const WalletDto(coins: 0, diamonds: 0),
      items: <CosmeticItemDto>[
        item(
          id: 'crimson-crown-3d',
          category: 'PIECES',
          currency: 'FREE',
          equipped: equipped,
        ),
      ],
    );

    await applyServerCosmeticLoadout(loadout(equipped: false));
    expect(
      ChessPieceAppearanceController.current.value.finish,
      'classic-staunton',
    );

    await applyServerCosmeticLoadout(loadout(equipped: true));
    expect(
      ChessPieceAppearanceController.current.value.finish,
      'crimson-crown-3d',
    );

    await applyServerCosmeticLoadout(loadout(equipped: false));
    expect(
      ChessPieceAppearanceController.current.value.finish,
      'classic-staunton',
    );
  });
}
