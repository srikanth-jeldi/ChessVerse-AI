@Tags(['golden'])
library;

import 'package:chessverse_ai/core/audio/chess_sound_service.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/presentation/analysis_screen.dart';
import 'package:chessverse_ai/features/auth/presentation/auth_screen.dart';
import 'package:chessverse_ai/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:chessverse_ai/features/home/presentation/home_dashboard_screen.dart';
import 'package:chessverse_ai/features/library/presentation/reference_screens.dart';
import 'package:chessverse_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:chessverse_ai/features/profile/presentation/profile_screen.dart';
import 'package:chessverse_ai/features/settings/presentation/settings_screen.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
const MethodChannel _audioEventsChannel =
    MethodChannel('xyz.luan/audioplayers.global/events');
const MethodChannel _audioGlobalChannel =
    MethodChannel('xyz.luan/audioplayers.global');
const MethodChannel _audioPlayerChannel =
    MethodChannel('xyz.luan/audioplayers');

Future<void> _pumpGallery(WidgetTester tester) async {
  await tester.pump();
  for (int index = 0; index < 5; index += 1) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _setPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _setLandscape(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1366, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ChessVerseTheme.dark(),
    // Golden images must not depend on the exact frame at which an ambient
    // animation happens to be sampled.
    home: TickerMode(enabled: false, child: child),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    ChessSoundService.instance.enabled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _secureStorageChannel,
      (MethodCall call) async {
        if (call.method == 'readAll') return <String, String>{};
        if (call.method == 'containsKey') return false;
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_audioEventsChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_audioGlobalChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_audioPlayerChannel, (_) async => null);
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_audioEventsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_audioPlayerChannel, null);
  });

  testWidgets('screen gallery - splash', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const BrandedSplash()));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(BrandedSplash),
      matchesGoldenFile('goldens/01_splash.png'),
    );
  });

  testWidgets('screen gallery - onboarding', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(OnboardingScreen(onComplete: () {})));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/02_onboarding.png'),
    );
  });

  testWidgets('screen gallery - onboarding landscape',
      (WidgetTester tester) async {
    await _setLandscape(tester);
    await tester.pumpWidget(_app(OnboardingScreen(onComplete: () {})));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/02b_onboarding_landscape.png'),
    );
  });

  testWidgets('screen gallery - auth login', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(AuthScreen(onAuthenticated: (_) {})));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(AuthScreen),
      matchesGoldenFile('goldens/03_auth_login.png'),
    );
  });

  testWidgets('screen gallery - auth landscape', (WidgetTester tester) async {
    await _setLandscape(tester);
    await tester.pumpWidget(_app(AuthScreen(onAuthenticated: (_) {})));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(AuthScreen),
      matchesGoldenFile('goldens/03b_auth_landscape.png'),
    );
  });

  testWidgets('screen gallery - home', (WidgetTester tester) async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await _setPhone(tester);
    await tester.pumpWidget(
      _app(
        HomeDashboardScreen(
          playerName: 'Guest Player',
          activityGames: const <SavedGameRecord>[],
          onPlayVsAi: () {},
          onDailyChallenge: () {},
          onLocalGame: () {},
          onOnlineGame: () {},
          onAnalysis: () {},
          onPuzzles: () {},
          onSavedGames: () {},
          onLearnChess: () {},
          onProfile: () {},
          onSettings: () {},
        ),
      ),
    );
    await _pumpGallery(tester);
    await expectLater(
      find.byType(HomeDashboardScreen),
      matchesGoldenFile('goldens/04_home.png'),
    );
  });

  testWidgets('screen gallery - home landscape', (WidgetTester tester) async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await _setLandscape(tester);
    await tester.pumpWidget(
      _app(
        HomeDashboardScreen(
          playerName: 'Guest Player',
          activityGames: const <SavedGameRecord>[],
          onPlayVsAi: () {},
          onDailyChallenge: () {},
          onLocalGame: () {},
          onOnlineGame: () {},
          onAnalysis: () {},
          onPuzzles: () {},
          onSavedGames: () {},
          onLearnChess: () {},
          onProfile: () {},
          onSettings: () {},
        ),
      ),
    );
    await _pumpGallery(tester);
    await expectLater(
      find.byType(HomeDashboardScreen),
      matchesGoldenFile('goldens/04b_home_landscape.png'),
    );
  });

  testWidgets('screen gallery - game portrait', (WidgetTester tester) async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await _setPhone(tester);
    await tester.pumpWidget(
      _app(
        const GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialPlayerName: 'Guest Player',
        ),
      ),
    );
    await _pumpGallery(tester);
    await expectLater(
      find.byType(GameScreen),
      matchesGoldenFile('goldens/05_game_portrait.png'),
    );
  });

  testWidgets('screen gallery - game landscape', (WidgetTester tester) async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await _setLandscape(tester);
    await tester.pumpWidget(
      _app(
        const GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialPlayerName: 'Guest Player',
        ),
      ),
    );
    await _pumpGallery(tester);
    await expectLater(
      find.byType(GameScreen),
      matchesGoldenFile('goldens/06_game_landscape.png'),
    );
  });

  testWidgets('screen gallery - daily challenge', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const DailyChallengeScreen()));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(DailyChallengeScreen),
      matchesGoldenFile('goldens/07_daily_challenge.png'),
    );
  });

  testWidgets('screen gallery - checkmate', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(
      _app(
        const GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: GameMode.local,
          initialPlayerName: 'Guest Player',
        ),
      ),
    );
    await _pumpGallery(tester);
    ChessSoundService.instance.enabled = false;

    for (final (String from, String to) in <(String, String)>[
      ('f2', 'f3'),
      ('e7', 'e5'),
      ('g2', 'g4'),
      ('d8', 'h4'),
    ]) {
      await tester.tap(find.byKey(ValueKey<String>('square-$from')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey<String>('square-$to')));
      await tester.pump(const Duration(milliseconds: 120));
    }
    await _pumpGallery(tester);
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(GameScreen),
      matchesGoldenFile('goldens/08_checkmate.png'),
    );
  });

  testWidgets('screen gallery - analysis', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const AnalysisScreen()));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(AnalysisScreen),
      matchesGoldenFile('goldens/09_analysis.png'),
    );
  });

  testWidgets('screen gallery - profile', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const ProfileScreen()));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('goldens/10_profile.png'),
    );
  });

  testWidgets('screen gallery - settings', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(SettingsScreen(onLogout: () async {})));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/11_settings.png'),
    );
  });

  testWidgets('screen gallery - options', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const GameOptionsScreen()));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(GameOptionsScreen),
      matchesGoldenFile('goldens/12_game_options.png'),
    );
  });

  testWidgets('screen gallery - move history', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const MoveHistoryScreen()));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(MoveHistoryScreen),
      matchesGoldenFile('goldens/13_move_history.png'),
    );
  });

  testWidgets('screen gallery - result win', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const GameResultScreen()));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(GameResultScreen),
      matchesGoldenFile('goldens/14_game_result_win.png'),
    );
  });

  testWidgets('screen gallery - result draw', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const GameResultScreen(draw: true)));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(GameResultScreen),
      matchesGoldenFile('goldens/15_game_result_draw.png'),
    );
  });

  testWidgets('screen gallery - puzzles', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const PuzzlesScreen()));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(PuzzlesScreen),
      matchesGoldenFile('goldens/16_puzzles.png'),
    );
  });

  testWidgets('screen gallery - saved games', (WidgetTester tester) async {
    await _setPhone(tester);
    await tester.pumpWidget(_app(const SavedGamesScreen()));
    await _pumpGallery(tester);
    await expectLater(
      find.byType(SavedGamesScreen),
      matchesGoldenFile('goldens/17_saved_games.png'),
    );
  });
}
