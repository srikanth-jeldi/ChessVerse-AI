import 'dart:async';

import 'package:chessverse_ai/core/diagnostics/firebase_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(FirebaseBootstrap.resetForTesting);

  test('concurrent consumers wait for Firebase before proceeding', () async {
    final ready = Completer<void>();
    var calls = 0;
    var consumers = 0;
    FirebaseBootstrap.initializer = () {
      calls++;
      return ready.future;
    };
    final tasks = List.generate(3, (_) async {
      await FirebaseBootstrap.ensureReady();
      consumers++;
    });
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    expect(consumers, 0);
    ready.complete();
    await Future.wait(tasks);
    expect(consumers, 3);
  });

  test('failed initialization permits a later retry', () async {
    FirebaseBootstrap.initializer = () => throw StateError('not ready');
    await expectLater(FirebaseBootstrap.ensureReady(), throwsStateError);
    FirebaseBootstrap.initializer = () async {};
    await FirebaseBootstrap.ensureReady();
  });
}
