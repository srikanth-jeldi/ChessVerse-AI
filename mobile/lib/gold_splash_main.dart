import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/app_config.dart';
import 'features/splash/presentation/reference_splash_screen.dart';
import 'main.dart' as game;
import 'preview_main.dart' show PreviewShell;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );
  AppConfig.validate();
  runApp(const GoldSplashApp());
}

class GoldSplashApp extends StatelessWidget {
  const GoldSplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessVerse AI',
      debugShowCheckedModeBanner: false,
      theme: game.ChessVerseTheme.dark(),
      home: const GoldSplashGate(),
    );
  }
}

class GoldSplashGate extends StatefulWidget {
  const GoldSplashGate({super.key});

  @override
  State<GoldSplashGate> createState() => _GoldSplashGateState();
}

class _GoldSplashGateState extends State<GoldSplashGate> {
  Timer? _timer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: _showSplash ? const ReferenceSplashScreen() : const PreviewShell(),
    );
  }
}
