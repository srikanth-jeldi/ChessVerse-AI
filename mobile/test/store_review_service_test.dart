import 'dart:async';

import 'package:chessverse_ai/core/store_review_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.britannio.in_app_review');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const service = StoreReviewService();
  var requests = 0;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterSecureStorage.setMockInitialValues({});
    requests = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isAvailable') return true;
      if (call.method == 'requestReview') requests++;
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });
  test('first completed game requests once, regardless of result', () async {
    await service.maybeRequestReview(completedGame: true);
    await service.maybeRequestReview(completedGame: true);
    expect(requests, 1);
  });
  test('unfinished games and unsupported platforms never prompt', () async {
    await service.maybeRequestReview(completedGame: false);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await service.maybeRequestReview(completedGame: true);
    expect(requests, 0);
  });
  test(
    'existing users already prompted are not prompted after upgrade',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'settings.playStoreReviewRequested': 'true',
      });
      await service.maybeRequestReview(completedGame: true);
      expect(requests, 0);
    },
  );
  test('unavailable store allows a later request', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    await service.maybeRequestReview(completedGame: true);
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isAvailable') return true;
      requests++;
      return null;
    });
    await service.maybeRequestReview(completedGame: true);
    expect(requests, 1);
  });
  test('plugin failure is contained and does not repeat prompts', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isAvailable') return true;
      requests++;
      throw PlatformException(code: 'store_unavailable');
    });
    await service.maybeRequestReview(completedGame: true);
    await service.maybeRequestReview(completedGame: true);
    expect(requests, 1);
  });
  test('concurrent result callbacks cannot open multiple dialogs', () async {
    final finished = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isAvailable') return true;
      requests++;
      await finished.future;
      return null;
    });
    final first = service.maybeRequestReview(completedGame: true);
    await service.maybeRequestReview(completedGame: true);
    finished.complete();
    await first;
    expect(requests, 1);
  });
}
