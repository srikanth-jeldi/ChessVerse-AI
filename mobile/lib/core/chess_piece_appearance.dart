import 'package:flutter/foundation.dart';

enum ChessPieceVisualStyle { premium3d, classic2d, highContrast }

enum ChessPieceVisualSize { large, extraLarge, doubleExtraLarge }

class ChessPieceAppearance {
  const ChessPieceAppearance({
    this.style = ChessPieceVisualStyle.premium3d,
    this.size = ChessPieceVisualSize.extraLarge,
  });

  final ChessPieceVisualStyle style;
  final ChessPieceVisualSize size;

  ChessPieceAppearance copyWith({
    ChessPieceVisualStyle? style,
    ChessPieceVisualSize? size,
  }) =>
      ChessPieceAppearance(
        style: style ?? this.style,
        size: size ?? this.size,
      );
}

abstract final class ChessPieceAppearanceController {
  static final ValueNotifier<ChessPieceAppearance> current =
      ValueNotifier<ChessPieceAppearance>(const ChessPieceAppearance());

  static const List<String> styleLabels = <String>[
    'Premium 3D',
    'Classic 2D',
    'High Contrast',
  ];

  static const List<String> sizeLabels = <String>[
    'Large',
    'Extra Large',
    'Double Extra Large',
  ];

  static ChessPieceVisualStyle styleFromLabel(String label) => switch (label) {
        'Classic' || 'Classic 2D' => ChessPieceVisualStyle.classic2d,
        'Modern' || 'High Contrast' => ChessPieceVisualStyle.highContrast,
        _ => ChessPieceVisualStyle.premium3d,
      };

  static ChessPieceVisualSize sizeFromLabel(String label) => switch (label) {
        'Double Extra Large' => ChessPieceVisualSize.doubleExtraLarge,
        'Extra Large' => ChessPieceVisualSize.extraLarge,
        _ => ChessPieceVisualSize.large,
      };

  static String styleLabel(ChessPieceVisualStyle style) => switch (style) {
        ChessPieceVisualStyle.premium3d => 'Premium 3D',
        ChessPieceVisualStyle.classic2d => 'Classic 2D',
        ChessPieceVisualStyle.highContrast => 'High Contrast',
      };

  static String sizeLabel(ChessPieceVisualSize size) => switch (size) {
        ChessPieceVisualSize.large => 'Large',
        ChessPieceVisualSize.extraLarge => 'Extra Large',
        ChessPieceVisualSize.doubleExtraLarge => 'Double Extra Large',
      };
}
