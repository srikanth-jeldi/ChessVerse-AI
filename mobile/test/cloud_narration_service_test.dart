import 'dart:convert';

import 'package:chessverse_ai/core/audio/cloud_narration_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel audioEvents = MethodChannel(
    'xyz.luan/audioplayers.global/events',
  );
  const MethodChannel audioGlobal = MethodChannel(
    'xyz.luan/audioplayers.global',
  );
  const MethodChannel audioPlayer = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(audioEvents, (_) async => null);
    messenger.setMockMethodCallHandler(audioGlobal, (_) async => null);
    messenger.setMockMethodCallHandler(audioPlayer, (_) async => null);
  });

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(audioEvents, null);
    messenger.setMockMethodCallHandler(audioGlobal, null);
    messenger.setMockMethodCallHandler(audioPlayer, null);
  });

  test(
    'speech request is authenticated and contains no Azure credential',
    () async {
      late http.Request captured;
      final CloudNarrationService service = CloudNarrationService(
        tokenProvider: () async => 'session-token',
        client: MockClient((http.Request request) async {
          captured = request;
          return http.Response('unavailable', 503);
        }),
      );

      final bool started = await service.speak(
        text: 'A safe king wins the story.',
        language: 'te',
      );

      expect(started, isFalse);
      expect(captured.headers['Authorization'], 'Bearer session-token');
      expect(captured.url.path, '/api/v1/speech/synthesize');
      expect(jsonDecode(captured.body), <String, String>{
        'text': 'A safe king wins the story.',
        'language': 'te',
      });
      expect(captured.body, isNot(contains('AZURE_SPEECH_KEY')));
      await service.dispose();
    },
  );

  test(
    'missing session uses safe text-only fallback without a request',
    () async {
      int requests = 0;
      final CloudNarrationService service = CloudNarrationService(
        tokenProvider: () async => null,
        client: MockClient((http.Request request) async {
          requests++;
          return http.Response('', 500);
        }),
      );

      expect(
        await service.speak(text: 'Visible caption', language: 'en'),
        isFalse,
      );
      expect(requests, 0);
      await service.dispose();
    },
  );
}
