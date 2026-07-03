import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/app_config.dart';
import 'features/home/presentation/home_dashboard_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'main.dart' as game;

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
      theme: game.ChessVerseTheme.dark(),
      home: const PreviewShell(),
    );
  }
}

class PreviewShell extends StatelessWidget {
  const PreviewShell({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDashboardScreen(
      playerName: 'Guest Player',
      onPlayVsAi: () => _openGame(context, game.GameMode.computer),
      onDailyChallenge: () => _openGame(context, game.GameMode.daily),
      onLocalGame: () => _openGame(context, game.GameMode.local),
      onAnalysis: () => _showComingSoon(context, 'Analysis'),
      onProfile: () => _openProfile(context),
    );
  }

  void _openGame(BuildContext context, game.GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PreviewGameLauncher(mode: mode),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature screen is coming next.')),
    );
  }
}

class _PreviewGameLauncher extends StatefulWidget {
  const _PreviewGameLauncher({required this.mode});

  final game.GameMode mode;

  @override
  State<_PreviewGameLauncher> createState() => _PreviewGameLauncherState();
}

class _PreviewGameLauncherState extends State<_PreviewGameLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final String message = switch (widget.mode) {
        game.GameMode.computer => 'Use Play mode: Vs Computer.',
        game.GameMode.daily => 'Use Play mode: Daily Checkmate.',
        game.GameMode.local => 'Use Play mode: Local 2P.',
        game.GameMode.online => 'Online mode is not enabled yet.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => _openSettings(context),
          ),
        ),
      );
    });
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const game.GameScreen(
      initiallySignedIn: true,
      useRemoteEngine: false,
    );
  }
}
