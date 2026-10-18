import 'dart:async';

import 'package:chessverse_ai/core/computer_game_store.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final action in ['hint', 'analysis']) {
    testWidgets(
      '$action failure after leaving game does not update disposed state',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({
          'settings.coachLanguage': 'en',
        });
        ComputerGameStore.resetForTesting();
        tester.view.physicalSize = const Size(1400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final response = Completer<http.Response>();
        var requested = false;
        await http.runWithClient(
          () async {
            await tester.pumpWidget(
              const MaterialApp(
                home: GameScreen(
                  initiallySignedIn: true,
                  useRemoteEngine: true,
                ),
              ),
            );
            await tester.pump();
            await tester.pump();
            final dynamic panel = tester.widget(
              find.byWidgetPredicate(
                (widget) =>
                    widget.runtimeType.toString() == '_StudioCoachPanel',
              ),
            );
            if (action == 'hint') {
              panel.onHint();
            } else {
              panel.onAnalyze();
            }
            await tester.pump();
            expect(requested, isTrue);
            await tester.pumpWidget(const SizedBox());
            response.complete(http.Response('unavailable', 503));
            await tester.pump();
            await tester.pump();
            expect(tester.takeException(), isNull);
          },
          () => MockClient((request) {
            if (request.url.path.endsWith('/engine/analyze')) {
              requested = true;
              return response.future;
            }
            return Future.value(http.Response('{}', 200));
          }),
        );
      },
    );
  }
}
