import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_session_store.dart';
import '../config/app_config.dart';

enum CloudNarrationState { stopped, playing, paused }

class CloudNarrationService {
  CloudNarrationService({
    http.Client? client,
    AudioPlayer? player,
    this._sessionStore = const AuthSessionStore(),
    this._tokenProvider,
  }) : _client = client ?? http.Client(),
       _player = player ?? AudioPlayer(playerId: 'chessverse-cloud-narration') {
    _stateSubscription = _player.onPlayerStateChanged.listen((
      PlayerState state,
    ) {
      onStateChanged?.call(switch (state) {
        PlayerState.playing => CloudNarrationState.playing,
        PlayerState.paused => CloudNarrationState.paused,
        _ => CloudNarrationState.stopped,
      });
    });
    _completeSubscription = _player.onPlayerComplete.listen(
      (_) => onStateChanged?.call(CloudNarrationState.stopped),
    );
    if (kIsWeb) {
      _browserTts.setStartHandler(
        () => onStateChanged?.call(CloudNarrationState.playing),
      );
      _browserTts.setCompletionHandler(() {
        _usingBrowserTts = false;
        onStateChanged?.call(CloudNarrationState.stopped);
      });
      _browserTts.setCancelHandler(() {
        _usingBrowserTts = false;
        onStateChanged?.call(CloudNarrationState.stopped);
      });
      _browserTts.setErrorHandler((_) {
        _usingBrowserTts = false;
        onStateChanged?.call(CloudNarrationState.stopped);
      });
    }
  }

  static const int _maxAudioBytes = 8 * 1024 * 1024;
  static const int _maxCacheEntries = 24;
  static final LinkedHashMap<String, Uint8List> _memoryCache =
      LinkedHashMap<String, Uint8List>();

  final http.Client _client;
  final AudioPlayer _player;
  final AuthSessionStore _sessionStore;
  final Future<String?> Function()? _tokenProvider;
  final FlutterTts _browserTts = FlutterTts();
  bool _usingBrowserTts = false;
  String _browserText = '';
  late final StreamSubscription<PlayerState> _stateSubscription;
  late final StreamSubscription<void> _completeSubscription;

  void Function(CloudNarrationState state)? onStateChanged;

  Future<bool> speak({required String text, required String language}) async {
    final String cleanText = text.trim();
    if (cleanText.isEmpty || cleanText.length > 2400) return false;
    try {
      final String? token;
      if (_tokenProvider != null) {
        token = await _tokenProvider();
      } else {
        final StoredAuthSession? session = await _sessionStore.read();
        token = session == null || session.isExpired ? null : session.token;
      }
      if (token == null || token.isEmpty) {
        return await _speakBrowserFallback(cleanText, language);
      }
      final String cacheKey = '$language\u0000$cleanText';
      Uint8List? audio = _memoryCache.remove(cacheKey);
      if (audio != null) {
        _memoryCache[cacheKey] = audio;
      } else {
        final http.Request request =
            http.Request(
                'POST',
                Uri.parse('${AppConfig.apiBaseUrl}/api/v1/speech/synthesize'),
              )
              ..headers.addAll(<String, String>{
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'audio/mpeg',
              })
              ..body = jsonEncode(<String, String>{
                'text': cleanText,
                'language': language,
              });
        final http.StreamedResponse response = await _client
            .send(request)
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200 ||
            !(response.headers['content-type'] ?? '').startsWith(
              'audio/mpeg',
            )) {
          await response.stream.drain<void>();
          return await _speakBrowserFallback(cleanText, language);
        }
        final BytesBuilder bytes = BytesBuilder(copy: false);
        await for (final List<int> chunk in response.stream) {
          bytes.add(chunk);
          if (bytes.length > _maxAudioBytes) return false;
        }
        audio = bytes.takeBytes();
        if (audio.isEmpty) {
          return await _speakBrowserFallback(cleanText, language);
        }
        _memoryCache[cacheKey] = audio;
        while (_memoryCache.length > _maxCacheEntries) {
          _memoryCache.remove(_memoryCache.keys.first);
        }
      }
      await _player.stop();
      await _player.play(BytesSource(audio));
      return true;
    } on Object {
      onStateChanged?.call(CloudNarrationState.stopped);
      return _speakBrowserFallback(cleanText, language);
    }
  }

  Future<bool> _speakBrowserFallback(String text, String language) async {
    if (!kIsWeb) return false;
    try {
      final String locale = switch (language.toLowerCase()) {
        'te' => 'te-IN',
        'hi' => 'hi-IN',
        'ta' => 'ta-IN',
        'kn' => 'kn-IN',
        'ml' => 'ml-IN',
        _ => 'en-IN',
      };
      await _player.stop();
      await _browserTts.stop();
      await _browserTts.setLanguage(locale);
      await _browserTts.setSpeechRate(.45);
      await _browserTts.setPitch(1.0);
      await _browserTts.setVolume(1.0);
      _browserText = text;
      _usingBrowserTts = true;
      onStateChanged?.call(CloudNarrationState.playing);
      await _browserTts.speak(text);
      return true;
    } on Object {
      _usingBrowserTts = false;
      onStateChanged?.call(CloudNarrationState.stopped);
      return false;
    }
  }

  Future<void> pause() async {
    if (_usingBrowserTts) {
      await _browserTts.pause();
    } else {
      await _player.pause();
    }
  }

  Future<void> resume() async {
    if (_usingBrowserTts) {
      // Web Speech resumes when speak is invoked while paused.
      await _browserTts.speak(_browserText);
    } else {
      await _player.resume();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    if (kIsWeb) await _browserTts.stop();
    _usingBrowserTts = false;
  }

  Future<void> dispose() async {
    await _stateSubscription.cancel();
    await _completeSubscription.cancel();
    _client.close();
    if (kIsWeb) await _browserTts.stop();
    await _player.dispose();
  }
}
