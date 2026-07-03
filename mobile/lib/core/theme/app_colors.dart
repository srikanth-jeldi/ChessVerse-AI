import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF050B18);
  static const Color backgroundDeep = Color(0xFF02070D);
  static const Color surface = Color(0xFF0D1628);
  static const Color surfaceLight = Color(0xFF162238);
  static const Color surfaceMuted = Color(0xFF101827);

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF4C1D95);
  static const Color accentGold = Color(0xFFEABF61);
  static const Color accentGoldDark = Color(0xFFD6A84F);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFF23314A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: <Color>[accentGold, accentGoldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: <Color>[backgroundDeep, background, Color(0xFF081329)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
