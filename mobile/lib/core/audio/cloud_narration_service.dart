import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    {
      _localTts.setStartHandler(
        () => onStateChanged?.call(CloudNarrationState.playing),
      );
      _localTts.setCompletionHandler(() {
        _usingLocalTts = false;
        onStateChanged?.call(CloudNarrationState.stopped);
      });
      _localTts.setCancelHandler(() {
        _usingLocalTts = false;
        onStateChanged?.call(CloudNarrationState.stopped);
      });
      _localTts.setErrorHandler((_) {
        _usingLocalTts = false;
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
  final FlutterTts _localTts = FlutterTts();
  bool _usingLocalTts = false;
  String _localText = '';
  late final StreamSubscription<PlayerState> _stateSubscription;
  late final StreamSubscription<void> _completeSubscription;

  void Function(CloudNarrationState state)? onStateChanged;

  Future<bool> speak({required String text, required String language}) async {
    final String cleanText = text.trim();
    if (cleanText.isEmpty || cleanText.length > 2400) return false;
    final String cacheKey = '$language\u0000$cleanText';
    Uint8List? audio = _memoryCache.remove(cacheKey);
    if (audio != null) _memoryCache[cacheKey] = audio;
    try {
      audio ??= await _downloadAudio(cleanText, language, cacheKey);
      if (audio == null) {
        return await _speakLocalFallback(cleanText, language);
      }
      await _player.stop();
      await _player.play(BytesSource(audio));
      return true;
    } on Object {
      onStateChanged?.call(CloudNarrationState.stopped);
      return _speakLocalFallback(cleanText, language);
    }
  }

  /// Fetches narration while the lesson is opening. On web this means the
  /// later button press can start cached audio inside the browser gesture.
  Future<void> prepare({required String text, required String language}) async {
    final String cleanText = text.trim();
    if (cleanText.isEmpty || cleanText.length > 2400) return;
    final String cacheKey = '$language\u0000$cleanText';
    if (_memoryCache.containsKey(cacheKey)) return;
    try {
      await _downloadAudio(cleanText, language, cacheKey);
    } on Object {
      // Local browser/device speech remains the safe fallback on button press.
    }
  }

  Future<Uint8List?> _downloadAudio(
    String text,
    String language,
    String cacheKey,
  ) async {
    final String? token;
    if (_tokenProvider != null) {
      token = await _tokenProvider();
    } else {
      final StoredAuthSession? session = await _sessionStore.read();
      token = session == null || session.isExpired ? null : session.token;
    }
    if (token == null || token.isEmpty) return null;
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
            'text': text,
            'language': language,
          });
    final http.StreamedResponse response = await _client
        .send(request)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 ||
        !(response.headers['content-type'] ?? '').startsWith('audio/mpeg')) {
      await response.stream.drain<void>();
      return null;
    }
    final BytesBuilder bytes = BytesBuilder(copy: false);
    await for (final List<int> chunk in response.stream) {
      bytes.add(chunk);
      if (bytes.length > _maxAudioBytes) return null;
    }
    final Uint8List audio = bytes.takeBytes();
    if (audio.isEmpty) return null;
    _memoryCache[cacheKey] = audio;
    while (_memoryCache.length > _maxCacheEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    return audio;
  }

  Future<bool> _speakLocalFallback(String text, String language) async {
    try {
      final String locale = switch (language.toLowerCase()) {
        'te' => 'te-IN',
        'hi' => 'hi-IN',
        'ta' => 'ta-IN',
        'kn' => 'kn-IN',
        'ml' => 'ml-IN',
        'mr' => 'mr-IN',
        'bn' => 'bn-IN',
        'gu' => 'gu-IN',
        'pa' => 'pa-IN',
        'ur' => 'ur-PK',
        'ar' => 'ar-SA',
        'es' => 'es-ES',
        'fr' => 'fr-FR',
        'de' => 'de-DE',
        'it' => 'it-IT',
        'pt' => 'pt-BR',
        'ru' => 'ru-RU',
        'uk' => 'uk-UA',
        'tr' => 'tr-TR',
        'fa' => 'fa-IR',
        'zh' => 'zh-CN',
        'ja' => 'ja-JP',
        'ko' => 'ko-KR',
        'id' => 'id-ID',
        'ms' => 'ms-MY',
        'th' => 'th-TH',
        'vi' => 'vi-VN',
        'pl' => 'pl-PL',
        'nl' => 'nl-NL',
        'sv' => 'sv-SE',
        'el' => 'el-GR',
        'he' => 'he-IL',
        'sw' => 'sw-KE',
        _ => 'en-IN',
      };
      await _player.stop();
      await _localTts.stop();
      final bool languageAvailable =
          (await _localTts.isLanguageAvailable(locale)) == true;
      await _localTts.setLanguage(languageAvailable ? locale : 'en-US');
      // Web Speech uses 1.0 as its natural rate. The previous .45 setting
      // made Telugu narration sound unnaturally slow and exhausted.
      await _localTts.setSpeechRate(kIsWeb ? .90 : .48);
      await _localTts.setPitch(1.0);
      await _localTts.setVolume(1.0);
      if (!kIsWeb) await _localTts.awaitSpeakCompletion(true);
      _localText = text;
      _usingLocalTts = true;
      onStateChanged?.call(CloudNarrationState.playing);
      final dynamic result = await _localTts.speak(text);
      if (result == 0 || result == false) throw StateError('TTS rejected');
      return true;
    } on Object {
      _usingLocalTts = false;
      onStateChanged?.call(CloudNarrationState.stopped);
      return false;
    }
  }

  Future<void> pause() async {
    if (_usingLocalTts) {
      await _localTts.pause();
    } else {
      await _player.pause();
    }
  }

  Future<void> resume() async {
    if (_usingLocalTts) {
      // Web Speech resumes when speak is invoked while paused.
      await _localTts.speak(_localText);
    } else {
      await _player.resume();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    try {
      await _localTts.stop();
    } on MissingPluginException {
      // Unit tests and unsupported desktop shells do not register native TTS.
    }
    _usingLocalTts = false;
  }

  Future<void> dispose() async {
    await _stateSubscription.cancel();
    await _completeSubscription.cancel();
    _client.close();
    try {
      await _localTts.stop();
    } on MissingPluginException {
      // Unit tests and unsupported desktop shells do not register native TTS.
    }
    await _player.dispose();
  }
}
