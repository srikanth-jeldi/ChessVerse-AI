import 'package:flutter/material.dart';

abstract final class ChessVerseColors {
  static const Color ink = Color(0xFF090D14);
  static const Color panel = Color(0xFF131A25);
  static const Color panelSoft = Color(0xFF1C2633);
  static const Color gold = Color(0xFFD6A84F);
  static const Color mint = Color(0xFF63D2B8);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color text = Color(0xFFF6F1E8);
  static const Color muted = Color(0xFFB8B0A2);
}

abstract final class ChessVerseTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ChessVerseColors.ink,
      colorScheme: const ColorScheme.dark(
        primary: ChessVerseColors.gold,
        secondary: ChessVerseColors.mint,
        surface: ChessVerseColors.panel,
        onSurface: ChessVerseColors.text,
        error: ChessVerseColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ChessVerseColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: ChessVerseColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ChessVerseColors.gold,
          foregroundColor: ChessVerseColors.ink,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ChessVerseColors.text,
          side: const BorderSide(color: Color(0xFF4E5A6C)),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
