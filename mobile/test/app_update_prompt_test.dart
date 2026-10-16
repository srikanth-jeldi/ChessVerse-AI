import 'dart:async';

import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_update_prompt.dart';
import 'package:chessverse_ai/core/app_update_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BuildContext screen;
  var now = DateTime.utc(2026, 10, 17);
  Future<void> open(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            screen = context;
            return const Scaffold(body: Text('Home'));
          },
        ),
      ),
    );
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    now = DateTime.utc(2026, 10, 17);
  });

  test('all supported languages have all five update messages', () {
    expect(appUpdateTranslations.length, 34);
    expect(
      appUpdateTranslations.keys.toSet(),
      AppLanguageController.supported
          .where((language) => language.code != 'system')
          .map((language) => language.code)
          .toSet(),
    );
    for (final language in appUpdateTranslations.keys) {
      expect(appUpdateStrings(language), hasLength(5));
      expect(
        appUpdateStrings(language).every((value) => value.isNotEmpty),
        isTrue,
      );
    }
  });

  testWidgets('Later dismisses and suppresses repeat prompts for 24 hours', (
    tester,
  ) async {
    await open(tester);
    var checks = 0;
    AppUpdatePrompt service() => AppUpdatePrompt(
      check: () async {
        checks++;
        return 298;
      },
      now: () => now,
    );
    final first = service().maybeShow(screen, canShow: () => true);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-update-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('app-update-later')));
    await tester.pumpAndSettle();
    await first;
    await service().maybeShow(screen, canShow: () => true);
    expect(checks, 1);
    now = now.add(const Duration(days: 1));
    final next = service().maybeShow(screen, canShow: () => true);
    await tester.pumpAndSettle();
    expect(checks, 2);
    await tester.tap(find.byKey(const ValueKey('app-update-later')));
    await tester.pumpAndSettle();
    await next;
  });

  testWidgets('Update opens store only after explicit tap', (tester) async {
    await open(tester);
    var opened = 0;
    final service = AppUpdatePrompt(
      check: () async => 298,
      openStore: () async {
        opened++;
        return true;
      },
    );
    final pending = service.maybeShow(screen, canShow: () => true);
    await tester.pumpAndSettle();
    expect(opened, 0);
    await tester.tap(find.byKey(const ValueKey('app-update-now')));
    await tester.pumpAndSettle();
    await pending;
    expect(opened, 1);
    await service.maybeShow(screen, canShow: () => true);
    expect(find.byKey(const ValueKey('app-update-dialog')), findsNothing);
  });

  testWidgets('offline and no update leave the game accessible', (
    tester,
  ) async {
    await open(tester);
    await AppUpdatePrompt(check: () async => null)
        .maybeShow(screen, canShow: () => true);
    await AppUpdatePrompt(check: () async => throw Exception('offline'))
        .maybeShow(screen, canShow: () => true);
    expect(find.byKey(const ValueKey('app-update-dialog')), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('slow check times out and ignores a late update result', (
    tester,
  ) async {
    await open(tester);
    final result = Completer<int?>();
    final pending = AppUpdatePrompt(
      check: () => result.future,
      timeout: const Duration(seconds: 1),
    ).maybeShow(screen, canShow: () => true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await pending;
    result.complete(298);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-update-dialog')), findsNothing);
  });

  testWidgets('a late check never interrupts a game route', (tester) async {
    await open(tester);
    final result = Completer<int?>();
    final pending = AppUpdatePrompt(check: () => result.future)
        .maybeShow(screen, canShow: () => true);
    await tester.pump();
    unawaited(
      Navigator.of(screen).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Playing')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    result.complete(298);
    await tester.pumpAndSettle();
    await pending;
    expect(find.text('Playing'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-update-dialog')), findsNothing);
  });

  testWidgets('backgrounded app does not display an update dialog', (
    tester,
  ) async {
    await open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await AppUpdatePrompt(check: () async => 298)
        .maybeShow(screen, canShow: () => true);
    expect(find.byKey(const ValueKey('app-update-dialog')), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
