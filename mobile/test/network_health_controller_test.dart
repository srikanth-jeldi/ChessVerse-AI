import 'dart:async';
import 'dart:io';

import 'package:chessverse_ai/core/network/network_health_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel('dev.fluttercommunity.plus/connectivity');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => ['wifi']);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  for (final message in [
    'Network is unreachable',
    'Failed host lookup',
    'Software caused connection abort',
  ]) {
    test(
      'transport failure stays non-blocking and recovers: $message',
      () async {
        final controller = NetworkHealthController.forTesting(
          NetworkHealth.online,
        );
        addTearDown(controller.dispose);
        var recovered = false;
        final client = MockClient((_) async {
          if (!recovered) throw http.ClientException(message);
          return http.Response('{}', 200);
        });
        addTearDown(client.close);
        await http.runWithClient(() async {
          await controller.checkNow();
          expect(controller.health, NetworkHealth.offline);
          expect(controller.showApiUnavailableScreen, isFalse);
          recovered = true;
          await controller.checkNow();
          expect(controller.health, NetworkHealth.online);
        }, () => client);
      },
    );
  }

  test(
    'HTTP server failure remains distinguishable from offline transport',
    () async {
      final controller = NetworkHealthController.forTesting(
        NetworkHealth.online,
      );
      addTearDown(controller.dispose);
      final client = MockClient((_) async => http.Response('', 503));
      addTearDown(client.close);
      await http.runWithClient(controller.checkNow, () => client);
      expect(controller.health, NetworkHealth.apiUnavailable);
      expect(controller.showApiUnavailableScreen, isTrue);
    },
  );

  for (final error in <Object>[
    const SocketException('Network is unreachable'),
    const HandshakeException(
      'CERTIFICATE_VERIFY_FAILED: self signed certificate',
    ),
  ]) {
    test(
      'native transport failure permits offline play and verified recovery: ${error.runtimeType}',
      () async {
        final controller = NetworkHealthController.forTesting(
          NetworkHealth.online,
        );
        addTearDown(controller.dispose);
        var fail = true;
        await http.runWithClient(
          () async {
            await controller.checkNow();
            expect(controller.health, NetworkHealth.offline);
            expect(controller.showApiUnavailableScreen, isFalse);
            fail = false;
            await controller.checkNow();
            expect(controller.health, NetworkHealth.online);
          },
          () => MockClient((_) async {
            if (fail) throw error;
            return http.Response('{}', 200);
          }),
        );
      },
    );
  }

  test('background probes are skipped and late failures cannot replace foreground state', () async {
    final controller = NetworkHealthController.forTesting(NetworkHealth.online);
    addTearDown(controller.dispose);
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    var calls = 0;
    await http.runWithClient(
      () async {
        final oldProbe = controller.checkNow();
        await started.future;
        controller.didChangeAppLifecycleState(AppLifecycleState.paused);
        await controller.checkNow();
        expect(calls, 1);
        controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await controller.checkNow();
        expect(calls, 2);
        pending.complete(http.Response('', 503));
        await oldProbe;
        expect(controller.health, NetworkHealth.online);
      },
      () => MockClient((_) {
        calls++;
        if (calls == 1) {
          started.complete();
          return pending.future;
        }
        return Future.value(http.Response('{}', 200));
      }),
    );
  });

  test(
    'disposing during a probe does not notify a disposed controller',
    () async {
      final controller = NetworkHealthController.forTesting(
        NetworkHealth.online,
      );
      final pending = Completer<http.Response>();
      final started = Completer<void>();
      await http.runWithClient(
        () async {
          final checking = controller.checkNow();
          await started.future;
          controller.dispose();
          pending.complete(http.Response('', 503));
          await checking;
          expect(controller.health, NetworkHealth.online);
        },
        () => MockClient((_) {
          started.complete();
          return pending.future;
        }),
      );
    },
  );
}
