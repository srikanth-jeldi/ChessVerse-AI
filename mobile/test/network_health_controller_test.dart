import 'package:chessverse_ai/core/network/network_health_controller.dart';
import 'package:flutter/services.dart';
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

  for (final message in ['Network is unreachable', 'Failed host lookup',
    'Software caused connection abort']) {
    test('transport failure stays non-blocking and recovers: $message', () async {
      final controller = NetworkHealthController.forTesting(NetworkHealth.online);
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
    });
  }

  test('HTTP server failure remains distinguishable from offline transport', () async {
    final controller = NetworkHealthController.forTesting(NetworkHealth.online);
    addTearDown(controller.dispose);
    final client = MockClient((_) async => http.Response('', 503));
    addTearDown(client.close);
    await http.runWithClient(controller.checkNow, () => client);
    expect(controller.health, NetworkHealth.apiUnavailable);
    expect(controller.showApiUnavailableScreen, isTrue);
  });
}
