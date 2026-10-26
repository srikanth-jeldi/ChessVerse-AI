import 'dart:convert';

import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/auth/data/auth_session_store.dart';
import 'package:chessverse_ai/features/auth/data/guest_feature_trial.dart';
import 'package:chessverse_ai/features/auth/data/guest_progress_merge.dart';
import 'package:chessverse_ai/features/auth/presentation/guest_feature_gate.dart';
import 'package:chessverse_ai/features/auth/presentation/auth_screen.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_review.dart';
import 'package:chessverse_ai/features/tutorial/data/academy_progress_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'trial survives new instances and serializes simultaneous attempts',
    () async {
      final granted = await Future.wait(
        List.generate(
          5,
          (_) => const GuestFeatureTrial().consume(
            'guest:one',
            GuestFeature.review,
          ),
        ),
      );
      expect(granted.where((value) => value).length, 2);
      expect(
        await const GuestFeatureTrial().consume(
          'guest:one',
          GuestFeature.review,
        ),
        false,
      );
      expect(
        await const GuestFeatureTrial().consume(
          'guest:one',
          GuestFeature.mistakeBank,
        ),
        true,
      );
    },
  );

  test(
    'daily reset and ten-day deferral remain feature and identity scoped',
    () async {
      var time = DateTime(2026, 10, 21, 12);
      final trial = GuestFeatureTrial(now: () => time);
      expect(await trial.consume('one', GuestFeature.review), true);
      expect(await trial.consume('one', GuestFeature.review), true);
      expect(await trial.consume('one', GuestFeature.review), false);
      time = time.add(const Duration(days: 1));
      expect(await trial.consume('one', GuestFeature.review), true);
      expect(await trial.consume('one', GuestFeature.review), true);
      final until = await trial.defer('one', GuestFeature.review);
      time = time.add(const Duration(days: 1));
      expect(
        (await trial.attempt('one', GuestFeature.review)).lockedUntil,
        until,
      );
      expect(await trial.defer('one', GuestFeature.review), until);
      expect(await trial.consume('one', GuestFeature.mistakeBank), true);
      expect(await trial.consume('two', GuestFeature.review), true);
      time = until.subtract(const Duration(milliseconds: 1));
      expect(await trial.consume('one', GuestFeature.review), false);
      time = until;
      expect(await trial.consume('one', GuestFeature.review), true);
      expect(await trial.consume('one', GuestFeature.review), true);
      expect(await trial.consume('one', GuestFeature.review), false);
    },
  );

  test('merge restores games once, stays account bound, does not copy streak/coins', () async {
    await LocalGameArchive.activateIdentity('guest:one');
    LocalGameArchive.markDailyChallengeComplete('daily-guest');
    LocalGameArchive.addGame(
      SavedGameRecord(
        mode: 'Computer',
        result: 'You win',
        detail: 'Checkmate',
        moves: ['e4'],
        playedAt: DateTime.utc(2026, 10, 21),
        whitePlayer: 'Guest',
        blackPlayer: 'AI',
      ),
    );
    const storage = FlutterSecureStorage();
    final now = DateTime.utc(2026, 10, 21);
    await const AcademyProgressStore().mergeMistakeReviewsFor('guest:one', {
      'game-1': MistakeReview(
        nextReview: now.add(const Duration(days: 3)),
        updatedAt: now,
        successes: 2,
      ),
    });
    await storage.write(key: 'coins.target', value: '250');
    await GuestProgressMerge.save(
      previous: 'guest:one',
      target: 'account:target',
      samePlayer: false,
    );
    await GuestProgressMerge.restore('account:other');
    expect(await LocalGameArchive.hasActiveIdentity('guest:one'), true);
    // Simulate an existing account restored from cloud before pending merge.
    await LocalGameArchive.activateIdentity('account:target');
    LocalGameArchive.addGame(
      SavedGameRecord(
        mode: 'Computer',
        result: 'Draw',
        detail: 'Draw',
        moves: ['d4'],
        playedAt: DateTime.utc(2026, 10, 20),
        whitePlayer: 'Existing player',
        blackPlayer: 'AI',
      ),
    );
    final recovery = await storage.read(key: 'guest.progress.pending.v1');
    await GuestProgressMerge.restore('account:target');
    expect(LocalGameArchive.games.length, 2);
    expect(LocalGameArchive.stats().dailySolved, 0);
    // Crash after persistence but before clearing the recovery snapshot.
    await storage.write(key: 'guest.progress.pending.v1', value: recovery);
    await GuestProgressMerge.restore('account:target');
    expect(LocalGameArchive.games.length, 2);
    expect(await storage.read(key: 'coins.target'), '250');
    expect(
      (await const AcademyProgressStore().readMistakeReviewsFor(
        'account:target',
      ))['game-1']!.successes,
      2,
    );
  });

  test('new account upgrade keeps the existing guest archive', () async {
    await LocalGameArchive.activateIdentity('guest:new');
    LocalGameArchive.markDailyChallengeComplete('daily-new');
    await GuestProgressMerge.save(
      previous: 'guest:new',
      target: 'account:new',
      samePlayer: true,
    );
    await GuestProgressMerge.restore('account:new');
    expect(await LocalGameArchive.hasActiveIdentity('account:new'), true);
    expect(LocalGameArchive.stats().dailySolved, 1);
  });

  testWidgets('third-use prompt is dismissible and fits all 34 languages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manifest = (await tester.runAsync(
      () => AssetManifest.loadFromAssetBundle(rootBundle),
    ))!;
    final languages = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/i18n/ui/') && path.endsWith('.json'),
        )
        .toList();
    expect(languages.length, 34);
    for (final path in languages) {
      FlutterSecureStorage.setMockInitialValues({});
      final code = path.split('/').last.split('.').first;
      debugPrint('Guest layout: $code');
      final copy = jsonDecode(
        (await tester.runAsync(() => rootBundle.loadString(path)))!,
      ) as Map;
      expect(copy['Save your chess progress'], isNotEmpty);
      expect(
        copy['Free access to this feature reopens in {days} days. You can keep playing as a guest.'],
        contains('{days}'),
      );
      await tester.runAsync(() => UiCopy.load(code));
      await const AuthSessionStore().write(
        StoredAuthSession(
          token: 'guest-token',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          displayName: 'Guest',
          isGuest: true,
        ),
      );
      final session = (await const AuthSessionStore().read())!;
      final identity = await const AuthSessionStore().progressIdentity(session);
      await const GuestFeatureTrial().consume(identity, GuestFeature.review);
      await const GuestFeatureTrial().consume(identity, GuestFeature.review);
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => Directionality(
            textDirection: {'ar', 'ur', 'fa', 'he'}.contains(code)
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
          ),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.4)),
              child: Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await GuestFeatureGate.allow(
                      context,
                      GuestFeature.review,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget, reason: code);
      expect(tester.takeException(), isNull, reason: code);
      await tester.tap(find.text(UiCopy.text('Not now')));
      await tester.pumpAndSettle();
      expect(result, false, reason: code);
      expect(find.byType(SnackBar), findsOneWidget, reason: code);
      expect(tester.takeException(), isNull, reason: '$code cooldown');
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: '$code no repeat popup',
      );
      expect(tester.takeException(), isNull, reason: '$code cooldown repeat');
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => Directionality(
            textDirection: {'ar', 'ur', 'fa', 'he'}.contains(code)
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
          ),
          home: AuthScreen(
            googleChatOnly: true,
            googleAccessMessage: 'Save your games and Mistake Bank with your free Google account.',
            onAuthenticated: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$code Google sign-in');
    }
  });
}
