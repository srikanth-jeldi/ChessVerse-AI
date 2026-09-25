import 'dart:convert';

import 'package:chessverse_ai/core/audio/cloud_narration_service.dart';
import 'package:flutter/foundation.dart';
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
    'speech preparation is authenticated and contains no Azure credential',
    () async {
      late http.Request captured;
      final CloudNarrationService service = CloudNarrationService(
        tokenProvider: () async => 'session-token',
        client: MockClient((http.Request request) async {
          captured = request;
          return http.Response('unavailable', 503);
        }),
      );

      await service.prepare(
        text: 'A safe king wins the story.',
        language: 'te',
      );

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
    'missing session uses immediate local fallback without a request',
    () async {
      int requests = 0;
      final CloudNarrationService service = CloudNarrationService(
        tokenProvider: () async => null,
        client: MockClient((http.Request request) async {
          requests++;
          return http.Response('', 500);
        }),
        localSpeaker: (_, _) async => true,
      );

      expect(
        await service.speak(text: 'Visible caption', language: 'en'),
        isTrue,
      );
      expect(requests, 0);
      await service.dispose();
    },
  );

  test(
    'cloud narration preparation is cached without a second request',
    () async {
      int requests = 0;
      final CloudNarrationService service = CloudNarrationService(
        tokenProvider: () async => 'session-token',
        client: MockClient((http.Request request) async {
          requests++;
          return http.Response.bytes(
            <int>[73, 68, 51, 4, 0, 0, 0, 0],
            200,
            headers: <String, String>{'content-type': 'audio/mpeg'},
          );
        }),
      );

      await service.prepare(text: 'Cached lesson', language: 'te');
      await service.prepare(text: 'Cached lesson', language: 'te');
      expect(requests, 1);
      await service.dispose();
    },
  );

  test('web-style narration tries Azure before built-in fallback', () async {
    int requests = 0;
    int localSpeaks = 0;
    final CloudNarrationService service = CloudNarrationService(
      preferImmediateLocal: true,
      tokenProvider: () async => 'session-token',
      client: MockClient((http.Request request) async {
        requests++;
        return http.Response('', 503);
      }),
      localSpeaker: (_, _) async {
        localSpeaks++;
        return true;
      },
    );

    expect(
      await service.speak(text: 'Azure lesson', language: 'en'),
      isTrue,
    );
    expect(requests, 1);
    expect(localSpeaks, 1);
    await service.dispose();
  });

  test('translated preparation keeps the requested cloud voice', () async {
    int requests = 0;
    late http.Request captured;
    final CloudNarrationService service = CloudNarrationService(
      preferImmediateLocal: true,
      tokenProvider: () async => 'session-token',
      client: MockClient((http.Request request) async {
        requests++;
        captured = request;
        return http.Response.bytes(
          <int>[73, 68, 51, 4, 0, 0, 0, 0],
          200,
          headers: <String, String>{'content-type': 'audio/mpeg'},
        );
      }),
      localSpeaker: (_, _) async => true,
    );

    await service.prepare(text: 'తెలుగు పాఠం', language: 'te');
    expect(requests, 1);
    expect(jsonDecode(captured.body)['language'], 'te');
    await service.dispose();
  });

  test('browser speech can stop and start the next English lesson', () async {
    if (!kIsWeb) return;
    final CloudNarrationService service = CloudNarrationService(
      preferImmediateLocal: true,
      tokenProvider: () async => null,
    );

    expect(
      await service.speak(text: 'First chess lesson.', language: 'en'),
      isTrue,
    );
    await service.stop();
    expect(
      await service.speak(text: 'Next chess lesson.', language: 'en'),
      isTrue,
    );
    await service.dispose();
  });
}
