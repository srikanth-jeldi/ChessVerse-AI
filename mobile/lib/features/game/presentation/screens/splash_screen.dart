import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/chessverse_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF02070D), Color(0xFF10251E)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('♟', style: TextStyle(fontSize: 72, color: ChessVerseColors.gold)),
              SizedBox(height: 10),
              Text('ChessVerse AI', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('Play. Learn. Improve.', style: TextStyle(color: ChessVerseColors.muted)),
              SizedBox(height: 28),
              SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3)),
            ],
          ),
        ),
      ),
    );
  }
}
