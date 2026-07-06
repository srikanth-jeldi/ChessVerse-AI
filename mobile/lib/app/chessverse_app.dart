import 'package:flutter/material.dart';

import '../core/theme/chessverse_theme.dart';
import '../features/game/presentation/screens/splash_screen.dart';

class ChessVerseApp extends StatelessWidget {
  const ChessVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessVerse AI',
      debugShowCheckedModeBanner: false,
      theme: ChessVerseTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
