import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Centralized sound effects for ChessVerse.
///
/// Add these files under `assets/audio/` for production audio:
/// - chess_move.mp3
/// - chess_capture.mp3
/// - chess_check.mp3
/// - chess_checkmate_dark.mp3
///
/// Missing files are intentionally ignored so preview builds never crash.
class ChessSoundService {
  ChessSoundService._();

  static final ChessSoundService instance = ChessSoundService._();

  final AudioPlayer _movePlayer = AudioPlayer(playerId: 'chessverse-move');
  final AudioPlayer _capturePlayer = AudioPlayer(playerId: 'chessverse-capture');
  final AudioPlayer _checkPlayer = AudioPlayer(playerId: 'chessverse-check');
  final AudioPlayer _checkmatePlayer = AudioPlayer(playerId: 'chessverse-checkmate');

  bool enabled = true;

  Future<void> move() => _play(_movePlayer, 'audio/chess_move.mp3', volume: 0.62);

  Future<void> capture() =>
      _play(_capturePlayer, 'audio/chess_capture.mp3', volume: 0.78);

  Future<void> check() => _play(_checkPlayer, 'audio/chess_check.mp3', volume: 0.72);

  Future<void> checkmate() => _play(
        _checkmatePlayer,
        'audio/chess_checkmate_dark.mp3',
        volume: 0.9,
      );

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      _movePlayer.dispose(),
      _capturePlayer.dispose(),
      _checkPlayer.dispose(),
      _checkmatePlayer.dispose(),
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
