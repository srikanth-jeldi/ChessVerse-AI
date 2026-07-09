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
  AudioPlayer? _victoryPlayer;
  AudioPlayer? _drawPlayer;
  AudioPlayer? _uiPlayer;
  AudioPlayer? _errorPlayer;

  bool enabled = true;

  Future<void> move() {
    if (!enabled) return Future<void>.value();
    return _play(
      _movePlayer ??= AudioPlayer(playerId: 'chessverse-move'),
      'audio/chess_move.wav',
      volume: 0.82,
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
      volume: 1.0,
    ).then((_) {
      return Future<void>.delayed(const Duration(milliseconds: 180), () {
        return _play(
          _victoryPlayer ??= AudioPlayer(playerId: 'chessverse-victory'),
          'audio/chess_victory.wav',
          volume: 0.92,
        );
      });
    });
  }

  Future<void> victory() {
    if (!enabled) return Future<void>.value();
    return _play(
      _victoryPlayer ??= AudioPlayer(playerId: 'chessverse-victory'),
      'audio/chess_victory.wav',
      volume: 0.92,
    );
  }

  Future<void> draw() {
    if (!enabled) return Future<void>.value();
    return _play(
      _drawPlayer ??= AudioPlayer(playerId: 'chessverse-draw'),
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
      _errorPlayer ??= AudioPlayer(playerId: 'chessverse-error'),
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
      if (_victoryPlayer != null) _victoryPlayer!.dispose(),
      if (_drawPlayer != null) _drawPlayer!.dispose(),
      if (_uiPlayer != null) _uiPlayer!.dispose(),
      if (_errorPlayer != null) _errorPlayer!.dispose(),
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
