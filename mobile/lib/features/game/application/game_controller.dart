import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/chess_move.dart';
import '../domain/chess_piece.dart';
import '../domain/chess_rules.dart';
import '../domain/game_status.dart';

enum ChessGameMode { ai, local }

enum AiDifficulty { easy, medium, hard }

extension AiDifficultyX on AiDifficulty {
  String get label => switch (this) {
        AiDifficulty.easy => 'Easy',
        AiDifficulty.medium => 'Medium',
        AiDifficulty.hard => 'Hard',
      };
}

class GameController extends ChangeNotifier {
  GameController({
    ChessGameMode mode = ChessGameMode.ai,
    AiDifficulty difficulty = AiDifficulty.medium,
  })  : _mode = mode,
        _difficulty = difficulty {
    reset(mode: mode, difficulty: difficulty);
  }

  final math.Random _random = math.Random();

  late BoardState _board;
  final List<ChessMove> _history = <ChessMove>[];
  final List<ChessPiece> _capturedWhite = <ChessPiece>[];
  final List<ChessPiece> _capturedBlack = <ChessPiece>[];

  ChessGameMode _mode;
  AiDifficulty _difficulty;
  PieceColor _turn = PieceColor.white;
  String? _selectedSquare;
  List<String> _legalTargets = <String>[];
  bool _aiThinking = false;
  GameStatus _status = const GameStatus.playing();
  String _message = 'White to move. Select a piece.';

  BoardState get board => Map<String, ChessPiece>.unmodifiable(_board);
  List<ChessMove> get history => List<ChessMove>.unmodifiable(_history);
  List<ChessPiece> get capturedWhite => List<ChessPiece>.unmodifiable(_capturedWhite);
  List<ChessPiece> get capturedBlack => List<ChessPiece>.unmodifiable(_capturedBlack);
  ChessGameMode get mode => _mode;
  AiDifficulty get difficulty => _difficulty;
  PieceColor get turn => _turn;
  String? get selectedSquare => _selectedSquare;
  List<String> get legalTargets => List<String>.unmodifiable(_legalTargets);
  bool get aiThinking => _aiThinking;
  GameStatus get status => _status;
  String get message => _message;

  void reset({ChessGameMode? mode, AiDifficulty? difficulty}) {
    _mode = mode ?? _mode;
    _difficulty = difficulty ?? _difficulty;
    _board = ChessRules.initialBoard();
    _history.clear();
    _capturedWhite.clear();
    _capturedBlack.clear();
    _turn = PieceColor.white;
    _selectedSquare = null;
    _legalTargets = <String>[];
    _aiThinking = false;
    _status = const GameStatus.playing();
    _message = 'White to move. Select a piece.';
    notifyListeners();
  }

  void resign() {
    if (_status.isGameOver) return;
    _status = GameStatus.ended(
      reason: GameEndReason.resignation,
      winnerLabel: _turn.opposite.label,
    );
    _message = _status.detail;
    notifyListeners();
  }

  Future<void> tapSquare(String square) async {
    if (_status.isGameOver || _aiThinking) return;
    if (_mode == ChessGameMode.ai && _turn == PieceColor.black) return;

    final ChessPiece? tappedPiece = _board[square];

    if (_selectedSquare == null) {
      _selectPiece(square, tappedPiece);
      return;
    }

    if (_selectedSquare == square) {
      _clearSelection('${_turn.label} to move.');
      return;
    }

    if (tappedPiece != null && tappedPiece.color == _turn) {
      _selectPiece(square, tappedPiece);
      return;
    }

    if (!_legalTargets.contains(square)) {
      _clearSelection('Illegal move. Pick a highlighted square.');
      return;
    }

    final String from = _selectedSquare!;
    _commitMove(from, square);
    if (_mode == ChessGameMode.ai && !_status.isGameOver && _turn == PieceColor.black) {
      await _scheduleAiMove();
    }
  }

  void _selectPiece(String square, ChessPiece? piece) {
    if (piece == null) {
      _clearSelection('Choose one of your pieces first.');
      return;
    }
    if (piece.color != _turn) {
      _clearSelection('${_turn.label} to move.');
      return;
    }
    final List<String> targets = ChessRules.legalTargets(
      from: square,
      board: _board,
      history: _history,
    );
    _selectedSquare = square;
    _legalTargets = targets;
    _message = targets.isEmpty
        ? 'No legal moves for ${piece.symbol} on $square.'
        : '${piece.symbol} on $square has ${targets.length} legal move${targets.length == 1 ? '' : 's'}.';
    notifyListeners();
  }

  void _clearSelection(String message) {
    _selectedSquare = null;
    _legalTargets = <String>[];
    _message = message;
    notifyListeners();
  }

  void _commitMove(String from, String to) {
    final ChessMove move = ChessRules.buildMove(
      from: from,
      to: to,
      board: _board,
      history: _history,
    );
    final ChessPiece? captured = move.capturedSquare == null ? null : _board[move.capturedSquare];
    if (captured != null) {
      if (captured.color == PieceColor.white) {
        _capturedWhite.add(captured);
      } else {
        _capturedBlack.add(captured);
      }
    }
    _board = ChessRules.applyMove(board: _board, move: move);
    _history.add(move);
    _turn = _turn.opposite;
    _selectedSquare = null;
    _legalTargets = <String>[];
    _refreshStatus(fallback: '${move.notation}. ${_turn.label} to move.');
    notifyListeners();
  }

  void _refreshStatus({required String fallback}) {
    final bool inCheck = ChessRules.isKingInCheck(_turn, _board);
    final bool hasMove = ChessRules.hasAnyLegalMove(_turn, _board, _history);
    if (inCheck && !hasMove) {
      _status = GameStatus.ended(
        reason: GameEndReason.checkmate,
        winnerLabel: _turn.opposite.label,
      );
      _message = _status.detail;
      return;
    }
    if (!inCheck && !hasMove) {
      _status = const GameStatus.ended(reason: GameEndReason.stalemate);
      _message = _status.detail;
      return;
    }
    _status = GameStatus.playing(check: inCheck);
    _message = inCheck ? '${_turn.label} is in check. Find a legal escape.' : fallback;
  }

  Future<void> _scheduleAiMove() async {
    _aiThinking = true;
    _message = '${_difficulty.label} AI is thinking...';
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (_status.isGameOver || _turn != PieceColor.black) {
      _aiThinking = false;
      notifyListeners();
      return;
    }
    final _AiMove? aiMove = _pickAiMove();
    if (aiMove == null) {
      _aiThinking = false;
      _refreshStatus(fallback: 'AI has no legal move.');
      notifyListeners();
      return;
    }
    _aiThinking = false;
    _commitMove(aiMove.from, aiMove.to);
  }

  _AiMove? _pickAiMove() {
    final List<_AiMove> moves = <_AiMove>[];
    for (final MapEntry<String, ChessPiece> entry in _board.entries) {
      if (entry.value.color != PieceColor.black) continue;
      for (final String target in ChessRules.legalTargets(from: entry.key, board: _board, history: _history)) {
        final ChessPiece? captured = _board[target];
        final int captureScore = captured == null ? 0 : _pieceValue(captured.type) * 10;
        final int centerScore = _centerScore(target);
        moves.add(_AiMove(entry.key, target, captureScore + centerScore + _random.nextInt(3)));
      }
    }
    if (moves.isEmpty) return null;
    moves.sort((_AiMove a, _AiMove b) => b.score.compareTo(a.score));
    final int pool = switch (_difficulty) {
      AiDifficulty.easy => moves.length.clamp(1, 8).toInt(),
      AiDifficulty.medium => moves.length.clamp(1, 4).toInt(),
      AiDifficulty.hard => 1,
    };
    return moves[_random.nextInt(pool)];
  }

  int _pieceValue(PieceType type) {
    return switch (type) {
      PieceType.pawn => 1,
      PieceType.knight => 3,
      PieceType.bishop => 3,
      PieceType.rook => 5,
      PieceType.queen => 9,
      PieceType.king => 100,
    };
  }

  int _centerScore(String square) {
    final BoardPoint point = ChessRules.pointOf(square);
    return 7 - (point.file - 3).abs() - (point.rank - 4).abs();
  }
}

class _AiMove {
  const _AiMove(this.from, this.to, this.score);
  final String from;
  final String to;
  final int score;
}
