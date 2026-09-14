import 'package:chessverse_ai/core/chess_piece_appearance.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChessPieceAppearanceController', () {
    test('uses Extra Large pieces by default', () {
      expect(
        const ChessPieceAppearance().size,
        ChessPieceVisualSize.extraLarge,
      );
    });

    test('keeps the equipped premium finish in the game appearance', () {
      const ChessPieceAppearance appearance = ChessPieceAppearance(
        finish: 'sapphire-elite',
      );
      expect(appearance.finish, 'sapphire-elite');
      expect(
        appearance.copyWith(size: ChessPieceVisualSize.large).finish,
        'sapphire-elite',
      );
    });

    test('each Royal Collection finish has a visible five-tone material', () {
      for (final String finish in <String>[
        'crimson-crown-3d',
        'inferno-gold',
        'ruby-emperor',
        'obsidian-regal',
        'sapphire-elite',
        'emerald-sovereign',
      ]) {
        expect(premiumPieceFinishColors(finish, true), hasLength(5));
        expect(premiumPieceFinishColors(finish, false), hasLength(5));
        expect(
          premiumPieceFinishColors(finish, true),
          isNot(equals(premiumPieceFinishColors(finish, false))),
        );
      }
    });

    test(
      'each Royal Collection finish bundles individual gameplay pieces',
      () async {
        final Set<String> assets = <String>{};
        for (final String finish in <String>[
          'crimson-crown-3d',
          'inferno-gold',
          'ruby-emperor',
          'obsidian-regal',
          'sapphire-elite',
          'emerald-sovereign',
        ]) {
          for (final bool white in <bool>[true, false]) {
            for (final String code in <String>['K', 'Q', 'R', 'B', 'N', 'P']) {
              final String? asset = premiumPieceAsset(
                finish,
                ChessPiece(code, white),
              );
              expect(asset, contains('/premium_individual/'));
              expect(asset, endsWith('.webp'));
              assets.add(asset!);
              final ByteData bytes = await rootBundle.load(asset);
              expect(bytes.lengthInBytes, greaterThan(1000), reason: asset);
            }
          }
        }
        expect(assets, hasLength(72));
      },
    );

    test('all twelve Royal Collection boards use premium gameplay images', () {
      for (final BoardPalette palette in boardPalettes.values.take(12)) {
        expect(premiumBoardAsset(palette.label), endsWith('-v1.webp'));
      }
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

  test('world circuit cities select distinct playable board palettes', () {
    expect(tournamentBoardSkin('Hyderabad Royal Cup'), BoardSkin.jadeGlass);
    expect(tournamentBoardSkin('Tokyo Neon Masters'), BoardSkin.sapphire);
    expect(tournamentBoardSkin('Dubai Gold Open'), BoardSkin.royalWalnut);
    expect(tournamentBoardSkin('London Classic'), BoardSkin.tournament);
    expect(tournamentBoardSkin('New York Grand Final'), BoardSkin.marble);
  });

  test('all twelve Royal Collection boards have playable palettes', () {
    const Set<BoardSkin> collection = <BoardSkin>{
      BoardSkin.royalWalnut,
      BoardSkin.oceanTeal,
      BoardSkin.midnightSapphire,
      BoardSkin.emeraldArena,
      BoardSkin.amethystClash,
      BoardSkin.desertGold,
      BoardSkin.frostMarble,
      BoardSkin.jadeDynasty,
      BoardSkin.azureTemple,
      BoardSkin.volcanicObsidian,
      BoardSkin.roseQuartz,
      BoardSkin.celestialSilver,
    };
    expect(collection, hasLength(12));
    expect(boardPalettes.keys, containsAll(collection));
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
    expect(find.text('♟︎'), findsNWidgets(2));
  });
}
