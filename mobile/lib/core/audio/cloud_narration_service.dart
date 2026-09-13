import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
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
  }

  static const int _maxAudioBytes = 8 * 1024 * 1024;
  static const int _maxCacheEntries = 24;
  static final LinkedHashMap<String, Uint8List> _memoryCache =
      LinkedHashMap<String, Uint8List>();

  final http.Client _client;
  final AudioPlayer _player;
  final AuthSessionStore _sessionStore;
  final Future<String?> Function()? _tokenProvider;
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
      if (token == null || token.isEmpty) return false;
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
          return false;
        }
        final BytesBuilder bytes = BytesBuilder(copy: false);
        await for (final List<int> chunk in response.stream) {
          bytes.add(chunk);
          if (bytes.length > _maxAudioBytes) return false;
        }
        audio = bytes.takeBytes();
        if (audio.isEmpty) return false;
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
      return false;
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.resume();
  Future<void> stop() => _player.stop();

  Future<void> dispose() async {
    await _stateSubscription.cancel();
    await _completeSubscription.cancel();
    _client.close();
    await _player.dispose();
  }
}
