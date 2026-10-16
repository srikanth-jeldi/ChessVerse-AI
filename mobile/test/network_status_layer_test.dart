import 'package:chessverse_ai/core/network/network_health_controller.dart';
import 'package:chessverse_ai/core/widgets/network_status_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Health extends NetworkHealthController {
  _Health(super.health) : super.forTesting();
  @override
  Future<void> initialize() async {}
  @override
  Future<void> checkNow() async {}
}

void main() {
  for (final health in [NetworkHealth.offline, NetworkHealth.slow]) {
    testWidgets('$health banner works above Navigator without an Overlay', (
      tester,
    ) async {
      final controller = _Health(health);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              NetworkStatusLayer(controller: controller, child: child!),
          home: const Scaffold(body: Text('Game remains available')),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.text('Game remains available'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
  testWidgets(
    'server error remains readable and dismissible on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _Health(NetworkHealth.apiUnavailable);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: NetworkStatusLayer(controller: controller, child: child!),
          ),
          home: const Scaffold(body: Text('Offline game')),
        ),
      );
      expect(tester.takeException(), isNull);
      final message = find.text(
        'Your local games and learning progress remain safe. Retry now or continue with offline features.',
      );
      expect(
        DefaultTextStyle.of(tester.element(message)).style.decoration,
        isNot(TextDecoration.underline),
      );
      await tester.ensureVisible(find.text('Continue offline'));
      await tester.tap(find.text('Continue offline'));
      await tester.pumpAndSettle();
      expect(find.text('ChessVerseAI server is unavailable'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
