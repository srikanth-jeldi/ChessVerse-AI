import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

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
  AudioPlayer? _capturePlayer;
  AudioPlayer? _checkPlayer;
  AudioPlayer? _checkmatePlayer;
  AudioPlayer? _uiPlayer;

  bool enabled = true;

  Future<void> move() {
    if (!enabled) return Future<void>.value();
    return _play(
      _movePlayer ??= AudioPlayer(playerId: 'chessverse-move'),
      'audio/chess_move.wav',
      volume: 0.62,
    );
  }

  Future<void> capture() {
    if (!enabled) return Future<void>.value();
    return _play(
      _capturePlayer ??= AudioPlayer(playerId: 'chessverse-capture'),
      'audio/chess_capture.wav',
      volume: 0.78,
    );
  }

  Future<void> check() {
    if (!enabled) return Future<void>.value();
    return _play(
      _checkPlayer ??= AudioPlayer(playerId: 'chessverse-check'),
      'audio/chess_check.wav',
      volume: 0.72,
    );
  }

  Future<void> checkmate() {
    if (!enabled) return Future<void>.value();
    return _play(
      _checkmatePlayer ??= AudioPlayer(playerId: 'chessverse-checkmate'),
      'audio/chess_checkmate_dark.wav',
      volume: 0.9,
    );
  }

  Future<void> victory() {
    if (!enabled) return Future<void>.value();
    return _play(
      _checkmatePlayer ??= AudioPlayer(playerId: 'chessverse-checkmate'),
      'audio/chess_victory.wav',
      volume: 0.86,
    );
  }

  Future<void> draw() {
    if (!enabled) return Future<void>.value();
    return _play(
      _checkmatePlayer ??= AudioPlayer(playerId: 'chessverse-checkmate'),
      'audio/chess_draw.wav',
      volume: 0.72,
    );
  }

  Future<void> tap() {
    if (!enabled) return Future<void>.value();
    return _play(
      _uiPlayer ??= AudioPlayer(playerId: 'chessverse-ui'),
      'audio/chess_tap.wav',
      volume: 0.38,
    );
  }

  Future<void> error() {
    if (!enabled) return Future<void>.value();
    return _play(
      _uiPlayer ??= AudioPlayer(playerId: 'chessverse-ui'),
      'audio/chess_error.wav',
      volume: 0.62,
    );
  }

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      if (_movePlayer != null) _movePlayer!.dispose(),
      if (_capturePlayer != null) _capturePlayer!.dispose(),
      if (_checkPlayer != null) _checkPlayer!.dispose(),
      if (_checkmatePlayer != null) _checkmatePlayer!.dispose(),
      if (_uiPlayer != null) _uiPlayer!.dispose(),
    ]);
  }

  Future<void> _play(
    AudioPlayer player,
    String assetPath, {
    required double volume,
  }) async {
    if (!enabled) {
      return;
    }
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Audio assets may be added after the service is wired. Missing or
      // unsupported audio files should never block gameplay/testing.
    }
  }
}
