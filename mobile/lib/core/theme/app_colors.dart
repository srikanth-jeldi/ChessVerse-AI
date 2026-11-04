import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF071A2C);
  static const Color backgroundDeep = Color(0xFF02070D);
  static const Color surface = Color(0xFF0C2435);
  static const Color surfaceLight = Color(0xFF14384C);
  static const Color surfaceMuted = Color(0xFF0A1C2B);

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF4C1D95);
  static const Color accentGold = Color(0xFFEABF61);
  static const Color accentGoldDark = Color(0xFFD6A84F);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFB1C4D0);
  static const Color textMuted = Color(0xFF91A8B8);
  static const Color border = Color(0xFF315366);
  static const Color accentTeal = Color(0xFF54DECA);

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
    colors: <Color>[Colors.transparent, Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
