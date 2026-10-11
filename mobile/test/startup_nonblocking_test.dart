import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first frame is rendered before optional SDK initialization', () {
    final String source = File('lib/main.dart').readAsStringSync();
    final int mainStart = source.indexOf('Future<void> main() async');
    final int runAppIndex = source.indexOf(
      'runApp(const ChessVerseApp())',
      mainStart,
    );
    final int deferredIndex = source.indexOf(
      '_initializeAfterFirstFrame()',
      runAppIndex,
    );

    expect(mainStart, greaterThanOrEqualTo(0));
    expect(runAppIndex, greaterThan(mainStart));
    expect(deferredIndex, greaterThan(runAppIndex));

    final String criticalPath = source.substring(mainStart, runAppIndex);
    expect(criticalPath, isNot(contains('MobileAds')));
    expect(
      criticalPath,
      isNot(contains('FirebasePushService.instance.initialize')),
    );
    expect(criticalPath, isNot(contains('LocalGameArchive.init')));
    expect(source, isNot(contains('RewardedCoinService.instance.initialize')));
    expect(source, isNot(contains('PostMatchAdService.instance.load()')));
    expect(
      source,
      contains('await Future<void>.delayed(const Duration(milliseconds: 650))'),
    );
    expect(
      source.indexOf('DailyReminderService.instance.initialize()'),
      lessThan(source.indexOf('class _SplashGateState')),
    );
    expect(source, contains('Timer(const Duration(milliseconds: 900)'));
    expect(source, isNot(contains('milliseconds: 2200')));
  });
}
