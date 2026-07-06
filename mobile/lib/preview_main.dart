import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/app_config.dart';
import 'core/theme/chessverse_theme.dart';
import 'features/analysis/presentation/analysis_screen.dart';
import 'features/game/application/game_controller.dart';
import 'features/game/presentation/screens/chess_board_screen.dart';
import 'features/home/presentation/home_dashboard_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/splash/presentation/premium_splash_screen.dart';

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
  runApp(const ChessVersePreviewApp());
}

class ChessVersePreviewApp extends StatelessWidget {
  const ChessVersePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessVerse AI Preview',
      debugShowCheckedModeBanner: false,
      theme: ChessVerseTheme.dark(),
      home: const PreviewSplashGate(),
    );
  }
}

class PreviewSplashGate extends StatefulWidget {
  const PreviewSplashGate({super.key});

  @override
  State<PreviewSplashGate> createState() => _PreviewSplashGateState();
}

class _PreviewSplashGateState extends State<PreviewSplashGate> {
  Timer? _timer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1300), () {
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
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showSplash
          ? const PremiumSplashScreen(key: ValueKey<String>('premium-splash'))
          : const PreviewShell(key: ValueKey<String>('preview-home')),
    );
  }
}

class PreviewShell extends StatelessWidget {
  const PreviewShell({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDashboardScreen(
      playerName: 'Guest Player',
      onPlayVsAi: () => _openGame(context, ChessGameMode.ai),
      onDailyChallenge: () => _showComingSoon(context, 'Daily Challenge'),
      onLocalGame: () => _openGame(context, ChessGameMode.local),
      onAnalysis: () => _openAnalysis(context),
      onProfile: () => _openProfile(context),
      onSettings: () => _openSettings(context),
    );
  }

  void _openGame(BuildContext context, ChessGameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChessBoardScreen(
          mode: mode,
          difficulty: AiDifficulty.medium,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will return after Milestone 1 gameplay QA.')),
    );
  }

  void _openAnalysis(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AnalysisScreen()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }
}
