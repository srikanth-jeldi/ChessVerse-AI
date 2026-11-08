import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized sound effects for ChessVerse.
///
/// Add these files under `assets/audio/` for production audio:
/// - chess_move.wav
/// - chess_capture.wav
/// - chess_check.wav
/// - chess_checkmate_dark.wav
/// - chess_victory.wav
/// - chess_draw.wav
/// - chess_tap.wav
/// - chess_error.wav
///
/// Missing files are intentionally ignored so preview builds never crash.
class ChessSoundService {
  ChessSoundService._();

  static final ChessSoundService instance = ChessSoundService._();

  AudioPlayer? _movePlayer;
  final Map<String, AudioPlayer> _piecePlayers = <String, AudioPlayer>{};
  AudioPlayer? _capturePlayer;
  AudioPlayer? _checkPlayer;
  AudioPlayer? _checkmatePlayer;
  AudioPlayer? _victoryPlayer;
  AudioPlayer? _drawPlayer;
  AudioPlayer? _uiPlayer;
  AudioPlayer? _errorPlayer;

  bool enabled = true;
  bool _disposing = false;
  final Set<AudioPlayer> _prepared = <AudioPlayer>{};
  final Map<AudioPlayer, Future<void>> _inFlight =
      <AudioPlayer, Future<void>>{};

  @visibleForTesting
  int get preparedEffectCount => _prepared.length;

  static const Map<String, String> pieceAssetPaths = <String, String>{
    'P': 'audio/piece_pawn.wav',
    'N': 'audio/piece_knight.ogg',
    'B': 'audio/piece_bishop.ogg',
    'R': 'audio/piece_rook.wav',
    'Q': 'audio/piece_queen.wav',
    'K': 'audio/piece_king.wav',
  };

  static String assetForPiece(String pieceCode) =>
      pieceAssetPaths[pieceCode.toUpperCase()] ?? 'audio/chess_move.wav';

  Future<void> move() {
    if (!enabled || _disposing) return Future<void>.value();
    return _play(
      _movePlayer ??= AudioPlayer(playerId: 'chessverse-move'),
      'audio/chess_move.wav',
      volume: 0.82,
    );
  }

  Future<void> pieceMove(String pieceCode, {bool capture = false}) async {
    if (!enabled || _disposing) return;
    final String normalized = pieceCode.toUpperCase();
    final String name = switch (normalized) {
      'P' => 'pawn',
      'N' => 'knight',
      'B' => 'bishop',
      'R' => 'rook',
      'Q' => 'queen',
      'K' => 'king',
      _ => 'move',
    };
    await _play(
      _piecePlayers.putIfAbsent(
        normalized,
        () => AudioPlayer(playerId: 'chessverse-piece-$name'),
      ),
      assetForPiece(normalized),
      volume: 0.88,
    );
    if (capture) {
      // Let the piece keep its identity (especially the horse/elephant cues)
      // before the impact sound is layered on top.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await this.capture();
    }
  }

  Future<void> capture() {
    if (!enabled || _disposing) return Future<void>.value();
    return _play(
      _capturePlayer ??= AudioPlayer(playerId: 'chessverse-capture'),
      'audio/chess_capture.wav',
      volume: 0.78,
    );
  }

  Future<void> check() async {
    if (!enabled || _disposing) return Future<void>.value();
    // A move/capture cue may have just started. A short gap keeps the check
    // alert crisp instead of masking the selected piece sound.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return _play(
      _checkPlayer ??= AudioPlayer(playerId: 'chessverse-check'),
      'audio/chess_check.wav',
      volume: 0.72,
    );
  }

  Future<void> checkmate() async {
    if (!enabled || _disposing) return Future<void>.value();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _play(
      _checkmatePlayer ??= AudioPlayer(playerId: 'chessverse-checkmate'),
      'audio/chess_checkmate_dark.wav',
      volume: 1.0,
    );
    await Future<void>.delayed(const Duration(milliseconds: 520));
    await _play(
      _victoryPlayer ??= AudioPlayer(playerId: 'chessverse-victory'),
      'audio/chess_victory.wav',
      volume: 0.92,
    );
  }

  Future<void> victory() {
    if (!enabled || _disposing) return Future<void>.value();
    return _play(
      _victoryPlayer ??= AudioPlayer(playerId: 'chessverse-victory'),
      'audio/chess_victory.wav',
      volume: 0.92,
    );
  }

  Future<void> draw() {
    if (!enabled || _disposing) return Future<void>.value();
    return _play(
      _drawPlayer ??= AudioPlayer(playerId: 'chessverse-draw'),
      'audio/chess_draw.wav',
      volume: 0.72,
    );
  }

  Future<void> tap() {
    if (!enabled || _disposing) return Future<void>.value();
    return _play(
      _uiPlayer ??= AudioPlayer(playerId: 'chessverse-ui'),
      'audio/chess_tap.wav',
      volume: 0.38,
    );
  }

  Future<void> error() {
    if (!enabled || _disposing) return Future<void>.value();
    return _play(
      _errorPlayer ??= AudioPlayer(playerId: 'chessverse-error'),
      'audio/chess_error.wav',
      volume: 0.62,
    );
  }

  Future<void> dispose() async {
    if (_disposing) return;
    _disposing = true;
    try {
      await Future.wait(_inFlight.values.toList());
      final players = <AudioPlayer>{
        ?_movePlayer,
        ..._piecePlayers.values,
        ?_capturePlayer,
        ?_checkPlayer,
        ?_checkmatePlayer,
        ?_victoryPlayer,
        ?_drawPlayer,
        ?_uiPlayer,
        ?_errorPlayer,
      };
      await Future.wait(players.map((player) => player.dispose()));
    } finally {
      _movePlayer = _capturePlayer = _checkPlayer = _checkmatePlayer = null;
      _victoryPlayer = _drawPlayer = _uiPlayer = _errorPlayer = null;
      _piecePlayers.clear();
      _prepared.clear();
      _inFlight.clear();
      _disposing = false;
    }
  }

  Future<void> _play(
    AudioPlayer player,
    String assetPath, {
    required double volume,
  }) {
    if (!enabled || _disposing) return Future<void>.value();
    // Coalesce rapid duplicate requests instead of racing native preparations.
    return _inFlight.putIfAbsent(player, () {
      return _playEffect(player, assetPath, volume: volume).whenComplete(() {
        _inFlight.remove(player);
      });
    });
  }

  Future<void> _playEffect(
    AudioPlayer player,
    String assetPath, {
    required double volume,
  }) async {
    if (!enabled || _disposing) {
      return;
    }
    try {
      // Android's file-path MediaPlayer source can synchronously enter a
      // ContentProvider Binder call (seen in Play vitals UrlSource ANRs).
      // Bundled effects are small: use MediaDataSource bytes instead, as the
      // cloud narration player already does, without a temporary file URI.
      if (!_prepared.contains(player)) {
        final Source source;
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          final data = await rootBundle.load('assets/$assetPath');
          source = BytesSource(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        } else {
          source = AssetSource(assetPath);
        }
        if (!enabled || _disposing) return;
        // Retain the bundled effect instead of repeatedly preparing a native
        // MediaPlayer source after every move (the default release mode).
        await player.setReleaseMode(ReleaseMode.stop);
        // Brief board effects must not steal focus and pause the voice coach.
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              audioFocus: AndroidAudioFocus.none,
              usageType: AndroidUsageType.game,
              contentType: AndroidContentType.sonification,
            ),
          ),
        );
        await player.setVolume(volume);
        if (!enabled || _disposing) return;
        await player.setSource(source);
        _prepared.add(player);
      }
      if (!enabled || _disposing) return;
      await player.stop();
      if (!enabled || _disposing) return;
      await player.resume();
    } catch (_) {
      _prepared.remove(player);
      // Audio assets may be added after the service is wired. Missing or
      // unsupported audio files should never block gameplay/testing.
    }
  }
}
